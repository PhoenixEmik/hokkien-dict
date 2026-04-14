import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_open_chinese_convert/flutter_open_chinese_convert.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';


class ChineseTranslationService {
  ChineseTranslationService._();

  static final ChineseTranslationService instance =
      ChineseTranslationService._();

  Future<void>? _initializeFuture;

  Future<void> initialize() {
    return _initializeFuture ??= _warmUp();
  }

  bool shouldUseSimplifiedDisplay(Locale locale) {
    return AppLocalizations.resolveLocale(locale) ==
        AppLocalizations.simplifiedChineseLocale;
  }

  Future<String> normalizeSearchInput(
    String text, {
    required Locale locale,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !shouldUseSimplifiedDisplay(locale)) {
      return trimmed;
    }

    // In simplified mode, normalize Han text toward Taiwanese Traditional so
    // the SQLite search index remains stable while still honoring phrase-level
    // Taiwan conversions such as "网络" -> "網路".
    return _convertOrOriginal(trimmed, S2TWp());
  }

  Future<String> translateForDisplay(
    String text, {
    required Locale locale,
  }) async {
    if (text.trim().isEmpty || !shouldUseSimplifiedDisplay(locale)) {
      return text;
    }
    return _convertOrOriginal(text, TW2Sp());
  }

  Future<List<String>> translateStringsForDisplay(
    List<String> values, {
    required Locale locale,
  }) async {
    if (values.isEmpty || !shouldUseSimplifiedDisplay(locale)) {
      return values;
    }

    return Future.wait(
      values.map((value) => translateForDisplay(value, locale: locale)),
    );
  }

  Future<List<DictionaryEntry>> translateEntriesForDisplay(
    List<DictionaryEntry> entries, {
    required Locale locale,
  }) async {
    if (entries.isEmpty || !shouldUseSimplifiedDisplay(locale)) {
      return entries;
    }

    return Future.wait(
      entries.map((entry) => translateEntryForDisplay(entry, locale: locale)),
    );
  }

  Future<DictionaryEntry> translateEntryForDisplay(
    DictionaryEntry entry, {
    required Locale locale,
  }) async {
    if (!shouldUseSimplifiedDisplay(locale)) {
      return entry;
    }

    final translatedHanji = translateForDisplay(entry.hanji, locale: locale);
    final translatedType = translateForDisplay(entry.type, locale: locale);
    final translatedCategory = translateForDisplay(
      entry.category,
      locale: locale,
    );
    final translatedVariants = translateStringsForDisplay(
      entry.variantChars,
      locale: locale,
    );
    final translatedWordSynonyms = translateStringsForDisplay(
      entry.wordSynonyms,
      locale: locale,
    );
    final translatedWordAntonyms = translateStringsForDisplay(
      entry.wordAntonyms,
      locale: locale,
    );
    final translatedPhoneticDifferences = translateStringsForDisplay(
      entry.phoneticDifferences,
      locale: locale,
    );
    final translatedVocabularyComparisons = translateStringsForDisplay(
      entry.vocabularyComparisons,
      locale: locale,
    );
    final translatedSenses = Future.wait(
      entry.senses.map((sense) => _translateSense(sense, locale: locale)),
    );

    return DictionaryEntry(
      id: entry.id,
      type: await translatedType,
      hanji: await translatedHanji,
      romanization: entry.romanization,
      category: await translatedCategory,
      audioId: entry.audioId,
      hokkienSearch: entry.hokkienSearch,
      mandarinSearch: entry.mandarinSearch,
      variantChars: await translatedVariants,
      wordSynonyms: await translatedWordSynonyms,
      wordAntonyms: await translatedWordAntonyms,
      alternativePronunciations: entry.alternativePronunciations,
      contractedPronunciations: entry.contractedPronunciations,
      colloquialPronunciations: entry.colloquialPronunciations,
      phoneticDifferences: await translatedPhoneticDifferences,
      vocabularyComparisons: await translatedVocabularyComparisons,
      aliasTargetEntryId: entry.aliasTargetEntryId,
      senses: await translatedSenses,
    );
  }

  Future<DictionarySense> _translateSense(
    DictionarySense sense, {
    required Locale locale,
  }) async {
    final translatedPartOfSpeech = translateForDisplay(
      sense.partOfSpeech,
      locale: locale,
    );
    final translatedDefinition = translateForDisplay(
      sense.definition,
      locale: locale,
    );
    final translatedDefinitionSynonyms = translateStringsForDisplay(
      sense.definitionSynonyms,
      locale: locale,
    );
    final translatedDefinitionAntonyms = translateStringsForDisplay(
      sense.definitionAntonyms,
      locale: locale,
    );
    final translatedExamples = Future.wait(
      sense.examples.map(
        (example) => _translateExample(example, locale: locale),
      ),
    );

    return DictionarySense(
      partOfSpeech: await translatedPartOfSpeech,
      definition: await translatedDefinition,
      definitionSynonyms: await translatedDefinitionSynonyms,
      definitionAntonyms: await translatedDefinitionAntonyms,
      examples: await translatedExamples,
    );
  }

  Future<DictionaryExample> _translateExample(
    DictionaryExample example, {
    required Locale locale,
  }) async {
    final translatedHanji = translateForDisplay(example.hanji, locale: locale);
    final translatedMandarin = translateForDisplay(
      example.mandarin,
      locale: locale,
    );

    return DictionaryExample(
      hanji: await translatedHanji,
      romanization: example.romanization,
      mandarin: await translatedMandarin,
      audioId: example.audioId,
    );
  }

  Future<void> _warmUp() async {
    try {
      await ChineseConverter.convert('網路', TW2Sp(), inBackground: true);
    } on MissingPluginException {
      // Widget tests and unsupported hosts can safely fall back to pass-through.
    } on PlatformException {
      // Keep runtime resilient even if the native side is temporarily unavailable.
    }
  }

  Future<String> _convertOrOriginal(String text, ConverterOption option) async {
    try {
      await initialize();
      return await ChineseConverter.convert(text, option, inBackground: true);
    } on MissingPluginException {
      return text;
    } on PlatformException {
      return text;
    }
  }
}
