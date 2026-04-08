import 'dart:io';
import 'dart:math';

import '../domain/audio_archive.dart';
import 'audio_archive_index.dart';

class AudioArchiveStorage {
  const AudioArchiveStorage(this.supportDirectory);

  final Directory supportDirectory;

  Directory get audioRootDirectory {
    return Directory('${supportDirectory.path}/offline_audio');
  }

  File archiveFile(AudioArchiveType type) {
    return File('${audioRootDirectory.path}/${type.storageStem}.zip');
  }

  File indexFile(AudioArchiveType type) {
    return File('${audioRootDirectory.path}/${type.storageStem}.index.json');
  }

  Directory cacheDirectory(AudioArchiveType type) {
    return Directory('${audioRootDirectory.path}/${type.cacheFolderName}');
  }

  File clipCacheFile(AudioArchiveType type, String clipId) {
    final safeFileName = clipId.replaceAll(RegExp(r'[^0-9A-Za-z()_-]'), '_');
    return File('${cacheDirectory(type).path}/$safeFileName.mp3');
  }

  Future<Map<String, ZipEntryLocation>?> loadArchiveState(
    AudioArchiveType type,
  ) async {
    final archive = archiveFile(type);
    if (!await archive.exists()) {
      return null;
    }

    final index = indexFile(type);
    if (await index.exists()) {
      final cachedIndex = await readZipIndex(index);
      if (cachedIndex.containsKey(type.sampleClipId)) {
        return cachedIndex;
      }
    }

    final rebuiltIndex = await buildStoredZipIndex(archive);
    if (!rebuiltIndex.containsKey(type.sampleClipId)) {
      return null;
    }

    await writeZipIndex(index, rebuiltIndex);
    return rebuiltIndex;
  }

  Future<void> replaceArchive({
    required AudioArchiveType type,
    required File tempFile,
    required Map<String, ZipEntryLocation> index,
  }) async {
    final cache = cacheDirectory(type);
    if (await cache.exists()) {
      await cache.delete(recursive: true);
    }

    final target = archiveFile(type);
    if (await target.exists()) {
      await target.delete();
    }
    await tempFile.rename(target.path);
    await writeZipIndex(indexFile(type), index);
  }
}

class AudioArchiveDownloader {
  const AudioArchiveDownloader({this.maxAttempts = 4});

  final int maxAttempts;

  Future<int> download(
    AudioArchiveType type,
    File tempFile, {
    required void Function(int downloadedBytes, int totalBytes) onProgress,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _downloadOnce(type, tempFile, onProgress: onProgress);
      } on FormatException {
        rethrow;
      } catch (error) {
        lastError = error;
        if (attempt == maxAttempts) {
          break;
        }
        await Future<void>.delayed(_retryDelay(attempt));
      }
    }

    throw HttpException('連線中斷，重試 $maxAttempts 次後仍未完成下載。最後錯誤：$lastError');
  }

  Future<int> _downloadOnce(
    AudioArchiveType type,
    File tempFile, {
    required void Function(int downloadedBytes, int totalBytes) onProgress,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 30);

    try {
      var downloadedBytes = await _existingLength(tempFile);
      onProgress(downloadedBytes, type.archiveBytes);

      final request = await client.getUrl(Uri.parse(type.sourceUrl));
      if (downloadedBytes > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$downloadedBytes-');
      }

      final response = await request.close();
      var totalBytes = type.archiveBytes;
      if (response.statusCode == HttpStatus.partialContent) {
        totalBytes =
            _parseTotalBytesFromContentRange(
              response.headers.value(HttpHeaders.contentRangeHeader),
            ) ??
            totalBytes;
      } else if (response.statusCode == HttpStatus.ok) {
        if (downloadedBytes > 0) {
          await tempFile.delete();
          downloadedBytes = 0;
          onProgress(0, totalBytes);
        }
        if (response.contentLength > 0) {
          totalBytes = response.contentLength;
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
          onProgress(downloadedBytes, totalBytes);
        }
      } finally {
        await sink.close();
      }

      return downloadedBytes;
    } finally {
      client.close(force: true);
    }
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
}
