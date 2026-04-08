import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/audio_archive.dart';
import 'audio_archive_index.dart';

class OfflineAudioLibrary extends ChangeNotifier {
  OfflineAudioLibrary();

  static const int _maxDownloadAttempts = 4;

  final AudioPlayer _player = AudioPlayer();
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
      await _audioRootDirectory.create(recursive: true);
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

    final targetFile = _archiveFile(type);
    final tempFile = File('${targetFile.path}.download');

    try {
      await tempFile.parent.create(recursive: true);
      _downloadedBytes[type] = await _downloadArchiveWithRetry(type, tempFile);

      final index = await buildStoredZipIndex(tempFile);
      if (!index.containsKey(type.sampleClipId)) {
        throw FormatException('下載回來的檔案不是 ${type.archiveFileName}');
      }

      final cacheDirectory = _cacheDirectory(type);
      if (await cacheDirectory.exists()) {
        await cacheDirectory.delete(recursive: true);
      }

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);

      _indexes[type] = index;
      _isReady[type] = true;
      await writeZipIndex(_indexFile(type), index);
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

  Future<int> _downloadArchiveWithRetry(
    AudioArchiveType type,
    File tempFile,
  ) async {
    Object? lastError;

    for (var attempt = 1; attempt <= _maxDownloadAttempts; attempt++) {
      try {
        return await _downloadArchiveOnce(type, tempFile);
      } on FormatException {
        rethrow;
      } catch (error) {
        lastError = error;
        if (attempt == _maxDownloadAttempts) {
          break;
        }
        await Future<void>.delayed(_retryDelay(attempt));
      }
    }

    throw HttpException(
      '連線中斷，重試 $_maxDownloadAttempts 次後仍未完成下載。最後錯誤：$lastError',
    );
  }

  Future<int> _downloadArchiveOnce(AudioArchiveType type, File tempFile) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 30);

    try {
      var downloadedBytes = await _existingLength(tempFile);
      _downloadedBytes[type] = downloadedBytes;
      notifyListeners();

      final request = await client.getUrl(Uri.parse(type.sourceUrl));
      if (downloadedBytes > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$downloadedBytes-');
      }

      final response = await request.close();
      if (response.statusCode == HttpStatus.partialContent) {
        final totalBytes = _parseTotalBytesFromContentRange(
          response.headers.value(HttpHeaders.contentRangeHeader),
        );
        if (totalBytes != null) {
          _totalBytes[type] = totalBytes;
        }
      } else if (response.statusCode == HttpStatus.ok) {
        if (downloadedBytes > 0) {
          await tempFile.delete();
          downloadedBytes = 0;
          _downloadedBytes[type] = 0;
        }
        if (response.contentLength > 0) {
          _totalBytes[type] = response.contentLength;
        }
      } else if (response.statusCode ==
              HttpStatus.requestedRangeNotSatisfiable &&
          downloadedBytes > 0) {
        return downloadedBytes;
      } else {
        throw HttpException('下載失敗，HTTP ${response.statusCode}');
      }

      final sink = tempFile.openWrite(
        mode: downloadedBytes > 0 ? FileMode.append : FileMode.write,
      );
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          _downloadedBytes[type] = downloadedBytes;
          notifyListeners();
        }
      } finally {
        await sink.close();
      }

      return downloadedBytes;
    } finally {
      client.close(force: true);
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
        archiveFile: _archiveFile(type),
        outputFile: _clipCacheFile(type, clipId),
        entry: entry,
      );
      final clipDiagnostics = await _describeClipFile(clipFile);
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
    final archiveFile = _archiveFile(type);
    if (!await archiveFile.exists()) {
      return;
    }

    final indexFile = _indexFile(type);
    if (await indexFile.exists()) {
      final cachedIndex = await readZipIndex(indexFile);
      if (cachedIndex.containsKey(type.sampleClipId)) {
        _indexes[type] = cachedIndex;
        _isReady[type] = true;
        return;
      }
    }

    final rebuiltIndex = await buildStoredZipIndex(archiveFile);
    if (rebuiltIndex.containsKey(type.sampleClipId)) {
      _indexes[type] = rebuiltIndex;
      _isReady[type] = true;
      await writeZipIndex(indexFile, rebuiltIndex);
    }
  }

  Directory get _audioRootDirectory {
    return Directory('${_supportDirectory!.path}/offline_audio');
  }

  File _archiveFile(AudioArchiveType type) {
    return File('${_audioRootDirectory.path}/${type.storageStem}.zip');
  }

  File _indexFile(AudioArchiveType type) {
    return File('${_audioRootDirectory.path}/${type.storageStem}.index.json');
  }

  Directory _cacheDirectory(AudioArchiveType type) {
    return Directory('${_audioRootDirectory.path}/${type.cacheFolderName}');
  }

  File _clipCacheFile(AudioArchiveType type, String clipId) {
    final safeFileName = clipId.replaceAll(RegExp(r'[^0-9A-Za-z()_-]'), '_');
    return File('${_cacheDirectory(type).path}/$safeFileName.mp3');
  }

  Future<String> _describeClipFile(File file) async {
    final exists = await file.exists();
    if (!exists) {
      return 'missing file';
    }

    final length = await file.length();
    final headerBytes = Uint8List.fromList(await file.openRead(0, 12).first);
    final headerKind = _classifyAudioHeader(headerBytes);
    final headerHex = headerBytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    return 'size=${formatBytes(length)}, header=$headerKind [$headerHex]';
  }

  String _classifyAudioHeader(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return 'id3';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return 'mpeg-frame';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return 'riff';
    }
    return 'unknown';
  }

  Future<int> _existingLength(File file) async {
    if (!await file.exists()) {
      return 0;
    }
    return file.length();
  }

  int? _parseTotalBytesFromContentRange(String? contentRange) {
    if (contentRange == null) {
      return null;
    }

    final match = RegExp(r'bytes\s+\d+-\d+/(\d+)').firstMatch(contentRange);
    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1)!);
  }

  Duration _retryDelay(int attempt) {
    return Duration(seconds: min(attempt * 2, 8));
  }

  String _clipKey(AudioArchiveType type, String clipId) {
    return '${type.name}:$clipId';
  }
}
