package org.taigidict.app.data.database

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "dictionary_metadata")
data class DictionaryMetadataEntity(
    @PrimaryKey
    val key: String,
    val value: String,
)
