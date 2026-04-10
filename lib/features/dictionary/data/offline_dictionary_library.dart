import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:taigi_dict/core/constants/app_constants.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/features/audio/data/download_service.dart';
import 'package:taigi_dict/features/audio/domain/audio_archive.dart';
import 'package:taigi_dict/features/dictionary/data/dictionary_database_builder_service.dart';

class OfflineDictionaryLibrary extends ChangeNotifier {
  OfflineDictionaryLibrary() {
    _downloadService.snapshot.addListener(notifyListeners);
  }

  final DownloadService _downloadService = DownloadService();
  final DictionaryDatabaseBuilderService _builderService =
      const DictionaryDatabaseBuilderService();

  bool _initialized = false;
  bool _initializationFailed = false;
  bool _sourceReady = false;

  bool get initialized => _initialized;

  bool get isSourceReady => _sourceReady;

  ValueListenable<DownloadSnapshot> get downloadListenable =>
      _downloadService.snapshot;

  DownloadSnapshot get downloadSnapshot => _downloadService.snapshot.value;

  DownloadState get downloadState => downloadSnapshot.state;

  String get fileName => AppConstants.dictionaryOdsFileName;

  String downloadStatus() {
    final snapshot = downloadSnapshot;
    if (snapshot.totalBytes > 0) {
      return '${formatBytes(snapshot.downloadedBytes)} / ${formatBytes(snapshot.totalBytes)}';
    }
    if (snapshot.downloadedBytes > 0) {
      return formatBytes(snapshot.downloadedBytes);
    }
    return fileName;
  }

  String downloadSpeed() {
    return formatBytesPerSecond(downloadSnapshot.speedBytesPerSecond);
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await reloadState();
    _initialized = true;
  }

  Future<AudioActionResult> handleDownloadAction(AppLocalizations l10n) async {
    if (downloadState == DownloadState.downloading) {
      _downloadService.pause();
      return AudioActionResult(
        message: l10n.dictionarySourcePaused(
          AppConstants.dictionaryOdsFileName,
        ),
      );
    }
    if (downloadState == DownloadState.completed && isSourceReady) {
      return const AudioActionResult();
    }
    return downloadSource(l10n);
  }

  Future<AudioActionResult> downloadSource(AppLocalizations l10n) async {
    await initialize();
    if (_initializationFailed) {
      return AudioActionResult(
        message: l10n.dictionarySourceInitFailed,
        isError: true,
      );
    }

    _downloadService.defaultErrorMessage = l10n.downloadFailed;
    if (_downloadService.isDownloading) {
      return const AudioActionResult();
    }

    final sourceFile = await _builderService.locateDownloadedOdsFile();
    final tempFile = File('${sourceFile.path}.download');

    try {
      if (await sourceFile.exists() && await sourceFile.length() <= 0) {
        await _builderService.deleteDownloadedSourceFiles();
        await _restoreDownloadSnapshot(sourceFile);
      }

      final outcome = await _downloadService.download(
        url: AppConstants.dictionaryOdsUrl,
        targetFile: tempFile,
        fallbackTotalBytes: 0,
      );

      if (outcome != DownloadOutcome.completed ||
          !_isDownloadFinalized(_downloadService.snapshot.value)) {
        _sourceReady = false;
        notifyListeners();
        return const AudioActionResult();
      }

      if (await sourceFile.exists()) {
        await sourceFile.delete();
      }
      await tempFile.rename(sourceFile.path);
      final downloadedBytes = await sourceFile.length();
      _sourceReady = true;
      _downloadService.seed(
        DownloadSnapshot(
          state: DownloadState.completed,
          downloadedBytes: downloadedBytes,
          totalBytes: downloadedBytes,
          speedBytesPerSecond: 0,
        ),
      );
      notifyListeners();

      return AudioActionResult(
        message: l10n.dictionarySourceDownloaded(
          AppConstants.dictionaryOdsFileName,
        ),
      );
    } on DioException catch (_) {
      if (downloadState == DownloadState.paused) {
        return const AudioActionResult();
      }
      return AudioActionResult(
        message: l10n.dictionarySourceDownloadFailed(
          downloadSnapshot.errorMessage ?? l10n.networkInterrupted,
        ),
        isError: true,
      );
    } catch (error) {
      return AudioActionResult(
        message: l10n.dictionarySourceDownloadFailed('$error'),
        isError: true,
      );
    }
  }

  Future<void> reloadState() async {
    _initializationFailed = false;
    try {
      final sourceFile = await _builderService.locateDownloadedOdsFile();
      await sourceFile.parent.create(recursive: true);
      final removedInvalidFile = await _builderService
          .deleteInvalidDownloadedOdsIfNeeded();
      if (removedInvalidFile) {
        _sourceReady = false;
      }
      await _restoreDownloadSnapshot(sourceFile);
    } catch (_) {
      _initializationFailed = true;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> invalidateSource() async {
    await _builderService.deleteDownloadedSourceFiles();
    final sourceFile = await _builderService.locateDownloadedOdsFile();
    await _restoreDownloadSnapshot(sourceFile);
    notifyListeners();
  }

  Future<void> _restoreDownloadSnapshot(File sourceFile) async {
    if (await sourceFile.exists()) {
      final bytes = await sourceFile.length();
      _sourceReady = true;
      _downloadService.seed(
        DownloadSnapshot(
          state: DownloadState.completed,
          downloadedBytes: bytes,
          totalBytes: bytes,
          speedBytesPerSecond: 0,
        ),
      );
      return;
    }

    final tempFile = File('${sourceFile.path}.download');
    if (await tempFile.exists()) {
      final bytes = await tempFile.length();
      _sourceReady = false;
      _downloadService.seed(
        DownloadSnapshot(
          state: DownloadState.paused,
          downloadedBytes: bytes,
          totalBytes: bytes,
          speedBytesPerSecond: 0,
        ),
      );
      return;
    }

    _sourceReady = false;
    _downloadService.seed(const DownloadSnapshot.idle(totalBytes: 0));
  }

  @override
  void dispose() {
    _downloadService.dispose();
    super.dispose();
  }

  bool _isDownloadFinalized(DownloadSnapshot snapshot) {
    return snapshot.state == DownloadState.completed &&
        snapshot.totalBytes > 0 &&
        snapshot.downloadedBytes == snapshot.totalBytes;
  }
}
