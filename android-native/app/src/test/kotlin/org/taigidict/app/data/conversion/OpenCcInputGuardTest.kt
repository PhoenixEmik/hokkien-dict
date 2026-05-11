package org.taigidict.app.data.conversion

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OpenCcInputGuardTest {
    @Test
    fun shouldBypass_returnsTrueForRomanizationOnly() {
        assertTrue(OpenCcInputGuard.shouldBypass("su-tian"))
    }

    @Test
    fun shouldBypass_returnsFalseForHanCharacters() {
        assertFalse(OpenCcInputGuard.shouldBypass("词典"))
    }

    @Test
    fun shouldBypass_returnsTrueForInvalidSurrogate() {
        val invalid = "词\uD800典"
        assertTrue(OpenCcInputGuard.shouldBypass(invalid))
    }
}