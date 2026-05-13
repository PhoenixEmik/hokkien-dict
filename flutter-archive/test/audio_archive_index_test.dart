import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taigi_dict/features/audio/audio.dart';

void main() {
  group('audio archive index helpers', () {
    test('clipIdFromPath extracts basename without extension', () {
      expect(clipIdFromPath('clips/1(1).mp3'), '1(1)');
      expect(clipIdFromPath('1-1-1.wav'), '1-1-1');
      expect(clipIdFromPath('clips/no-extension'), '');
      expect(clipIdFromPath('clips.with.dot/file'), '');
    });

    test('readUint16/readUint32 parse little-endian numbers', () {
      final bytes = Uint8List.fromList([0x34, 0x12, 0x78, 0x56, 0xCD, 0xAB]);
      expect(readUint16(bytes, 0), 0x1234);
      expect(readUint16(bytes, 2), 0x5678);
      expect(readUint32(bytes, 0), 0x56781234);
      expect(readUint32(bytes, 2), 0xABCD5678);
    });
  });

  group('zip index persistence', () {
    test('writeZipIndex and readZipIndex round-trip values', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'zip-index-roundtrip-',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));

      final indexFile = File('${tempDirectory.path}/index.json');
      final source = <String, ZipEntryLocation>{
        '1(1)': const ZipEntryLocation(localHeaderOffset: 12, size: 34),
        '1-1-1': const ZipEntryLocation(localHeaderOffset: 56, size: 78),
      };

      await writeZipIndex(indexFile, source);
      final restored = await readZipIndex(indexFile);

      expect(restored.keys.toSet(), source.keys.toSet());
      expect(restored['1(1)']?.localHeaderOffset, 12);
      expect(restored['1(1)']?.size, 34);
      expect(restored['1-1-1']?.localHeaderOffset, 56);
      expect(restored['1-1-1']?.size, 78);
    });
  });

  group('zip parsing error handling', () {
    test('readEndOfCentralDirectory throws when signature is missing', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'zip-index-missing-eocd-',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));
      final archiveFile = File('${tempDirectory.path}/bad.zip');
      await archiveFile.writeAsBytes([1, 2, 3, 4, 5], flush: true);

      expect(
        () => readEndOfCentralDirectory(archiveFile),
        throwsA(isA<ZipIndexNotFoundException>()),
      );
    });

    test('materializeStoredZipEntry validates local header signature', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'zip-index-bad-header-',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));

      final archiveFile = File('${tempDirectory.path}/bad-header.zip');
      final outputFile = File('${tempDirectory.path}/clip.mp3');
      await archiveFile.writeAsBytes(
        // 30-byte fake local header with incorrect signature.
        <int>[...List<int>.filled(30, 0), 0xAA, 0xBB],
        flush: true,
      );

      const entry = ZipEntryLocation(localHeaderOffset: 0, size: 2);
      expect(
        () => materializeStoredZipEntry(
          archiveFile: archiveFile,
          outputFile: outputFile,
          entry: entry,
        ),
        throwsA(isA<ZipLocalHeaderFormatException>()),
      );
    });
  });
}
