package org.taigidict.app.data.importer

import android.database.sqlite.SQLiteDatabase
import org.taigidict.app.data.database.DictionaryDatabase
import java.io.File
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

sealed class DictionaryImportException(message: String) : Exception(message) {
    class UnsupportedSchemaVersion(schemaVersion: Int) :
        DictionaryImportException("Unsupported dictionary schema version $schemaVersion.")

    class EntryCountMismatch(expected: Int, actual: Int) :
        DictionaryImportException("Entry count mismatch. Expected $expected but imported $actual.")

    class SenseCountMismatch(expected: Int, actual: Int) :
        DictionaryImportException("Sense count mismatch. Expected $expected but imported $actual.")

    class ExampleCountMismatch(expected: Int, actual: Int) :
        DictionaryImportException("Example count mismatch. Expected $expected but imported $actual.")
}

data class DictionaryImportProgress(
    val processedEntries: Int,
    val totalEntries: Int,
) {
    val fraction: Float
        get() = if (totalEntries <= 0) 0f else (processedEntries.toFloat() / totalEntries.toFloat()).coerceIn(0f, 1f)
}

data class DictionaryImportResult(
    val databaseFile: File,
    val manifest: DictionaryManifest,
    val imported: Boolean,
)

class DictionaryImportService(
    private val databaseFile: File,
    private val packageLoader: DictionaryPackageLoading,
    private val jsonlReader: DictionaryJsonlReader,
    private val json: Json = Json,
) {
    fun ensureBundledDatabase(
        onProgress: ((DictionaryImportProgress) -> Unit)? = null,
    ): DictionaryImportResult {
        val validatedPackage = packageLoader.validateBundledPackage()
        val manifest = validatedPackage.manifest
        validateSchemaVersion(manifest)

        if (isExistingDatabaseCurrent(manifest)) {
            return DictionaryImportResult(
                databaseFile = databaseFile,
                manifest = manifest,
                imported = false,
            )
        }

        importValidatedPackage(validatedPackage, onProgress)
        return DictionaryImportResult(
            databaseFile = databaseFile,
            manifest = manifest,
            imported = true,
        )
    }

    private fun isExistingDatabaseCurrent(manifest: DictionaryManifest): Boolean {
        val metadata = DictionaryDatabase.readMetadata(databaseFile) ?: return false
        if (metadata.isEmpty()) {
            return false
        }

        return metadata["entry_count"] == manifest.entryCount.toString() &&
            metadata["sense_count"] == manifest.senseCount.toString() &&
            metadata["example_count"] == manifest.exampleCount.toString() &&
            metadata["source_modified_at"].orEmpty() == manifest.sourceModifiedAt.orEmpty()
    }

    private fun importValidatedPackage(
        validatedPackage: ValidatedDictionaryPackage,
        onProgress: ((DictionaryImportProgress) -> Unit)?,
    ) {
        val tempFile = File(databaseFile.parentFile, "${databaseFile.name}.tmp")
        if (tempFile.exists()) {
            tempFile.delete()
        }

        var entryCount = 0
        var senseCount = 0
        var exampleCount = 0
        val manifest = validatedPackage.manifest

        DictionaryDatabase.openWritable(tempFile).use { database ->
            DictionaryDatabase.createSchema(database)
            database.beginTransaction()

            try {
                val entryStatement = database.compileStatement(
                    """
                    INSERT INTO dictionary_entries (
                        id, type, hanji, romanization, category, audio_id,
                        variant_chars, word_synonyms, word_antonyms,
                        alternative_pronunciations, contracted_pronunciations,
                        colloquial_pronunciations, phonetic_differences,
                        vocabulary_comparisons, alias_target_entry_id,
                        hokkien_search, mandarin_search
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                )
                val senseStatement = database.compileStatement(
                    """
                    INSERT INTO dictionary_senses (
                        entry_id, sense_id, part_of_speech, definition,
                        definition_synonyms, definition_antonyms
                    ) VALUES (?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                )
                val exampleStatement = database.compileStatement(
                    """
                    INSERT INTO dictionary_examples (
                        entry_id, sense_id, example_order, hanji,
                        romanization, mandarin, audio_id
                    ) VALUES (?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                )
                val metadataStatement = database.compileStatement(
                    "INSERT INTO dictionary_metadata (key, value) VALUES (?, ?)",
                )

                jsonlReader.enumerateEntries(validatedPackage.entriesBytes) { entry ->
                    insertEntry(database, entryStatement, senseStatement, exampleStatement, entry)
                    entryCount += 1
                    senseCount += entry.senses.size
                    exampleCount += entry.senses.sumOf { it.examples.size }

                    if (entryCount % INSERT_BATCH_SIZE == 0) {
                        onProgress?.invoke(DictionaryImportProgress(entryCount, manifest.entryCount))
                    }
                }

                validateCounts(
                    manifest = manifest,
                    entryCount = entryCount,
                    senseCount = senseCount,
                    exampleCount = exampleCount,
                )

                insertMetadata(metadataStatement, "built_at", manifest.builtAt)
                insertMetadata(metadataStatement, "source_modified_at", manifest.sourceModifiedAt.orEmpty())
                insertMetadata(metadataStatement, "entry_count", entryCount.toString())
                insertMetadata(metadataStatement, "sense_count", senseCount.toString())
                insertMetadata(metadataStatement, "example_count", exampleCount.toString())

                database.setTransactionSuccessful()
                onProgress?.invoke(DictionaryImportProgress(entryCount, manifest.entryCount))
            } finally {
                database.endTransaction()
            }
        }

        if (databaseFile.exists()) {
            databaseFile.delete()
        }
        tempFile.renameTo(databaseFile)
    }

    private fun insertEntry(
        database: SQLiteDatabase,
        entryStatement: android.database.sqlite.SQLiteStatement,
        senseStatement: android.database.sqlite.SQLiteStatement,
        exampleStatement: android.database.sqlite.SQLiteStatement,
        entry: DictionaryPackageEntry,
    ) {
        entryStatement.clearBindings()
        entryStatement.bindLong(1, entry.id)
        entryStatement.bindString(2, entry.type)
        entryStatement.bindString(3, entry.hanji)
        entryStatement.bindString(4, entry.romanization)
        entryStatement.bindString(5, entry.category)
        entryStatement.bindString(6, entry.audioId)
        entryStatement.bindString(7, json.encodeToString(entry.variantChars))
        entryStatement.bindString(8, json.encodeToString(entry.wordSynonyms))
        entryStatement.bindString(9, json.encodeToString(entry.wordAntonyms))
        entryStatement.bindString(10, json.encodeToString(entry.alternativePronunciations))
        entryStatement.bindString(11, json.encodeToString(entry.contractedPronunciations))
        entryStatement.bindString(12, json.encodeToString(entry.colloquialPronunciations))
        entryStatement.bindString(13, json.encodeToString(entry.phoneticDifferences))
        entryStatement.bindString(14, json.encodeToString(entry.vocabularyComparisons))
        if (entry.aliasTargetEntryId == null) {
            entryStatement.bindNull(15)
        } else {
            entryStatement.bindLong(15, entry.aliasTargetEntryId)
        }
        entryStatement.bindString(16, entry.hokkienSearch)
        entryStatement.bindString(17, entry.mandarinSearch)
        entryStatement.executeInsert()

        entry.senses.forEachIndexed { senseIndex, sense ->
            val senseId = senseIndex + 1L
            senseStatement.clearBindings()
            senseStatement.bindLong(1, entry.id)
            senseStatement.bindLong(2, senseId)
            senseStatement.bindString(3, sense.partOfSpeech)
            senseStatement.bindString(4, sense.definition)
            senseStatement.bindString(5, json.encodeToString(sense.definitionSynonyms))
            senseStatement.bindString(6, json.encodeToString(sense.definitionAntonyms))
            senseStatement.executeInsert()

            sense.examples.forEachIndexed { exampleIndex, example ->
                exampleStatement.clearBindings()
                exampleStatement.bindLong(1, entry.id)
                exampleStatement.bindLong(2, senseId)
                exampleStatement.bindLong(3, example.order.takeIf { it > 0 }?.toLong() ?: exampleIndex.toLong())
                exampleStatement.bindString(4, example.hanji)
                exampleStatement.bindString(5, example.romanization)
                exampleStatement.bindString(6, example.mandarin)
                exampleStatement.bindString(7, example.audioId)
                exampleStatement.executeInsert()
            }
        }
    }

    private fun insertMetadata(
        metadataStatement: android.database.sqlite.SQLiteStatement,
        key: String,
        value: String,
    ) {
        metadataStatement.clearBindings()
        metadataStatement.bindString(1, key)
        metadataStatement.bindString(2, value)
        metadataStatement.executeInsert()
    }

    private fun validateSchemaVersion(manifest: DictionaryManifest) {
        if (manifest.schemaVersion != SUPPORTED_SCHEMA_VERSION) {
            throw DictionaryImportException.UnsupportedSchemaVersion(manifest.schemaVersion)
        }
    }

    private fun validateCounts(
        manifest: DictionaryManifest,
        entryCount: Int,
        senseCount: Int,
        exampleCount: Int,
    ) {
        if (entryCount != manifest.entryCount) {
            throw DictionaryImportException.EntryCountMismatch(manifest.entryCount, entryCount)
        }
        if (senseCount != manifest.senseCount) {
            throw DictionaryImportException.SenseCountMismatch(manifest.senseCount, senseCount)
        }
        if (exampleCount != manifest.exampleCount) {
            throw DictionaryImportException.ExampleCountMismatch(manifest.exampleCount, exampleCount)
        }
    }

    private companion object {
        const val SUPPORTED_SCHEMA_VERSION = 1
        const val INSERT_BATCH_SIZE = 200
    }
}