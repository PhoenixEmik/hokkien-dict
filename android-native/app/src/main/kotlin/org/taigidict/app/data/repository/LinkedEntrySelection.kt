package org.taigidict.app.data.repository

import org.taigidict.app.domain.model.DictionaryEntry

internal object LinkedEntrySelection {
    private const val APPENDIX_ENTRY_TYPE = "附錄"

    fun select(
        candidates: List<DictionaryEntry>,
        rawWord: String,
        normalizedWord: String,
        matchesLinkedWord: (String, String) -> Boolean,
    ): DictionaryEntry? {
        return bestCandidate(
            candidates.filter { candidate ->
                candidate.hanji.trim() == rawWord.trim() ||
                    org.taigidict.app.core.util.TextNormalization.normalizeQuery(candidate.hanji) == normalizedWord
            },
        ) ?: bestCandidate(
            candidates.filter { candidate ->
                candidate.variantChars.any { matchesLinkedWord(it, normalizedWord) } ||
                    candidate.wordSynonyms.any { matchesLinkedWord(it, normalizedWord) } ||
                    candidate.wordAntonyms.any { matchesLinkedWord(it, normalizedWord) } ||
                    candidate.senses.any { sense ->
                        sense.definitionSynonyms.any { matchesLinkedWord(it, normalizedWord) } ||
                            sense.definitionAntonyms.any { matchesLinkedWord(it, normalizedWord) }
                    }
            },
        ) ?: bestCandidate(
            candidates.filter { candidate ->
                matchesLinkedWord(candidate.romanization, normalizedWord)
            },
        )
    }

    private fun bestCandidate(candidates: List<DictionaryEntry>): DictionaryEntry? {
        return candidates.minWithOrNull(
            compareBy<DictionaryEntry>(
                ::priority,
                { it.id },
            ),
        )
    }

    private fun priority(entry: DictionaryEntry): Int {
        return when {
            !entry.redirectsToPrimaryEntry && entry.type != APPENDIX_ENTRY_TYPE -> 0
            entry.redirectsToPrimaryEntry -> 1
            else -> 2
        }
    }
}
