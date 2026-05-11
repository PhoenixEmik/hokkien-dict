package org.taigidict.app.data.database

import androidx.room.Dao
import androidx.room.Query
import androidx.room.RawQuery
import androidx.sqlite.db.SupportSQLiteQuery

@Dao
interface DictionaryRoomDao {
    @Query("SELECT key, value FROM dictionary_metadata")
    suspend fun metadataRows(): List<DictionaryMetadataEntity>

    @Query("SELECT * FROM dictionary_entries WHERE id IN (:ids)")
    suspend fun entryRows(ids: List<Long>): List<DictionaryEntryEntity>

    @Query(
        """
        SELECT * FROM dictionary_senses
        WHERE entry_id IN (:entryIds)
        ORDER BY entry_id, sense_id
        """,
    )
    suspend fun senseRows(entryIds: List<Long>): List<DictionarySenseEntity>

    @Query(
        """
        SELECT * FROM dictionary_examples
        WHERE entry_id IN (:entryIds)
        ORDER BY entry_id, sense_id, example_order
        """,
    )
    suspend fun exampleRows(entryIds: List<Long>): List<DictionaryExampleEntity>

    @Query("SELECT * FROM dictionary_entries WHERE id = :id LIMIT 1")
    suspend fun entryRow(id: Long): DictionaryEntryEntity?

    @RawQuery
    suspend fun searchOrderedIds(query: SupportSQLiteQuery): List<DictionaryEntryIdRow>
}
