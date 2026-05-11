package org.taigidict.app.feature.dictionary

import org.taigidict.app.domain.model.DictionaryEntry

object DictionaryShareFormatter {
    fun buildShareTitle(
        entry: DictionaryEntry,
        fallbackTitle: String,
    ): String {
        return entry.hanji.trim().ifEmpty { fallbackTitle }
    }

    fun buildShareText(
        entry: DictionaryEntry,
        fallbackHanji: String,
        footer: String,
    ): String {
        val word = entry.hanji.trim().ifEmpty { fallbackHanji }
        val romanization = entry.romanization.trim()
        val definitions = entry.senses
            .map { sense -> sense.definition.trim() }
            .filter { definition -> definition.isNotEmpty() }

        val buffer = StringBuilder().append("【").append(word).append("】")
        if (romanization.isNotEmpty()) {
            buffer.append("(").append(romanization).append(")")
        }

        if (definitions.isNotEmpty()) {
            buffer.appendLine()
            buffer.appendLine(definitions.joinToString(separator = "\n"))
        } else {
            val summary = entry.briefSummary.trim()
            if (summary.isNotEmpty()) {
                buffer.appendLine()
                buffer.appendLine(summary)
            }
        }

        buffer.appendLine()
        buffer.append(footer)
        return buffer.toString().trim()
    }
}