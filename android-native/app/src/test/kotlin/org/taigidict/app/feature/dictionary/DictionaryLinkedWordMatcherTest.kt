package org.taigidict.app.feature.dictionary

import org.junit.Assert.assertEquals
import org.junit.Test

class DictionaryLinkedWordMatcherTest {
    @Test
    fun findLinks_matchesChineseWordsInsideDefinition() {
        val links = DictionaryLinkedWordMatcher.findLinks(
            text = "像字典這款工具書。",
            openableLinkedWords = setOf("字典"),
        )

        assertEquals(listOf("字典"), links.map { it.value })
        assertEquals(1, links.single().start)
        assertEquals(3, links.single().end)
    }

    @Test
    fun findLinks_prefersLongerCandidateWhenRangesOverlap() {
        val links = DictionaryLinkedWordMatcher.findLinks(
            text = "請看台灣話字典。",
            openableLinkedWords = setOf("台灣", "台灣話"),
        )

        assertEquals(listOf("台灣話"), links.map { it.value })
    }

    @Test
    fun findLinks_requiresWordBoundariesForRomanization() {
        val links = DictionaryLinkedWordMatcher.findLinks(
            text = "sui2 kah suí-tsián",
            openableLinkedWords = setOf("sui", "suí-tsián"),
        )

        assertEquals(listOf("suí-tsián"), links.map { it.value })
    }

    @Test
    fun findLinks_matchesRomanizationWithBoundaries() {
        val links = DictionaryLinkedWordMatcher.findLinks(
            text = "可參考 su-tian 這个講法。",
            openableLinkedWords = setOf("su-tian"),
        )

        assertEquals(listOf("su-tian"), links.map { it.value })
    }
}
