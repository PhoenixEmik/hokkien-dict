package org.taigidict.app.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import org.taigidict.app.app.MainAppState
import org.taigidict.app.feature.bookmarks.BookmarksScreen
import org.taigidict.app.feature.dictionary.DictionaryScreen
import org.taigidict.app.feature.settings.SettingsScreen

@Composable
fun MainNavGraph(appState: MainAppState) {
    val currentDestination = appState.currentDestination

    Scaffold(
        bottomBar = {
            NavigationBar {
                MainDestination.entries.forEach { destination ->
                    NavigationBarItem(
                        selected = destination == currentDestination,
                        onClick = { appState.navigate(destination) },
                        icon = {
                            Icon(
                                imageVector = destination.icon,
                                contentDescription = null,
                            )
                        },
                        label = {
                            Text(text = stringResource(destination.labelRes))
                        },
                    )
                }
            }
        },
    ) { _ ->
        when (currentDestination) {
            MainDestination.Dictionary -> DictionaryScreen(
                manifestAssetPath = appState.appContainer.bundledDictionaryManifestAssetPath,
                entriesAssetPath = appState.appContainer.bundledDictionaryEntriesAssetPath,
                dataVersion = appState.dictionaryDataVersion,
            )

            MainDestination.Bookmarks -> BookmarksScreen(
                dataVersion = appState.dictionaryDataVersion,
            )

            MainDestination.Settings -> SettingsScreen(
                assetDirectory = appState.appContainer.bundledDictionaryAssetDirectory,
                onDictionaryDataChanged = appState::invalidateDictionaryData,
            )
        }
    }
}
