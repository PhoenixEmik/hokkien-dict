package org.taigidict.app.feature.dictionary

import org.taigidict.app.feature.common.DictionaryTextLink

internal object DictionaryLinkedWordMatcher {
    fun findLinks(
        text: String,
        openableLinkedWords: Set<String>,
    ): List<DictionaryTextLink> {
        if (text.isBlank() || openableLinkedWords.isEmpty()) {
            return emptyList()
        }

        val candidates = openableLinkedWords
            .map(String::trim)
            .filter(String::isNotBlank)
            .distinct()
            .sortedWith(compareByDescending<String> { it.length }.thenBy { it })

        if (candidates.isEmpty()) {
            return emptyList()
        }

        val results = mutableListOf<DictionaryTextLink>()
        var index = 0
        while (index < text.length) {
            val match = candidates.firstOrNull { candidate ->
                text.regionMatches(index, candidate, 0, candidate.length) &&
                    hasValidBoundaries(text, index, candidate)
            }

            if (match == null) {
                index += 1
                continue
            }

            results += DictionaryTextLink(
                start = index,
                end = index + match.length,
                value = match,
            )
            index += match.length
        }

        return results
    }

    private fun hasValidBoundaries(
        text: String,
        start: Int,
        candidate: String,
    ): Boolean {
        if (!candidate.any(::isAsciiWordLike)) {
            return true
        }

        val before = text.getOrNull(start - 1)
        val after = text.getOrNull(start + candidate.length)
        return !isAsciiWordLike(before) && !isAsciiWordLike(after)
    }

    private fun isAsciiWordLike(char: Char?): Boolean {
        if (char == null) {
            return false
        }

        return char.isAsciiLetterOrDigit() || char == '-' || char == '\''
    }

    private fun Char.isAsciiLetterOrDigit(): Boolean {
        return this in 'a'..'z' || this in 'A'..'Z' || this in '0'..'9'
    }
}
