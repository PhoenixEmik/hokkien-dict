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
import org.taigidict.app.data.bookmarks.BookmarkStoring
import org.taigidict.app.data.conversion.ChineseConversionService
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense
import org.taigidict.app.feature.dictionary.DictionaryEntryDetailController
import org.taigidict.app.feature.dictionary.PreparedDictionaryEntryDetail

data class BookmarksUiState(
    val isLoadingEntries: Boolean = true,
    val entries: List<DictionaryEntry> = emptyList(),
    val entriesErrorMessage: String? = null,
    val isLoadingEntryDetail: Boolean = false,
    val selectedEntry: DictionaryEntry? = null,
    val canNavigateBackInDetail: Boolean = false,
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
    private val bookmarkStore: BookmarkStoring =
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
    private var rawEntries: List<DictionaryEntry> = emptyList()
    private var rawSelectedEntryDetail: PreparedDictionaryEntryDetail? = null
    private var rawEntryDetailBackStack: List<PreparedDictionaryEntryDetail> = emptyList()

    val uiState: StateFlow<BookmarksUiState> = _uiState.asStateFlow()

    init {
        observeLanguagePreference()
        observeBookmarks()
    }

    fun onEntrySelected(entryId: Long) {
        if (_uiState.value.selectedEntry?.id == entryId && rawSelectedEntryDetail?.entry?.id == entryId) {
            return
        }
        val sourceEntry = rawEntries.firstOrNull { it.id == entryId }
        if (sourceEntry == null) {
            _uiState.update {
                it.copy(entryDetailErrorMessage = "Entry $entryId not found")
            }
            return
        }

        _uiState.update {
            it.copy(
                isLoadingEntryDetail = true,
                selectedEntry = null,
                canNavigateBackInDetail = false,
                openableLinkedWords = emptySet(),
                entryDetailErrorMessage = null,
            )
        }
        rawEntryDetailBackStack = emptyList()
        viewModelScope.launch {
            val result = withContext(ioDispatcher) {
                runCatching {
                    val rawDetail = detailController.prepareEntryDetail(sourceEntry)
                    rawDetail to translateEntryDetailForDisplay(rawDetail)
                }
            }

            rawSelectedEntryDetail = result.getOrNull()?.first
            val translatedDetail = result.getOrNull()?.second
            _uiState.update {
                it.copy(
                    isLoadingEntryDetail = false,
                    selectedEntry = translatedDetail?.entry,
                    openableLinkedWords = translatedDetail?.openableLinkedWords.orEmpty(),
                    entryDetailErrorMessage = result.exceptionOrNull()?.message,
                )
            }
        }
    }

    fun onLinkedWordSelected(word: String) {
        val currentDetail = rawSelectedEntryDetail ?: return
        val currentEntry = currentDetail.entry
        if (!_uiState.value.openableLinkedWords.contains(word)) {
            return
        }

        _uiState.update {
            it.copy(
                isLoadingEntryDetail = true,
                entryDetailErrorMessage = null,
            )
        }
        viewModelScope.launch {
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
                    val rawDetail = detailController.prepareLinkedEntry(
                        currentEntryId = currentEntry.id,
                        openableLinkedWords = convertedOpenableWords,
                        word = convertedWord,
                    )
                    rawDetail to translateEntryDetailForDisplay(rawDetail)
                }
            }

            val rawDetail = result.getOrNull()?.first
            val translatedDetail = result.getOrNull()?.second
            if (rawDetail != null && translatedDetail != null) {
                rawSelectedEntryDetail = rawDetail
                rawEntryDetailBackStack = rawEntryDetailBackStack + currentDetail
            }
            _uiState.update {
                it.copy(
                    isLoadingEntryDetail = false,
                    selectedEntry = translatedDetail?.entry ?: it.selectedEntry,
                    canNavigateBackInDetail = rawEntryDetailBackStack.isNotEmpty(),
                    openableLinkedWords = translatedDetail?.openableLinkedWords ?: it.openableLinkedWords,
                    entryDetailErrorMessage = result.exceptionOrNull()?.message,
                )
            }
        }
    }

    fun onEntryDetailBack() {
        val previousDetail = rawEntryDetailBackStack.lastOrNull()
        if (previousDetail == null) {
            onEntryDetailDismissed()
            return
        }

        rawEntryDetailBackStack = rawEntryDetailBackStack.dropLast(1)
        rawSelectedEntryDetail = previousDetail
        _uiState.update {
            it.copy(
                isLoadingEntryDetail = true,
                entryDetailErrorMessage = null,
            )
        }
        viewModelScope.launch {
            val translatedDetail = withContext(ioDispatcher) {
                translateEntryDetailForDisplay(previousDetail)
            }
            _uiState.update {
                it.copy(
                    isLoadingEntryDetail = false,
                    selectedEntry = translatedDetail.entry,
                    canNavigateBackInDetail = rawEntryDetailBackStack.isNotEmpty(),
                    openableLinkedWords = translatedDetail.openableLinkedWords,
                    entryDetailErrorMessage = null,
                )
            }
        }
    }

    fun onEntryDetailDismissed() {
        rawSelectedEntryDetail = null
        rawEntryDetailBackStack = emptyList()
        _uiState.update {
            it.copy(
                isLoadingEntryDetail = false,
                selectedEntry = null,
                canNavigateBackInDetail = false,
                openableLinkedWords = emptySet(),
                entryDetailErrorMessage = null,
            )
        }
    }

    fun removeBookmark(entryId: Long) {
        viewModelScope.launch {
            bookmarkStore.removeBookmark(entryId)
        }
    }

    fun removeBookmarks(entryIds: Collection<Long>) {
        viewModelScope.launch {
            entryIds.forEach { entryId ->
                bookmarkStore.removeBookmark(entryId)
            }
        }
    }

    fun addBookmark(entryId: Long, index: Int = 0) {
        viewModelScope.launch {
            bookmarkStore.addBookmark(entryId, index)
        }
    }

    fun restoreBookmarks(entries: List<Pair<Long, Int>>) {
        viewModelScope.launch {
            entries.sortedBy { it.second }.forEach { (entryId, index) ->
                bookmarkStore.addBookmark(entryId, index)
            }
        }
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
                        val rawBookmarkedEntries = if (bookmarkedIds.isEmpty()) {
                            emptyList()
                        } else {
                            repository.entries(bookmarkedIds)
                        }
                        rawBookmarkedEntries to rawBookmarkedEntries.map { entry ->
                            translateEntryForDisplay(entry)
                        }
                    }
                }

                rawEntries = result.getOrNull()?.first.orEmpty()
                _uiState.update {
                    it.copy(
                        isLoadingEntries = false,
                        entries = result.getOrNull()?.second.orEmpty(),
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
                retranslateVisibleContent()
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

    private suspend fun translateEntryDetailForDisplay(
        detail: PreparedDictionaryEntryDetail,
    ): PreparedDictionaryEntryDetail {
        return PreparedDictionaryEntryDetail(
            entry = translateEntryForDisplay(detail.entry),
            openableLinkedWords = detail.openableLinkedWords.map { word ->
                chineseConversionService.translateForDisplay(word, currentLocale)
            }.toSet(),
        )
    }

    private suspend fun retranslateVisibleContent() {
        val result = withContext(ioDispatcher) {
            runCatching {
                val translatedEntries = rawEntries.map { entry ->
                    translateEntryForDisplay(entry)
                }
                val translatedDetail = rawSelectedEntryDetail?.let { detail ->
                    translateEntryDetailForDisplay(detail)
                }
                translatedEntries to translatedDetail
            }
        }
        val (translatedEntries, translatedDetail) = result.getOrNull() ?: return
        _uiState.update {
            val translatedLoadingPreview = if (rawSelectedEntryDetail == null) {
                it.selectedEntry?.let { selected ->
                    translatedEntries.firstOrNull { entry -> entry.id == selected.id }
                }
            } else {
                null
            }
            it.copy(
                entries = translatedEntries,
                selectedEntry = translatedDetail?.entry ?: translatedLoadingPreview,
                canNavigateBackInDetail = rawEntryDetailBackStack.isNotEmpty(),
                openableLinkedWords = translatedDetail?.openableLinkedWords
                    ?: if (rawSelectedEntryDetail == null) it.openableLinkedWords else emptySet(),
            )
        }
    }
}
