package org.taigidict.app.feature.bookmarks

import android.app.Application
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.CoroutineScope
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
import org.taigidict.app.data.bookmarks.BookmarkStoring
import org.taigidict.app.data.conversion.ChineseConversionService
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.domain.model.DictionaryBundle
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class BookmarksViewModelTest {
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
    fun loadsBookmarkedEntriesInStoredOrder() = runTest(dispatcher) {
        val first = sampleEntry(id = 10, hanji = "冊", romanization = "tsheh")
        val second = sampleEntry(id = 20, hanji = "辭典", romanization = "sû-tián")
        val repository = FakeBookmarksRepository(
            entryById = mapOf(first.id to first, second.id to second),
        )
        val bookmarkStore = createBookmarkStore(backgroundScope)
        bookmarkStore.toggleBookmark(first.id)
        bookmarkStore.toggleBookmark(second.id)

        val viewModel = createViewModel(repository, bookmarkStore)
        advanceUntilIdle()

        val uiState = viewModel.uiState.value
        assertFalse(uiState.isLoadingEntries)
        assertEquals(listOf(second, first), uiState.entries)
    }

    @Test
    fun selectedBookmarkLoadsDetailAndLinkedEntry() = runTest(dispatcher) {
        val source = sampleEntry(
            id = 20,
            hanji = "辭典",
            romanization = "sû-tián",
            wordSynonyms = listOf("字典"),
        )
        val linked = sampleEntry(id = 30, hanji = "字典", romanization = "jī-tián")
        val repository = FakeBookmarksRepository(
            entryById = mapOf(source.id to source, linked.id to linked),
            linkedEntriesByWord = mapOf("字典" to linked),
        )
        val bookmarkStore = createBookmarkStore(backgroundScope)
        bookmarkStore.toggleBookmark(source.id)

        val viewModel = createViewModel(repository, bookmarkStore)
        advanceUntilIdle()

        viewModel.onEntrySelected(source.id)
        advanceUntilIdle()
        assertEquals(source, viewModel.uiState.value.selectedEntry)
        assertEquals(setOf("字典"), viewModel.uiState.value.openableLinkedWords)

        viewModel.onLinkedWordSelected("字典")
        advanceUntilIdle()

        assertEquals(linked, viewModel.uiState.value.selectedEntry)
    }

    @Test
    fun onEntrySelected_waitsForOpenableWordsBeforeShowingBookmarkDetail() = runTest(dispatcher) {
        val source = sampleEntry(
            id = 20,
            hanji = "辭典",
            romanization = "sû-tián",
            wordSynonyms = listOf("字典"),
        )
        val linked = sampleEntry(id = 30, hanji = "字典", romanization = "jī-tián")
        val repository = FakeBookmarksRepository(
            entryById = mapOf(source.id to source, linked.id to linked),
            linkedEntriesByWord = mapOf("字典" to linked),
        )
        val bookmarkStore = createBookmarkStore(backgroundScope)

        val viewModel = createViewModel(
            repository = repository,
            bookmarkStore = bookmarkStore,
        )
        advanceUntilIdle()
        bookmarkStore.toggleBookmark(source.id)
        advanceUntilIdle()

        viewModel.onEntrySelected(source.id)

        val loadingState = viewModel.uiState.value
        assertTrue(loadingState.isLoadingEntryDetail)
        assertNull(loadingState.selectedEntry)
        assertTrue(loadingState.openableLinkedWords.isEmpty())
        advanceUntilIdle()
        assertEquals(source, viewModel.uiState.value.selectedEntry)
        assertEquals(setOf("字典"), viewModel.uiState.value.openableLinkedWords)
        viewModel.onEntrySelected(source.id)
        assertFalse(viewModel.uiState.value.isLoadingEntryDetail)
        assertEquals(setOf("字典"), viewModel.uiState.value.openableLinkedWords)
    }

    @Test
    fun simplifiedChinese_translatesBookmarkDisplayFields() = runTest(dispatcher) {
        val entry = sampleEntry(id = 20, hanji = "辭典", romanization = "sû-tián")
        val repository = FakeBookmarksRepository(
            entryById = mapOf(entry.id to entry),
        )
        val bookmarkStore = createBookmarkStore(backgroundScope)
        bookmarkStore.toggleBookmark(entry.id)
        val settingsStore = FakeBookmarksSettingsStore()
        settingsStore.setLanguagePreference(AppLanguagePreference.SimplifiedChinese)
        val conversionService = FakeBookmarksChineseConversionService(
            translatedMap = mapOf("辭典" to "词典", "一種工具書。" to "一种工具书。"),
        )

        val viewModel = createViewModel(
            repository = repository,
            bookmarkStore = bookmarkStore,
            settingsStore = settingsStore,
            conversionService = conversionService,
        )
        advanceUntilIdle()

        assertEquals("词典", viewModel.uiState.value.entries.first().hanji)
        assertEquals("一种工具书。", viewModel.uiState.value.entries.first().senses.first().definition)
    }

    @Test
    fun languageChange_retranslatesVisibleBookmarksAndDetail() = runTest(dispatcher) {
        val linkedEntry = sampleEntry(id = 30, hanji = "辭書", romanization = "sû-su")
        val entry = sampleEntry(
            id = 20,
            hanji = "辭典",
            romanization = "sû-tián",
            wordSynonyms = listOf("辭書"),
        )
        val repository = FakeBookmarksRepository(
            entryById = mapOf(entry.id to entry, linkedEntry.id to linkedEntry),
            linkedEntriesByWord = mapOf("辭書" to linkedEntry),
        )
        val bookmarkStore = createBookmarkStore(backgroundScope)
        bookmarkStore.toggleBookmark(entry.id)
        val settingsStore = FakeBookmarksSettingsStore()
        val conversionService = FakeBookmarksChineseConversionService(
            translatedMap = mapOf(
                "辭典" to "词典",
                "辭書" to "辞书",
                "一種工具書。" to "一种工具书。",
            ),
        )

        val viewModel = createViewModel(
            repository = repository,
            bookmarkStore = bookmarkStore,
            settingsStore = settingsStore,
            conversionService = conversionService,
        )
        advanceUntilIdle()
        viewModel.onEntrySelected(entry.id)
        advanceUntilIdle()
        assertEquals("辭典", viewModel.uiState.value.entries.first().hanji)
        assertEquals("辭典", viewModel.uiState.value.selectedEntry?.hanji)
        assertEquals(setOf("辭書"), viewModel.uiState.value.openableLinkedWords)

        settingsStore.setLanguagePreference(AppLanguagePreference.SimplifiedChinese)
        advanceUntilIdle()

        assertEquals("词典", viewModel.uiState.value.entries.first().hanji)
        assertEquals("词典", viewModel.uiState.value.selectedEntry?.hanji)
        assertEquals("一种工具书。", viewModel.uiState.value.selectedEntry?.senses?.first()?.definition)
        assertEquals(setOf("辞书"), viewModel.uiState.value.openableLinkedWords)
    }

    private fun createBookmarkStore(@Suppress("UNUSED_PARAMETER") scope: CoroutineScope): BookmarkStoring {
        return FakeBookmarkStore()
    }

    private fun createViewModel(
        repository: DictionaryRepositoryDataSource,
        bookmarkStore: BookmarkStoring,
        settingsStore: AppSettingsStoring = FakeBookmarksSettingsStore(),
        conversionService: ChineseConversionService = FakeBookmarksChineseConversionService(),
        ioDispatcher: kotlinx.coroutines.CoroutineDispatcher = dispatcher,
    ): BookmarksViewModel {
        val application = ApplicationProvider.getApplicationContext<Application>()
        return BookmarksViewModel(
            application = application,
            repository = repository,
            settingsStore = settingsStore,
            chineseConversionService = conversionService,
            bookmarkStore = bookmarkStore,
            ioDispatcher = ioDispatcher,
        )
    }
}

private class FakeBookmarkStore : BookmarkStoring {
    private val _bookmarkedIds = MutableStateFlow(emptyList<Long>())
    override val bookmarkedIds: StateFlow<List<Long>> = _bookmarkedIds.asStateFlow()

    override fun isBookmarked(entryId: Long): Boolean {
        return _bookmarkedIds.value.contains(entryId)
    }

    override suspend fun toggleBookmark(entryId: Long): Boolean {
        val updated = _bookmarkedIds.value.toMutableList().apply {
            if (contains(entryId)) {
                remove(entryId)
            } else {
                remove(entryId)
                add(0, entryId)
            }
        }
        _bookmarkedIds.value = updated
        return updated.contains(entryId)
    }

    override suspend fun addBookmark(entryId: Long, index: Int): Boolean {
        _bookmarkedIds.value = _bookmarkedIds.value.toMutableList().apply {
            remove(entryId)
            add(index.coerceIn(0, size), entryId)
        }
        return true
    }

    override suspend fun removeBookmark(entryId: Long): Boolean {
        val previous = _bookmarkedIds.value
        if (!previous.contains(entryId)) {
            return false
        }
        _bookmarkedIds.value = previous.filterNot { it == entryId }
        return true
    }
}

private class FakeBookmarksSettingsStore : AppSettingsStoring {
    private val _themePreference = kotlinx.coroutines.flow.MutableStateFlow(AppThemePreference.System)
    private val _languagePreference = kotlinx.coroutines.flow.MutableStateFlow(AppLanguagePreference.System)
    private val _readingTextScale = kotlinx.coroutines.flow.MutableStateFlow(AppSettingsConstants.DEFAULT_READING_TEXT_SCALE)

    override val initialThemePreference: AppThemePreference = _themePreference.value
    override val initialLanguagePreference: AppLanguagePreference = _languagePreference.value
    override val initialReadingTextScale: Double = _readingTextScale.value
    override val themePreference: kotlinx.coroutines.flow.StateFlow<AppThemePreference> = _themePreference
    override val languagePreference: kotlinx.coroutines.flow.StateFlow<AppLanguagePreference> = _languagePreference
    override val readingTextScale: kotlinx.coroutines.flow.StateFlow<Double> = _readingTextScale

    override suspend fun setThemePreference(preference: AppThemePreference) {
        _themePreference.value = preference
    }

    override suspend fun setLanguagePreference(preference: AppLanguagePreference) {
        _languagePreference.value = preference
    }

    override suspend fun setReadingTextScale(value: Double) {
        _readingTextScale.value = AppSettingsConstants.snapReadingTextScale(value)
    }
}

private class FakeBookmarksChineseConversionService(
    private val translatedMap: Map<String, String> = emptyMap(),
) : ChineseConversionService {
    override suspend fun normalizeSearchInput(text: String, locale: AppLocale): String {
        return translatedMap[text] ?: text
    }

    override suspend fun translateForDisplay(text: String, locale: AppLocale): String {
        return if (locale == AppLocale.SimplifiedChinese) {
            translatedMap[text] ?: text
        } else {
            text
        }
    }
}

private class FakeBookmarksRepository(
    private val entryById: Map<Long, DictionaryEntry>,
    private val linkedEntriesByWord: Map<String, DictionaryEntry> = emptyMap(),
) : DictionaryRepositoryDataSource {
    override fun loadBundle(): DictionaryBundle {
        return DictionaryBundle(0, 0, 0, "/tmp/dictionary.sqlite")
    }

    override fun search(rawQuery: String, limit: Int): List<DictionaryEntry> {
        return emptyList()
    }

    override fun entries(ids: List<Long>): List<DictionaryEntry> {
        return ids.mapNotNull(entryById::get)
    }

    override fun entry(id: Long): DictionaryEntry? {
        return entryById[id]
    }

    override fun findLinkedEntry(rawWord: String): DictionaryEntry? {
        return linkedEntriesByWord[rawWord]
    }
}

private fun sampleEntry(
    id: Long,
    hanji: String,
    romanization: String,
    wordSynonyms: List<String> = emptyList(),
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
        wordSynonyms = wordSynonyms,
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
