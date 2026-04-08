import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/audio_archive.dart';
import 'audio_archive_index.dart';
import 'audio_archive_storage.dart';
import 'audio_playback_diagnostics.dart';

class OfflineAudioLibrary extends ChangeNotifier {
  OfflineAudioLibrary();

  final AudioPlayer _player = AudioPlayer();
  final AudioArchiveDownloader _downloader = const AudioArchiveDownloader();
  final Map<AudioArchiveType, Map<String, ZipEntryLocation>> _indexes = {
    AudioArchiveType.word: <String, ZipEntryLocation>{},
    AudioArchiveType.sentence: <String, ZipEntryLocation>{},
  };
  final Map<AudioArchiveType, bool> _isReady = {
    AudioArchiveType.word: false,
    AudioArchiveType.sentence: false,
  };
  final Map<AudioArchiveType, bool> _isDownloading = {
    AudioArchiveType.word: false,
    AudioArchiveType.sentence: false,
  };
  final Map<AudioArchiveType, int> _downloadedBytes = {
    AudioArchiveType.word: 0,
    AudioArchiveType.sentence: 0,
  };
  final Map<AudioArchiveType, int> _totalBytes = {
    AudioArchiveType.word: AudioArchiveType.word.archiveBytes,
    AudioArchiveType.sentence: AudioArchiveType.sentence.archiveBytes,
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

  bool isDownloading(AudioArchiveType type) => _isDownloading[type] ?? false;

  double? downloadProgress(AudioArchiveType type) {
    final totalBytes = _totalBytes[type] ?? 0;
    if (totalBytes <= 0) {
      return null;
    }
    return (_downloadedBytes[type] ?? 0) / totalBytes;
  }

  String downloadStatus(AudioArchiveType type) {
    final downloadedBytes = _downloadedBytes[type] ?? 0;
    final totalBytes = _totalBytes[type] ?? type.archiveBytes;
    return '${formatBytes(downloadedBytes)} / ${formatBytes(totalBytes)}';
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
      }
    } catch (_) {
      _initializationFailed = true;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<AudioActionResult> downloadArchive(AudioArchiveType type) async {
    await initialize();
    if (_supportDirectory == null) {
      return AudioActionResult(
        message: _initializationFailed ? '目前無法初始化離線音檔儲存空間。' : '離線音檔儲存空間尚未準備好。',
        isError: true,
      );
    }

    if (_isDownloading[type] == true) {
      return const AudioActionResult();
    }

    _isDownloading[type] = true;
    _totalBytes[type] = type.archiveBytes;
    notifyListeners();

    final storage = _storage!;
    final targetFile = storage.archiveFile(type);
    final tempFile = File('${targetFile.path}.download');

    try {
      await tempFile.parent.create(recursive: true);
      _downloadedBytes[type] = await _downloader.download(
        type,
        tempFile,
        onProgress: (downloadedBytes, totalBytes) {
          _downloadedBytes[type] = downloadedBytes;
          _totalBytes[type] = totalBytes;
          notifyListeners();
        },
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
      notifyListeners();

      return AudioActionResult(message: '已下載 ${type.displayLabel}，之後可離線播放。');
    } catch (error) {
      if (error is FormatException && await tempFile.exists()) {
        await tempFile.delete();
      }
      return AudioActionResult(
        message: '下載 ${type.displayLabel} 失敗：$error',
        isError: true,
      );
    } finally {
      _isDownloading[type] = false;
      notifyListeners();
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

  String _clipKey(AudioArchiveType type, String clipId) {
    return '${type.name}:$clipId';
  }
}
