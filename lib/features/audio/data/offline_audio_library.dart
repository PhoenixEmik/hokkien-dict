import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hokkien_dictionary/features/audio/data/audio_archive_index.dart';
import 'package:hokkien_dictionary/features/audio/data/audio_archive_storage.dart';
import 'package:hokkien_dictionary/features/audio/data/download_service.dart';
import 'package:hokkien_dictionary/features/audio/data/audio_playback_diagnostics.dart';
import 'package:hokkien_dictionary/features/audio/domain/audio_archive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<AudioActionResult> handleDownloadAction(AudioArchiveType type) async {
    final state = downloadState(type);
    if (state == DownloadState.downloading) {
      _downloadServices[type]!.pause();
      return AudioActionResult(message: '已暫停下載 ${type.displayLabel}。');
    }
    if (state == DownloadState.completed && isArchiveReady(type)) {
      return const AudioActionResult();
    }
    return downloadArchive(type);
  }

  Future<AudioActionResult> downloadArchive(AudioArchiveType type) async {
    await initialize();
    if (_supportDirectory == null) {
      return AudioActionResult(
        message: _initializationFailed ? '目前無法初始化離線音檔儲存空間。' : '離線音檔儲存空間尚未準備好。',
        isError: true,
      );
    }

    final service = _downloadServices[type]!;
    if (service.isDownloading) {
      return const AudioActionResult();
    }

    final storage = _storage!;
    final tempFile = storage.downloadTempFile(type);

    try {
      await service.download(
        url: type.sourceUrl,
        targetFile: tempFile,
        fallbackTotalBytes: type.archiveBytes,
      );

      final index = await buildStoredZipIndex(tempFile);
      if (!index.containsKey(type.sampleClipId)) {
        throw FormatException('下載回來的檔案不是 ${type.archiveFileName}');
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

      return AudioActionResult(message: '已下載 ${type.displayLabel}，之後可離線播放。');
    } on DioException catch (_) {
      if (downloadState(type) == DownloadState.paused) {
        return const AudioActionResult();
      }
      return AudioActionResult(
        message:
            '下載 ${type.displayLabel} 失敗：${downloadSnapshot(type).errorMessage ?? '網路連線中斷'}',
        isError: true,
      );
    } catch (error) {
      if (error is FormatException && await tempFile.exists()) {
        await tempFile.delete();
        service.seed(
          const DownloadSnapshot(
            state: DownloadState.error,
            downloadedBytes: 0,
            totalBytes: 0,
            speedBytesPerSecond: 0,
            errorMessage: '下載內容格式不正確',
          ),
        );
      }
      return AudioActionResult(
        message: '下載 ${type.displayLabel} 失敗：$error',
        isError: true,
      );
    }
  }

  Future<AudioActionResult> playClip(
    AudioArchiveType type,
    String clipId,
  ) async {
    await initialize();
    if (_supportDirectory == null) {
      return const AudioActionResult(message: '離線音檔功能尚未初始化完成。', isError: true);
    }

    if (!isArchiveReady(type)) {
      return AudioActionResult(
        message: '請先下載 ${type.archiveFileName}。',
        isError: true,
      );
    }

    final entry = _indexes[type]?[clipId];
    if (entry == null) {
      return AudioActionResult(message: '找不到音檔：$clipId', isError: true);
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
        message: '播放失敗：${error.code} ${error.message ?? ''}'.trim(),
        isError: true,
      );
    } catch (error) {
      _loadingClipKey = null;
      _playingClipKey = null;
      notifyListeners();
      debugPrint(
        '[audio] unexpected playback failure for ${type.name}:$clipId: $error',
      );
      return AudioActionResult(message: '播放失敗：$error', isError: true);
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
}
