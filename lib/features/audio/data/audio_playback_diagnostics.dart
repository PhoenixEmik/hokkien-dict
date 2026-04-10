import 'dart:io';
import 'dart:typed_data';

import 'package:taigi_dict/features/audio/domain/audio_archive.dart';

Future<String> describeAudioClipFile(File file) async {
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
