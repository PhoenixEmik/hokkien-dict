package org.taigidict.app.domain.model

data class DictionaryEntry(
    val id: Long,
    val type: String,
    val hanji: String,
    val romanization: String,
    val category: String,
    val audioId: String,
    val hokkienSearch: String,
    val mandarinSearch: String,
    val variantChars: List<String>,
    val wordSynonyms: List<String>,
    val wordAntonyms: List<String>,
    val alternativePronunciations: List<String>,
    val contractedPronunciations: List<String>,
    val colloquialPronunciations: List<String>,
    val phoneticDifferences: List<String>,
    val vocabularyComparisons: List<String>,
    val aliasTargetEntryId: Long?,
    val senses: List<DictionarySense>,
) {
    val redirectsToPrimaryEntry: Boolean
        get() = aliasTargetEntryId != null

    val briefSummary: String
        get() {
            if (redirectsToPrimaryEntry) {
                return ""
            }

            return senses.firstOrNull { it.definition.isNotBlank() }?.definition
                ?: category.takeIf { it.isNotBlank() }
                ?: type.takeIf { it.isNotBlank() }
                ?: romanization
        }
}

data class DictionarySense(
    val partOfSpeech: String,
    val definition: String,
    val definitionSynonyms: List<String>,
    val definitionAntonyms: List<String>,
    val examples: List<DictionaryExample>,
)

data class DictionaryExample(
    val hanji: String,
    val romanization: String,
    val mandarin: String,
    val audioId: String,
)