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
                    entryDetailErrorMessage = null,
                )
            }

            val result = withContext(ioDispatcher) {
                runCatching {
                    repository.entry(entryId)
                        ?: throw IllegalStateException("Entry $entryId not found")
                }
            }

            _uiState.update {
                it.copy(
                    isLoadingEntryDetail = false,
                    selectedEntry = result.getOrNull(),
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
                entryDetailErrorMessage = null,
            )
        }
    }

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