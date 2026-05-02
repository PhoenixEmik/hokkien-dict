import Foundation
import TaigiDictCore

enum DictionaryDisplayLocalization {
    static func translateEntry(
        _ entry: DictionaryEntry,
        locale: AppLocale,
        converter: (any ChineseConversionProviding)?
    ) async -> DictionaryEntry {
        guard let converter, locale.usesSimplifiedChineseDisplay else {
            return entry
        }

        var translated = entry
        translated.hanji = await converter.translateForDisplay(entry.hanji, locale: locale)
        translated.category = await converter.translateForDisplay(entry.category, locale: locale)
        translated.type = await converter.translateForDisplay(entry.type, locale: locale)
        translated.variantChars = await translateArray(entry.variantChars, locale: locale, converter: converter)
        translated.wordSynonyms = await translateArray(entry.wordSynonyms, locale: locale, converter: converter)
        translated.wordAntonyms = await translateArray(entry.wordAntonyms, locale: locale, converter: converter)
        translated.alternativePronunciations = await translateArray(entry.alternativePronunciations, locale: locale, converter: converter)
        translated.contractedPronunciations = await translateArray(entry.contractedPronunciations, locale: locale, converter: converter)
        translated.colloquialPronunciations = await translateArray(entry.colloquialPronunciations, locale: locale, converter: converter)
        translated.phoneticDifferences = await translateArray(entry.phoneticDifferences, locale: locale, converter: converter)
        translated.vocabularyComparisons = await translateArray(entry.vocabularyComparisons, locale: locale, converter: converter)

        translated.senses = await entry.senses.asyncMap { sense in
            var translatedSense = sense
            translatedSense.partOfSpeech = await converter.translateForDisplay(sense.partOfSpeech, locale: locale)
            translatedSense.definition = await converter.translateForDisplay(sense.definition, locale: locale)
            translatedSense.definitionSynonyms = await translateArray(sense.definitionSynonyms, locale: locale, converter: converter)
            translatedSense.definitionAntonyms = await translateArray(sense.definitionAntonyms, locale: locale, converter: converter)
            translatedSense.examples = await sense.examples.asyncMap { example in
                var translatedExample = example
                translatedExample.hanji = await converter.translateForDisplay(example.hanji, locale: locale)
                translatedExample.mandarin = await converter.translateForDisplay(example.mandarin, locale: locale)
                return translatedExample
            }
            return translatedSense
        }

        return translated
    }

    static func normalizeLookupWord(
        _ word: String,
        locale: AppLocale,
        converter: (any ChineseConversionProviding)?
    ) async -> String {
        guard let converter else {
            return word
        }
        return await converter.normalizeSearchInput(word, locale: locale)
    }

    static func translateEntryWord(
        _ word: String,
        locale: AppLocale,
        converter: (any ChineseConversionProviding)?
    ) async -> String {
        guard let converter, locale.usesSimplifiedChineseDisplay else {
            return word
        }
        return await converter.translateForDisplay(word, locale: locale)
    }

    private static func translateArray(
        _ source: [String],
        locale: AppLocale,
        converter: any ChineseConversionProviding
    ) async -> [String] {
        await source.asyncMap { value in
            await converter.translateForDisplay(value, locale: locale)
        }
    }
}

private extension Array {
    func asyncMap<T>(_ transform: @escaping (Element) async -> T) async -> [T] {
        var values: [T] = []
        values.reserveCapacity(count)
        for element in self {
            values.append(await transform(element))
        }
        return values
    }
}
