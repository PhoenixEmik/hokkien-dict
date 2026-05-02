package org.taigidict.app.feature.bookmarks

import android.app.Application
import android.content.Context
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
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.taigidict.app.data.bookmarks.BookmarkStore
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.domain.model.DictionaryBundle
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense
import java.util.UUID

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
        val bookmarkStore = createBookmarkStore().apply {
            toggleBookmark(first.id)
            toggleBookmark(second.id)
        }

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
        val bookmarkStore = createBookmarkStore().apply {
            toggleBookmark(source.id)
        }

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

    private fun createBookmarkStore(): BookmarkStore {
        val context = ApplicationProvider.getApplicationContext<Context>()
        return BookmarkStore(
            context = context,
            preferencesName = "bookmarks-viewmodel-test-${UUID.randomUUID()}",
        )
    }

    private fun createViewModel(
        repository: DictionaryRepositoryDataSource,
        bookmarkStore: BookmarkStore,
    ): BookmarksViewModel {
        val application = ApplicationProvider.getApplicationContext<Application>()
        return BookmarksViewModel(
            application = application,
            repository = repository,
            bookmarkStore = bookmarkStore,
            ioDispatcher = dispatcher,
        )
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