package org.taigidict.app.feature.dictionary

import android.app.Application
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
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
import org.taigidict.app.core.localization.AppLocale
import org.taigidict.app.core.settings.AppLanguagePreference
import org.taigidict.app.core.settings.AppSettingsConstants
import org.taigidict.app.core.settings.AppSettingsStoring
import org.taigidict.app.core.settings.AppThemePreference
import org.taigidict.app.data.conversion.ChineseConversionService
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.data.search.SearchHistoryStoring
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
    fun onSearchSubmitted_addsQueryToHistory() = runTest(dispatcher) {
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(1, 1, 0, "/tmp/dictionary.sqlite"),
        )
        val historyStore = FakeSearchHistoryStore()

        val viewModel = createViewModel(repository, historyStore)
        advanceUntilIdle()

        viewModel.onQueryChange("辭典")
        advanceUntilIdle()
        viewModel.onSearchSubmitted()
        advanceUntilIdle()

        assertEquals(listOf("辭典"), historyStore.recentQueries.value)
        assertEquals(listOf("辭典"), viewModel.uiState.value.recentSearches)
    }

    @Test
    fun onClearRecentSearches_clearsHistoryInUiState() = runTest(dispatcher) {
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(1, 1, 0, "/tmp/dictionary.sqlite"),
        )
        val historyStore = FakeSearchHistoryStore(initialQueries = listOf("辭典", "字典"))

        val viewModel = createViewModel(repository, historyStore)
        advanceUntilIdle()
        assertEquals(listOf("辭典", "字典"), viewModel.uiState.value.recentSearches)

        viewModel.onClearRecentSearches()
        advanceUntilIdle()

        assertTrue(viewModel.uiState.value.recentSearches.isEmpty())
    }

    @Test
    fun onQueryChange_usesConvertedQueryForSimplifiedChinese() = runTest(dispatcher) {
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(1, 1, 0, "/tmp/dictionary.sqlite"),
        )
        val settingsStore = FakeDictionarySettingsStore()
        val conversionService = FakeChineseConversionService(
            normalizedQuery = "辭典",
        )

        settingsStore.setLanguagePreference(AppLanguagePreference.SimplifiedChinese)

        val viewModel = createViewModel(
            repository = repository,
            settingsStore = settingsStore,
            conversionService = conversionService,
        )
        advanceUntilIdle()

        viewModel.onQueryChange("词典")
        advanceUntilIdle()

        assertEquals(listOf("辭典"), repository.searchQueries)
        assertEquals(listOf("词典"), conversionService.capturedQueries)
        assertEquals(listOf(AppLocale.SimplifiedChinese), conversionService.capturedLocales)
    }

    @Test
    fun onEntrySelected_loadsFullEntryIntoUiState() = runTest(dispatcher) {
        val linkedEntry = sampleEntry(id = 8, hanji = "字典", romanization = "jī-tián")
        val entry = sampleEntry(
            id = 7,
            hanji = "辭典",
            romanization = "sû-tián",
            variantChars = listOf("字典"),
        )
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(1, 1, 0, "/tmp/dictionary.sqlite"),
            entryById = mapOf(entry.id to entry, linkedEntry.id to linkedEntry),
            linkedEntriesByWord = mapOf("字典" to linkedEntry),
        )

        val viewModel = createViewModel(repository)
        advanceUntilIdle()

        viewModel.onEntrySelected(entry.id)
        advanceUntilIdle()

        val uiState = viewModel.uiState.value
        assertFalse(uiState.isLoadingEntryDetail)
        assertEquals(entry, uiState.selectedEntry)
        assertEquals(setOf("字典"), uiState.openableLinkedWords)
        assertEquals(listOf(entry.id), repository.entryRequests)
    }

    @Test
    fun onEntrySelected_resolvesAliasChainBeforeShowingDetail() = runTest(dispatcher) {
        val primaryEntry = sampleEntry(id = 8, hanji = "字典", romanization = "jī-tián")
        val aliasEntry = sampleEntry(
            id = 7,
            hanji = "辭典",
            romanization = "sû-tián",
            aliasTargetEntryId = primaryEntry.id,
        )
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(1, 1, 0, "/tmp/dictionary.sqlite"),
            entryById = mapOf(aliasEntry.id to aliasEntry, primaryEntry.id to primaryEntry),
        )

        val viewModel = createViewModel(repository)
        advanceUntilIdle()

        viewModel.onEntrySelected(aliasEntry.id)
        advanceUntilIdle()

        val uiState = viewModel.uiState.value
        assertEquals(primaryEntry, uiState.selectedEntry)
        assertEquals(listOf(aliasEntry.id, primaryEntry.id), repository.entryRequests)
    }

    @Test
    fun onLinkedWordSelected_opensResolvedLinkedEntry() = runTest(dispatcher) {
        val currentEntry = sampleEntry(
            id = 7,
            hanji = "辭典",
            romanization = "sû-tián",
            wordSynonyms = listOf("字典"),
        )
        val aliasTarget = sampleEntry(id = 10, hanji = "字典", romanization = "jī-tián")
        val linkedAlias = sampleEntry(
            id = 9,
            hanji = "字典仔",
            romanization = "jī-tián-á",
            aliasTargetEntryId = aliasTarget.id,
        )
        val repository = FakeDictionaryRepository(
            bundle = DictionaryBundle(1, 1, 0, "/tmp/dictionary.sqlite"),
            entryById = mapOf(
                currentEntry.id to currentEntry,
                linkedAlias.id to linkedAlias,
                aliasTarget.id to aliasTarget,
            ),
            linkedEntriesByWord = mapOf("字典" to linkedAlias),
        )

        val viewModel = createViewModel(repository)
        advanceUntilIdle()
        viewModel.onEntrySelected(currentEntry.id)
        advanceUntilIdle()

        viewModel.onLinkedWordSelected("字典")
        advanceUntilIdle()

        val uiState = viewModel.uiState.value
        assertEquals(aliasTarget, uiState.selectedEntry)
        assertEquals(listOf("字典", "字典"), repository.linkedWordRequests)
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

    private fun createViewModel(
        repository: DictionaryRepositoryDataSource,
        searchHistoryStore: SearchHistoryStoring = FakeSearchHistoryStore(),
        settingsStore: AppSettingsStoring = FakeDictionarySettingsStore(),
        conversionService: ChineseConversionService = FakeChineseConversionService(),
    ): DictionarySearchViewModel {
        val application = ApplicationProvider.getApplicationContext<Application>()
        return DictionarySearchViewModel(
            application = application,
            repository = repository,
            settingsStore = settingsStore,
            chineseConversionService = conversionService,
            searchHistoryStore = searchHistoryStore,
            ioDispatcher = dispatcher,
        )
    }
}

private class FakeDictionarySettingsStore : AppSettingsStoring {
    private val _themePreference = MutableStateFlow(AppThemePreference.System)
    private val _languagePreference = MutableStateFlow(AppLanguagePreference.System)
    private val _readingTextScale = MutableStateFlow(AppSettingsConstants.DEFAULT_READING_TEXT_SCALE)

    override val themePreference: StateFlow<AppThemePreference> = _themePreference
    override val languagePreference: StateFlow<AppLanguagePreference> = _languagePreference
    override val readingTextScale: StateFlow<Double> = _readingTextScale

    override fun setThemePreference(preference: AppThemePreference) {
        _themePreference.value = preference
    }

    override fun setLanguagePreference(preference: AppLanguagePreference) {
        _languagePreference.value = preference
    }

    override fun setReadingTextScale(value: Double) {
        _readingTextScale.value = AppSettingsConstants.snapReadingTextScale(value)
    }
}

private class FakeChineseConversionService(
    private val normalizedQuery: String? = null,
) : ChineseConversionService {
    val capturedQueries = mutableListOf<String>()
    val capturedLocales = mutableListOf<AppLocale>()

    override suspend fun normalizeSearchInput(text: String, locale: AppLocale): String {
        capturedQueries += text
        capturedLocales += locale
        return normalizedQuery ?: text
    }

    override suspend fun translateForDisplay(text: String, locale: AppLocale): String {
        return text
    }
}

private class FakeSearchHistoryStore(
    initialQueries: List<String> = emptyList(),
) : SearchHistoryStoring {
    private val queries = MutableStateFlow(initialQueries)

    override val recentQueries: StateFlow<List<String>> = queries.asStateFlow()

    override fun addQuery(query: String) {
        val normalized = query.trim()
        if (normalized.isBlank()) {
            return
        }

        queries.value = listOf(normalized) + queries.value.filterNot {
            it.equals(normalized, ignoreCase = true)
        }
    }

    override fun clear() {
        queries.value = emptyList()
    }
}

private class FakeDictionaryRepository(
    private val bundle: DictionaryBundle,
    private val searchResults: List<DictionaryEntry> = emptyList(),
    private val entryById: Map<Long, DictionaryEntry> = searchResults.associateBy { it.id },
    private val linkedEntriesByWord: Map<String, DictionaryEntry> = emptyMap(),
) : DictionaryRepositoryDataSource {
    var loadBundleCalls: Int = 0
    val searchQueries = mutableListOf<String>()
    val entryRequests = mutableListOf<Long>()
    val linkedWordRequests = mutableListOf<String>()

    override fun loadBundle(): DictionaryBundle {
        loadBundleCalls += 1
        return bundle
    }

    override fun search(rawQuery: String, limit: Int): List<DictionaryEntry> {
        searchQueries += rawQuery
        return searchResults
    }

    override fun entries(ids: List<Long>): List<DictionaryEntry> {
        return ids.mapNotNull(entryById::get)
    }

    override fun entry(id: Long): DictionaryEntry? {
        entryRequests += id
        return entryById[id]
    }

    override fun findLinkedEntry(rawWord: String): DictionaryEntry? {
        linkedWordRequests += rawWord
        return linkedEntriesByWord[rawWord]
    }
}

private fun sampleEntry(
    id: Long,
    hanji: String,
    romanization: String,
    variantChars: List<String> = emptyList(),
    wordSynonyms: List<String> = emptyList(),
    wordAntonyms: List<String> = emptyList(),
    aliasTargetEntryId: Long? = null,
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
        variantChars = variantChars,
        wordSynonyms = wordSynonyms,
        wordAntonyms = wordAntonyms,
        alternativePronunciations = emptyList(),
        contractedPronunciations = emptyList(),
        colloquialPronunciations = emptyList(),
        phoneticDifferences = emptyList(),
        vocabularyComparisons = emptyList(),
        aliasTargetEntryId = aliasTargetEntryId,
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