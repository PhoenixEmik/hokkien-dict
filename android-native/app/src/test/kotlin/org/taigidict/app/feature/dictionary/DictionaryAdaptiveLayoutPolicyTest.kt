package org.taigidict.app.feature.dictionary

import androidx.compose.ui.unit.dp
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DictionaryAdaptiveLayoutPolicyTest {
    @Test
    fun shouldUseTwoPane_falseBelowBreakpoint() {
        assertFalse(DictionaryAdaptiveLayoutPolicy.shouldUseTwoPane(899.dp))
    }

    @Test
    fun shouldUseTwoPane_trueAtAndAboveBreakpoint() {
        assertTrue(DictionaryAdaptiveLayoutPolicy.shouldUseTwoPane(900.dp))
        assertTrue(DictionaryAdaptiveLayoutPolicy.shouldUseTwoPane(1080.dp))
    }
}