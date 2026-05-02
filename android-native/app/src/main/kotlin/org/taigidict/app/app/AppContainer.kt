package org.taigidict.app.app

import android.content.Context
import org.taigidict.app.core.constants.AppConstants

class AppContainer(context: Context) {
    val appContext: Context = context.applicationContext
    val bundledDictionaryAssetDirectory: String = AppConstants.BUNDLED_DICTIONARY_ASSET_DIRECTORY
    val bundledDictionaryManifestAssetPath: String = AppConstants.BUNDLED_DICTIONARY_MANIFEST_ASSET_PATH
    val bundledDictionaryEntriesAssetPath: String = AppConstants.BUNDLED_DICTIONARY_ENTRIES_ASSET_PATH
}
