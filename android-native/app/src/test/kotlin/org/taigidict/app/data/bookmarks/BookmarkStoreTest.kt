package org.taigidict.app.data.bookmarks

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.UUID

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class BookmarkStoreTest {
    @Test
    fun toggleBookmark_insertsAtFrontAndRemovesExistingEntry() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = BookmarkStore(
            context = context,
            preferencesName = "bookmark-store-test-${UUID.randomUUID()}",
        )

        assertTrue(store.toggleBookmark(10))
        assertTrue(store.toggleBookmark(20))
        assertEquals(listOf(20L, 10L), store.bookmarkedIds.value)

        assertFalse(store.toggleBookmark(10))
        assertEquals(listOf(20L), store.bookmarkedIds.value)
    }

    @Test
    fun removeBookmark_updatesStoredIds() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = BookmarkStore(
            context = context,
            preferencesName = "bookmark-store-test-${UUID.randomUUID()}",
        )

        store.toggleBookmark(10)
        store.toggleBookmark(20)

        assertTrue(store.removeBookmark(10))
        assertEquals(listOf(20L), store.bookmarkedIds.value)
        assertFalse(store.isBookmarked(10))
    }
}