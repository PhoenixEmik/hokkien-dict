import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class StoredZipEntryFormatException implements Exception {
  const StoredZipEntryFormatException({required this.fileName});

  final String fileName;
}

class ZipLocalHeaderFormatException implements Exception {
  const ZipLocalHeaderFormatException();
}

class ZipIndexNotFoundException implements Exception {
  const ZipIndexNotFoundException();
}

class EndOfCentralDirectory {
  const EndOfCentralDirectory({
    required this.entryCount,
    required this.centralDirectorySize,
    required this.centralDirectoryOffset,
  });

  final int entryCount;
  final int centralDirectorySize;
  final int centralDirectoryOffset;
}

class ZipEntryLocation {
  const ZipEntryLocation({required this.localHeaderOffset, required this.size});

  final int localHeaderOffset;
  final int size;
}

Future<Map<String, ZipEntryLocation>> buildStoredZipIndex(
  File archiveFile,
) async {
  final eocd = await readEndOfCentralDirectory(archiveFile);
  final archive = await archiveFile.open();

  try {
    await archive.setPosition(eocd.centralDirectoryOffset);
    final directoryBytes = Uint8List.fromList(
      await archive.read(eocd.centralDirectorySize),
    );

    var cursor = 0;
    final entries = <String, ZipEntryLocation>{};
    while (cursor + 46 <= directoryBytes.length) {
      if (readUint32(directoryBytes, cursor) != 0x02014b50) {
        break;
      }

      final compressionMethod = readUint16(directoryBytes, cursor + 10);
      final compressedSize = readUint32(directoryBytes, cursor + 20);
      final fileNameLength = readUint16(directoryBytes, cursor + 28);
      final extraLength = readUint16(directoryBytes, cursor + 30);
      final commentLength = readUint16(directoryBytes, cursor + 32);
      final localHeaderOffset = readUint32(directoryBytes, cursor + 42);
      final nameStart = cursor + 46;
      final nameEnd = nameStart + fileNameLength;
      final fileName = utf8.decode(
        directoryBytes.sublist(nameStart, nameEnd),
        allowMalformed: true,
      );

      if (compressionMethod != 0) {
        throw StoredZipEntryFormatException(fileName: fileName);
      }

      final clipId = clipIdFromPath(fileName);
      if (clipId.isNotEmpty) {
        entries[clipId] = ZipEntryLocation(
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

Future<File> materializeStoredZipEntry({
  required File archiveFile,
  required File outputFile,
  required ZipEntryLocation entry,
}) async {
  if (await outputFile.exists() && await outputFile.length() == entry.size) {
    return outputFile;
  }

  await outputFile.parent.create(recursive: true);
  final archive = await archiveFile.open();

  try {
    await archive.setPosition(entry.localHeaderOffset);
    final localHeader = Uint8List.fromList(await archive.read(30));
    if (readUint32(localHeader, 0) != 0x04034b50) {
      throw const ZipLocalHeaderFormatException();
    }

    final fileNameLength = readUint16(localHeader, 26);
    final extraLength = readUint16(localHeader, 28);
    final dataOffset =
        entry.localHeaderOffset + 30 + fileNameLength + extraLength;

    await archive.setPosition(dataOffset);
    final bytes = await archive.read(entry.size);
    await outputFile.writeAsBytes(bytes, flush: true);
    return outputFile;
  } finally {
    await archive.close();
  }
}

Future<EndOfCentralDirectory> readEndOfCentralDirectory(
  File archiveFile,
) async {
  final archiveLength = await archiveFile.length();
  final tailLength = archiveLength < 65557 ? archiveLength : 65557;
  final archive = await archiveFile.open();

  try {
    await archive.setPosition(archiveLength - tailLength);
    final tail = Uint8List.fromList(await archive.read(tailLength));

    for (var cursor = tail.length - 22; cursor >= 0; cursor--) {
      if (readUint32(tail, cursor) == 0x06054b50) {
        return EndOfCentralDirectory(
          entryCount: readUint16(tail, cursor + 10),
          centralDirectorySize: readUint32(tail, cursor + 12),
          centralDirectoryOffset: readUint32(tail, cursor + 16),
        );
      }
    }
  } finally {
    await archive.close();
  }

  throw const ZipIndexNotFoundException();
}

Future<Map<String, ZipEntryLocation>> readZipIndex(File indexFile) async {
  final raw =
      jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
  final index = <String, ZipEntryLocation>{};

  raw.forEach((key, value) {
    final encoded = value as List<dynamic>;
    index[key] = ZipEntryLocation(
      localHeaderOffset: encoded[0] as int,
      size: encoded[1] as int,
    );
  });

  return index;
}

Future<void> writeZipIndex(
  File indexFile,
  Map<String, ZipEntryLocation> index,
) async {
  await indexFile.parent.create(recursive: true);
  final payload = <String, List<int>>{
    for (final entry in index.entries)
      entry.key: [entry.value.localHeaderOffset, entry.value.size],
  };
  await indexFile.writeAsString(jsonEncode(payload));
}

int readUint16(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

int readUint32(Uint8List bytes, int offset) {
  return readUint16(bytes, offset) | (readUint16(bytes, offset + 2) << 16);
}

String clipIdFromPath(String path) {
  final slashIndex = path.lastIndexOf('/');
  final dotIndex = path.lastIndexOf('.');
  if (dotIndex <= slashIndex) {
    return '';
  }
  return path.substring(slashIndex + 1, dotIndex);
}
