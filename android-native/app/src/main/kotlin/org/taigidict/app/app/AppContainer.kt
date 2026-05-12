package org.taigidict.app.app

import android.content.Context
import java.io.File
import org.taigidict.app.BuildConfig
import org.taigidict.app.core.constants.AppConstants
import org.taigidict.app.core.settings.AppSettingsStoring
import org.taigidict.app.core.settings.DataStoreAppSettingsStore
import org.taigidict.app.data.audio.DictionaryAudioPlayer
import org.taigidict.app.data.audio.OfflineAudioArchiveManager
import org.taigidict.app.data.audio.OfflineDictionaryAudioPlayer
import org.taigidict.app.data.bookmarks.BookmarkStore
import org.taigidict.app.data.conversion.AndroidOpenCcChineseConversionService
import org.taigidict.app.data.conversion.ChineseConversionService
import org.taigidict.app.data.importer.BundledDictionaryImporting
import org.taigidict.app.data.importer.DictionaryImportService
import org.taigidict.app.data.importer.DictionaryJsonlReader
import org.taigidict.app.data.importer.LocalDictionaryPackageLoader
import org.taigidict.app.data.importer.DictionaryPackageLoader
import org.taigidict.app.data.repository.DictionaryRepositoryBackend
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.data.repository.DictionaryRepositoryFactory
import org.taigidict.app.data.search.SearchHistoryStore
import org.taigidict.app.data.search.SearchHistoryStoring
import org.taigidict.app.data.source.DictionarySourceResourceManaging
import org.taigidict.app.data.source.DictionarySourceResourceStore

data class AppContainerOverrides(
    val dictionaryDatabaseFile: File? = null,
    val dictionaryRepositoryBackend: DictionaryRepositoryBackend? = null,
    val dictionaryImportService: BundledDictionaryImporting? = null,
    val localDictionaryImportService: BundledDictionaryImporting? = null,
    val dictionarySourceResourceStore: DictionarySourceResourceManaging? = null,
    val bookmarkStore: BookmarkStore? = null,
    val searchHistoryStore: SearchHistoryStoring? = null,
    val appSettingsStore: AppSettingsStoring? = null,
    val chineseConversionService: ChineseConversionService? = null,
)

class AppContainer(
    context: Context,
    private val overrides: AppContainerOverrides = AppContainerOverrides(),
) {
    val appContext: Context = context.applicationContext
    val bundledDictionaryAssetDirectory: String = AppConstants.BUNDLED_DICTIONARY_ASSET_DIRECTORY
    val bundledDictionaryManifestAssetPath: String = AppConstants.BUNDLED_DICTIONARY_MANIFEST_ASSET_PATH
    val bundledDictionaryEntriesAssetPath: String = AppConstants.BUNDLED_DICTIONARY_ENTRIES_ASSET_PATH
    val dictionaryDatabaseFile = overrides.dictionaryDatabaseFile
        ?: appContext.getDatabasePath(AppConstants.DICTIONARY_DATABASE_FILE_NAME)
    val localDictionarySourceDirectory = File(appContext.filesDir, "dictionary_source")
    val dictionaryPackageLoader: DictionaryPackageLoader by lazy {
        DictionaryPackageLoader(
            assetManager = appContext.assets,
            manifestAssetPath = bundledDictionaryManifestAssetPath,
            entriesAssetDirectory = bundledDictionaryAssetDirectory,
            jsonlReader = DictionaryJsonlReader(),
        )
    }
    val dictionaryImportService: BundledDictionaryImporting by lazy {
        overrides.dictionaryImportService ?: DictionaryImportService(
            databaseFile = dictionaryDatabaseFile,
            packageLoader = dictionaryPackageLoader,
            jsonlReader = DictionaryJsonlReader(),
        )
    }
    val localDictionaryImportService: BundledDictionaryImporting by lazy {
        overrides.localDictionaryImportService ?: DictionaryImportService(
            databaseFile = dictionaryDatabaseFile,
            packageLoader = LocalDictionaryPackageLoader(
                sourceDirectory = localDictionarySourceDirectory,
                jsonlReader = DictionaryJsonlReader(),
            ),
            jsonlReader = DictionaryJsonlReader(),
        )
    }
    internal val dictionaryRepositoryBackend: DictionaryRepositoryBackend =
        overrides.dictionaryRepositoryBackend
            ?: DictionaryRepositoryBackend.parse(BuildConfig.DICTIONARY_REPOSITORY_BACKEND)
    val dictionaryRepository: DictionaryRepositoryDataSource by lazy {
        DictionaryRepositoryFactory.create(
            context = appContext,
            databaseFile = dictionaryDatabaseFile,
            backend = dictionaryRepositoryBackend,
        )
    }
    val bookmarkStore: BookmarkStore by lazy {
        overrides.bookmarkStore ?: BookmarkStore(context = appContext)
    }
    val searchHistoryStore: SearchHistoryStoring by lazy {
        overrides.searchHistoryStore ?: SearchHistoryStore(context = appContext)
    }
    internal val offlineAudioArchiveManager: OfflineAudioArchiveManager by lazy {
        OfflineAudioArchiveManager(filesDirectory = appContext.filesDir)
    }
    init {
        // Preload local audio archive state so Settings does not briefly show
        // installed archives as downloadable on first open.
        offlineAudioArchiveManager.refreshAll()
    }
    val dictionaryAudioPlayer: DictionaryAudioPlayer by lazy {
        OfflineDictionaryAudioPlayer(filesDirectory = appContext.filesDir)
    }
    val chineseConversionService: ChineseConversionService by lazy {
        overrides.chineseConversionService ?: AndroidOpenCcChineseConversionService(appContext = appContext)
    }
    val appSettingsStore: AppSettingsStoring by lazy {
        overrides.appSettingsStore ?: DataStoreAppSettingsStore(context = appContext)
    }
    val dictionarySourceResourceStore: DictionarySourceResourceManaging by lazy {
        overrides.dictionarySourceResourceStore ?: DictionarySourceResourceStore(
            assetManager = appContext.assets,
            bundledManifestAssetPath = bundledDictionaryManifestAssetPath,
            bundledEntriesAssetPath = bundledDictionaryEntriesAssetPath,
            localSourceDirectory = localDictionarySourceDirectory,
        )
    }
}
