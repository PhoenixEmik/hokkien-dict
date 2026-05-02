package org.taigidict.app.feature.dictionary

import org.junit.Assert.assertEquals
import org.junit.Test
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense

class DictionaryShareFormatterTest {
    @Test
    fun buildShareText_usesDefinitionsWhenAvailable() {
        val entry = sampleEntry(
            hanji = "辭典",
            romanization = "sû-tián",
            definition = "一種工具書。",
        )

        val result = DictionaryShareFormatter.buildShareText(
            entry = entry,
            fallbackHanji = "台語辭典詞條",
            footer = "-- 來自台語辭典 App",
        )

        assertEquals("【辭典】(sû-tián)\n一種工具書。\n\n-- 來自台語辭典 App", result)
    }

    @Test
    fun buildShareText_fallsBackToSummaryWhenDefinitionsAreBlank() {
        val entry = sampleEntry(
            hanji = "",
            romanization = "sû-tián",
            definition = "",
            category = "主詞目",
        )

        val result = DictionaryShareFormatter.buildShareText(
            entry = entry,
            fallbackHanji = "台語辭典詞條",
            footer = "-- 來自台語辭典 App",
        )

        assertEquals("【台語辭典詞條】(sû-tián)\n主詞目\n\n-- 來自台語辭典 App", result)
    }

    @Test
    fun buildShareTitle_fallsBackWhenHanjiMissing() {
        val entry = sampleEntry(hanji = "", romanization = "sû-tián", definition = "一種工具書。")

        val result = DictionaryShareFormatter.buildShareTitle(
            entry = entry,
            fallbackTitle = "台語辭典詞條",
        )

        assertEquals("台語辭典詞條", result)
    }
}

private fun sampleEntry(
    hanji: String,
    romanization: String,
    definition: String,
    category: String = "",
): DictionaryEntry {
    return DictionaryEntry(
        id = 1,
        type = "名詞",
        hanji = hanji,
        romanization = romanization,
        category = category,
        audioId = "audio-1",
        hokkienSearch = "$hanji $romanization",
        mandarinSearch = hanji,
        variantChars = emptyList(),
        wordSynonyms = emptyList(),
        wordAntonyms = emptyList(),
        alternativePronunciations = emptyList(),
        contractedPronunciations = emptyList(),
        colloquialPronunciations = emptyList(),
        phoneticDifferences = emptyList(),
        vocabularyComparisons = emptyList(),
        aliasTargetEntryId = null,
        senses = listOf(
            DictionarySense(
                partOfSpeech = "名詞",
                definition = definition,
                definitionSynonyms = emptyList(),
                definitionAntonyms = emptyList(),
                examples = listOf(
                    DictionaryExample(
                        hanji = "一本辭典",
                        romanization = "tsi̍t pún sû-tián",
                        mandarin = "一本辭典",
                        audioId = "example-1",
                    ),
                ),
            ),
        ),
    )
}