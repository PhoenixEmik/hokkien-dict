package org.taigidict.app.feature.bookmarks

import androidx.compose.ui.unit.dp
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BookmarksAdaptiveLayoutPolicyTest {
    @Test
    fun shouldUseGrid_falseBelowBreakpoint() {
        assertFalse(BookmarksAdaptiveLayoutPolicy.shouldUseGrid(699.dp))
    }

    @Test
    fun shouldUseGrid_trueAtAndAboveBreakpoint() {
        assertTrue(BookmarksAdaptiveLayoutPolicy.shouldUseGrid(700.dp))
        assertTrue(BookmarksAdaptiveLayoutPolicy.shouldUseGrid(840.dp))
    }
}