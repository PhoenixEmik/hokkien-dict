package org.taigidict.app.navigation

import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
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

    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val usesNavigationRail = MainNavigationAdaptiveLayoutPolicy.shouldUseNavigationRail(maxWidth)

        if (usesNavigationRail) {
            Row(modifier = Modifier.fillMaxSize()) {
                NavigationRail(
                    modifier = Modifier.fillMaxHeight(),
                ) {
                    MainDestination.entries.forEach { destination ->
                        NavigationRailItem(
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

                Box(
                    modifier = Modifier.weight(1f),
                ) {
                    MainNavContent(
                        appState = appState,
                        modifier = Modifier.fillMaxSize(),
                    )
                }
            }
        } else {
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
            ) { innerPadding ->
                MainNavContent(
                    appState = appState,
                    modifier = Modifier.padding(bottom = innerPadding.calculateBottomPadding()),
                )
            }
        }
    }
}

@Composable
private fun MainNavContent(
    appState: MainAppState,
    modifier: Modifier = Modifier,
) {
    when (appState.currentDestination) {
        MainDestination.Dictionary -> DictionaryScreen(
            manifestAssetPath = appState.appContainer.bundledDictionaryManifestAssetPath,
            entriesAssetPath = appState.appContainer.bundledDictionaryEntriesAssetPath,
            dataVersion = appState.dictionaryDataVersion,
            modifier = modifier,
        )

        MainDestination.Bookmarks -> BookmarksScreen(
            dataVersion = appState.dictionaryDataVersion,
            modifier = modifier,
        )

        MainDestination.Settings -> SettingsScreen(
            assetDirectory = appState.appContainer.bundledDictionaryAssetDirectory,
            onDictionaryDataChanged = appState::invalidateDictionaryData,
            modifier = modifier,
        )
    }
}
