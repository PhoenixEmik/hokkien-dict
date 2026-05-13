import 'package:flutter_test/flutter_test.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';

void main() {
  group('normalizeQuery', () {
    test('folds tones, punctuation, and separators', () {
      expect(normalizeQuery('  Tsìt4-tsi̍t8/【狗】  '), 'tsit tsit 狗');
      expect(normalizeQuery('母仔（bó-á）, foo_bar'), '母仔 bo a foo bar');
      expect(normalizeQuery('o͘ ⁿ óo'), 'o n oo');
    });
  });

  group('searchDictionaryEntryIds', () {
    test('ranks exact headwords before longer and definition matches', () {
      final index = buildDictionarySearchIndex([
        _entry(
          id: 10,
          hanji: '人民族',
          romanization: 'jin-bin-tso̍k',
          definition: '民族',
        ),
        _entry(id: 20, hanji: '人民', romanization: 'jin-bin', definition: '人民'),
        _entry(
          id: 30,
          hanji: '政權',
          romanization: 'tsing-khuan',
          definition: '人民的權力',
        ),
        _entry(
          id: 40,
          hanji: '新人民',
          romanization: 'sin-jin-bin',
          definition: '新人民',
        ),
      ]);

      expect(searchDictionaryEntryIds(index, normalizeQuery('人民')), [
        20,
        10,
        40,
        30,
      ]);
    });
  });

  group('DictionaryRepository in-memory helpers', () {
    test(
      'findLinkedEntry prefers exact and variant headwords before romanization',
      () {
        final bundle = DictionaryBundle(
          entryCount: 3,
          senseCount: 3,
          exampleCount: 0,
          entries: [
            _entry(id: 1, hanji: '母', romanization: 'bo', definition: '母親'),
            _entry(
              id: 2,
              hanji: '無',
              romanization: 'bo',
              definition: '沒有',
              variantChars: const ['毋'],
            ),
            _entry(id: 3, hanji: '母仔', romanization: 'bo-a', definition: '雌性'),
          ],
        );

        final repository = DictionaryRepository();

        expect(repository.findLinkedEntry(bundle, '毋')?.id, 2);
        expect(repository.findLinkedEntry(bundle, 'bo')?.id, 1);
        expect(repository.findLinkedEntry(bundle, '母仔')?.id, 3);
        expect(repository.findLinkedEntry(bundle, '母親'), isNull);
      },
    );

    test('entriesByIdsAsync preserves unique requested id order', () async {
      final bundle = DictionaryBundle(
        entryCount: 3,
        senseCount: 3,
        exampleCount: 0,
        entries: [
          _entry(id: 1, hanji: '一', romanization: 'tsi̍t', definition: '數字一'),
          _entry(id: 2, hanji: '狗', romanization: 'kau', definition: '狗'),
          _entry(id: 3, hanji: '貓', romanization: 'niau', definition: '貓'),
        ],
      );

      final results = await DictionaryRepository().entriesByIdsAsync(bundle, [
        3,
        1,
        3,
        99,
        2,
      ]);

      expect(results.map((entry) => entry.id), [3, 1, 2]);
    });
  });
}

DictionaryEntry _entry({
  required int id,
  required String hanji,
  required String romanization,
  required String definition,
  List<String> variantChars = const [],
}) {
  return DictionaryEntry(
    id: id,
    type: '',
    hanji: hanji,
    romanization: romanization,
    category: '',
    audioId: '',
    variantChars: variantChars,
    hokkienSearch: '$hanji $romanization',
    mandarinSearch: definition,
    senses: [
      DictionarySense(partOfSpeech: '', definition: definition, examples: []),
    ],
  );
}
