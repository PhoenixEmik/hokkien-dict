package org.taigidict.app.feature.dictionary

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

internal object DictionaryAdaptiveLayoutPolicy {
    val TwoPaneMinWidth: Dp = 900.dp

    fun shouldUseTwoPane(maxWidth: Dp): Boolean = maxWidth >= TwoPaneMinWidth
}