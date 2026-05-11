package org.taigidict.app.data.search

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import java.util.UUID
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

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class SearchHistoryStoreTest {
    @Test
    fun addQuery_movesExistingItemToFrontAndKeepsDistinctList() = runTest {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = SearchHistoryStore(
            context = context,
            preferencesName = "search-history-test-${UUID.randomUUID()}",
            scope = backgroundScope,
        )

        assertFalse(store.hasLoaded.value)

        store.addQuery("辭典")
        store.addQuery("字典")
        store.addQuery("辭典")
        advanceUntilIdle()

        assertTrue(store.hasLoaded.value)
        assertEquals(listOf("辭典", "字典"), store.recentQueries.value)
    }

    @Test
    fun clear_removesAllSavedQueries() = runTest {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = SearchHistoryStore(
            context = context,
            preferencesName = "search-history-test-${UUID.randomUUID()}",
            scope = backgroundScope,
        )

        store.addQuery("辭典")
        store.addQuery("字典")
        store.clear()
        advanceUntilIdle()

        assertTrue(store.recentQueries.value.isEmpty())
    }

    @Test
    fun addQuery_keepsAtMostTenEntries() = runTest {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = SearchHistoryStore(
            context = context,
            preferencesName = "search-history-test-${UUID.randomUUID()}",
            scope = backgroundScope,
        )

        (1..12).forEach { index ->
            store.addQuery("query-$index")
        }
        advanceUntilIdle()

        assertEquals(
            (12 downTo 3).map { index -> "query-$index" },
            store.recentQueries.value,
        )
    }
}
