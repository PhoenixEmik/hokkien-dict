package org.taigidict.app.app

import android.content.Context
import org.taigidict.app.core.constants.AppConstants
import org.taigidict.app.core.settings.AppSettingsStoring
import org.taigidict.app.core.settings.SharedPreferencesAppSettingsStore
import org.taigidict.app.data.audio.DictionaryAudioPlayer
import org.taigidict.app.data.audio.OfflineAudioArchiveManager
import org.taigidict.app.data.audio.OfflineDictionaryAudioPlayer
import org.taigidict.app.data.bookmarks.BookmarkStore
import org.taigidict.app.data.importer.DictionaryImportService
import org.taigidict.app.data.importer.DictionaryJsonlReader
import org.taigidict.app.data.importer.DictionaryPackageLoader
import org.taigidict.app.data.repository.SQLiteDictionaryRepository

class AppContainer(context: Context) {
    val appContext: Context = context.applicationContext
    val bundledDictionaryAssetDirectory: String = AppConstants.BUNDLED_DICTIONARY_ASSET_DIRECTORY
    val bundledDictionaryManifestAssetPath: String = AppConstants.BUNDLED_DICTIONARY_MANIFEST_ASSET_PATH
    val bundledDictionaryEntriesAssetPath: String = AppConstants.BUNDLED_DICTIONARY_ENTRIES_ASSET_PATH
    val dictionaryDatabaseFile = appContext.getDatabasePath(AppConstants.DICTIONARY_DATABASE_FILE_NAME)
    val dictionaryPackageLoader: DictionaryPackageLoader by lazy {
        DictionaryPackageLoader(
            assetManager = appContext.assets,
            manifestAssetPath = bundledDictionaryManifestAssetPath,
            entriesAssetDirectory = bundledDictionaryAssetDirectory,
            jsonlReader = DictionaryJsonlReader(),
        )
    }
    val dictionaryImportService: DictionaryImportService by lazy {
        DictionaryImportService(
            databaseFile = dictionaryDatabaseFile,
            packageLoader = dictionaryPackageLoader,
            jsonlReader = DictionaryJsonlReader(),
        )
    }
    val dictionaryRepository: SQLiteDictionaryRepository by lazy {
        SQLiteDictionaryRepository(databaseFile = dictionaryDatabaseFile)
    }
    val bookmarkStore: BookmarkStore by lazy {
        BookmarkStore(context = appContext)
    }
    internal val offlineAudioArchiveManager: OfflineAudioArchiveManager by lazy {
        OfflineAudioArchiveManager(filesDirectory = appContext.filesDir)
    }
    val dictionaryAudioPlayer: DictionaryAudioPlayer by lazy {
        OfflineDictionaryAudioPlayer(filesDirectory = appContext.filesDir)
    }
    val appSettingsStore: AppSettingsStoring by lazy {
        SharedPreferencesAppSettingsStore(
            prefs = appContext.getSharedPreferences("app_settings", Context.MODE_PRIVATE)
        )
    }
}
