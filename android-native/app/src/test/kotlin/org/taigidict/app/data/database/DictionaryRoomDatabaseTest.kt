package org.taigidict.app.data.database

import android.app.Application
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class DictionaryRoomDatabaseTest {
    @Test
    fun dao_readsMetadataAndEntryRows() = runTest {
        val application = ApplicationProvider.getApplicationContext<Application>()
        val database = Room.inMemoryDatabaseBuilder(
            application,
            DictionaryRoomDatabase::class.java,
        ).build()

        try {
            database.openHelper.writableDatabase.execSQL(
                "INSERT INTO dictionary_metadata (key, value) VALUES ('entry_count', '1')",
            )
            database.openHelper.writableDatabase.execSQL(
                """
                INSERT INTO dictionary_entries (
                    id, type, hanji, romanization, category, audio_id,
                    variant_chars, word_synonyms, word_antonyms,
                    alternative_pronunciations, contracted_pronunciations,
                    colloquial_pronunciations, phonetic_differences,
                    vocabulary_comparisons, alias_target_entry_id,
                    hokkien_search, mandarin_search
                ) VALUES (
                    1, '名詞', '辭典', 'sû-tián', '主詞目', 'word-1',
                    '[]', '[]', '[]',
                    '[]', '[]',
                    '[]', '[]',
                    '[]', NULL,
                    'sutian', '辭典'
                )
                """.trimIndent(),
            )

            val metadataRows = database.dictionaryDao().metadataRows()
            val entryRow = database.dictionaryDao().entryRow(1)

            assertEquals(listOf(DictionaryMetadataEntity("entry_count", "1")), metadataRows)
            assertNotNull(entryRow)
            assertEquals("辭典", entryRow?.hanji)
            assertEquals("sû-tián", entryRow?.romanization)
        } finally {
            database.close()
        }
    }
}
