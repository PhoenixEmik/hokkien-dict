package org.taigidict.app.feature.bookmarks

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

internal object BookmarksAdaptiveLayoutPolicy {
    val GridBreakpoint: Dp = 700.dp

    fun shouldUseGrid(maxWidth: Dp): Boolean = maxWidth >= GridBreakpoint
}