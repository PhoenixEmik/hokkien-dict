package org.taigidict.app.feature.common

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DictionaryFallbackTextRangesTest {
    @Test
    fun fallbackRanges_plainAscii_returnsEmpty() {
        val ranges = DictionaryFallbackTextRanges.fallbackRanges("tailo")

        assertTrue(ranges.isEmpty())
    }

    @Test
    fun fallbackRanges_combiningDot_marksBaseAndMark() {
        val text = "o\u0358"

        val ranges = DictionaryFallbackTextRanges.fallbackRanges(text)

        assertEquals(listOf(0..1), ranges)
    }

    @Test
    fun fallbackRanges_superscriptN_isMarked() {
        val text = "ho\u207F"

        val ranges = DictionaryFallbackTextRanges.fallbackRanges(text)

        assertEquals(listOf(2..2), ranges)
    }

    @Test
    fun fallbackRanges_cjkExtensionB_isMarked() {
        val text = "\uD840\uDC00" // U+20000

        val ranges = DictionaryFallbackTextRanges.fallbackRanges(text)

        assertEquals(listOf(0..1), ranges)
    }
}
