class OpenccInputGuard {
  const OpenccInputGuard._();

  static bool shouldConvert(String text) {
    if (text.trim().isEmpty) {
      return false;
    }
    if (hasUnpairedSurrogate(text)) {
      return false;
    }
    return containsHanScript(text);
  }

  static bool hasUnpairedSurrogate(String text) {
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        if (i + 1 >= text.length) {
          return true;
        }
        final next = text.codeUnitAt(i + 1);
        if (next < 0xDC00 || next > 0xDFFF) {
          return true;
        }
        i++;
        continue;
      }
      if (unit >= 0xDC00 && unit <= 0xDFFF) {
        return true;
      }
    }
    return false;
  }

  static bool containsHanScript(String text) {
    for (final rune in text.runes) {
      if ((rune >= 0x3400 && rune <= 0x9FFF) ||
          (rune >= 0xF900 && rune <= 0xFAFF) ||
          (rune >= 0x20000 && rune <= 0x2EBEF) ||
          (rune >= 0x30000 && rune <= 0x323AF)) {
        return true;
      }
    }
    return false;
  }
}
