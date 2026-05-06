package org.taigidict.app.core.settings

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.SharedPreferencesMigration
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStoreFile
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import java.io.IOException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

object AppSettingsConstants {
    const val MIN_READING_TEXT_SCALE = 0.9
    const val MAX_READING_TEXT_SCALE = 1.4
    const val DEFAULT_READING_TEXT_SCALE = 1.0
    const val READING_TEXT_SCALE_DIVISIONS = 5

    fun snapReadingTextScale(value: Double): Double {
        val step = (MAX_READING_TEXT_SCALE - MIN_READING_TEXT_SCALE) / READING_TEXT_SCALE_DIVISIONS
        val clamped = value.coerceIn(MIN_READING_TEXT_SCALE, MAX_READING_TEXT_SCALE)
        val normalized = (clamped - MIN_READING_TEXT_SCALE) / step
        val rounded = kotlin.math.round(normalized)
        val snapped = MIN_READING_TEXT_SCALE + rounded * step
        return ((snapped * 100).toLong()) / 100.0
    }
}

interface AppSettingsStoring {
    val themePreference: Flow<AppThemePreference>
    val languagePreference: Flow<AppLanguagePreference>
    val readingTextScale: Flow<Double>
    suspend fun setThemePreference(preference: AppThemePreference)
    suspend fun setLanguagePreference(preference: AppLanguagePreference)
    suspend fun setReadingTextScale(value: Double)
}

class DataStoreAppSettingsStore(
    context: Context,
    storeName: String = DEFAULT_STORE_NAME,
    sharedPreferencesName: String = storeName,
    scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO),
) : AppSettingsStoring {

    private val dataStore: DataStore<Preferences> = PreferenceDataStoreFactory.create(
        migrations = listOf(
            SharedPreferencesMigration(context, sharedPreferencesName),
        ),
        scope = scope,
        produceFile = {
            context.applicationContext.preferencesDataStoreFile(storeName)
        },
    )

    override val themePreference: Flow<AppThemePreference> = dataStore.data
        .recoverPreferences()
        .map { preferences ->
            preferences[KEY_THEME]
                ?.let { name -> AppThemePreference.entries.firstOrNull { it.name == name } }
                ?: AppThemePreference.System
        }

    override val languagePreference: Flow<AppLanguagePreference> = dataStore.data
        .recoverPreferences()
        .map { preferences ->
            preferences[KEY_LANGUAGE]
                ?.let { name -> AppLanguagePreference.entries.firstOrNull { it.name == name } }
                ?: AppLanguagePreference.System
        }

    override val readingTextScale: Flow<Double> = dataStore.data
        .recoverPreferences()
        .map { preferences ->
            AppSettingsConstants.snapReadingTextScale(
                preferences[KEY_READING_TEXT_SCALE]?.toDouble()
                    ?: AppSettingsConstants.DEFAULT_READING_TEXT_SCALE,
            )
        }

    override suspend fun setThemePreference(preference: AppThemePreference) {
        dataStore.edit { preferences ->
            preferences[KEY_THEME] = preference.name
        }
    }

    override suspend fun setLanguagePreference(preference: AppLanguagePreference) {
        dataStore.edit { preferences ->
            preferences[KEY_LANGUAGE] = preference.name
        }
    }

    override suspend fun setReadingTextScale(value: Double) {
        val snapped = AppSettingsConstants.snapReadingTextScale(value)
        dataStore.edit { preferences ->
            preferences[KEY_READING_TEXT_SCALE] = snapped.toFloat()
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
        const val DEFAULT_STORE_NAME = "app_settings"
        val KEY_THEME = stringPreferencesKey("theme_preference")
        val KEY_LANGUAGE = stringPreferencesKey("language_preference")
        val KEY_READING_TEXT_SCALE = floatPreferencesKey("reading_text_scale")
    }
}
