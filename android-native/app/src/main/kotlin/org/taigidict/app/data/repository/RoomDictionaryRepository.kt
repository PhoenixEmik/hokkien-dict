package org.taigidict.app.data.repository

import android.content.Context
import androidx.sqlite.db.SimpleSQLiteQuery
import java.io.File
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import org.taigidict.app.data.database.DictionaryEntryEntity
import org.taigidict.app.data.database.DictionaryExampleEntity
import org.taigidict.app.data.database.DictionaryRoomDatabase
import org.taigidict.app.data.database.DictionarySenseEntity
import org.taigidict.app.domain.model.DictionaryBundle
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense
import org.taigidict.app.domain.search.DictionarySearchService

class RoomDictionaryRepository(
    context: Context,
    private val databaseFile: File,
    private val json: Json = Json,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : DictionaryRepositoryDataSource, AutoCloseable {
    private val database = DictionaryRoomDatabase.open(
        context = context.applicationContext,
        databaseFile = databaseFile,
    )
    private val dao = database.dictionaryDao()

    override fun loadBundle(): DictionaryBundle = runBlocking(ioDispatcher) {
        val metadata = dao.metadataRows().associate { it.key to it.value }
        if (metadata.isEmpty()) {
            throw SQLiteDictionaryRepositoryException.MissingDatabase(databaseFile)
        }

        val entryCount = metadata["entry_count"]?.toIntOrNull()
            ?: throw SQLiteDictionaryRepositoryException.MissingMetadata("entry_count")
        val senseCount = metadata["sense_count"]?.toIntOrNull()
            ?: throw SQLiteDictionaryRepositoryException.MissingMetadata("sense_count")
        val exampleCount = metadata["example_count"]?.toIntOrNull()
            ?: throw SQLiteDictionaryRepositoryException.MissingMetadata("example_count")

        DictionaryBundle(
            entryCount = entryCount,
            senseCount = senseCount,
            exampleCount = exampleCount,
            databasePath = databaseFile.path,
        )
    }

    override fun search(rawQuery: String, limit: Int): List<DictionaryEntry> = runBlocking(ioDispatcher) {
        val normalizedQuery = org.taigidict.app.core.util.TextNormalization.normalizeQuery(rawQuery)
        if (normalizedQuery.isEmpty()) {
            return@runBlocking emptyList()
        }

        val pattern = "%${escapeLike(normalizedQuery)}%"
        val prefix = "${escapeLike(normalizedQuery)}%"
        val searchLimit = limit.coerceAtLeast(1)
        val candidateIds = dao.searchOrderedIds(
            SimpleSQLiteQuery(
                """
                SELECT e.id
                FROM dictionary_entries e
                WHERE e.hanji LIKE ? ESCAPE '\'
                   OR e.hokkien_search LIKE ? ESCAPE '\'
                   OR e.mandarin_search LIKE ? ESCAPE '\'
                   OR EXISTS (
                     SELECT 1
                     FROM dictionary_senses s
                     WHERE s.entry_id = e.id
                       AND s.definition LIKE ? ESCAPE '\'
                   )
                   OR EXISTS (
                     SELECT 1
                     FROM dictionary_examples x
                     WHERE x.entry_id = e.id
                       AND (
                         x.hanji LIKE ? ESCAPE '\'
                         OR x.romanization LIKE ? ESCAPE '\'
                         OR x.mandarin LIKE ? ESCAPE '\'
                       )
                   )
                ORDER BY
                  CASE
                    WHEN e.hanji = ? THEN 0
                    WHEN e.hokkien_search LIKE ? ESCAPE '\' THEN 1
                    WHEN e.hanji LIKE ? ESCAPE '\' THEN 1
                    ELSE 2
                  END ASC,
                  length(e.hokkien_search) ASC,
                  e.id ASC
                LIMIT ?
                """.trimIndent(),
                arrayOf<Any>(
                    pattern,
                    pattern,
                    pattern,
                    pattern,
                    pattern,
                    pattern,
                    pattern,
                    rawQuery.trim(),
                    prefix,
                    prefix,
                    maxOf(searchLimit, DictionarySearchService.DEFAULT_LIMIT) *
                        SEARCH_CANDIDATE_MULTIPLIER,
                ),
            ),
        ).map { it.id }

        val candidates = fetchEntries(candidateIds)
        val rankedIds = DictionarySearchService.searchEntryIds(
            index = DictionarySearchService.buildSearchIndex(candidates),
            rawQuery = rawQuery,
            limit = searchLimit,
        )
        val candidatesById = candidates.associateBy(DictionaryEntry::id)
        rankedIds.mapNotNull(candidatesById::get)
    }

    override fun entries(ids: List<Long>): List<DictionaryEntry> = runBlocking(ioDispatcher) {
        fetchEntries(ids)
    }

    override fun entry(id: Long): DictionaryEntry? = runBlocking(ioDispatcher) {
        fetchEntries(listOf(id)).firstOrNull()
    }

    override fun findLinkedEntry(rawWord: String): DictionaryEntry? = runBlocking(ioDispatcher) {
        val normalizedWord = org.taigidict.app.core.util.TextNormalization.normalizeQuery(rawWord)
        if (normalizedWord.isEmpty()) {
            return@runBlocking null
        }

        val candidates = search(rawWord, ROOM_DEFAULT_SEARCH_LIMIT)
        LinkedEntrySelection.select(
            candidates = candidates,
            rawWord = rawWord,
            normalizedWord = normalizedWord,
            matchesLinkedWord = ::matchesLinkedWord,
        )
    }

    override fun close() {
        database.close()
    }

    private suspend fun fetchEntries(ids: List<Long>): List<DictionaryEntry> {
        if (ids.isEmpty()) {
            return emptyList()
        }

        val uniqueIds = ids.distinct()
        val entryRows = dao.entryRows(uniqueIds)
        val rowsById = entryRows.associateBy { it.id }
        val examplesBySense = dao.exampleRows(uniqueIds)
            .groupBy { it.entryId to it.senseId }
            .mapValues { (_, rows) -> rows.map(::mapExample) }
        val sensesByEntry = dao.senseRows(uniqueIds)
            .groupBy { it.entryId }
            .mapValues { (_, rows) ->
                rows.map { sense ->
                    mapSense(
                        sense = sense,
                        examples = examplesBySense[sense.entryId to sense.senseId].orEmpty(),
                    )
                }
            }

        return uniqueIds.mapNotNull { id ->
            val row = rowsById[id] ?: return@mapNotNull null
            mapEntry(
                entry = row,
                senses = sensesByEntry[id].orEmpty(),
            )
        }
    }

    private fun mapEntry(
        entry: DictionaryEntryEntity,
        senses: List<DictionarySense>,
    ): DictionaryEntry {
        return DictionaryEntry(
            id = entry.id,
            type = entry.type,
            hanji = entry.hanji,
            romanization = entry.romanization,
            category = entry.category,
            audioId = entry.audioId,
            hokkienSearch = entry.hokkienSearch,
            mandarinSearch = entry.mandarinSearch,
            variantChars = decodeStringArray(entry.variantCharsJson),
            wordSynonyms = decodeStringArray(entry.wordSynonymsJson),
            wordAntonyms = decodeStringArray(entry.wordAntonymsJson),
            alternativePronunciations = decodeStringArray(entry.alternativePronunciationsJson),
            contractedPronunciations = decodeStringArray(entry.contractedPronunciationsJson),
            colloquialPronunciations = decodeStringArray(entry.colloquialPronunciationsJson),
            phoneticDifferences = decodeStringArray(entry.phoneticDifferencesJson),
            vocabularyComparisons = decodeStringArray(entry.vocabularyComparisonsJson),
            aliasTargetEntryId = entry.aliasTargetEntryId,
            senses = senses,
        )
    }

    private fun mapSense(
        sense: DictionarySenseEntity,
        examples: List<DictionaryExample>,
    ): DictionarySense {
        return DictionarySense(
            partOfSpeech = sense.partOfSpeech,
            definition = sense.definition,
            definitionSynonyms = decodeStringArray(sense.definitionSynonymsJson),
            definitionAntonyms = decodeStringArray(sense.definitionAntonymsJson),
            examples = examples,
        )
    }

    private fun mapExample(example: DictionaryExampleEntity): DictionaryExample {
        return DictionaryExample(
            hanji = example.hanji,
            romanization = example.romanization,
            mandarin = example.mandarin,
            audioId = example.audioId,
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

    private fun matchesLinkedWord(value: String, normalizedWord: String): Boolean {
        return org.taigidict.app.core.util.TextNormalization.normalizeQuery(value) == normalizedWord
    }

    private companion object {
        const val ROOM_DEFAULT_SEARCH_LIMIT = 60
        const val SEARCH_CANDIDATE_MULTIPLIER = 6
    }
}
