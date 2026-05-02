package org.taigidict.app.feature.dictionary

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.domain.model.DictionaryBundle
import org.taigidict.app.domain.model.DictionaryEntry

data class DictionarySearchUiState(
    val query: String = "",
    val isLoadingBundle: Boolean = true,
    val isSearching: Boolean = false,
    val isLoadingEntryDetail: Boolean = false,
    val bundle: DictionaryBundle? = null,
    val selectedEntry: DictionaryEntry? = null,
    val openableLinkedWords: Set<String> = emptySet(),
    val bundleErrorMessage: String? = null,
    val searchErrorMessage: String? = null,
    val entryDetailErrorMessage: String? = null,
    val results: List<DictionaryEntry> = emptyList(),
)

class DictionarySearchViewModel(
    application: Application,
    private val repository: DictionaryRepositoryDataSource =
        (application as TaigiDictApplication).appContainer.dictionaryRepository,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : AndroidViewModel(application) {
    private val _uiState = MutableStateFlow(DictionarySearchUiState())
    val uiState: StateFlow<DictionarySearchUiState> = _uiState.asStateFlow()
    private var searchJob: Job? = null
    private var entryDetailJob: Job? = null

    init {
        loadBundle()
    }

    fun onQueryChange(query: String) {
        _uiState.update {
            it.copy(
                query = query,
                searchErrorMessage = null,
            )
        }

        searchJob?.cancel()
        if (query.isBlank()) {
            _uiState.update {
                it.copy(
                    isSearching = false,
                    searchErrorMessage = null,
                    results = emptyList(),
                )
            }
            return
        }

        searchJob = viewModelScope.launch {
            _uiState.update {
                it.copy(
                    isSearching = true,
                    searchErrorMessage = null,
                )
            }

            val result = withContext(ioDispatcher) {
                runCatching {
                    repository.search(query)
                }
            }

            _uiState.update {
                it.copy(
                    isSearching = false,
                    searchErrorMessage = result.exceptionOrNull()?.message,
                    results = result.getOrDefault(emptyList()),
                )
            }
        }
    }

    fun onEntrySelected(entryId: Long) {
        entryDetailJob?.cancel()
        entryDetailJob = viewModelScope.launch {
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
                    val entry = repository.entry(entryId)
                        ?: throw IllegalStateException("Entry $entryId not found")
                    prepareEntryDetail(entry)
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
        if (!_uiState.value.openableLinkedWords.contains(word)) {
            return
        }

        entryDetailJob?.cancel()
        entryDetailJob = viewModelScope.launch {
            _uiState.update {
                it.copy(
                    isLoadingEntryDetail = true,
                    entryDetailErrorMessage = null,
                )
            }

            val result = withContext(ioDispatcher) {
                runCatching {
                    val linkedEntry = repository.findLinkedEntry(word)
                        ?: throw IllegalStateException("Linked entry $word not found")
                    val prepared = prepareEntryDetail(linkedEntry)
                    if (prepared.entry.id == currentEntry.id) {
                        throw IllegalStateException("Linked entry $word resolves to the current entry")
                    }
                    prepared
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
        entryDetailJob?.cancel()
        _uiState.update {
            it.copy(
                isLoadingEntryDetail = false,
                selectedEntry = null,
                openableLinkedWords = emptySet(),
                entryDetailErrorMessage = null,
            )
        }
    }

    private fun prepareEntryDetail(sourceEntry: DictionaryEntry): PreparedEntryDetail {
        val resolvedEntry = resolveAliasChain(sourceEntry)
        val openableLinkedWords = collectLinkedWords(resolvedEntry)
            .filterTo(linkedSetOf()) { word ->
                val linkedEntry = repository.findLinkedEntry(word) ?: return@filterTo false
                resolveAliasChain(linkedEntry).id != resolvedEntry.id
            }

        return PreparedEntryDetail(
            entry = resolvedEntry,
            openableLinkedWords = openableLinkedWords,
        )
    }

    private fun resolveAliasChain(sourceEntry: DictionaryEntry): DictionaryEntry {
        var currentEntry = sourceEntry
        val visitedIds = mutableSetOf<Long>()

        while (currentEntry.aliasTargetEntryId != null && visitedIds.add(currentEntry.id)) {
            val targetEntry = repository.entry(currentEntry.aliasTargetEntryId!!)
                ?: break
            currentEntry = targetEntry
        }

        return currentEntry
    }

    private fun collectLinkedWords(entry: DictionaryEntry): List<String> {
        val orderedWords = linkedSetOf<String>()

        fun addWords(words: List<String>) {
            words.forEach { word ->
                val trimmed = word.trim()
                if (trimmed.isNotEmpty()) {
                    orderedWords += trimmed
                }
            }
        }

        addWords(entry.variantChars)
        addWords(entry.wordSynonyms)
        addWords(entry.wordAntonyms)
        entry.senses.forEach { sense ->
            addWords(sense.definitionSynonyms)
            addWords(sense.definitionAntonyms)
        }

        return orderedWords.toList()
    }

    private data class PreparedEntryDetail(
        val entry: DictionaryEntry,
        val openableLinkedWords: Set<String>,
    )

    private fun loadBundle() {
        viewModelScope.launch {
            val result = withContext(ioDispatcher) {
                runCatching {
                    repository.loadBundle()
                }
            }

            _uiState.update {
                it.copy(
                    isLoadingBundle = false,
                    bundle = result.getOrNull(),
                    bundleErrorMessage = result.exceptionOrNull()?.message,
                )
            }
        }
    }
}