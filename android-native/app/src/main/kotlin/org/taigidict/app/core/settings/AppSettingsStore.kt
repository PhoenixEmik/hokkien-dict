package org.taigidict.app.core.settings

import android.content.SharedPreferences
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

interface AppSettingsStoring {
    val themePreference: Flow<AppThemePreference>
    fun setThemePreference(preference: AppThemePreference)
}

class SharedPreferencesAppSettingsStore(
    private val prefs: SharedPreferences,
) : AppSettingsStoring {

    private val _themePreference = MutableStateFlow(loadTheme())
    override val themePreference: Flow<AppThemePreference> = _themePreference.asStateFlow()

    override fun setThemePreference(preference: AppThemePreference) {
        prefs.edit().putString(KEY_THEME, preference.name).apply()
        _themePreference.value = preference
    }

    private fun loadTheme(): AppThemePreference {
        val name = prefs.getString(KEY_THEME, AppThemePreference.System.name)
        return AppThemePreference.entries.firstOrNull { it.name == name } ?: AppThemePreference.System
    }

    companion object {
        private const val KEY_THEME = "theme_preference"
    }
}
