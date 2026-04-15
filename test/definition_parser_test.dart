import 'package:flutter_test/flutter_test.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';

void main() {
  group('parseDefinitionSegments', () {
    test('handles multiple linked words', () {
      final segments = parseDefinitionSegments('參見【母】與【母仔】。');

      expect(segments.map((segment) => segment.displayText), [
        '參見',
        '【母】',
        '與',
        '【母仔】',
        '。',
      ]);
      expect(
        segments
            .where((segment) => segment.isActionable)
            .map((segment) => segment.actionWord),
        ['母', '母仔'],
      );
    });

    test('treats empty bracket content as plain text', () {
      final segments = parseDefinitionSegments('無效【   】連結');

      expect(segments, hasLength(3));
      expect(segments[1].displayText, '【   】');
      expect(segments[1].isActionable, isFalse);
    });
  });
}
