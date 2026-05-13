import 'package:flutter_test/flutter_test.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';

void main() {
  group('DictionaryEntry.fromJson', () {
    test('normalizes optional string list fields', () {
      final entry = DictionaryEntry.fromJson({
        'id': 42,
        'type': '名詞',
        'hanji': '網路',
        'romanization': 'bang-loo',
        'category': '',
        'audio': '42',
        'hokkienSearch': '網路 bang-loo',
        'mandarinSearch': '網路',
        'variantChars': ['  网路', null, '', '網路  '],
        'wordSynonyms': [' 網际网络 ', ''],
        'wordAntonyms': ['   '],
        'alternativePronunciations': [' bang-lo '],
        'contractedPronunciations': [123],
        'colloquialPronunciations': [''],
        'phoneticDifferences': ['文讀'],
        'vocabularyComparisons': ['A/B'],
        'senses': [
          {'partOfSpeech': '', 'definition': '資料傳輸系統', 'examples': []},
        ],
      });

      expect(entry.variantChars, ['网路', '網路']);
      expect(entry.wordSynonyms, ['網际网络']);
      expect(entry.wordAntonyms, isEmpty);
      expect(entry.alternativePronunciations, ['bang-lo']);
      expect(entry.contractedPronunciations, ['123']);
      expect(entry.colloquialPronunciations, isEmpty);
      expect(entry.phoneticDifferences, ['文讀']);
      expect(entry.vocabularyComparisons, ['A/B']);
    });
  });

  group('DictionaryEntry.briefSummary', () {
    test('returns empty summary for alias entries', () {
      const entry = DictionaryEntry(
        id: 1,
        type: '名詞',
        hanji: '字',
        romanization: 'ji',
        category: '語言',
        audioId: '',
        hokkienSearch: '字 ji',
        mandarinSearch: '字',
        aliasTargetEntryId: 10,
        senses: [
          DictionarySense(partOfSpeech: '', definition: '文字', examples: []),
        ],
      );

      expect(entry.redirectsToPrimaryEntry, isTrue);
      expect(entry.briefSummary, isEmpty);
    });

    test('uses first non-empty definition then falls back to metadata', () {
      const withDefinition = DictionaryEntry(
        id: 2,
        type: '名詞',
        hanji: '字典',
        romanization: 'ji-tian',
        category: '工具',
        audioId: '',
        hokkienSearch: '字典 ji-tian',
        mandarinSearch: '字典',
        senses: [
          DictionarySense(partOfSpeech: '', definition: '', examples: []),
          DictionarySense(partOfSpeech: '', definition: '查詞工具', examples: []),
        ],
      );
      const categoryFallback = DictionaryEntry(
        id: 3,
        type: '名詞',
        hanji: '測試',
        romanization: 'chhek-si',
        category: '分類',
        audioId: '',
        hokkienSearch: '測試 chhek-si',
        mandarinSearch: '測試',
        senses: [
          DictionarySense(partOfSpeech: '', definition: '', examples: []),
        ],
      );
      const typeFallback = DictionaryEntry(
        id: 4,
        type: '動詞',
        hanji: '測試',
        romanization: 'chhek-si',
        category: '',
        audioId: '',
        hokkienSearch: '測試 chhek-si',
        mandarinSearch: '測試',
        senses: [
          DictionarySense(partOfSpeech: '', definition: '', examples: []),
        ],
      );
      const romanizationFallback = DictionaryEntry(
        id: 5,
        type: '',
        hanji: '測試',
        romanization: 'chhek-si',
        category: '',
        audioId: '',
        hokkienSearch: '測試 chhek-si',
        mandarinSearch: '測試',
        senses: [
          DictionarySense(partOfSpeech: '', definition: '', examples: []),
        ],
      );

      expect(withDefinition.briefSummary, '查詞工具');
      expect(categoryFallback.briefSummary, '分類');
      expect(typeFallback.briefSummary, '動詞');
      expect(romanizationFallback.briefSummary, 'chhek-si');
    });
  });

  group('DictionaryBundle', () {
    test('reports database-backed mode when path is provided', () {
      const memoryBundle = DictionaryBundle(
        entryCount: 0,
        senseCount: 0,
        exampleCount: 0,
        entries: [],
      );
      const databaseBundle = DictionaryBundle(
        entryCount: 0,
        senseCount: 0,
        exampleCount: 0,
        entries: [],
        databasePath: '/tmp/dictionary.db',
      );

      expect(memoryBundle.isDatabaseBacked, isFalse);
      expect(databaseBundle.isDatabaseBacked, isTrue);
    });
  });
}
