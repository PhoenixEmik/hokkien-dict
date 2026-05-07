package org.taigidict.app.feature.dictionary

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.taigidict.app.R
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense

@RunWith(AndroidJUnit4::class)
class DictionaryScreenSmokeTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun homeEmptyCard_rendersPrompt() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                DictionaryHomeEmptyCard()
            }
        }

        composeRule.onNodeWithText(
            context.getString(R.string.dictionary_empty_state_title),
        ).assertIsDisplayed()
        composeRule.onNodeWithText(
            context.getString(R.string.dictionary_empty_state_body),
        ).assertIsDisplayed()
    }

    @Test
    fun recentSearchHistoryCard_rendersQueries() {
        composeRule.setContent {
            MaterialTheme {
                RecentSearchHistoryCard(
                    recentSearches = listOf("辭典", "字典"),
                    onRecentSearchSelected = {},
                )
            }
        }

        composeRule.onNodeWithText("辭典").assertIsDisplayed()
        composeRule.onNodeWithText("字典").assertIsDisplayed()
    }

    @Test
    fun resultList_rendersEntrySummary() {
        val entry = sampleDictionaryEntry()

        composeRule.setContent {
            MaterialTheme {
                DictionaryResultList(
                    results = listOf(entry),
                    onEntrySelected = {},
                )
            }
        }

        composeRule.onNodeWithText(entry.hanji).assertIsDisplayed()
        composeRule.onNodeWithText(entry.romanization).assertIsDisplayed()
        composeRule.onNodeWithText(entry.briefSummary).assertIsDisplayed()
    }

    @Test
    fun searchLoadingPlaceholder_rendersAnimatedRows() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                SearchLoadingPlaceholder()
            }
        }

        composeRule.onNodeWithTag("dictionary-search-loading").assertIsDisplayed()
        composeRule.onAllNodesWithText(
            context.getString(R.string.dictionary_searching),
        ).assertCountEquals(0)
    }

    @Test
    fun detailPane_rendersLinkedWordAndAudioActions() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val entry = sampleDictionaryEntry()

        composeRule.setContent {
            MaterialTheme {
                DictionaryEntryDetailPane(
                    isLoading = false,
                    entry = entry,
                    openableLinkedWords = setOf("字典"),
                    errorMessage = null,
                    isBookmarked = false,
                    onToggleBookmark = {},
                    onBack = {},
                    onOpenLinkedWord = {},
                )
            }
        }

        composeRule.onNodeWithText(entry.hanji).assertIsDisplayed()
        composeRule.onNodeWithText("字典").assertIsDisplayed()
        composeRule.onNodeWithText(entry.senses.first().examples.first().hanji).assertIsDisplayed()
        composeRule.onAllNodesWithText(
            context.getString(R.string.dictionary_detail_sense_title, 1),
        ).assertCountEquals(0)
        composeRule.onNodeWithText(
            context.getString(R.string.dictionary_detail_vocabulary_comparisons),
        ).assertIsDisplayed()
        composeRule.onNodeWithText("工作／職業：工課（khang-khuè）").assertIsDisplayed()
        composeRule.onNodeWithContentDescription(
            context.getString(R.string.dictionary_play_word_audio),
        ).assertIsDisplayed()
        composeRule.onNodeWithContentDescription(
            context.getString(R.string.dictionary_play_example_audio),
        ).assertIsDisplayed()
    }

    @Test
    fun detailPane_loadingState_rendersAnimatedPlaceholder() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                DictionaryEntryDetailPane(
                    isLoading = true,
                    entry = null,
                    openableLinkedWords = emptySet(),
                    errorMessage = null,
                    isBookmarked = false,
                    onToggleBookmark = {},
                    onBack = {},
                    onOpenLinkedWord = {},
                )
            }
        }

        composeRule.onNodeWithTag("dictionary-detail-loading").assertIsDisplayed()
        composeRule.onAllNodesWithText(
            context.getString(R.string.dictionary_detail_loading),
        ).assertCountEquals(0)
    }
}

private fun sampleDictionaryEntry(): DictionaryEntry {
    return DictionaryEntry(
        id = 1,
        type = "名詞",
        hanji = "辭典",
        romanization = "sû-tián",
        category = "主詞目",
        audioId = "word-1",
        hokkienSearch = "sutian",
        mandarinSearch = "辭典",
        variantChars = listOf("字典"),
        wordSynonyms = listOf("字典"),
        wordAntonyms = emptyList(),
        alternativePronunciations = emptyList(),
        contractedPronunciations = emptyList(),
        colloquialPronunciations = emptyList(),
        phoneticDifferences = emptyList(),
        vocabularyComparisons = listOf("工作／職業：工課（khang-khuè）"),
        aliasTargetEntryId = null,
        senses = listOf(
            DictionarySense(
                partOfSpeech = "名詞",
                definition = "一種工具書。",
                definitionSynonyms = emptyList(),
                definitionAntonyms = emptyList(),
                examples = listOf(
                    DictionaryExample(
                        hanji = "一本辭典",
                        romanization = "tsi̍t pún sû-tián",
                        mandarin = "一本辭典",
                        audioId = "sentence-1",
                    ),
                ),
            ),
        ),
    )
}
