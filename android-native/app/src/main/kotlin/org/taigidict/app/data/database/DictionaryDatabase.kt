package org.taigidict.app.data.database

import android.database.sqlite.SQLiteDatabase
import java.io.File

object DictionaryDatabase {
    private val schemaStatements = listOf(
        """
        CREATE TABLE dictionary_entries (
            id INTEGER PRIMARY KEY,
            type TEXT NOT NULL,
            hanji TEXT NOT NULL,
            romanization TEXT NOT NULL,
            category TEXT NOT NULL,
            audio_id TEXT NOT NULL,
            variant_chars TEXT NOT NULL,
            word_synonyms TEXT NOT NULL,
            word_antonyms TEXT NOT NULL,
            alternative_pronunciations TEXT NOT NULL,
            contracted_pronunciations TEXT NOT NULL,
            colloquial_pronunciations TEXT NOT NULL,
            phonetic_differences TEXT NOT NULL,
            vocabulary_comparisons TEXT NOT NULL,
            alias_target_entry_id INTEGER,
            hokkien_search TEXT NOT NULL,
            mandarin_search TEXT NOT NULL
        )
        """.trimIndent(),
        """
        CREATE TABLE dictionary_senses (
            entry_id INTEGER NOT NULL,
            sense_id INTEGER NOT NULL,
            part_of_speech TEXT NOT NULL,
            definition TEXT NOT NULL,
            definition_synonyms TEXT NOT NULL,
            definition_antonyms TEXT NOT NULL,
            PRIMARY KEY (entry_id, sense_id)
        )
        """.trimIndent(),
        """
        CREATE TABLE dictionary_examples (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            sense_id INTEGER NOT NULL,
            example_order INTEGER NOT NULL,
            hanji TEXT NOT NULL,
            romanization TEXT NOT NULL,
            mandarin TEXT NOT NULL,
            audio_id TEXT NOT NULL
        )
        """.trimIndent(),
        """
        CREATE TABLE dictionary_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )
        """.trimIndent(),
        "CREATE INDEX idx_entries_hokkien_search ON dictionary_entries(hokkien_search)",
        "CREATE INDEX idx_entries_mandarin_search ON dictionary_entries(mandarin_search)",
        "CREATE INDEX idx_senses_entry_id ON dictionary_senses(entry_id)",
        "CREATE INDEX idx_examples_entry_sense_order ON dictionary_examples(entry_id, sense_id, example_order)",
    )

    fun openWritable(file: File): SQLiteDatabase {
        file.parentFile?.mkdirs()
        return SQLiteDatabase.openOrCreateDatabase(file, null)
    }

    fun openReadOnly(file: File): SQLiteDatabase {
        return SQLiteDatabase.openDatabase(
            file.path,
            null,
            SQLiteDatabase.OPEN_READONLY,
        )
    }

    fun createSchema(database: SQLiteDatabase) {
        schemaStatements.forEach(database::execSQL)
    }

    fun readMetadata(file: File): Map<String, String>? {
        if (!file.exists()) {
            return null
        }

        openReadOnly(file).use { database ->
            database.rawQuery("SELECT key, value FROM dictionary_metadata", null).use { cursor ->
                if (!cursor.moveToFirst()) {
                    return emptyMap()
                }

                val keyIndex = cursor.getColumnIndexOrThrow("key")
                val valueIndex = cursor.getColumnIndexOrThrow("value")
                val values = linkedMapOf<String, String>()

                do {
                    values[cursor.getString(keyIndex)] = cursor.getString(valueIndex)
                } while (cursor.moveToNext())

                return values
            }
        }
    }
}