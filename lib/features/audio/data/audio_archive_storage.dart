import 'dart:io';

import 'package:taigi_dict/features/audio/data/audio_archive_index.dart';
import 'package:taigi_dict/features/audio/domain/audio_archive.dart';

class AudioArchiveStorage {
  const AudioArchiveStorage(this.supportDirectory);

  final Directory supportDirectory;

  Directory get audioRootDirectory {
    return Directory('${supportDirectory.path}/offline_audio');
  }

  File archiveFile(AudioArchiveType type) {
    return File('${audioRootDirectory.path}/${type.storageStem}.zip');
  }

  File downloadTempFile(AudioArchiveType type) {
    return File('${archiveFile(type).path}.download');
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
