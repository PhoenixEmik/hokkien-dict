package org.taigidict.app.data.importer

import java.nio.ByteBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets
import kotlinx.serialization.SerializationException
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json

sealed class DictionaryJsonlReaderException(message: String, cause: Throwable? = null) :
    Exception(message, cause) {
    class InvalidUtf8(cause: Throwable? = null) :
        DictionaryJsonlReaderException("Dictionary JSONL is not valid UTF-8.", cause)

    class InvalidLine(
        val lineNumber: Int,
        detail: String,
        cause: Throwable? = null,
    ) : DictionaryJsonlReaderException(
        message = "Dictionary JSONL line $lineNumber is invalid: $detail",
        cause = cause,
    )
}

class DictionaryJsonlReader(
    private val json: Json = Json {
        ignoreUnknownKeys = true
    },
) {
    fun readFirstEntry(bytes: ByteArray): DictionaryPackageEntry? {
        var firstEntry: DictionaryPackageEntry? = null
        enumerateEntries(bytes) { entry ->
            if (firstEntry == null) {
                firstEntry = entry
            }
        }
        return firstEntry
    }

    fun enumerateEntries(
        bytes: ByteArray,
        onEntry: (DictionaryPackageEntry) -> Unit,
    ) {
        val content = decodeContent(bytes)

        content.lineSequence().forEachIndexed { index, rawLine ->
            val line = rawLine.trim()
            if (line.isEmpty()) {
                return@forEachIndexed
            }

            try {
                onEntry(json.decodeFromString<DictionaryPackageEntry>(line))
            } catch (error: SerializationException) {
                throw DictionaryJsonlReaderException.InvalidLine(
                    lineNumber = index + 1,
                    detail = error.message ?: error.toString(),
                    cause = error,
                )
            }
        }
    }

    private fun decodeContent(bytes: ByteArray): String {
        return try {
            StandardCharsets.UTF_8
                .newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
                .decode(ByteBuffer.wrap(bytes))
                .toString()
        } catch (error: CharacterCodingException) {
            throw DictionaryJsonlReaderException.InvalidUtf8(error)
        }
    }
}