package org.taigidict.app.data.repository

import android.database.Cursor
import java.io.File
import org.taigidict.app.data.database.DictionaryDatabase
import org.taigidict.app.domain.model.DictionaryBundle
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense
import org.taigidict.app.domain.search.DictionarySearchService
import kotlinx.serialization.json.Json

class SQLiteDictionaryRepository(
    private val databaseFile: File,
    private val json: Json = Json,
) {
    fun loadBundle(): DictionaryBundle {
        val metadata = DictionaryDatabase.readMetadata(databaseFile)
            ?: throw SQLiteDictionaryRepositoryException.MissingDatabase(databaseFile)

        val entryCount = metadata["entry_count"]?.toIntOrNull()
            ?: throw SQLiteDictionaryRepositoryException.MissingMetadata("entry_count")
        val senseCount = metadata["sense_count"]?.toIntOrNull()
            ?: throw SQLiteDictionaryRepositoryException.MissingMetadata("sense_count")
        val exampleCount = metadata["example_count"]?.toIntOrNull()
            ?: throw SQLiteDictionaryRepositoryException.MissingMetadata("example_count")

        return DictionaryBundle(
            entryCount = entryCount,
            senseCount = senseCount,
            exampleCount = exampleCount,
            databasePath = databaseFile.path,
        )
    }

    fun search(rawQuery: String, limit: Int = DictionarySearchService.DEFAULT_LIMIT): List<DictionaryEntry> {
        val normalizedQuery = org.taigidict.app.core.util.TextNormalization.normalizeQuery(rawQuery)
        if (normalizedQuery.isEmpty()) {
            return emptyList()
        }

        val candidateIds = searchCandidateIds(normalizedQuery, maxOf(limit, DictionarySearchService.DEFAULT_LIMIT) * 6)
        if (candidateIds.isEmpty()) {
            return emptyList()
        }

        val candidateEntries = fetchEntries(candidateIds)
        val rankedIds = DictionarySearchService.searchEntryIds(
            index = DictionarySearchService.buildSearchIndex(candidateEntries),
            rawQuery = rawQuery,
            limit = limit,
        )
        val entriesById = candidateEntries.associateBy { it.id }
        return rankedIds.mapNotNull(entriesById::get)
    }

    fun entry(id: Long): DictionaryEntry? {
        return fetchEntries(listOf(id)).firstOrNull()
    }

    private fun searchCandidateIds(normalizedQuery: String, limit: Int): List<Long> {
        val pattern = "%${escapeLike(normalizedQuery)}%"
        return DictionaryDatabase.openReadOnly(databaseFile).use { database ->
            database.rawQuery(
                """
                SELECT DISTINCT e.id
                FROM dictionary_entries e
                LEFT JOIN dictionary_senses s ON s.entry_id = e.id
                LEFT JOIN dictionary_examples x ON x.entry_id = e.id
                     WHERE e.hokkien_search LIKE ? ESCAPE '\'
                         OR e.mandarin_search LIKE ? ESCAPE '\'
                         OR e.hanji LIKE ? ESCAPE '\'
                         OR e.romanization LIKE ? ESCAPE '\'
                         OR s.definition LIKE ? ESCAPE '\'
                         OR x.hanji LIKE ? ESCAPE '\'
                         OR x.romanization LIKE ? ESCAPE '\'
                         OR x.mandarin LIKE ? ESCAPE '\'
                ORDER BY e.id
                LIMIT ?
                """.trimIndent(),
                arrayOf(pattern, pattern, pattern, pattern, pattern, pattern, pattern, pattern, limit.toString()),
            ).use { cursor ->
                buildList {
                    val idIndex = cursor.getColumnIndexOrThrow("id")
                    while (cursor.moveToNext()) {
                        add(cursor.getLong(idIndex))
                    }
                }
            }
        }
    }

    private fun fetchEntries(ids: List<Long>): List<DictionaryEntry> {
        if (ids.isEmpty()) {
            return emptyList()
        }

        val uniqueIds = ids.distinct()
        val placeholders = uniqueIds.joinToString(separator = ",") { "?" }
        val args = uniqueIds.map(Long::toString).toTypedArray()

        return DictionaryDatabase.openReadOnly(databaseFile).use { database ->
            val entryRows = database.rawQuery(
                """
                SELECT id, type, hanji, romanization, category, audio_id,
                    variant_chars, word_synonyms, word_antonyms,
                    alternative_pronunciations, contracted_pronunciations,
                    colloquial_pronunciations, phonetic_differences,
                    vocabulary_comparisons, alias_target_entry_id,
                    hokkien_search, mandarin_search
                FROM dictionary_entries
                WHERE id IN ($placeholders)
                """.trimIndent(),
                args,
            ).use { cursor ->
                buildList {
                    while (cursor.moveToNext()) {
                        add(readEntryRow(cursor))
                    }
                }
            }

            val examplesBySense = fetchExamples(database, uniqueIds, placeholders, args)
            val sensesByEntry = fetchSenses(database, uniqueIds, placeholders, args, examplesBySense)
            val rowsById = entryRows.associateBy { it.id }

            uniqueIds.mapNotNull { id ->
                val row = rowsById[id] ?: return@mapNotNull null
                DictionaryEntry(
                    id = row.id,
                    type = row.type,
                    hanji = row.hanji,
                    romanization = row.romanization,
                    category = row.category,
                    audioId = row.audioId,
                    hokkienSearch = row.hokkienSearch,
                    mandarinSearch = row.mandarinSearch,
                    variantChars = decodeStringArray(row.variantCharsJson),
                    wordSynonyms = decodeStringArray(row.wordSynonymsJson),
                    wordAntonyms = decodeStringArray(row.wordAntonymsJson),
                    alternativePronunciations = decodeStringArray(row.alternativePronunciationsJson),
                    contractedPronunciations = decodeStringArray(row.contractedPronunciationsJson),
                    colloquialPronunciations = decodeStringArray(row.colloquialPronunciationsJson),
                    phoneticDifferences = decodeStringArray(row.phoneticDifferencesJson),
                    vocabularyComparisons = decodeStringArray(row.vocabularyComparisonsJson),
                    aliasTargetEntryId = row.aliasTargetEntryId,
                    senses = sensesByEntry[id].orEmpty(),
                )
            }
        }
    }

    private fun fetchSenses(
        database: android.database.sqlite.SQLiteDatabase,
        ids: List<Long>,
        placeholders: String,
        args: Array<String>,
        examplesBySense: Map<Pair<Long, Long>, List<DictionaryExample>>,
    ): Map<Long, List<DictionarySense>> {
        return database.rawQuery(
            """
            SELECT entry_id, sense_id, part_of_speech, definition, definition_synonyms, definition_antonyms
            FROM dictionary_senses
            WHERE entry_id IN ($placeholders)
            ORDER BY entry_id, sense_id
            """.trimIndent(),
            args,
        ).use { cursor ->
            val grouped = linkedMapOf<Long, MutableList<DictionarySense>>()
            while (cursor.moveToNext()) {
                val entryId = cursor.getLong(cursor.getColumnIndexOrThrow("entry_id"))
                val senseId = cursor.getLong(cursor.getColumnIndexOrThrow("sense_id"))
                val sense = DictionarySense(
                    partOfSpeech = cursor.getString(cursor.getColumnIndexOrThrow("part_of_speech")),
                    definition = cursor.getString(cursor.getColumnIndexOrThrow("definition")),
                    definitionSynonyms = decodeStringArray(cursor.getString(cursor.getColumnIndexOrThrow("definition_synonyms"))),
                    definitionAntonyms = decodeStringArray(cursor.getString(cursor.getColumnIndexOrThrow("definition_antonyms"))),
                    examples = examplesBySense[entryId to senseId].orEmpty(),
                )
                grouped.getOrPut(entryId) { mutableListOf() }.add(sense)
            }
            ids.associateWith { grouped[it].orEmpty() }
        }
    }

    private fun fetchExamples(
        database: android.database.sqlite.SQLiteDatabase,
        ids: List<Long>,
        placeholders: String,
        args: Array<String>,
    ): Map<Pair<Long, Long>, List<DictionaryExample>> {
        return database.rawQuery(
            """
            SELECT entry_id, sense_id, example_order, hanji, romanization, mandarin, audio_id
            FROM dictionary_examples
            WHERE entry_id IN ($placeholders)
            ORDER BY entry_id, sense_id, example_order
            """.trimIndent(),
            args,
        ).use { cursor ->
            val grouped = linkedMapOf<Pair<Long, Long>, MutableList<DictionaryExample>>()
            while (cursor.moveToNext()) {
                val entryId = cursor.getLong(cursor.getColumnIndexOrThrow("entry_id"))
                val senseId = cursor.getLong(cursor.getColumnIndexOrThrow("sense_id"))
                val example = DictionaryExample(
                    hanji = cursor.getString(cursor.getColumnIndexOrThrow("hanji")),
                    romanization = cursor.getString(cursor.getColumnIndexOrThrow("romanization")),
                    mandarin = cursor.getString(cursor.getColumnIndexOrThrow("mandarin")),
                    audioId = cursor.getString(cursor.getColumnIndexOrThrow("audio_id")),
                )
                grouped.getOrPut(entryId to senseId) { mutableListOf() }.add(example)
            }
            grouped
        }
    }

    private fun readEntryRow(cursor: Cursor): EntryRow {
        return EntryRow(
            id = cursor.getLong(cursor.getColumnIndexOrThrow("id")),
            type = cursor.getString(cursor.getColumnIndexOrThrow("type")),
            hanji = cursor.getString(cursor.getColumnIndexOrThrow("hanji")),
            romanization = cursor.getString(cursor.getColumnIndexOrThrow("romanization")),
            category = cursor.getString(cursor.getColumnIndexOrThrow("category")),
            audioId = cursor.getString(cursor.getColumnIndexOrThrow("audio_id")),
            variantCharsJson = cursor.getString(cursor.getColumnIndexOrThrow("variant_chars")),
            wordSynonymsJson = cursor.getString(cursor.getColumnIndexOrThrow("word_synonyms")),
            wordAntonymsJson = cursor.getString(cursor.getColumnIndexOrThrow("word_antonyms")),
            alternativePronunciationsJson = cursor.getString(cursor.getColumnIndexOrThrow("alternative_pronunciations")),
            contractedPronunciationsJson = cursor.getString(cursor.getColumnIndexOrThrow("contracted_pronunciations")),
            colloquialPronunciationsJson = cursor.getString(cursor.getColumnIndexOrThrow("colloquial_pronunciations")),
            phoneticDifferencesJson = cursor.getString(cursor.getColumnIndexOrThrow("phonetic_differences")),
            vocabularyComparisonsJson = cursor.getString(cursor.getColumnIndexOrThrow("vocabulary_comparisons")),
            aliasTargetEntryId = if (cursor.isNull(cursor.getColumnIndexOrThrow("alias_target_entry_id"))) null else cursor.getLong(cursor.getColumnIndexOrThrow("alias_target_entry_id")),
            hokkienSearch = cursor.getString(cursor.getColumnIndexOrThrow("hokkien_search")),
            mandarinSearch = cursor.getString(cursor.getColumnIndexOrThrow("mandarin_search")),
        )
    }

    private fun decodeStringArray(value: String): List<String> {
        return runCatching {
            json.decodeFromString<List<String>>(value)
        }.getOrDefault(emptyList())
    }

    private fun escapeLike(value: String): String {
        return value
            .replace("\\", "\\\\")
            .replace("%", "\\%")
            .replace("_", "\\_")
    }
}

private data class EntryRow(
    val id: Long,
    val type: String,
    val hanji: String,
    val romanization: String,
    val category: String,
    val audioId: String,
    val variantCharsJson: String,
    val wordSynonymsJson: String,
    val wordAntonymsJson: String,
    val alternativePronunciationsJson: String,
    val contractedPronunciationsJson: String,
    val colloquialPronunciationsJson: String,
    val phoneticDifferencesJson: String,
    val vocabularyComparisonsJson: String,
    val aliasTargetEntryId: Long?,
    val hokkienSearch: String,
    val mandarinSearch: String,
)

sealed class SQLiteDictionaryRepositoryException(message: String) : Exception(message) {
    class MissingDatabase(file: File) :
        SQLiteDictionaryRepositoryException("Dictionary database is missing at ${file.path}.")

    class MissingMetadata(key: String) :
        SQLiteDictionaryRepositoryException("Dictionary metadata is missing key $key.")
}