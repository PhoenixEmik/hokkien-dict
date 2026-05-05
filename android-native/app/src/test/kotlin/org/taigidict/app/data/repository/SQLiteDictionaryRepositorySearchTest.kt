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

    @Test
    fun search_prioritizesExactHanjiThenHeadwordPrefixThenDefinitionMatches() {
        val tempDirectory = createTempDirectory(prefix = "dict-search-order-").toFile()
        val databaseFile = File(tempDirectory, "dictionary.sqlite")
        val jsonl = """
            {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","senses":[{"partOfSpeech":"名詞","definition":"工具書。","examples":[]}]}
            {"id":2,"type":"名詞","hanji":"辭典仔","romanization":"sû-tián-á","category":"主詞目","audio":"","hokkienSearch":"辭典仔 su tian a","mandarinSearch":"小辭典","senses":[{"partOfSpeech":"名詞","definition":"較小本的辭典。","examples":[]}]}
            {"id":3,"type":"名詞","hanji":"參考書","romanization":"tsham-khó-tsu","category":"主詞目","audio":"","hokkienSearch":"參考書 tsham kho tsu","mandarinSearch":"參考書","senses":[{"partOfSpeech":"名詞","definition":"像辭典這款工具書。","examples":[]}]}
        """.trimIndent()
        val repository = importRepository(databaseFile, jsonl, entryCount = 3, senseCount = 3)

        assertEquals(listOf(1L, 2L, 3L), repository.search("辭典").map { it.id })
    }

    @Test
    fun findLinkedEntry_prefersExactHanjiThenRelatedWordThenRomanization() {
        val tempDirectory = createTempDirectory(prefix = "dict-linked-order-").toFile()
        val databaseFile = File(tempDirectory, "dictionary.sqlite")
        val jsonl = """
            {"id":1,"type":"名詞","hanji":"字典","romanization":"tsī-tián","category":"主詞目","audio":"","hokkienSearch":"字典 tsi tian","mandarinSearch":"字典","senses":[{"partOfSpeech":"名詞","definition":"一本冊。","examples":[]}]}
            {"id":2,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","wordSynonyms":["字典"],"senses":[{"partOfSpeech":"名詞","definition":"工具書。","examples":[]}]}
            {"id":3,"type":"名詞","hanji":"耳鏡","romanization":"ji-tian","category":"主詞目","audio":"","hokkienSearch":"耳鏡 ji tian","mandarinSearch":"耳鏡","senses":[{"partOfSpeech":"名詞","definition":"器材。","examples":[]}]}
        """.trimIndent()
        val repository = importRepository(databaseFile, jsonl, entryCount = 3, senseCount = 3)

        assertEquals(1L, repository.findLinkedEntry("字典")?.id)
        assertEquals(2L, repository.findLinkedEntry("辭典")?.id)
        assertEquals(3L, repository.findLinkedEntry("耳鏡")?.id)
        assertEquals(3L, repository.findLinkedEntry("ji tian")?.id)
    }

    private fun importRepository(
        databaseFile: File,
        jsonl: String,
        entryCount: Int,
        senseCount: Int,
        exampleCount: Int = 0,
    ): SQLiteDictionaryRepository {
        val manifest = DictionaryManifest(
            schemaVersion = 1,
            builtAt = "2026-04-30T00:00:00Z",
            sourceModifiedAt = "2026-04-30T00:00:00Z",
            entryCount = entryCount,
            senseCount = senseCount,
            exampleCount = exampleCount,
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

        return SQLiteDictionaryRepository(databaseFile)
    }
}
