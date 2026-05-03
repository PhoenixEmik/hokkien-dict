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
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.core.localization.AppLocale
import org.taigidict.app.core.localization.AppLocaleResolver
import org.taigidict.app.core.settings.AppSettingsStoring
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.data.conversion.ChineseConversionService
import org.taigidict.app.data.search.SearchHistoryStoring
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
    val recentSearches: List<String> = emptyList(),
)

class DictionarySearchViewModel(
    application: Application,
    private val repository: DictionaryRepositoryDataSource =
        (application as TaigiDictApplication).appContainer.dictionaryRepository,
    private val settingsStore: AppSettingsStoring =
        (application as TaigiDictApplication).appContainer.appSettingsStore,
    private val chineseConversionService: ChineseConversionService =
        (application as TaigiDictApplication).appContainer.chineseConversionService,
    private val searchHistoryStore: SearchHistoryStoring =
        (application as TaigiDictApplication).appContainer.searchHistoryStore,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : AndroidViewModel(application) {
    constructor(application: Application) : this(
        application = application,
        repository = (application as TaigiDictApplication).appContainer.dictionaryRepository,
        settingsStore = (application as TaigiDictApplication).appContainer.appSettingsStore,
        chineseConversionService = (application as TaigiDictApplication).appContainer.chineseConversionService,
        searchHistoryStore = (application as TaigiDictApplication).appContainer.searchHistoryStore,
        ioDispatcher = Dispatchers.IO,
    )

    private val detailController = DictionaryEntryDetailController(repository)
    private val _uiState = MutableStateFlow(DictionarySearchUiState())
    val uiState: StateFlow<DictionarySearchUiState> = _uiState.asStateFlow()
    private var searchJob: Job? = null
    private var entryDetailJob: Job? = null
    private var currentLocale: AppLocale = AppLocale.TraditionalChinese

    init {
        observeLanguagePreference()
        observeSearchHistory()
        loadBundle()
    }

    fun onSearchSubmitted() {
        searchHistoryStore.addQuery(_uiState.value.query)
    }

    fun onRecentSearchSelected(query: String) {
        onQueryChange(query)
    }

    fun onClearRecentSearches() {
        searchHistoryStore.clear()
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
                    val convertedQuery = chineseConversionService.normalizeSearchInput(
                        text = query,
                        locale = currentLocale,
                    )
                    repository.search(convertedQuery)
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
        onSearchSubmitted()
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
                    detailController.prepareEntryDetail(entry)
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
                    val convertedWord = chineseConversionService.normalizeSearchInput(
                        text = word,
                        locale = currentLocale,
                    )
                    detailController.prepareLinkedEntry(
                        currentEntryId = currentEntry.id,
                        openableLinkedWords = _uiState.value.openableLinkedWords,
                        word = convertedWord,
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

    private fun observeSearchHistory() {
        viewModelScope.launch {
            searchHistoryStore.recentQueries.collectLatest { queries ->
                _uiState.update {
                    it.copy(recentSearches = queries)
                }
            }
        }
    }

    private fun observeLanguagePreference() {
        viewModelScope.launch {
            settingsStore.languagePreference.collectLatest { preference ->
                currentLocale = AppLocaleResolver.resolve(preference)
            }
        }
    }
}