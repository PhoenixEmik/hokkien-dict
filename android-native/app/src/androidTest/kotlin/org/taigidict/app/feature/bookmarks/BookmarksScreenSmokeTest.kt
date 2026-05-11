package org.taigidict.app.feature.bookmarks

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeLeft
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
class BookmarksScreenSmokeTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun emptyCard_rendersPrompt() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                BookmarksEmptyCard()
            }
        }

        composeRule.onNodeWithText(
            context.getString(R.string.bookmarks_empty_title),
        ).assertIsDisplayed()
        composeRule.onNodeWithText(
            context.getString(R.string.bookmarks_empty_body),
        ).assertIsDisplayed()
    }

    @Test
    fun entryListItem_rendersBookmarkedEntry() {
        val entry = sampleBookmarkedEntry()

        composeRule.setContent {
            MaterialTheme {
                BookmarkEntryListItem(
                    entry = entry,
                    onClick = {},
                    onRemove = {},
                )
            }
        }

        composeRule.onNodeWithText(entry.hanji).assertIsDisplayed()
        composeRule.onNodeWithText(entry.romanization).assertIsDisplayed()
        composeRule.onNodeWithText(entry.briefSummary).assertIsDisplayed()
    }

    @Test
    fun entryListItem_swipeLeftRemovesBookmark() {
        val entry = sampleBookmarkedEntry()
        var removedEntryId by mutableStateOf<Long?>(null)

        composeRule.setContent {
            MaterialTheme {
                BookmarkEntryListItem(
                    entry = entry,
                    onClick = {},
                    onRemove = { removedEntryId = entry.id },
                )
            }
        }

        composeRule.onNodeWithTag("bookmark-list-item-${entry.id}")
            .performTouchInput { swipeLeft() }

        composeRule.runOnIdle {
            org.junit.Assert.assertEquals(entry.id, removedEntryId)
        }
    }
}

private fun sampleBookmarkedEntry(): DictionaryEntry {
    return DictionaryEntry(
        id = 2,
        type = "名詞",
        hanji = "字典",
        romanization = "jī-tián",
        category = "主詞目",
        audioId = "word-2",
        hokkienSearch = "jitian",
        mandarinSearch = "字典",
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
                definition = "一本工具書。",
                definitionSynonyms = emptyList(),
                definitionAntonyms = emptyList(),
                examples = listOf(
                    DictionaryExample(
                        hanji = "查字典",
                        romanization = "tsha5 jī-tián",
                        mandarin = "查字典",
                        audioId = "",
                    ),
                ),
            ),
        ),
    )
}
