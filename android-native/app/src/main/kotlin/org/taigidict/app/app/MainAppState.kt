package org.taigidict.app.app

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import org.taigidict.app.navigation.MainDestination

@Stable
class MainAppState(
    val appContainer: AppContainer,
    initialDestination: MainDestination,
) {
    var currentDestination by mutableStateOf(initialDestination)
        private set

    fun navigate(destination: MainDestination) {
        currentDestination = destination
    }
}

@Composable
fun rememberMainAppState(appContainer: AppContainer): MainAppState {
    return remember(appContainer) {
        MainAppState(
            appContainer = appContainer,
            initialDestination = MainDestination.Dictionary,
        )
    }
}
