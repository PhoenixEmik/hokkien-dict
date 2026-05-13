import 'package:flutter_test/flutter_test.dart';
import 'package:taigi_dict/core/translation/opencc_input_guard.dart';

void main() {
  group('OpenccInputGuard.hasUnpairedSurrogate', () {
    test('returns false for normal Han text', () {
      expect(OpenccInputGuard.hasUnpairedSurrogate('網路'), isFalse);
    });

    test('returns true for lone high surrogate', () {
      const input = '\uD800';
      expect(OpenccInputGuard.hasUnpairedSurrogate(input), isTrue);
    });

    test('returns true for lone low surrogate', () {
      const input = '\uDC00';
      expect(OpenccInputGuard.hasUnpairedSurrogate(input), isTrue);
    });

    test('returns false for valid surrogate pair', () {
      const input = '𠀋';
      expect(OpenccInputGuard.hasUnpairedSurrogate(input), isFalse);
    });
  });

  group('OpenccInputGuard.shouldConvert', () {
    test('returns true for Han text', () {
      expect(OpenccInputGuard.shouldConvert('網路'), isTrue);
    });

    test('returns false for romanization-only text', () {
      expect(OpenccInputGuard.shouldConvert('tai gi su'), isFalse);
    });

    test('returns false for malformed surrogate text', () {
      const input = '測試\uD800';
      expect(OpenccInputGuard.shouldConvert(input), isFalse);
    });
  });
}
