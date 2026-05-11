package org.taigidict.app

import android.os.Looper
import androidx.lifecycle.ViewModelProvider
import androidx.test.core.app.ApplicationProvider
import java.time.Duration
import kotlinx.coroutines.Dispatchers
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.taigidict.app.app.RoomBackendSmokeTestApplication
import org.taigidict.app.feature.dictionary.DictionarySearchViewModel
import org.taigidict.app.feature.initialization.InitializationViewModel

@RunWith(RobolectricTestRunner::class)
@Config(
    manifest = Config.DEFAULT_MANIFEST_NAME,
    sdk = [34],
    application = RoomBackendSmokeTestApplication::class,
)
class MainActivityRoomBackendSmokeTest {
    @Test
    fun mainActivity_initializesAndSearchesWithRoomRepository() {
        val activity = Robolectric.buildActivity(MainActivity::class.java)
            .setup()
            .get()
        val application = ApplicationProvider.getApplicationContext<RoomBackendSmokeTestApplication>()
        val appContainer = application.appContainer
        val initializationViewModel = ViewModelProvider(activity)[InitializationViewModel::class.java]

        waitUntil(timeoutMillis = 5_000) {
            initializationViewModel.uiState.value.isReady
        }

        assertFalse(activity.isFinishing)
        assertTrue(appContainer.dictionaryRepository is org.taigidict.app.data.repository.RoomDictionaryRepository)
        assertNull(initializationViewModel.uiState.value.errorMessage)

        val searchViewModel = DictionarySearchViewModel(
            application = application,
            repository = appContainer.dictionaryRepository,
            settingsStore = appContainer.appSettingsStore,
            chineseConversionService = appContainer.chineseConversionService,
            searchHistoryStore = appContainer.searchHistoryStore,
            ioDispatcher = Dispatchers.IO,
            searchDebounceMillis = 0,
        )

        searchViewModel.onQueryChange("辭典")
        waitUntil(timeoutMillis = 5_000) {
            !searchViewModel.uiState.value.isSearching &&
                searchViewModel.uiState.value.results.isNotEmpty()
        }

        assertEquals(listOf("辭典"), searchViewModel.uiState.value.results.map { it.hanji })

        searchViewModel.onEntrySelected(1L)
        waitUntil(timeoutMillis = 5_000) {
            !searchViewModel.uiState.value.isLoadingEntryDetail &&
                searchViewModel.uiState.value.selectedEntry != null
        }

        assertEquals("辭典", searchViewModel.uiState.value.selectedEntry?.hanji)
        assertEquals(
            "一本工具書。",
            searchViewModel.uiState.value.selectedEntry?.senses?.firstOrNull()?.definition,
        )
    }

    private fun waitUntil(
        timeoutMillis: Long,
        condition: () -> Boolean,
    ) {
        val deadline = System.currentTimeMillis() + timeoutMillis
        while (System.currentTimeMillis() < deadline) {
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(50))
            if (condition()) {
                return
            }
            Thread.sleep(20)
        }

        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(condition())
    }
}
