package org.taigidict.app.data.database

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "dictionary_entries",
    indices = [
        Index(value = ["hokkien_search"], name = "idx_entries_hokkien_search"),
        Index(value = ["mandarin_search"], name = "idx_entries_mandarin_search"),
    ],
)
data class DictionaryEntryEntity(
    @PrimaryKey
    val id: Long,
    val type: String,
    val hanji: String,
    val romanization: String,
    val category: String,
    @ColumnInfo(name = "audio_id")
    val audioId: String,
    @ColumnInfo(name = "variant_chars")
    val variantCharsJson: String,
    @ColumnInfo(name = "word_synonyms")
    val wordSynonymsJson: String,
    @ColumnInfo(name = "word_antonyms")
    val wordAntonymsJson: String,
    @ColumnInfo(name = "alternative_pronunciations")
    val alternativePronunciationsJson: String,
    @ColumnInfo(name = "contracted_pronunciations")
    val contractedPronunciationsJson: String,
    @ColumnInfo(name = "colloquial_pronunciations")
    val colloquialPronunciationsJson: String,
    @ColumnInfo(name = "phonetic_differences")
    val phoneticDifferencesJson: String,
    @ColumnInfo(name = "vocabulary_comparisons")
    val vocabularyComparisonsJson: String,
    @ColumnInfo(name = "alias_target_entry_id")
    val aliasTargetEntryId: Long?,
    @ColumnInfo(name = "hokkien_search")
    val hokkienSearch: String,
    @ColumnInfo(name = "mandarin_search")
    val mandarinSearch: String,
)
