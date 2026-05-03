package org.taigidict.app.data.search

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import java.util.UUID
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class SearchHistoryStoreTest {
    @Test
    fun addQuery_movesExistingItemToFrontAndKeepsDistinctList() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = SearchHistoryStore(
            context = context,
            preferencesName = "search-history-test-${UUID.randomUUID()}",
        )

        store.addQuery("辭典")
        store.addQuery("字典")
        store.addQuery("辭典")

        assertEquals(listOf("辭典", "字典"), store.recentQueries.value)
    }

    @Test
    fun clear_removesAllSavedQueries() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = SearchHistoryStore(
            context = context,
            preferencesName = "search-history-test-${UUID.randomUUID()}",
        )

        store.addQuery("辭典")
        store.addQuery("字典")
        store.clear()

        assertTrue(store.recentQueries.value.isEmpty())
    }
}