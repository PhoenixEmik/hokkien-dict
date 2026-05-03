package org.taigidict.app.core.settings

import android.content.SharedPreferences
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

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
    val readingTextScale: Flow<Double>
    fun setThemePreference(preference: AppThemePreference)
    fun setReadingTextScale(value: Double)
}

class SharedPreferencesAppSettingsStore(
    private val prefs: SharedPreferences,
) : AppSettingsStoring {

    private val _themePreference = MutableStateFlow(loadTheme())
    override val themePreference: Flow<AppThemePreference> = _themePreference.asStateFlow()

    private val _readingTextScale = MutableStateFlow(loadReadingTextScale())
    override val readingTextScale: Flow<Double> = _readingTextScale.asStateFlow()

    override fun setThemePreference(preference: AppThemePreference) {
        prefs.edit().putString(KEY_THEME, preference.name).apply()
        _themePreference.value = preference
    }

    override fun setReadingTextScale(value: Double) {
        val snapped = AppSettingsConstants.snapReadingTextScale(value)
        prefs.edit().putFloat(KEY_READING_TEXT_SCALE, snapped.toFloat()).apply()
        _readingTextScale.value = snapped
    }

    private fun loadTheme(): AppThemePreference {
        val name = prefs.getString(KEY_THEME, AppThemePreference.System.name)
        return AppThemePreference.entries.firstOrNull { it.name == name } ?: AppThemePreference.System
    }

    private fun loadReadingTextScale(): Double {
        return prefs.getFloat(KEY_READING_TEXT_SCALE, AppSettingsConstants.DEFAULT_READING_TEXT_SCALE.toFloat()).toDouble()
    }

    companion object {
        private const val KEY_THEME = "theme_preference"
        private const val KEY_READING_TEXT_SCALE = "reading_text_scale"
    }
}
