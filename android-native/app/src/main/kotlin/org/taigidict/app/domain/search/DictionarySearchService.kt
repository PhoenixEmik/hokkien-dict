package org.taigidict.app.domain.search

import org.taigidict.app.core.util.TextNormalization
import org.taigidict.app.domain.model.DictionaryEntry

data class DictionarySearchRow(
    val entryId: Long,
    val headwords: List<String>,
    val definitions: List<String>,
    val examples: List<String> = emptyList(),
    val fallbackDefinitions: List<String> = emptyList(),
)

object DictionarySearchService {
    const val DEFAULT_LIMIT = 60

    fun buildSearchIndex(entries: List<DictionaryEntry>): List<DictionarySearchRow> {
        return entries.map { entry ->
            DictionarySearchRow(
                entryId = entry.id,
                headwords = headwordFields(entry),
                definitions = definitionFields(entry),
                examples = exampleFields(entry),
                fallbackDefinitions = fallbackDefinitionFields(entry),
            )
        }
    }

    fun searchEntryIds(
        index: List<DictionarySearchRow>,
        rawQuery: String,
        limit: Int = DEFAULT_LIMIT,
    ): List<Long> {
        val query = TextNormalization.normalizeQuery(rawQuery)
        if (query.isEmpty()) {
            return emptyList()
        }

        return index
            .mapNotNull { match(it, query) }
            .sorted()
            .take(limit)
            .map { it.entryId }
    }

    private fun match(row: DictionarySearchRow, query: String): ScoredSearchHit? {
        val headwordMatch = bestMatch(row.headwords, query)
        if (headwordMatch != null) {
            val score = if (headwordMatch.matchedLength == query.length) 0 else 1
            return ScoredSearchHit(
                entryId = row.entryId,
                score = score,
                matchQuality = headwordMatch.quality,
                matchedLength = headwordMatch.matchedLength,
            )
        }

        val definitionMatch = bestMatch(row.definitions, query)
        if (definitionMatch != null) {
            return ScoredSearchHit(
                entryId = row.entryId,
                score = 2,
                matchQuality = definitionMatch.quality,
                matchedLength = definitionMatch.matchedLength,
            )
        }

        val exampleMatch = bestMatch(row.examples, query)
        if (exampleMatch != null) {
            return ScoredSearchHit(
                entryId = row.entryId,
                score = 3,
                matchQuality = exampleMatch.quality,
                matchedLength = exampleMatch.matchedLength,
            )
        }

        val fallbackDefinitionMatch = bestMatch(row.fallbackDefinitions, query) ?: return null
        return ScoredSearchHit(
            entryId = row.entryId,
            score = 4,
            matchQuality = fallbackDefinitionMatch.quality,
            matchedLength = fallbackDefinitionMatch.matchedLength,
        )
    }

    private fun headwordFields(entry: DictionaryEntry): List<String> {
        return uniqueNonEmpty(
            listOf(
                TextNormalization.normalizeQuery(entry.hanji),
                TextNormalization.normalizeQuery(entry.romanization),
            ),
        )
    }

    private fun definitionFields(entry: DictionaryEntry): List<String> {
        return uniqueNonEmpty(
            entry.senses.flatMap { sense ->
                listOf(sense.definition) +
                    sense.definitionSynonyms +
                    sense.definitionAntonyms
            }.map(TextNormalization::normalizeQuery),
        )
    }

    private fun exampleFields(entry: DictionaryEntry): List<String> {
        return uniqueNonEmpty(
            entry.senses.flatMap { sense ->
                sense.examples.flatMap { example ->
                    listOf(example.hanji, example.romanization, example.mandarin)
                }
            }.map(TextNormalization::normalizeQuery),
        )
    }

    private fun fallbackDefinitionFields(entry: DictionaryEntry): List<String> {
        return uniqueNonEmpty(
            listOf(TextNormalization.normalizeQuery(entry.mandarinSearch)),
        )
    }

    private fun bestMatch(fields: List<String>, query: String): SearchFieldMatch? {
        var bestMatch: SearchFieldMatch? = null

        for (field in fields) {
            if (field.isEmpty() || query.isEmpty() || !field.contains(query)) {
                continue
            }

            val quality = when {
                containsExactTerm(field, query) -> 0
                field.startsWith(query) -> 1
                else -> 2
            }
            val candidate = SearchFieldMatch(
                quality = quality,
                matchedLength = field.length,
            )
            if (bestMatch == null || candidate < bestMatch) {
                bestMatch = candidate
            }
        }

        return bestMatch
    }

    private fun containsExactTerm(field: String, query: String): Boolean {
        var matchStart = field.indexOf(query)
        while (matchStart >= 0) {
            val matchEnd = matchStart + query.length
            val hasLeadingBoundary = matchStart == 0 ||
                !Character.isLetterOrDigit(field.codePointBefore(matchStart))
            val hasTrailingBoundary = matchEnd == field.length ||
                !Character.isLetterOrDigit(field.codePointAt(matchEnd))
            if (hasLeadingBoundary && hasTrailingBoundary) {
                return true
            }
            matchStart = field.indexOf(query, startIndex = matchStart + 1)
        }
        return false
    }

    private fun uniqueNonEmpty(values: List<String>): List<String> {
        val seen = LinkedHashSet<String>()
        values.forEach { value ->
            if (value.isNotEmpty()) {
                seen.add(value)
            }
        }
        return seen.toList()
    }
}

private data class ScoredSearchHit(
    val entryId: Long,
    val score: Int,
    val matchQuality: Int,
    val matchedLength: Int,
) : Comparable<ScoredSearchHit> {
    override fun compareTo(other: ScoredSearchHit): Int {
        if (score != other.score) {
            return score.compareTo(other.score)
        }
        if (matchQuality != other.matchQuality) {
            return matchQuality.compareTo(other.matchQuality)
        }
        if (matchedLength != other.matchedLength) {
            return matchedLength.compareTo(other.matchedLength)
        }
        return entryId.compareTo(other.entryId)
    }
}

private data class SearchFieldMatch(
    val quality: Int,
    val matchedLength: Int,
) : Comparable<SearchFieldMatch> {
    override fun compareTo(other: SearchFieldMatch): Int {
        if (quality != other.quality) {
            return quality.compareTo(other.quality)
        }
        return matchedLength.compareTo(other.matchedLength)
    }
}
