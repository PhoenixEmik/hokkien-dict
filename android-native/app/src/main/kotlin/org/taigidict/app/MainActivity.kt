package org.taigidict.app

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.core.os.LocaleListCompat
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.app.rememberMainAppState
import org.taigidict.app.core.settings.AppLanguagePreference
import org.taigidict.app.core.settings.AppSettingsConstants
import org.taigidict.app.core.settings.AppThemePreference
import org.taigidict.app.feature.common.appPageContainerColor
import org.taigidict.app.feature.initialization.InitializationScreen
import org.taigidict.app.feature.initialization.InitializationViewModel
import org.taigidict.app.navigation.MainDestination
import org.taigidict.app.navigation.MainNavGraph
import org.taigidict.app.ui.theme.TaigiDictTheme

class MainActivity : AppCompatActivity() {
    private val initializationViewModel: InitializationViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        val appContainer = (application as TaigiDictApplication).appContainer
        applyAppLanguagePreference(appContainer.appSettingsStore.initialLanguagePreference)

        super.onCreate(savedInstanceState)

        setContent {
            val uiState = initializationViewModel.uiState.collectAsStateWithLifecycle().value
            var savedDestinationName by rememberSaveable {
                mutableStateOf(MainDestination.Dictionary.name)
            }
            val restoredDestination = MainDestination.entries.firstOrNull {
                it.name == savedDestinationName
            } ?: MainDestination.Dictionary
            val appState = rememberMainAppState(
                appContainer = appContainer,
                initialDestination = restoredDestination,
            )
            val themePreference = appContainer.appSettingsStore.themePreference
                .collectAsState(initial = appContainer.appSettingsStore.initialThemePreference).value
            val languagePreference = appContainer.appSettingsStore.languagePreference
                .collectAsState(initial = appContainer.appSettingsStore.initialLanguagePreference).value
            val readingTextScale = appContainer.appSettingsStore.readingTextScale
                .collectAsState(initial = appContainer.appSettingsStore.initialReadingTextScale).value

            LaunchedEffect(appState.currentDestination) {
                if (savedDestinationName != appState.currentDestination.name) {
                    savedDestinationName = appState.currentDestination.name
                }
            }

            LaunchedEffect(languagePreference) {
                val targetLocales = when (languagePreference) {
                    AppLanguagePreference.System -> LocaleListCompat.getEmptyLocaleList()
                    AppLanguagePreference.TraditionalChinese -> LocaleListCompat.forLanguageTags("zh-TW")
                    AppLanguagePreference.SimplifiedChinese -> LocaleListCompat.forLanguageTags("zh-CN")
                    AppLanguagePreference.English -> LocaleListCompat.forLanguageTags("en")
                }
                val currentLocales = AppCompatDelegate.getApplicationLocales()
                if (currentLocales != targetLocales) {
                    AppCompatDelegate.setApplicationLocales(targetLocales)
                }
            }

            LaunchedEffect(uiState.databaseGeneration) {
                appState.applyDatabaseGeneration(uiState.databaseGeneration)
            }

            val systemDark = isSystemInDarkTheme()
            val darkTheme = when (themePreference) {
                AppThemePreference.Light -> false
                AppThemePreference.Dark -> true
                AppThemePreference.System -> systemDark
            }

            TaigiDictTheme(
                darkTheme = darkTheme,
                readingTextScale = readingTextScale.toFloat(),
            ) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = appPageContainerColor(),
                ) {
                    if (uiState.isReady) {
                        MainNavGraph(appState = appState)
                    } else {
                        InitializationScreen(
                            uiState = uiState,
                            onRetry = initializationViewModel::retry,
                        )
                    }
                }
            }
        }
    }

    private fun applyAppLanguagePreference(preference: AppLanguagePreference) {
        val targetLocales = when (preference) {
            AppLanguagePreference.System -> LocaleListCompat.getEmptyLocaleList()
            AppLanguagePreference.TraditionalChinese -> LocaleListCompat.forLanguageTags("zh-TW")
            AppLanguagePreference.SimplifiedChinese -> LocaleListCompat.forLanguageTags("zh-CN")
            AppLanguagePreference.English -> LocaleListCompat.forLanguageTags("en")
        }
        val currentLocales = AppCompatDelegate.getApplicationLocales()
        if (currentLocales != targetLocales) {
            AppCompatDelegate.setApplicationLocales(targetLocales)
        }
    }
}
