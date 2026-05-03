package org.taigidict.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.app.rememberMainAppState
import org.taigidict.app.core.settings.AppThemePreference
import org.taigidict.app.feature.initialization.InitializationScreen
import org.taigidict.app.feature.initialization.InitializationViewModel
import org.taigidict.app.navigation.MainNavGraph
import org.taigidict.app.ui.theme.TaigiDictTheme

class MainActivity : ComponentActivity() {
    private val initializationViewModel: InitializationViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val appContainer = (application as TaigiDictApplication).appContainer

        setContent {
            val uiState = initializationViewModel.uiState.collectAsStateWithLifecycle().value
            val themePreference = appContainer.appSettingsStore.themePreference
                .collectAsState(initial = AppThemePreference.System).value
            val systemDark = isSystemInDarkTheme()
            val darkTheme = when (themePreference) {
                AppThemePreference.Light -> false
                AppThemePreference.Dark -> true
                AppThemePreference.System -> systemDark
            }

            TaigiDictTheme(darkTheme = darkTheme) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                ) {
                    if (uiState.isReady) {
                        MainNavGraph(appState = rememberMainAppState(appContainer))
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
}
