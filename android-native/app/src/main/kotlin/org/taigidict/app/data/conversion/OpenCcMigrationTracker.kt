package org.taigidict.app.data.conversion

import android.content.Context
import androidx.datastore.preferences.SharedPreferencesMigration
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStoreFile
import java.io.IOException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

internal interface OpenCcMigrationTracker {
    fun shouldClearDictDataFolder(versionCode: Int): Boolean

    fun markDictDataFolderCleared(versionCode: Int)
}

internal class DataStoreOpenCcMigrationTracker(
    context: Context,
    storeName: String = DEFAULT_STORE_NAME,
    sharedPreferencesName: String = storeName,
    scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO),
) : OpenCcMigrationTracker {

    private val dataStore = PreferenceDataStoreFactory.create(
        migrations = listOf(SharedPreferencesMigration(context, sharedPreferencesName)),
        scope = scope,
        produceFile = {
            context.applicationContext.preferencesDataStoreFile(storeName)
        },
    )

    override fun shouldClearDictDataFolder(versionCode: Int): Boolean = runBlocking {
        val lastClearedVersion = dataStore.data
            .recoverPreferences()
            .first()[KEY_LAST_CLEARED_VERSION_CODE] ?: 0
        lastClearedVersion < versionCode
    }

    override fun markDictDataFolderCleared(versionCode: Int) {
        runBlocking {
            dataStore.edit { preferences ->
                preferences[KEY_LAST_CLEARED_VERSION_CODE] = versionCode
            }
        }
    }

    private fun Flow<Preferences>.recoverPreferences(): Flow<Preferences> {
        return catch { error ->
            if (error is IOException) {
                emit(emptyPreferences())
            } else {
                throw error
            }
        }
    }

    private companion object {
        const val DEFAULT_STORE_NAME = "opencc_migrations"
        val KEY_LAST_CLEARED_VERSION_CODE = intPreferencesKey("last_cleared_version_code")
    }
}
