package org.taigidict.app.data.repository

import java.io.File
import kotlin.io.path.createTempDirectory
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.taigidict.app.data.importer.DictionaryImportService
import org.taigidict.app.data.importer.DictionaryJsonlReader
import org.taigidict.app.data.importer.DictionaryManifest
import org.taigidict.app.data.importer.DictionaryPackageLoading
import org.taigidict.app.data.importer.ValidatedDictionaryPackage

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class SQLiteDictionaryRepositorySearchTest {
    @Test
    fun search_matchesHanjiRomanizationAndDefinition() {
        val tempDirectory = createTempDirectory(prefix = "dict-search-").toFile()
        val databaseFile = File(tempDirectory, "dictionary.sqlite")
        val jsonl = """
            {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"su-tian","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","senses":[{"partOfSpeech":"名詞","definition":"工具書。","examples":[]}]}
            {"id":2,"type":"名詞","hanji":"字典","romanization":"jī-tián","category":"","audio":"","hokkienSearch":"字典 ji tian","mandarinSearch":"字典","senses":[{"partOfSpeech":"名詞","definition":"收錄字詞的書。","examples":[]}]}
            {"id":3,"type":"形容詞","hanji":"媠","romanization":"suí","category":"","audio":"","hokkienSearch":"媠 sui","mandarinSearch":"漂亮","senses":[{"partOfSpeech":"形容詞","definition":"美麗、好看。","examples":[]}]}
        """.trimIndent()
        val manifest = DictionaryManifest(
            schemaVersion = 1,
            builtAt = "2026-04-30T00:00:00Z",
            sourceModifiedAt = "2026-04-30T00:00:00Z",
            entryCount = 3,
            senseCount = 3,
            exampleCount = 0,
            entriesFileName = "dictionary_entries.jsonl",
        )
        val validatedPackage = ValidatedDictionaryPackage(
            manifest = manifest,
            entriesBytes = jsonl.toByteArray(),
            firstEntry = DictionaryJsonlReader().readFirstEntry(jsonl.toByteArray())!!,
        )

        DictionaryImportService(
            databaseFile = databaseFile,
            packageLoader = object : DictionaryPackageLoading {
                override fun validateBundledPackage(): ValidatedDictionaryPackage = validatedPackage
            },
            jsonlReader = DictionaryJsonlReader(),
        ).ensureBundledDatabase()

        val repository = SQLiteDictionaryRepository(databaseFile)

        assertEquals(listOf(1L), repository.search("辭典").map { it.id })
        assertEquals(listOf(1L), repository.search("su tian").map { it.id })
        assertEquals(listOf(3L), repository.search("好看").map { it.id })
    }
}