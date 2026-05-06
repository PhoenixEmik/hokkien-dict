package org.taigidict.app.data.repository

import android.app.Application
import androidx.test.core.app.ApplicationProvider
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
class RoomDictionaryRepositoryParityTest {
    @Test
    fun loadBundle_matchesSQLiteRepository() {
        val (_, sqliteRepository, roomRepository) = importRepositories(sampleJsonl)

        roomRepository.use {
            assertEquals(sqliteRepository.loadBundle(), roomRepository.loadBundle())
        }
    }

    @Test
    fun search_matchesSQLiteRepositoryAcrossQueries() {
        val (_, sqliteRepository, roomRepository) = importRepositories(sampleJsonl)

        roomRepository.use {
            listOf("辭典", "su tian", "好看", "字典").forEach { query ->
                assertEquals(
                    sqliteRepository.search(query),
                    roomRepository.search(query),
                )
            }
        }
    }

    @Test
    fun entryAndEntries_matchSQLiteRepository() {
        val (_, sqliteRepository, roomRepository) = importRepositories(sampleJsonl)

        roomRepository.use {
            assertEquals(sqliteRepository.entry(1L), roomRepository.entry(1L))
            assertEquals(
                sqliteRepository.entries(listOf(2L, 1L, 3L)),
                roomRepository.entries(listOf(2L, 1L, 3L)),
            )
        }
    }

    @Test
    fun findLinkedEntry_matchesSQLiteRepository() {
        val jsonl = """
            {"id":1,"type":"名詞","hanji":"字典","romanization":"tsī-tián","category":"主詞目","audio":"","hokkienSearch":"字典 tsi tian","mandarinSearch":"字典","senses":[{"partOfSpeech":"名詞","definition":"一本冊。","examples":[]}]}
            {"id":2,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","wordSynonyms":["字典"],"senses":[{"partOfSpeech":"名詞","definition":"工具書。","examples":[]}]}
            {"id":3,"type":"名詞","hanji":"耳鏡","romanization":"ji-tian","category":"主詞目","audio":"","hokkienSearch":"耳鏡 ji tian","mandarinSearch":"耳鏡","senses":[{"partOfSpeech":"名詞","definition":"器材。","examples":[]}]}
        """.trimIndent()
        val (_, sqliteRepository, roomRepository) = importRepositories(jsonl, entryCount = 3, senseCount = 3)

        roomRepository.use {
            listOf("字典", "辭典", "耳鏡", "ji tian").forEach { query ->
                assertEquals(
                    sqliteRepository.findLinkedEntry(query),
                    roomRepository.findLinkedEntry(query),
                )
            }
        }
    }

    private fun importRepositories(
        jsonl: String,
        entryCount: Int = 4,
        senseCount: Int = 4,
        exampleCount: Int = 0,
    ): Triple<File, SQLiteDictionaryRepository, RoomDictionaryRepository> {
        val tempDirectory = createTempDirectory(prefix = "dict-room-parity-").toFile()
        val databaseFile = File(tempDirectory, "dictionary.sqlite")
        val application = ApplicationProvider.getApplicationContext<Application>()
        val validatedPackage = ValidatedDictionaryPackage(
            manifest = DictionaryManifest(
                schemaVersion = 1,
                builtAt = "2026-04-30T00:00:00Z",
                sourceModifiedAt = "2026-04-30T00:00:00Z",
                entryCount = entryCount,
                senseCount = senseCount,
                exampleCount = exampleCount,
                entriesFileName = "dictionary_entries.jsonl",
            ),
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

        return Triple(
            databaseFile,
            SQLiteDictionaryRepository(databaseFile),
            RoomDictionaryRepository(application, databaseFile),
        )
    }

    private companion object {
        val sampleJsonl = """
            {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"su-tian","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","senses":[{"partOfSpeech":"名詞","definition":"工具書。","examples":[]}]}
            {"id":2,"type":"名詞","hanji":"字典","romanization":"jī-tián","category":"","audio":"","hokkienSearch":"字典 ji tian","mandarinSearch":"字典","senses":[{"partOfSpeech":"名詞","definition":"收錄字詞的書。","examples":[]}]}
            {"id":3,"type":"形容詞","hanji":"媠","romanization":"suí","category":"","audio":"","hokkienSearch":"媠 sui","mandarinSearch":"漂亮","senses":[{"partOfSpeech":"形容詞","definition":"美麗、好看。","examples":[]}]}
            {"id":4,"type":"名詞","hanji":"參考書","romanization":"tsham-khó-tsu","category":"主詞目","audio":"","hokkienSearch":"參考書 tsham kho tsu","mandarinSearch":"參考書","senses":[{"partOfSpeech":"名詞","definition":"像辭典這款工具書。","examples":[]}]}
        """.trimIndent()
    }
}
