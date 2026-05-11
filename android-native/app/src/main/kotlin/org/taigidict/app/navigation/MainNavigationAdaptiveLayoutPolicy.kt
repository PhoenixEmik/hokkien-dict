package org.taigidict.app.navigation

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

internal object MainNavigationAdaptiveLayoutPolicy {
    val NavigationRailBreakpoint: Dp = 840.dp

    fun shouldUseNavigationRail(maxWidth: Dp): Boolean = maxWidth >= NavigationRailBreakpoint
}
