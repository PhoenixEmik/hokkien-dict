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
    private const val MIN_READING_TEXT_SCALE_TENTHS = 9
    private const val MAX_READING_TEXT_SCALE_TENTHS = 14

    const val MIN_READING_TEXT_SCALE = MIN_READING_TEXT_SCALE_TENTHS / 10.0
    const val MAX_READING_TEXT_SCALE = MAX_READING_TEXT_SCALE_TENTHS / 10.0
    const val DEFAULT_READING_TEXT_SCALE = 1.0
    const val READING_TEXT_SCALE_STEP = 0.1
    const val READING_TEXT_SCALE_STEPS = MAX_READING_TEXT_SCALE_TENTHS - MIN_READING_TEXT_SCALE_TENTHS - 1

    fun snapReadingTextScale(value: Double): Double {
        val snappedTenths = kotlin.math.round(value * 10.0)
            .toInt()
            .coerceIn(MIN_READING_TEXT_SCALE_TENTHS, MAX_READING_TEXT_SCALE_TENTHS)
        return snappedTenths / 10.0
    }
}

interface AppSettingsStoring {
    val initialThemePreference: AppThemePreference
    val initialLanguagePreference: AppLanguagePreference
    val initialReadingTextScale: Double
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

    private val sharedPreferences = context.applicationContext.getSharedPreferences(
        sharedPreferencesName,
        Context.MODE_PRIVATE,
    )

    override val initialThemePreference: AppThemePreference = sharedPreferences
        .getString(KEY_THEME_NAME, null)
        ?.let { name -> AppThemePreference.entries.firstOrNull { it.name == name } }
        ?: AppThemePreference.System

    override val initialLanguagePreference: AppLanguagePreference = sharedPreferences
        .getString(KEY_LANGUAGE_NAME, null)
        ?.let { name -> AppLanguagePreference.entries.firstOrNull { it.name == name } }
        ?: AppLanguagePreference.System

    override val initialReadingTextScale: Double = AppSettingsConstants.snapReadingTextScale(
        sharedPreferences.getFloat(KEY_READING_TEXT_SCALE_NAME, AppSettingsConstants.DEFAULT_READING_TEXT_SCALE.toFloat()).toDouble(),
    )

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
        const val KEY_THEME_NAME = "theme_preference"
        const val KEY_LANGUAGE_NAME = "language_preference"
        const val KEY_READING_TEXT_SCALE_NAME = "reading_text_scale"

        val KEY_THEME = stringPreferencesKey(KEY_THEME_NAME)
        val KEY_LANGUAGE = stringPreferencesKey(KEY_LANGUAGE_NAME)
        val KEY_READING_TEXT_SCALE = floatPreferencesKey(KEY_READING_TEXT_SCALE_NAME)
    }
}
