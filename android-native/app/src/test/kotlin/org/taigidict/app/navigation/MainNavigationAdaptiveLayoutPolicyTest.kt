package org.taigidict.app.navigation

import androidx.compose.ui.unit.dp
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MainNavigationAdaptiveLayoutPolicyTest {
    @Test
    fun shouldUseNavigationRail_falseBelowBreakpoint() {
        assertFalse(MainNavigationAdaptiveLayoutPolicy.shouldUseNavigationRail(839.dp))
    }

    @Test
    fun shouldUseNavigationRail_trueAtAndAboveBreakpoint() {
        assertTrue(MainNavigationAdaptiveLayoutPolicy.shouldUseNavigationRail(840.dp))
        assertTrue(MainNavigationAdaptiveLayoutPolicy.shouldUseNavigationRail(1024.dp))
    }
}
