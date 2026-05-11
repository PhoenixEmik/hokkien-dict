package org.taigidict.app.data.importer

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class DictionaryPackageEntry(
    val id: Long,
    val type: String,
    val hanji: String,
    val romanization: String,
    val category: String,
    @SerialName("audio") val audioId: String,
    val hokkienSearch: String,
    val mandarinSearch: String,
    val variantChars: List<String> = emptyList(),
    val wordSynonyms: List<String> = emptyList(),
    val wordAntonyms: List<String> = emptyList(),
    val alternativePronunciations: List<String> = emptyList(),
    val contractedPronunciations: List<String> = emptyList(),
    val colloquialPronunciations: List<String> = emptyList(),
    val phoneticDifferences: List<String> = emptyList(),
    val vocabularyComparisons: List<String> = emptyList(),
    val aliasTargetEntryId: Long? = null,
    val senses: List<DictionaryPackageSense>,
)

@Serializable
data class DictionaryPackageSense(
    val partOfSpeech: String,
    val definition: String,
    val definitionSynonyms: List<String> = emptyList(),
    val definitionAntonyms: List<String> = emptyList(),
    val examples: List<DictionaryPackageExample> = emptyList(),
)

@Serializable
data class DictionaryPackageExample(
    val order: Int,
    val hanji: String,
    val romanization: String,
    val mandarin: String,
    @SerialName("audio") val audioId: String,
)