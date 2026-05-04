package org.taigidict.app.data.conversion

import android.content.SharedPreferences

internal interface OpenCcMigrationTracker {
    fun shouldClearDictDataFolder(versionCode: Int): Boolean

    fun markDictDataFolderCleared(versionCode: Int)
}

internal class SharedPreferencesOpenCcMigrationTracker(
    private val prefs: SharedPreferences,
) : OpenCcMigrationTracker {

    override fun shouldClearDictDataFolder(versionCode: Int): Boolean {
        val lastClearedVersion = prefs.getInt(KEY_LAST_CLEARED_VERSION_CODE, 0)
        return lastClearedVersion < versionCode
    }

    override fun markDictDataFolderCleared(versionCode: Int) {
        prefs.edit().putInt(KEY_LAST_CLEARED_VERSION_CODE, versionCode).apply()
    }

    private companion object {
        private const val KEY_LAST_CLEARED_VERSION_CODE = "last_cleared_version_code"
    }
}