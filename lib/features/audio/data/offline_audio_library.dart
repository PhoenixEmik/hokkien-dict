import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';


class OfflineAudioLibrary extends ChangeNotifier {
  OfflineAudioLibrary() {
    for (final type in AudioArchiveType.values) {
      final service = DownloadService();
      service.snapshot.addListener(notifyListeners);
      _downloadServices[type] = service;
    }
  }

  final AudioPlayer _player = AudioPlayer();
  final Map<AudioArchiveType, Map<String, ZipEntryLocation>> _indexes = {
    AudioArchiveType.word: <String, ZipEntryLocation>{},
    AudioArchiveType.sentence: <String, ZipEntryLocation>{},
  };
  final Map<AudioArchiveType, DownloadService> _downloadServices = {};
  final Map<AudioArchiveType, bool> _isReady = {
    AudioArchiveType.word: false,
    AudioArchiveType.sentence: false,
  };

  Directory? _supportDirectory;
  AudioArchiveStorage? _storage;
  bool _initialized = false;
  bool _initializationFailed = false;
  String? _loadingClipKey;
  String? _playingClipKey;
  int _playbackToken = 0;

  bool get initialized => _initialized;

  bool get canUseOfflineAudio => _supportDirectory != null;

  bool isArchiveReady(AudioArchiveType type) => _isReady[type] ?? false;

  ValueListenable<DownloadSnapshot> downloadListenable(AudioArchiveType type) {
    return _downloadServices[type]!.snapshot;
  }

  DownloadSnapshot downloadSnapshot(AudioArchiveType type) {
    return _downloadServices[type]!.snapshot.value;
  }

  DownloadState downloadState(AudioArchiveType type) {
    return downloadSnapshot(type).state;
  }

  bool isDownloading(AudioArchiveType type) {
    return downloadState(type) == DownloadState.downloading;
  }

  double? downloadProgress(AudioArchiveType type) {
    return downloadSnapshot(type).progress;
  }

  String downloadStatus(AudioArchiveType type) {
    final snapshot = downloadSnapshot(type);
    final totalBytes = snapshot.totalBytes > 0
        ? snapshot.totalBytes
        : type.archiveBytes;
    return '${formatBytes(snapshot.downloadedBytes)} / ${formatBytes(totalBytes)}';
  }

  String downloadSpeed(AudioArchiveType type) {
    return formatBytesPerSecond(downloadSnapshot(type).speedBytesPerSecond);
  }

  bool isClipLoading(AudioArchiveType type, String clipId) {
    return _loadingClipKey == _clipKey(type, clipId);
  }

  bool isClipPlaying(AudioArchiveType type, String clipId) {
    return _playingClipKey == _clipKey(type, clipId);
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      _supportDirectory = await getApplicationSupportDirectory();
      _storage = AudioArchiveStorage(_supportDirectory!);
      await _storage!.audioRootDirectory.create(recursive: true);
      for (final type in AudioArchiveType.values) {
        await _loadArchiveState(type);
        await _restoreDownloadSnapshot(type);
      }
    } catch (_) {
      _initializationFailed = true;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<AudioActionResult> handleDownloadAction(
    AudioArchiveType type,
    AppLocalizations l10n,
  ) async {
    final state = downloadState(type);
    if (state == DownloadState.downloading) {
      _downloadServices[type]!.pause();
      return AudioActionResult(
        message: l10n.audioArchivePaused(_archiveLabel(type, l10n)),
      );
    }
    if (state == DownloadState.completed && isArchiveReady(type)) {
      return const AudioActionResult();
    }
    return downloadArchive(type, l10n);
  }

  Future<AudioActionResult> downloadArchive(
    AudioArchiveType type,
    AppLocalizations l10n,
  ) async {
    await initialize();
    if (_supportDirectory == null) {
      return AudioActionResult(
        message: _initializationFailed
            ? l10n.audioStorageInitFailed
            : l10n.audioStorageNotReady,
        isError: true,
      );
    }

    final service = _downloadServices[type]!;
    service.defaultErrorMessage = l10n.downloadFailed;
    if (service.isDownloading) {
      return const AudioActionResult();
    }

    final storage = _storage!;
    final tempFile = storage.downloadTempFile(type);

    try {
      final outcome = await service.download(
        url: type.sourceUrl,
        targetFile: tempFile,
        fallbackTotalBytes: type.archiveBytes,
      );

      if (outcome != DownloadOutcome.completed ||
          !_isDownloadFinalized(service.snapshot.value, type.archiveBytes)) {
        return const AudioActionResult();
      }

      final index = await buildStoredZipIndex(tempFile);
      if (!index.containsKey(type.sampleClipId)) {
        throw FormatException(
          l10n.audioArchiveUnexpectedFile(type.archiveFileName),
        );
      }

      await storage.replaceArchive(
        type: type,
        tempFile: tempFile,
        index: index,
      );
      _indexes[type] = index;
      _isReady[type] = true;
      service.seed(
        DownloadSnapshot(
          state: DownloadState.completed,
          downloadedBytes: type.archiveBytes,
          totalBytes: type.archiveBytes,
          speedBytesPerSecond: 0,
        ),
      );
      notifyListeners();

      return AudioActionResult(
        message: l10n.audioArchiveDownloaded(_archiveLabel(type, l10n)),
      );
    } on DioException catch (_) {
      if (downloadState(type) == DownloadState.paused) {
        return const AudioActionResult();
      }
      return AudioActionResult(
        message: l10n.audioArchiveDownloadFailed(
          _archiveLabel(type, l10n),
          downloadSnapshot(type).errorMessage ?? l10n.networkInterrupted,
        ),
        isError: true,
      );
    } catch (error) {
      if ((error is FormatException ||
              error is StoredZipEntryFormatException ||
              error is ZipIndexNotFoundException) &&
          await tempFile.exists()) {
        await tempFile.delete();
        service.seed(
          DownloadSnapshot(
            state: DownloadState.error,
            downloadedBytes: 0,
            totalBytes: 0,
            speedBytesPerSecond: 0,
            errorMessage: l10n.audioArchiveInvalidContent,
          ),
        );
      }
      final describedError = switch (error) {
        StoredZipEntryFormatException(fileName: final fileName) =>
          l10n.zipEntryNotStored(fileName),
        ZipLocalHeaderFormatException() => l10n.zipLocalHeaderInvalid,
        ZipIndexNotFoundException() => l10n.zipIndexNotFound,
        _ => '$error',
      };
      return AudioActionResult(
        message: l10n.audioArchiveDownloadFailed(
          _archiveLabel(type, l10n),
          describedError,
        ),
        isError: true,
      );
    }
  }

  Future<AudioActionResult> playClip(
    AudioArchiveType type,
    String clipId,
    AppLocalizations l10n,
  ) async {
    await initialize();
    if (_supportDirectory == null) {
      return AudioActionResult(
        message: l10n.offlineAudioNotInitialized,
        isError: true,
      );
    }

    if (!isArchiveReady(type)) {
      return AudioActionResult(
        message: l10n.audioArchiveDownloadFirst(type.archiveFileName),
        isError: true,
      );
    }

    final entry = _indexes[type]?[clipId];
    if (entry == null) {
      return AudioActionResult(
        message: l10n.audioClipNotFound(clipId),
        isError: true,
      );
    }

    final clipKey = _clipKey(type, clipId);
    if (_playingClipKey == clipKey) {
      await _player.stop();
      _playingClipKey = null;
      _loadingClipKey = null;
      notifyListeners();
      return const AudioActionResult();
    }

    _loadingClipKey = clipKey;
    notifyListeners();

    try {
      final clipFile = await materializeStoredZipEntry(
        archiveFile: _storage!.archiveFile(type),
        outputFile: _storage!.clipCacheFile(type, clipId),
        entry: entry,
      );
      final clipDiagnostics = await describeAudioClipFile(clipFile);
      debugPrint(
        '[audio] preparing ${type.name}:$clipId -> ${clipFile.path} '
        '($clipDiagnostics)',
      );

      await _player.stop();
      await _player.setFilePath(clipFile.path);

      _loadingClipKey = null;
      _playingClipKey = clipKey;
      final playbackToken = ++_playbackToken;
      notifyListeners();

      unawaited(
        _player.play().whenComplete(() {
          if (_playbackToken == playbackToken) {
            _playingClipKey = null;
            notifyListeners();
          }
        }),
      );

      return const AudioActionResult();
    } on PlayerException catch (error, stackTrace) {
      _loadingClipKey = null;
      _playingClipKey = null;
      notifyListeners();
      debugPrint(
        '[audio] PlayerException while playing ${type.name}:$clipId '
        'code=${error.code} message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      return AudioActionResult(
        message: l10n.audioPlaybackFailed(
          '${error.code} ${error.message ?? ''}'.trim(),
        ),
        isError: true,
      );
    } catch (error) {
      _loadingClipKey = null;
      _playingClipKey = null;
      notifyListeners();
      debugPrint(
        '[audio] unexpected playback failure for ${type.name}:$clipId: $error',
      );
      return AudioActionResult(
        message: l10n.audioPlaybackFailed(switch (error) {
          StoredZipEntryFormatException(fileName: final fileName) =>
            l10n.zipEntryNotStored(fileName),
          ZipLocalHeaderFormatException() => l10n.zipLocalHeaderInvalid,
          ZipIndexNotFoundException() => l10n.zipIndexNotFound,
          _ => '$error',
        }),
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    for (final service in _downloadServices.values) {
      service.snapshot.removeListener(notifyListeners);
      service.dispose();
    }
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _loadArchiveState(AudioArchiveType type) async {
    final storage = _storage;
    if (storage == null) {
      return;
    }
    final index = await storage.loadArchiveState(type);
    if (index != null) {
      _indexes[type] = index;
      _isReady[type] = true;
    }
  }

  Future<void> _restoreDownloadSnapshot(AudioArchiveType type) async {
    final storage = _storage;
    final service = _downloadServices[type];
    if (storage == null || service == null) {
      return;
    }

    if (_isReady[type] == true) {
      service.seed(
        DownloadSnapshot(
          state: DownloadState.completed,
          downloadedBytes: type.archiveBytes,
          totalBytes: type.archiveBytes,
          speedBytesPerSecond: 0,
        ),
      );
      return;
    }

    final tempFile = storage.downloadTempFile(type);
    if (await tempFile.exists()) {
      final partialBytes = await tempFile.length();
      service.seed(
        DownloadSnapshot(
          state: partialBytes > 0 ? DownloadState.paused : DownloadState.idle,
          downloadedBytes: partialBytes,
          totalBytes: type.archiveBytes,
          speedBytesPerSecond: 0,
        ),
      );
      return;
    }

    service.seed(DownloadSnapshot.idle(totalBytes: type.archiveBytes));
  }

  String _clipKey(AudioArchiveType type, String clipId) {
    return '${type.name}:$clipId';
  }

  String _archiveLabel(AudioArchiveType type, AppLocalizations l10n) {
    return type == AudioArchiveType.word
        ? l10n.audioWordArchive
        : l10n.audioSentenceArchive;
  }

  bool _isDownloadFinalized(DownloadSnapshot snapshot, int fallbackTotalBytes) {
    final resolvedTotal = snapshot.totalBytes > 0
        ? snapshot.totalBytes
        : fallbackTotalBytes;
    return snapshot.state == DownloadState.completed &&
        resolvedTotal > 0 &&
        snapshot.downloadedBytes == resolvedTotal;
  }
}
