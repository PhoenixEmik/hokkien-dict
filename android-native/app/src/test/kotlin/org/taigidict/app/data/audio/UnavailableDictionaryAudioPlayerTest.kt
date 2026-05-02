package org.taigidict.app.data.audio

import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense

class UnavailableDictionaryAudioPlayerTest {
    private val player = UnavailableDictionaryAudioPlayer()

    @Test
    fun playEntryAudio_withMissingAudioId_returnsMissingClipFailure() = runTest {
        val result = player.playEntryAudio(sampleEntry(audioId = ""))

        assertEquals(
            DictionaryAudioPlaybackResult.Failed(DictionaryAudioPlaybackResult.FailureReason.MissingClipId),
            result,
        )
    }

    @Test
    fun playExampleAudio_withAudioId_returnsUnavailableFailure() = runTest {
        val result = player.playExampleAudio(
            DictionaryExample(
                hanji = "一本辭典",
                romanization = "tsi̍t pún sû-tián",
                mandarin = "一本辭典",
                audioId = "example-1",
            ),
        )

        assertEquals(
            DictionaryAudioPlaybackResult.Failed(DictionaryAudioPlaybackResult.FailureReason.AudioNotAvailable),
            result,
        )
    }
}

private fun sampleEntry(audioId: String): DictionaryEntry {
    return DictionaryEntry(
        id = 1,
        type = "名詞",
        hanji = "辭典",
        romanization = "sû-tián",
        category = "主詞目",
        audioId = audioId,
        hokkienSearch = "辭典 sû-tián",
        mandarinSearch = "辭典",
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
                definition = "一種工具書。",
                definitionSynonyms = emptyList(),
                definitionAntonyms = emptyList(),
                examples = emptyList(),
            ),
        ),
    )
}