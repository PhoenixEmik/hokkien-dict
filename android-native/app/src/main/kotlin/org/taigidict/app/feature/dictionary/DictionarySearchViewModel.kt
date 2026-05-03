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
import kotlinx.coroutines.delay
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
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense

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
    val hasLoadedRecentSearches: Boolean = false,
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
    private val searchDebounceMillis: Long = SEARCH_DEBOUNCE_MILLIS,
) : AndroidViewModel(application) {
    constructor(application: Application) : this(
        application = application,
        repository = (application as TaigiDictApplication).appContainer.dictionaryRepository,
        settingsStore = (application as TaigiDictApplication).appContainer.appSettingsStore,
        chineseConversionService = (application as TaigiDictApplication).appContainer.chineseConversionService,
        searchHistoryStore = (application as TaigiDictApplication).appContainer.searchHistoryStore,
        ioDispatcher = Dispatchers.IO,
        searchDebounceMillis = SEARCH_DEBOUNCE_MILLIS,
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
        persistCurrentQueryIfNeeded()
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

            delay(searchDebounceMillis)

            val result = withContext(ioDispatcher) {
                runCatching {
                    val convertedQuery = chineseConversionService.normalizeSearchInput(
                        text = query,
                        locale = currentLocale,
                    )
                    val rawResults = repository.search(convertedQuery)
                    rawResults.map { entry ->
                        translateEntryForDisplay(entry)
                    }
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
        persistCurrentQueryIfNeeded()
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
                    val prepared = detailController.prepareEntryDetail(entry)
                    PreparedDictionaryEntryDetail(
                        entry = translateEntryForDisplay(prepared.entry),
                        openableLinkedWords = prepared.openableLinkedWords.map {
                            chineseConversionService.translateForDisplay(it, currentLocale)
                        }.toSet(),
                    )
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
                    val convertedOpenableWords = _uiState.value.openableLinkedWords.map {
                        chineseConversionService.normalizeSearchInput(
                            text = it,
                            locale = currentLocale,
                        )
                    }.toSet()
                    detailController.prepareLinkedEntry(
                        currentEntryId = currentEntry.id,
                        openableLinkedWords = convertedOpenableWords,
                        word = convertedWord,
                    )
                }
            }

            _uiState.update {
                it.copy(
                    isLoadingEntryDetail = false,
                    selectedEntry = result.getOrNull()?.entry?.let { entry ->
                        runCatching { translateEntryForDisplay(entry) }.getOrDefault(entry)
                    } ?: currentEntry,
                    openableLinkedWords = result.getOrNull()?.openableLinkedWords?.map { linkedWord ->
                        runCatching {
                            chineseConversionService.translateForDisplay(
                                linkedWord,
                                currentLocale,
                            )
                        }.getOrDefault(linkedWord)
                    }?.toSet() ?: it.openableLinkedWords,
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
                    it.copy(
                        recentSearches = queries,
                        hasLoadedRecentSearches = true,
                    )
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

    private fun persistCurrentQueryIfNeeded() {
        val state = _uiState.value
        if (state.query.isBlank() || state.results.isEmpty()) {
            return
        }

        searchHistoryStore.addQuery(state.query)
    }

    private suspend fun translateEntryForDisplay(entry: DictionaryEntry): DictionaryEntry {
        val senses = entry.senses.map { sense ->
            DictionarySense(
                partOfSpeech = chineseConversionService.translateForDisplay(
                    sense.partOfSpeech,
                    currentLocale,
                ),
                definition = chineseConversionService.translateForDisplay(
                    sense.definition,
                    currentLocale,
                ),
                definitionSynonyms = sense.definitionSynonyms.map { value ->
                    chineseConversionService.translateForDisplay(value, currentLocale)
                },
                definitionAntonyms = sense.definitionAntonyms.map { value ->
                    chineseConversionService.translateForDisplay(value, currentLocale)
                },
                examples = sense.examples.map { example ->
                    DictionaryExample(
                        hanji = chineseConversionService.translateForDisplay(
                            example.hanji,
                            currentLocale,
                        ),
                        romanization = chineseConversionService.translateForDisplay(
                            example.romanization,
                            currentLocale,
                        ),
                        mandarin = chineseConversionService.translateForDisplay(
                            example.mandarin,
                            currentLocale,
                        ),
                        audioId = example.audioId,
                    )
                },
            )
        }

        return entry.copy(
            type = chineseConversionService.translateForDisplay(entry.type, currentLocale),
            hanji = chineseConversionService.translateForDisplay(entry.hanji, currentLocale),
            category = chineseConversionService.translateForDisplay(entry.category, currentLocale),
            mandarinSearch = chineseConversionService.translateForDisplay(
                entry.mandarinSearch,
                currentLocale,
            ),
            variantChars = entry.variantChars.map { value ->
                chineseConversionService.translateForDisplay(value, currentLocale)
            },
            wordSynonyms = entry.wordSynonyms.map { value ->
                chineseConversionService.translateForDisplay(value, currentLocale)
            },
            wordAntonyms = entry.wordAntonyms.map { value ->
                chineseConversionService.translateForDisplay(value, currentLocale)
            },
            alternativePronunciations = entry.alternativePronunciations.map { value ->
                chineseConversionService.translateForDisplay(value, currentLocale)
            },
            contractedPronunciations = entry.contractedPronunciations.map { value ->
                chineseConversionService.translateForDisplay(value, currentLocale)
            },
            colloquialPronunciations = entry.colloquialPronunciations.map { value ->
                chineseConversionService.translateForDisplay(value, currentLocale)
            },
            phoneticDifferences = entry.phoneticDifferences.map { value ->
                chineseConversionService.translateForDisplay(value, currentLocale)
            },
            vocabularyComparisons = entry.vocabularyComparisons.map { value ->
                chineseConversionService.translateForDisplay(value, currentLocale)
            },
            senses = senses,
        )
    }

    private companion object {
        const val SEARCH_DEBOUNCE_MILLIS = 300L
    }
}