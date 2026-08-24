package org.taigidict.app.app

import java.io.File
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.taigidict.app.core.settings.AppSettingsStoring
import org.taigidict.app.core.settings.DataStoreAppSettingsStore
import org.taigidict.app.data.bookmarks.BookmarkStore
import org.taigidict.app.data.conversion.ChineseConversionService
import org.taigidict.app.data.importer.BundledDictionaryImporting
import org.taigidict.app.data.importer.DictionaryImportService
import org.taigidict.app.data.importer.DictionaryJsonlReader
import org.taigidict.app.data.importer.DictionaryManifest
import org.taigidict.app.data.importer.DictionaryPackageLoading
import org.taigidict.app.data.importer.ValidatedDictionaryPackage
import org.taigidict.app.data.repository.DictionaryRepositoryBackend
import org.taigidict.app.data.search.SearchHistoryStore
import org.taigidict.app.data.search.SearchHistoryStoring
import org.taigidict.app.data.source.DictionarySourceResourceManaging
import org.taigidict.app.data.source.DownloadSnapshot

class RoomBackendSmokeTestApplication : TaigiDictApplication() {
    override fun createAppContainer(): AppContainer {
        val fixtureDirectory = File(filesDir, "room-smoke")
        fixtureDirectory.deleteRecursively()
        fixtureDirectory.mkdirs()

        val databaseFile = File(fixtureDirectory, "dictionary.sqlite")
        val packageLoader = StaticDictionaryPackageLoader(samplePackage())
        val importService = DictionaryImportService(
            databaseFile = databaseFile,
            packageLoader = packageLoader,
            jsonlReader = DictionaryJsonlReader(),
        )

        return AppContainer(
            context = applicationContext,
            overrides = AppContainerOverrides(
                dictionaryDatabaseFile = databaseFile,
                dictionaryRepositoryBackend = DictionaryRepositoryBackend.Room,
                dictionaryImportService = importService,
                localDictionaryImportService = importService,
                dictionarySourceResourceStore = IdleDictionarySourceStore(),
                bookmarkStore = BookmarkStore(
                    context = applicationContext,
                    preferencesName = "room_smoke_bookmarks",
                    storageKey = "room_smoke_bookmarks",
                ),
                searchHistoryStore = SearchHistoryStore(
                    context = applicationContext,
                    preferencesName = "room_smoke_search_history",
                    storageKey = "room_smoke_search_history",
                ),
                appSettingsStore = DataStoreAppSettingsStore(
                    context = applicationContext,
                    storeName = "room_smoke_settings",
                    sharedPreferencesName = "room_smoke_settings",
                ),
                chineseConversionService = PassthroughChineseConversionService,
            ),
        )
    }

    private fun samplePackage(): ValidatedDictionaryPackage {
        val entriesJsonl = """
            {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"su-tian","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典 工具書","wordSynonyms":["字典"],"senses":[{"partOfSpeech":"名詞","definition":"一本工具書。","definitionSynonyms":["字典"],"examples":[{"order":1,"hanji":"一本辭典","romanization":"tsi̍t pún sû-tián","mandarin":"一本辭典","audio":"sentence-1"}]}]}
            {"id":2,"type":"名詞","hanji":"字典","romanization":"jī-tián","category":"","audio":"","hokkienSearch":"字典 ji tian","mandarinSearch":"字典","senses":[{"partOfSpeech":"名詞","definition":"收錄字詞的書。","examples":[]}]}
        """.trimIndent()

        return ValidatedDictionaryPackage(
            manifest = DictionaryManifest(
                schemaVersion = 1,
                builtAt = "2026-05-07T00:00:00Z",
                sourceModifiedAt = "2026-05-07T00:00:00Z",
                entryCount = 2,
                senseCount = 2,
                exampleCount = 1,
                entriesFileName = "dictionary_entries.jsonl",
            ),
            entriesBytes = entriesJsonl.toByteArray(),
            firstEntry = DictionaryJsonlReader().readFirstEntry(entriesJsonl.toByteArray())!!,
        )
    }
}

private class StaticDictionaryPackageLoader(
    private val validatedPackage: ValidatedDictionaryPackage,
) : DictionaryPackageLoading {
    override fun validateBundledPackage(): ValidatedDictionaryPackage = validatedPackage
}

private class IdleDictionarySourceStore : DictionarySourceResourceManaging {
    private val snapshotFlow = MutableStateFlow(DownloadSnapshot())
    override val snapshot: StateFlow<DownloadSnapshot> = snapshotFlow.asStateFlow()

    override suspend fun refresh(): Result<Unit> = Result.success(Unit)

    override suspend fun restoreBundledSource(): Result<Unit> = Result.success(Unit)

    override suspend fun restoreBundledSourceIfNewer(): Result<Boolean> = Result.success(false)

    override suspend fun downloadSource(): Result<Unit> = Result.success(Unit)

    override suspend fun pauseDownload(): Result<Unit> = Result.success(Unit)

    override suspend fun resumeDownload(): Result<Unit> = Result.success(Unit)
}

private object PassthroughChineseConversionService : ChineseConversionService {
    override suspend fun normalizeSearchInput(
        text: String,
        locale: org.taigidict.app.core.localization.AppLocale,
    ): String = text

    override suspend fun translateForDisplay(
        text: String,
        locale: org.taigidict.app.core.localization.AppLocale,
    ): String = text
}
