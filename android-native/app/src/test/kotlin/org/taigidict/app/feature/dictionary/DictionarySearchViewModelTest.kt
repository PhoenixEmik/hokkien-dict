package org.taigidict.app.feature.dictionary

import android.app.Application
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.domain.model.DictionaryBundle
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class DictionarySearchViewModelTest {
    private val dispatcher = StandardTestDispatcher()

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun init_loadsBundleIntoUiState() = runTest(dispatcher) {
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(
                entryCount = 10,
                senseCount = 20,
                exampleCount = 30,
                databasePath = "/tmp/dictionary.sqlite",
            ),
        )

        val viewModel = createViewModel(repository)
        advanceUntilIdle()

        val uiState = viewModel.uiState.value
        assertFalse(uiState.isLoadingBundle)
        assertEquals(10, uiState.bundle?.entryCount)
        assertEquals("/tmp/dictionary.sqlite", uiState.bundle?.databasePath)
        assertEquals(1, repository.loadBundleCalls)
    }

    @Test
    fun onQueryChange_searchesAndPublishesResults() = runTest(dispatcher) {
        val entry = sampleEntry(id = 7, hanji = "辭典", romanization = "sû-tián")
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(1, 1, 0, "/tmp/dictionary.sqlite"),
            searchResults = listOf(entry),
        )

        val viewModel = createViewModel(repository)
        advanceUntilIdle()

        viewModel.onQueryChange("辭典")
        advanceUntilIdle()

        val uiState = viewModel.uiState.value
        assertEquals("辭典", uiState.query)
        assertFalse(uiState.isSearching)
        assertEquals(listOf(entry), uiState.results)
        assertEquals(listOf("辭典"), repository.searchQueries)
    }

    @Test
    fun onQueryChange_blankClearsExistingResults() = runTest(dispatcher) {
        val entry = sampleEntry(id = 7, hanji = "辭典", romanization = "sû-tián")
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(1, 1, 0, "/tmp/dictionary.sqlite"),
            searchResults = listOf(entry),
        )

        val viewModel = createViewModel(repository)
        advanceUntilIdle()

        viewModel.onQueryChange("辭典")
        advanceUntilIdle()
        assertTrue(viewModel.uiState.value.results.isNotEmpty())

        viewModel.onQueryChange("")
        advanceUntilIdle()

        val uiState = viewModel.uiState.value
        assertEquals("", uiState.query)
        assertTrue(uiState.results.isEmpty())
        assertFalse(uiState.isSearching)
    }

    @Test
    fun onEntrySelected_loadsFullEntryIntoUiState() = runTest(dispatcher) {
        val entry = sampleEntry(id = 7, hanji = "辭典", romanization = "sû-tián")
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(1, 1, 0, "/tmp/dictionary.sqlite"),
            entryById = mapOf(entry.id to entry),
        )

        val viewModel = createViewModel(repository)
        advanceUntilIdle()

        viewModel.onEntrySelected(entry.id)
        advanceUntilIdle()

        val uiState = viewModel.uiState.value
        assertFalse(uiState.isLoadingEntryDetail)
        assertEquals(entry, uiState.selectedEntry)
        assertEquals(listOf(entry.id), repository.entryRequests)
    }

    @Test
    fun onEntrySelected_missingEntryStoresErrorUntilDismissed() = runTest(dispatcher) {
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(1, 1, 0, "/tmp/dictionary.sqlite"),
        )

        val viewModel = createViewModel(repository)
        advanceUntilIdle()

        viewModel.onEntrySelected(99)
        advanceUntilIdle()

        val errorState = viewModel.uiState.value
        assertFalse(errorState.isLoadingEntryDetail)
        assertEquals("Entry 99 not found", errorState.entryDetailErrorMessage)
        assertNull(errorState.selectedEntry)

        viewModel.onEntryDetailDismissed()

        val clearedState = viewModel.uiState.value
        assertNull(clearedState.entryDetailErrorMessage)
        assertNull(clearedState.selectedEntry)
    }

    private fun createViewModel(repository: DictionaryRepositoryDataSource): DictionarySearchViewModel {
        val application = ApplicationProvider.getApplicationContext<Application>()
        return DictionarySearchViewModel(
            application = application,
            repository = repository,
            ioDispatcher = dispatcher,
        )
    }
}

private class FakeDictionaryRepository(
    private val bundle: DictionaryBundle,
    private val searchResults: List<DictionaryEntry> = emptyList(),
    private val entryById: Map<Long, DictionaryEntry> = searchResults.associateBy { it.id },
) : DictionaryRepositoryDataSource {
    var loadBundleCalls: Int = 0
    val searchQueries = mutableListOf<String>()
    val entryRequests = mutableListOf<Long>()

    override fun loadBundle(): DictionaryBundle {
        loadBundleCalls += 1
        return bundle
    }

    override fun search(rawQuery: String, limit: Int): List<DictionaryEntry> {
        searchQueries += rawQuery
        return searchResults
    }

    override fun entry(id: Long): DictionaryEntry? {
        entryRequests += id
        return entryById[id]
    }
}

private fun sampleEntry(
    id: Long,
    hanji: String,
    romanization: String,
): DictionaryEntry {
    return DictionaryEntry(
        id = id,
        type = "名詞",
        hanji = hanji,
        romanization = romanization,
        category = "主詞目",
        audioId = "audio-$id",
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
                definition = "一種工具書。",
                definitionSynonyms = emptyList(),
                definitionAntonyms = emptyList(),
                examples = listOf(
                    DictionaryExample(
                        hanji = "一本辭典",
                        romanization = "tsi̍t pún sû-tián",
                        mandarin = "一本辭典",
                        audioId = "example-$id",
                    ),
                ),
            ),
        ),
    )
}