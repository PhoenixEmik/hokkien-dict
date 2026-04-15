import 'package:flutter_test/flutter_test.dart';
import 'package:taigi_dict/features/audio/audio.dart';

void main() {
  group('formatBytes', () {
    test('uses compact binary units', () {
      expect(formatBytes(-1), '0 B');
      expect(formatBytes(999), '999 B');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(1048576), '1.0 MB');
      expect(formatBytes(1073741824), '1.0 GB');
    });
  });

  group('formatBytesPerSecond', () {
    test('rounds before formatting', () {
      expect(formatBytesPerSecond(0), '0 B/s');
      expect(formatBytesPerSecond(1535.6), '1.5 KB/s');
    });
  });
}
