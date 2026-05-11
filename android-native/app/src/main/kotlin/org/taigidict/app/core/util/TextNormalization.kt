package org.taigidict.app.core.util

import java.text.Normalizer
import java.util.Locale

object TextNormalization {
    private val romanizationFold = mapOf(
        'á' to "a",
        'à' to "a",
        'â' to "a",
        'ǎ' to "a",
        'ā' to "a",
        'ä' to "a",
        'ã' to "a",
        'é' to "e",
        'è' to "e",
        'ê' to "e",
        'ē' to "e",
        'ë' to "e",
        'í' to "i",
        'ì' to "i",
        'î' to "i",
        'ī' to "i",
        'ï' to "i",
        'ó' to "o",
        'ò' to "o",
        'ô' to "o",
        'ō' to "o",
        'ö' to "o",
        'ő' to "o",
        'ú' to "u",
        'ù' to "u",
        'û' to "u",
        'ū' to "u",
        'ü' to "u",
        'ḿ' to "m",
        'ń' to "n",
        'ǹ' to "n",
    )
    private val toneNumberRegex = Regex("[1-8]")
    private val separatorRegex = Regex("[-_/]")
    private val punctuationRegex = Regex("[【】\\[\\]（）()、,.;:!?\"'`]+")
    private val whitespaceRegex = Regex("\\s+")

    fun normalizedSearchText(text: String): String = normalizeQuery(text)

    fun normalizeQuery(input: String): String {
        var normalized = removeTones(input.trim())
        normalized = toneNumberRegex.replace(normalized, "")
        normalized = collapseWhitespace(normalized)
        normalized = separatorRegex.replace(normalized, " ")
        normalized = punctuationRegex.replace(normalized, " ")
        return collapseWhitespace(normalized)
    }

    fun removeTones(input: String): String {
        val lowered = input.lowercase(Locale.ROOT)
        val builder = StringBuilder(lowered.length)

        lowered.forEach { character ->
            builder.append(romanizationFold[character] ?: character)
        }

        var output = removeCombiningMarks(builder.toString())
        output = output.replace("o\u0358", "oo")
        output = output.replace("\u207F", "n")
        return toneNumberRegex.replace(output, "")
    }

    private fun removeCombiningMarks(input: String): String {
        return Normalizer.normalize(input, Normalizer.Form.NFD)
            .replace(Regex("\\p{M}+"), "")
    }

    private fun collapseWhitespace(input: String): String {
        return whitespaceRegex.replace(input, " ").trim()
    }
}