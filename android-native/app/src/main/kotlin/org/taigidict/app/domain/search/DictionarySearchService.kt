package org.taigidict.app.domain.search

import org.taigidict.app.core.util.TextNormalization
import org.taigidict.app.domain.model.DictionaryEntry

data class DictionarySearchRow(
    val entryId: Long,
    val headwords: List<String>,
    val definitions: List<String>,
)

object DictionarySearchService {
    const val DEFAULT_LIMIT = 60

    fun buildSearchIndex(entries: List<DictionaryEntry>): List<DictionarySearchRow> {
        return entries.map { entry ->
            DictionarySearchRow(
                entryId = entry.id,
                headwords = headwordFields(entry),
                definitions = definitionFields(entry),
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
        val headwordMatch = bestMatchLength(row.headwords, query)
        if (headwordMatch != null) {
            val score = if (headwordMatch == query.length) 0 else 1
            return ScoredSearchHit(row.entryId, score, headwordMatch)
        }

        val definitionMatch = bestMatchLength(row.definitions, query) ?: return null
        return ScoredSearchHit(row.entryId, 2, definitionMatch)
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
        val senseFields = entry.senses.flatMap { sense ->
            listOf(sense.definition) +
                sense.definitionSynonyms +
                sense.definitionAntonyms +
                sense.examples.flatMap { example ->
                    listOf(example.hanji, example.romanization, example.mandarin)
                }
        }

        return uniqueNonEmpty(
            listOf(entry.mandarinSearch) + senseFields.map(TextNormalization::normalizeQuery),
        )
    }

    private fun bestMatchLength(fields: List<String>, query: String): Int? {
        var bestLength: Int? = null

        for (field in fields) {
            if (field.isEmpty() || query.isEmpty() || !field.contains(query)) {
                continue
            }

            bestLength = if (bestLength == null) {
                field.length
            } else {
                minOf(bestLength, field.length)
            }
        }

        return bestLength
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
    val matchedLength: Int,
) : Comparable<ScoredSearchHit> {
    override fun compareTo(other: ScoredSearchHit): Int {
        if (score != other.score) {
            return score.compareTo(other.score)
        }
        if (matchedLength != other.matchedLength) {
            return matchedLength.compareTo(other.matchedLength)
        }
        return entryId.compareTo(other.entryId)
    }
}