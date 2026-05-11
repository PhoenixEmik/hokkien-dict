package org.taigidict.app.data.database

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "dictionary_examples",
    indices = [
        Index(
            value = ["entry_id", "sense_id", "example_order"],
            name = "idx_examples_entry_sense_order",
        ),
    ],
)
data class DictionaryExampleEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    @ColumnInfo(name = "entry_id")
    val entryId: Long,
    @ColumnInfo(name = "sense_id")
    val senseId: Long,
    @ColumnInfo(name = "example_order")
    val exampleOrder: Long,
    val hanji: String,
    val romanization: String,
    val mandarin: String,
    @ColumnInfo(name = "audio_id")
    val audioId: String,
)
