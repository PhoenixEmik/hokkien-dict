import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

enum AudioArchiveType { word, sentence }

extension AudioArchiveTypeMetadata on AudioArchiveType {
  String get archiveFileName => switch (this) {
    AudioArchiveType.word => 'sutiau-mp3.zip',
    AudioArchiveType.sentence => 'leku-mp3.zip',
  };

  String get displayLabel => switch (this) {
    AudioArchiveType.word => '詞目音檔',
    AudioArchiveType.sentence => '例句音檔',
  };

  String get sourceUrl => switch (this) {
    AudioArchiveType.word =>
      'https://sutian.moe.edu.tw/media/senn/sutiau-mp3.zip',
    AudioArchiveType.sentence =>
      'https://sutian.moe.edu.tw/media/senn/leku-mp3.zip',
  };

  int get archiveBytes => switch (this) {
    AudioArchiveType.word => 298531008,
    AudioArchiveType.sentence => 514423301,
  };

  String get sampleClipId => switch (this) {
    AudioArchiveType.word => '1(1)',
    AudioArchiveType.sentence => '1-1-1',
  };

  String get cacheFolderName => switch (this) {
    AudioArchiveType.word => 'word_clips',
    AudioArchiveType.sentence => 'sentence_clips',
  };

  String get storageStem => switch (this) {
    AudioArchiveType.word => 'sutiau_mp3',
    AudioArchiveType.sentence => 'leku_mp3',
  };
}

class AudioActionResult {
  const AudioActionResult({this.message, this.isError = false});

  final String? message;
  final bool isError;
}

class OfflineAudioLibrary extends ChangeNotifier {
  OfflineAudioLibrary();

  static const int _maxDownloadAttempts = 4;

  final AudioPlayer _player = AudioPlayer();
  final Map<AudioArchiveType, Map<String, _ZipEntryLocation>> _indexes = {
    AudioArchiveType.word: <String, _ZipEntryLocation>{},
    AudioArchiveType.sentence: <String, _ZipEntryLocation>{},
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

      final index = await _buildIndex(tempFile);
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
      await _writeIndex(type, index);
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
      final clipFile = await _materializeClip(type, clipId, entry);
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
    } catch (error) {
      _loadingClipKey = null;
      _playingClipKey = null;
      notifyListeners();
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
      final cachedIndex = await _readIndex(indexFile);
      if (cachedIndex.containsKey(type.sampleClipId)) {
        _indexes[type] = cachedIndex;
        _isReady[type] = true;
        return;
      }
    }

    final rebuiltIndex = await _buildIndex(archiveFile);
    if (rebuiltIndex.containsKey(type.sampleClipId)) {
      _indexes[type] = rebuiltIndex;
      _isReady[type] = true;
      await _writeIndex(type, rebuiltIndex);
    }
  }

  Future<Map<String, _ZipEntryLocation>> _buildIndex(File archiveFile) async {
    final eocd = await _readEndOfCentralDirectory(archiveFile);
    final archive = await archiveFile.open();

    try {
      await archive.setPosition(eocd.centralDirectoryOffset);
      final directoryBytes = Uint8List.fromList(
        await archive.read(eocd.centralDirectorySize),
      );

      var cursor = 0;
      final entries = <String, _ZipEntryLocation>{};
      while (cursor + 46 <= directoryBytes.length) {
        if (_readUint32(directoryBytes, cursor) != 0x02014b50) {
          break;
        }

        final compressionMethod = _readUint16(directoryBytes, cursor + 10);
        final compressedSize = _readUint32(directoryBytes, cursor + 20);
        final fileNameLength = _readUint16(directoryBytes, cursor + 28);
        final extraLength = _readUint16(directoryBytes, cursor + 30);
        final commentLength = _readUint16(directoryBytes, cursor + 32);
        final localHeaderOffset = _readUint32(directoryBytes, cursor + 42);
        final nameStart = cursor + 46;
        final nameEnd = nameStart + fileNameLength;
        final fileName = utf8.decode(
          directoryBytes.sublist(nameStart, nameEnd),
          allowMalformed: true,
        );

        if (compressionMethod != 0) {
          throw FormatException('zip 內的音檔不是 stored 模式：$fileName');
        }

        final clipId = _clipIdFromPath(fileName);
        if (clipId.isNotEmpty) {
          entries[clipId] = _ZipEntryLocation(
            localHeaderOffset: localHeaderOffset,
            size: compressedSize,
          );
        }

        cursor = nameEnd + extraLength + commentLength;
      }

      return entries;
    } finally {
      await archive.close();
    }
  }

  Future<File> _materializeClip(
    AudioArchiveType type,
    String clipId,
    _ZipEntryLocation entry,
  ) async {
    final cacheFile = _clipCacheFile(type, clipId);
    if (await cacheFile.exists() && await cacheFile.length() == entry.size) {
      return cacheFile;
    }

    await cacheFile.parent.create(recursive: true);
    final archive = await _archiveFile(type).open();

    try {
      await archive.setPosition(entry.localHeaderOffset);
      final localHeader = Uint8List.fromList(await archive.read(30));
      if (_readUint32(localHeader, 0) != 0x04034b50) {
        throw const FormatException('zip 的 local header 格式不正確。');
      }

      final fileNameLength = _readUint16(localHeader, 26);
      final extraLength = _readUint16(localHeader, 28);
      final dataOffset =
          entry.localHeaderOffset + 30 + fileNameLength + extraLength;

      await archive.setPosition(dataOffset);
      final bytes = await archive.read(entry.size);
      await cacheFile.writeAsBytes(bytes, flush: true);
      return cacheFile;
    } finally {
      await archive.close();
    }
  }

  Future<_EndOfCentralDirectory> _readEndOfCentralDirectory(
    File archiveFile,
  ) async {
    final archiveLength = await archiveFile.length();
    final tailLength = min(archiveLength, 65557);
    final archive = await archiveFile.open();

    try {
      await archive.setPosition(archiveLength - tailLength);
      final tail = Uint8List.fromList(await archive.read(tailLength));

      for (var cursor = tail.length - 22; cursor >= 0; cursor--) {
        if (_readUint32(tail, cursor) == 0x06054b50) {
          return _EndOfCentralDirectory(
            entryCount: _readUint16(tail, cursor + 10),
            centralDirectorySize: _readUint32(tail, cursor + 12),
            centralDirectoryOffset: _readUint32(tail, cursor + 16),
          );
        }
      }
    } finally {
      await archive.close();
    }

    throw const FormatException('找不到 zip 索引資訊。');
  }

  Future<Map<String, _ZipEntryLocation>> _readIndex(File indexFile) async {
    final raw =
        jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
    final index = <String, _ZipEntryLocation>{};

    raw.forEach((key, value) {
      final encoded = value as List<dynamic>;
      index[key] = _ZipEntryLocation(
        localHeaderOffset: encoded[0] as int,
        size: encoded[1] as int,
      );
    });

    return index;
  }

  Future<void> _writeIndex(
    AudioArchiveType type,
    Map<String, _ZipEntryLocation> index,
  ) async {
    final indexFile = _indexFile(type);
    await indexFile.parent.create(recursive: true);
    final payload = <String, List<int>>{
      for (final entry in index.entries)
        entry.key: [entry.value.localHeaderOffset, entry.value.size],
    };
    await indexFile.writeAsString(jsonEncode(payload));
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

  int _readUint16(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  int _readUint32(Uint8List bytes, int offset) {
    return _readUint16(bytes, offset) | (_readUint16(bytes, offset + 2) << 16);
  }

  String _clipIdFromPath(String path) {
    final slashIndex = path.lastIndexOf('/');
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex <= slashIndex) {
      return '';
    }
    return path.substring(slashIndex + 1, dotIndex);
  }

  String _clipKey(AudioArchiveType type, String clipId) {
    return '${type.name}:$clipId';
  }
}

class _EndOfCentralDirectory {
  const _EndOfCentralDirectory({
    required this.entryCount,
    required this.centralDirectorySize,
    required this.centralDirectoryOffset,
  });

  final int entryCount;
  final int centralDirectorySize;
  final int centralDirectoryOffset;
}

class _ZipEntryLocation {
  const _ZipEntryLocation({
    required this.localHeaderOffset,
    required this.size,
  });

  final int localHeaderOffset;
  final int size;
}

String formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final fixed = value >= 100 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(fixed)} ${units[unitIndex]}';
}
