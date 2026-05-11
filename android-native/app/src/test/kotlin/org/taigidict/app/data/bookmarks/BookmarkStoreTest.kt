package org.taigidict.app.data.bookmarks

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.UUID

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class BookmarkStoreTest {
    @Test
    fun toggleBookmark_insertsAtFrontAndRemovesExistingEntry() = runTest {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = BookmarkStore(
            context = context,
            preferencesName = "bookmark-store-test-${UUID.randomUUID()}",
            scope = backgroundScope,
        )

        assertTrue(store.toggleBookmark(10))
        assertTrue(store.toggleBookmark(20))
        advanceUntilIdle()
        assertEquals(listOf(20L, 10L), store.bookmarkedIds.value)

        assertFalse(store.toggleBookmark(10))
        advanceUntilIdle()
        assertEquals(listOf(20L), store.bookmarkedIds.value)
    }

    @Test
    fun removeBookmark_updatesStoredIds() = runTest {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = BookmarkStore(
            context = context,
            preferencesName = "bookmark-store-test-${UUID.randomUUID()}",
            scope = backgroundScope,
        )

        store.toggleBookmark(10)
        store.toggleBookmark(20)
        advanceUntilIdle()

        assertTrue(store.removeBookmark(10))
        advanceUntilIdle()
        assertEquals(listOf(20L), store.bookmarkedIds.value)
        assertFalse(store.isBookmarked(10))
    }
}
