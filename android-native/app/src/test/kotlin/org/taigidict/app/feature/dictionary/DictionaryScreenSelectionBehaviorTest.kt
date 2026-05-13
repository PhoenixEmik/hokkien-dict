package org.taigidict.app.feature.dictionary

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DictionaryScreenSelectionBehaviorTest {
    @Test
    fun shouldOpenTwoPaneDetailPage_falseOutsideTwoPaneLayout() {
        assertFalse(
            shouldOpenTwoPaneDetailPage(
                usesTwoPaneLayout = false,
                selectedPreviewEntryId = 7L,
                tappedEntryId = 7L,
                isDetailPageVisible = false,
            ),
        )
    }

    @Test
    fun shouldOpenTwoPaneDetailPage_falseForDifferentEntry() {
        assertFalse(
            shouldOpenTwoPaneDetailPage(
                usesTwoPaneLayout = true,
                selectedPreviewEntryId = 7L,
                tappedEntryId = 8L,
                isDetailPageVisible = false,
            ),
        )
    }

    @Test
    fun shouldOpenTwoPaneDetailPage_trueForSecondTapOnSameEntry() {
        assertTrue(
            shouldOpenTwoPaneDetailPage(
                usesTwoPaneLayout = true,
                selectedPreviewEntryId = 7L,
                tappedEntryId = 7L,
                isDetailPageVisible = false,
            ),
        )
    }

    @Test
    fun shouldOpenTwoPaneDetailPage_falseWhenDetailPageAlreadyVisible() {
        assertFalse(
            shouldOpenTwoPaneDetailPage(
                usesTwoPaneLayout = true,
                selectedPreviewEntryId = 7L,
                tappedEntryId = 7L,
                isDetailPageVisible = true,
            ),
        )
    }
}
