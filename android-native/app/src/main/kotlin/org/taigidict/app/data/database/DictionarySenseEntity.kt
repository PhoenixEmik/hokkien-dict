package org.taigidict.app.data.database

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index

@Entity(
    tableName = "dictionary_senses",
    primaryKeys = ["entry_id", "sense_id"],
    indices = [
        Index(value = ["entry_id"], name = "idx_senses_entry_id"),
    ],
)
data class DictionarySenseEntity(
    @ColumnInfo(name = "entry_id")
    val entryId: Long,
    @ColumnInfo(name = "sense_id")
    val senseId: Long,
    @ColumnInfo(name = "part_of_speech")
    val partOfSpeech: String,
    val definition: String,
    @ColumnInfo(name = "definition_synonyms")
    val definitionSynonymsJson: String,
    @ColumnInfo(name = "definition_antonyms")
    val definitionAntonymsJson: String,
)
