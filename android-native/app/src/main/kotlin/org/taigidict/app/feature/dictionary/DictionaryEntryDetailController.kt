package org.taigidict.app.feature.dictionary

import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.domain.model.DictionaryEntry

data class PreparedDictionaryEntryDetail(
    val entry: DictionaryEntry,
    val openableLinkedWords: Set<String>,
)

class DictionaryEntryDetailController(
    private val repository: DictionaryRepositoryDataSource,
) {
    fun prepareEntryDetail(sourceEntry: DictionaryEntry): PreparedDictionaryEntryDetail {
        val resolvedEntry = resolveAliasChain(sourceEntry)
        val openableLinkedWords = collectLinkedWords(resolvedEntry)
            .filterTo(linkedSetOf()) { word ->
                val linkedEntry = repository.findLinkedEntry(word) ?: return@filterTo false
                resolveAliasChain(linkedEntry).id != resolvedEntry.id
            }

        return PreparedDictionaryEntryDetail(
            entry = resolvedEntry,
            openableLinkedWords = openableLinkedWords,
        )
    }

    fun prepareLinkedEntry(
        currentEntryId: Long,
        openableLinkedWords: Set<String>,
        word: String,
    ): PreparedDictionaryEntryDetail {
        if (!openableLinkedWords.contains(word)) {
            throw IllegalStateException("Linked entry $word is not openable")
        }

        val linkedEntry = repository.findLinkedEntry(word)
            ?: throw IllegalStateException("Linked entry $word not found")
        val prepared = prepareEntryDetail(linkedEntry)
        if (prepared.entry.id == currentEntryId) {
            throw IllegalStateException("Linked entry $word resolves to the current entry")
        }
        return prepared
    }

    private fun resolveAliasChain(sourceEntry: DictionaryEntry): DictionaryEntry {
        var currentEntry = sourceEntry
        val visitedIds = mutableSetOf<Long>()

        while (currentEntry.aliasTargetEntryId != null && visitedIds.add(currentEntry.id)) {
            val targetEntry = repository.entry(currentEntry.aliasTargetEntryId!!)
                ?: break
            currentEntry = targetEntry
        }

        return currentEntry
    }

    private fun collectLinkedWords(entry: DictionaryEntry): List<String> {
        val orderedWords = linkedSetOf<String>()

        fun addWords(words: List<String>) {
            words.forEach { word ->
                val trimmed = word.trim()
                if (trimmed.isNotEmpty()) {
                    orderedWords += trimmed
                }
            }
        }

        addWords(entry.variantChars)
        addWords(entry.wordSynonyms)
        addWords(entry.wordAntonyms)
        entry.senses.forEach { sense ->
            addWords(sense.definitionSynonyms)
            addWords(sense.definitionAntonyms)
        }

        return orderedWords.toList()
    }
}