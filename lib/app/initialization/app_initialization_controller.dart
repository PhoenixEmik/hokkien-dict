import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:taigi_dict/core/constants/app_constants.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/features/audio/data/download_service.dart';
import 'package:taigi_dict/features/dictionary/data/dictionary_database_builder_service.dart';
import 'package:taigi_dict/features/dictionary/data/dictionary_repository.dart';
import 'package:taigi_dict/features/dictionary/data/offline_dictionary_library.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppInitializationPhase {
  idle,
  checking,
  downloadingSource,
  parsingSource,
  writingDatabase,
  finalizingDatabase,
  ready,
  error,
}

class AppInitializationController extends ChangeNotifier {
  AppInitializationController({
    required DictionaryDatabaseBuilderService builderService,
    required OfflineDictionaryLibrary dictionaryLibrary,
  }) : _builderService = builderService,
       _dictionaryLibrary = dictionaryLibrary {
    _dictionaryLibrary.addListener(_handleDictionaryLibraryChanged);
  }

  static const databaseReadyPreferenceKey = 'is_db_ready';

  final DictionaryDatabaseBuilderService _builderService;
  final OfflineDictionaryLibrary _dictionaryLibrary;

  AppInitializationPhase _phase = AppInitializationPhase.idle;
  Object? _error;
  DictionaryBuildProgress? _buildProgress;
  Future<void>? _activeOperation;
  int _databaseGeneration = 0;

  AppInitializationPhase get phase => _phase;
  Object? get error => _error;
  DictionaryBuildProgress? get buildProgress => _buildProgress;
  int get databaseGeneration => _databaseGeneration;

  bool get isReady => _phase == AppInitializationPhase.ready;
  bool get isRunning =>
      _phase != AppInitializationPhase.ready &&
      _phase != AppInitializationPhase.error;

  double? get progress {
    if (_phase == AppInitializationPhase.downloadingSource) {
      return _dictionaryLibrary.downloadSnapshot.progress;
    }
    if (_phase == AppInitializationPhase.parsingSource ||
        _phase == AppInitializationPhase.writingDatabase ||
        _phase == AppInitializationPhase.finalizingDatabase) {
      return _buildProgress?.progress;
    }
    return null;
  }

  int get processedUnits => switch (_phase) {
    AppInitializationPhase.downloadingSource =>
      _dictionaryLibrary.downloadSnapshot.downloadedBytes,
    _ => _buildProgress?.processedUnits ?? 0,
  };

  int get totalUnits => switch (_phase) {
    AppInitializationPhase.downloadingSource =>
      _dictionaryLibrary.downloadSnapshot.totalBytes,
    _ => _buildProgress?.totalUnits ?? 0,
  };

  Future<void> initialize(AppLocalizations l10n) {
    return _start(l10n, forceRebuild: false);
  }

  Future<void> retry(AppLocalizations l10n) {
    return _start(l10n, forceRebuild: false);
  }

  Future<void> rebuild(AppLocalizations l10n) {
    return _start(l10n, forceRebuild: true);
  }

  String describeError(AppLocalizations l10n) {
    final error = _error;
    if (error is MissingDictionarySourceException) {
      return l10n.downloadDictionarySourceFirst;
    }
    if (error is CorruptedDictionarySourceException) {
      return l10n.dictionarySourceCorrupted;
    }
    if (error is MissingDictionarySheetException) {
      return l10n.dictionarySourceSheetMissing(error.sheetName);
    }
    if (error is _InitializationException) {
      return error.message;
    }
    return l10n.dictionaryDatabaseRebuildFailed('$error');
  }

  Future<void> _start(AppLocalizations l10n, {required bool forceRebuild}) {
    final activeOperation = _activeOperation;
    if (activeOperation != null) {
      return activeOperation;
    }

    late final Future<void> operation;
    operation = _runInitialization(l10n, forceRebuild: forceRebuild)
        .whenComplete(() {
          if (identical(_activeOperation, operation)) {
            _activeOperation = null;
          }
        });
    _activeOperation = operation;
    return operation;
  }

  Future<void> _runInitialization(
    AppLocalizations l10n, {
    required bool forceRebuild,
  }) async {
    _setPhase(AppInitializationPhase.checking);
    _error = null;
    _buildProgress = null;

    final preferences = await SharedPreferences.getInstance();
    await _dictionaryLibrary.initialize();

    if (!DictionaryRepository.preferLocalDatabase &&
        DictionaryRepository.hasDebugFallbackBundle) {
      _setPhase(AppInitializationPhase.ready);
      return;
    }

    final hasDatabase = await _builderService.hasBuiltDatabase();
    final needsRebuild = forceRebuild || await _builderService.needsRebuild();
    final readyFlag = preferences.getBool(databaseReadyPreferenceKey) ?? false;

    if (hasDatabase && !needsRebuild) {
      if (!readyFlag) {
        await preferences.setBool(databaseReadyPreferenceKey, true);
      }
      _setPhase(AppInitializationPhase.ready);
      return;
    }

    await preferences.setBool(databaseReadyPreferenceKey, false);

    try {
      await _ensureSourceAvailable(l10n);
      await _buildDatabaseWithRecovery(l10n);
      await preferences.setBool(databaseReadyPreferenceKey, true);
      DictionaryRepository.clearBundleCache();
      _databaseGeneration++;
      _setPhase(AppInitializationPhase.ready);
    } catch (error) {
      _error = error;
      _setPhase(AppInitializationPhase.error);
      rethrow;
    }
  }

  Future<void> _ensureSourceAvailable(AppLocalizations l10n) async {
    final hasSource = await _builderService.hasDownloadedOdsFile();
    if (hasSource) {
      final removedInvalid = await _builderService
          .deleteInvalidDownloadedOdsIfNeeded();
      if (removedInvalid) {
        await _dictionaryLibrary.reloadState();
      }
    }

    final refreshedHasSource = await _builderService.hasDownloadedOdsFile();
    if (refreshedHasSource) {
      return;
    }

    _setPhase(AppInitializationPhase.downloadingSource);
    final result = await _dictionaryLibrary.downloadSource(l10n);
    if (result.isError) {
      throw _InitializationException(
        result.message ??
            l10n.dictionarySourceDownloadFailed(l10n.downloadFailed),
      );
    }
    if (!_isDictionarySourceFullyDownloaded()) {
      throw _InitializationException(
        l10n.dictionarySourcePaused(AppConstants.dictionaryOdsFileName),
      );
    }
  }

  Future<void> _buildDatabaseWithRecovery(AppLocalizations l10n) async {
    try {
      await _buildDatabase();
    } on CorruptedDictionarySourceException {
      await _dictionaryLibrary.invalidateSource();
      _setPhase(AppInitializationPhase.downloadingSource);
      final result = await _dictionaryLibrary.downloadSource(l10n);
      if (result.isError) {
        throw _InitializationException(
          result.message ??
              l10n.dictionarySourceDownloadFailed(l10n.downloadFailed),
        );
      }
      if (!_isDictionarySourceFullyDownloaded()) {
        throw _InitializationException(
          l10n.dictionarySourcePaused(AppConstants.dictionaryOdsFileName),
        );
      }
      await _buildDatabase();
    }
  }

  Future<void> _buildDatabase() async {
    await _builderService.rebuildFromDownloadedOds(
      onProgress: (progress) {
        _buildProgress = progress;
        switch (progress.phase) {
          case DictionaryBuildPhase.validatingSource:
            _setPhase(AppInitializationPhase.checking, notify: true);
          case DictionaryBuildPhase.parsingSource:
            _setPhase(AppInitializationPhase.parsingSource, notify: true);
          case DictionaryBuildPhase.writingDatabase:
            _setPhase(AppInitializationPhase.writingDatabase, notify: true);
          case DictionaryBuildPhase.finalizing:
            _setPhase(AppInitializationPhase.finalizingDatabase, notify: true);
        }
      },
    );
  }

  void _handleDictionaryLibraryChanged() {
    if (_phase != AppInitializationPhase.downloadingSource) {
      return;
    }
    notifyListeners();
  }

  void _setPhase(AppInitializationPhase value, {bool notify = true}) {
    _phase = value;
    if (notify) {
      notifyListeners();
    }
  }

  bool _isDictionarySourceFullyDownloaded() {
    final snapshot = _dictionaryLibrary.downloadSnapshot;
    return _dictionaryLibrary.isSourceReady &&
        snapshot.state == DownloadState.completed &&
        snapshot.totalBytes > 0 &&
        snapshot.downloadedBytes == snapshot.totalBytes;
  }

  @override
  void dispose() {
    _dictionaryLibrary.removeListener(_handleDictionaryLibraryChanged);
    super.dispose();
  }
}

class _InitializationException implements Exception {
  const _InitializationException(this.message);

  final String message;
}
