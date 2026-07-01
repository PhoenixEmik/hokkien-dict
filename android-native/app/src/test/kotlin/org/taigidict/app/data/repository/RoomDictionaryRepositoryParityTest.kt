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
    fun search_prioritizesClosestDefinitionMatchAcrossBackends() {
        val jsonl = """
            {"id":1300,"type":"助詞","hanji":"仔【替】","romanization":"--á","category":"","audio":"","hokkienSearch":"仔 a","mandarinSearch":"名詞後綴。 今天","senses":[{"partOfSpeech":"助詞","definition":"名詞後綴。","examples":[{"order":1,"hanji":"今仔日","romanization":"kin-á-ji̍t","mandarin":"今天","audio":""}]}]}
            {"id":366,"type":"時間詞","hanji":"下昏暗","romanization":"e-hng-àm","category":"","audio":"","hokkienSearch":"下昏暗 e hng am","mandarinSearch":"今晚 今天晚上。","senses":[{"partOfSpeech":"時間詞","definition":"今晚、今天晚上。","examples":[]}]}
            {"id":629,"type":"時間詞","hanji":"今仔日","romanization":"kin-á-ji̍t","category":"","audio":"","hokkienSearch":"今仔日 kin a jit","mandarinSearch":"今天 今日。 今天是我的生日。","senses":[{"partOfSpeech":"時間詞","definition":"今天、今日。","examples":[{"order":1,"hanji":"今仔日是我的生日。","romanization":"Kin-á-ji̍t sī guá ê senn-ji̍t.","mandarin":"今天是我的生日。","audio":""}]}]}
        """.trimIndent()
        val (_, sqliteRepository, roomRepository) = importRepositories(
            jsonl = jsonl,
            entryCount = 3,
            senseCount = 3,
            exampleCount = 2,
        )

        roomRepository.use {
            val expectedIds = listOf(629L, 366L, 1300L)
            assertEquals(expectedIds, sqliteRepository.search("今天").map { it.id })
            assertEquals(expectedIds, roomRepository.search("今天").map { it.id })
            assertEquals(
                sqliteRepository.search("今天", limit = 1),
                roomRepository.search("今天", limit = 1),
            )
        }
    }

    @Test
    fun search_prioritizesExactDefinitionTermAcrossBackends() {
        val jsonl = """
            {"id":4204,"type":"時間詞","hanji":"明仔日","romanization":"bîn-á-ji̍t","category":"","audio":"","hokkienSearch":"明仔日 bin a jit","mandarinSearch":"明天 明日。","senses":[{"partOfSpeech":"時間詞","definition":"明天、明日。","examples":[]}]}
            {"id":4206,"type":"時間詞","hanji":"明仔早起","romanization":"bîn-á-tsá-khí","category":"","audio":"","hokkienSearch":"明仔早起 bin a tsa khi","mandarinSearch":"明天早上。","senses":[{"partOfSpeech":"時間詞","definition":"明天早上。","examples":[]}]}
            {"id":4207,"type":"時間詞","hanji":"明仔暗","romanization":"bîn-á-àm","category":"","audio":"","hokkienSearch":"明仔暗 bin a am","mandarinSearch":"明天晚上。","senses":[{"partOfSpeech":"時間詞","definition":"明天晚上。","examples":[]}]}
            {"id":4208,"type":"時間詞","hanji":"明仔載","romanization":"bîn-á-tsài","category":"","audio":"","hokkienSearch":"明仔載 bin a tsai","mandarinSearch":"明天 明日。","senses":[{"partOfSpeech":"時間詞","definition":"明天、明日。","examples":[]}]}
        """.trimIndent()
        val (_, sqliteRepository, roomRepository) = importRepositories(
            jsonl = jsonl,
            entryCount = 4,
            senseCount = 4,
        )

        roomRepository.use {
            val expectedIds = listOf(4204L, 4208L, 4206L, 4207L)
            assertEquals(expectedIds, sqliteRepository.search("明天").map { it.id })
            assertEquals(expectedIds, roomRepository.search("明天").map { it.id })
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

    @Test
    fun findLinkedEntry_prioritization_matchesSQLiteRepositoryWithAppendixCollisions() {
        val jsonl = """
            {"id":1,"type":"主詞目","hanji":"白","romanization":"【白】pe̍h","category":"顏色、氣味","audio":"","hokkienSearch":"白 白 peh 顏色 氣味","mandarinSearch":"白色","senses":[{"partOfSpeech":"名詞","definition":"顏色名。","definitionSynonyms":[],"definitionAntonyms":["烏"],"examples":[]}]}
            {"id":2,"type":"主詞目","hanji":"白","romanization":"【文】pi̍k","category":"性質、程度","audio":"","hokkienSearch":"白 文 pik 性質 程度","mandarinSearch":"清白","senses":[{"partOfSpeech":"形容詞","definition":"清楚。","examples":[]}]}
            {"id":3,"type":"附錄","hanji":"白","romanization":"Pe̍h","category":"全部,五畫","audio":"","hokkienSearch":"白 peh 全部 五畫","mandarinSearch":"附錄 百家姓","senses":[{"partOfSpeech":"","definition":"附錄－百家姓","examples":[]}]}
            {"id":4,"type":"主詞目","hanji":"烏","romanization":"oo","category":"顏色、氣味","audio":"","hokkienSearch":"烏 oo 顏色 氣味","mandarinSearch":"黑色","senses":[{"partOfSpeech":"名詞","definition":"顏色名。","definitionSynonyms":[],"definitionAntonyms":["白"],"examples":[]}]}
        """.trimIndent()
        val (_, sqliteRepository, roomRepository) = importRepositories(jsonl, entryCount = 4, senseCount = 4)

        roomRepository.use {
            assertEquals(1L, sqliteRepository.findLinkedEntry("白")?.id)
            assertEquals(
                sqliteRepository.findLinkedEntry("白"),
                roomRepository.findLinkedEntry("白"),
            )
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
