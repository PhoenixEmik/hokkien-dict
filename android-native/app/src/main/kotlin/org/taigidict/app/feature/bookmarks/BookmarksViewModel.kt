package org.taigidict.app.feature.bookmarks

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.data.bookmarks.BookmarkStore
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.feature.dictionary.DictionaryEntryDetailController

data class BookmarksUiState(
    val isLoadingEntries: Boolean = true,
    val entries: List<DictionaryEntry> = emptyList(),
    val entriesErrorMessage: String? = null,
    val isLoadingEntryDetail: Boolean = false,
    val selectedEntry: DictionaryEntry? = null,
    val openableLinkedWords: Set<String> = emptySet(),
    val entryDetailErrorMessage: String? = null,
)

class BookmarksViewModel(
    application: Application,
    private val repository: DictionaryRepositoryDataSource =
        (application as TaigiDictApplication).appContainer.dictionaryRepository,
    private val bookmarkStore: BookmarkStore =
        (application as TaigiDictApplication).appContainer.bookmarkStore,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : AndroidViewModel(application) {
    constructor(application: Application) : this(
        application = application,
        repository = (application as TaigiDictApplication).appContainer.dictionaryRepository,
        bookmarkStore = (application as TaigiDictApplication).appContainer.bookmarkStore,
        ioDispatcher = Dispatchers.IO,
    )

    private val detailController = DictionaryEntryDetailController(repository)
    private val _uiState = MutableStateFlow(BookmarksUiState())

    val uiState: StateFlow<BookmarksUiState> = _uiState.asStateFlow()

    init {
        observeBookmarks()
    }

    fun onEntrySelected(entryId: Long) {
        val sourceEntry = _uiState.value.entries.firstOrNull { it.id == entryId }
        if (sourceEntry == null) {
            _uiState.update {
                it.copy(entryDetailErrorMessage = "Entry $entryId not found")
            }
            return
        }

        viewModelScope.launch {
            _uiState.update {
                it.copy(
                    isLoadingEntryDetail = true,
                    selectedEntry = null,
                    openableLinkedWords = emptySet(),
                    entryDetailErrorMessage = null,
                )
            }

            val result = withContext(ioDispatcher) {
                runCatching {
                    detailController.prepareEntryDetail(sourceEntry)
                }
            }

            _uiState.update {
                it.copy(
                    isLoadingEntryDetail = false,
                    selectedEntry = result.getOrNull()?.entry,
                    openableLinkedWords = result.getOrNull()?.openableLinkedWords.orEmpty(),
                    entryDetailErrorMessage = result.exceptionOrNull()?.message,
                )
            }
        }
    }

    fun onLinkedWordSelected(word: String) {
        val currentEntry = _uiState.value.selectedEntry ?: return

        viewModelScope.launch {
            _uiState.update {
                it.copy(
                    isLoadingEntryDetail = true,
                    entryDetailErrorMessage = null,
                )
            }

            val result = withContext(ioDispatcher) {
                runCatching {
                    detailController.prepareLinkedEntry(
                        currentEntryId = currentEntry.id,
                        openableLinkedWords = _uiState.value.openableLinkedWords,
                        word = word,
                    )
                }
            }

            _uiState.update {
                it.copy(
                    isLoadingEntryDetail = false,
                    selectedEntry = result.getOrNull()?.entry ?: currentEntry,
                    openableLinkedWords = result.getOrNull()?.openableLinkedWords ?: it.openableLinkedWords,
                    entryDetailErrorMessage = result.exceptionOrNull()?.message,
                )
            }
        }
    }

    fun onEntryDetailDismissed() {
        _uiState.update {
            it.copy(
                isLoadingEntryDetail = false,
                selectedEntry = null,
                openableLinkedWords = emptySet(),
                entryDetailErrorMessage = null,
            )
        }
    }

    fun removeBookmark(entryId: Long) {
        bookmarkStore.removeBookmark(entryId)
    }

    private fun observeBookmarks() {
        viewModelScope.launch {
            bookmarkStore.bookmarkedIds.collectLatest { bookmarkedIds ->
                _uiState.update {
                    it.copy(
                        isLoadingEntries = true,
                        entriesErrorMessage = null,
                    )
                }

                val result = withContext(ioDispatcher) {
                    runCatching {
                        if (bookmarkedIds.isEmpty()) {
                            emptyList()
                        } else {
                            repository.entries(bookmarkedIds)
                        }
                    }
                }

                _uiState.update {
                    it.copy(
                        isLoadingEntries = false,
                        entries = result.getOrDefault(emptyList()),
                        entriesErrorMessage = result.exceptionOrNull()?.message,
                    )
                }
            }
        }
    }
}