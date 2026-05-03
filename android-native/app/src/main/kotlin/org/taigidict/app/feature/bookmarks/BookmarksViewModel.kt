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
import org.taigidict.app.core.localization.AppLocale
import org.taigidict.app.core.localization.AppLocaleResolver
import org.taigidict.app.core.settings.AppSettingsStoring
import org.taigidict.app.data.bookmarks.BookmarkStore
import org.taigidict.app.data.conversion.ChineseConversionService
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense
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
    private val settingsStore: AppSettingsStoring =
        (application as TaigiDictApplication).appContainer.appSettingsStore,
    private val chineseConversionService: ChineseConversionService =
        (application as TaigiDictApplication).appContainer.chineseConversionService,
    private val bookmarkStore: BookmarkStore =
        (application as TaigiDictApplication).appContainer.bookmarkStore,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : AndroidViewModel(application) {
    constructor(application: Application) : this(
        application = application,
        repository = (application as TaigiDictApplication).appContainer.dictionaryRepository,
        settingsStore = (application as TaigiDictApplication).appContainer.appSettingsStore,
        chineseConversionService = (application as TaigiDictApplication).appContainer.chineseConversionService,
        bookmarkStore = (application as TaigiDictApplication).appContainer.bookmarkStore,
        ioDispatcher = Dispatchers.IO,
    )

    private val detailController = DictionaryEntryDetailController(repository)
    private val _uiState = MutableStateFlow(BookmarksUiState())
    private var currentLocale: AppLocale = AppLocale.TraditionalChinese

    val uiState: StateFlow<BookmarksUiState> = _uiState.asStateFlow()

    init {
        observeLanguagePreference()
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
                    val prepared = detailController.prepareEntryDetail(sourceEntry)
                    org.taigidict.app.feature.dictionary.PreparedDictionaryEntryDetail(
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

        viewModelScope.launch {
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
                            repository.entries(bookmarkedIds).map { entry ->
                                translateEntryForDisplay(entry)
                            }
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

    private fun observeLanguagePreference() {
        viewModelScope.launch {
            settingsStore.languagePreference.collectLatest { preference ->
                currentLocale = AppLocaleResolver.resolve(preference)
            }
        }
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
}