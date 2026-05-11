package org.taigidict.app.data.importer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DictionaryJsonlReaderTest {
    private val reader = DictionaryJsonlReader()

    @Test
    fun readFirstEntry_parsesAliasFieldAndExamples() {
        val bytes = (
            """
            {"id":2,"type":"名詞","hanji":"字典","romanization":"ji-tián","category":"","audio":"","aliasTargetEntryId":1,"hokkienSearch":"字典 ji tian","mandarinSearch":"字典","senses":[{"partOfSpeech":"","definition":"","examples":[{"order":1,"hanji":"一本字典","romanization":"tsi̍t pún jī-tián","mandarin":"一本字典","audio":"ex-1"}]}]}
            """.trimIndent()
        ).toByteArray()

        val entry = reader.readFirstEntry(bytes)

        requireNotNull(entry)
        assertEquals(1L, entry.aliasTargetEntryId)
        assertEquals("ex-1", entry.senses.first().examples.first().audioId)
    }

    @Test
    fun enumerateEntries_rejectsInvalidUtf8() {
        val invalidUtf8 = byteArrayOf(0x7b, 0x0a, 0x22, 0x61, 0x22, 0x3a, 0x20, 0xC3.toByte())

        val error = runCatching {
            reader.enumerateEntries(invalidUtf8) { }
        }.exceptionOrNull()

        assertTrue(error is DictionaryJsonlReaderException.InvalidUtf8)
    }

    @Test
    fun enumerateEntries_rejectsInvalidJsonLine() {
        val bytes = (
            """
            {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"su-tian","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","senses":[{"partOfSpeech":"名詞","definition":"一種工具書。","examples":[]}]} 
            not-json
            """.trimIndent()
        ).toByteArray()

        val error = runCatching {
            reader.enumerateEntries(bytes) { }
        }.exceptionOrNull()

        require(error is DictionaryJsonlReaderException.InvalidLine)
        assertEquals(2, error.lineNumber)
    }
}