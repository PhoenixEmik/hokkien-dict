package org.taigidict.app.data.repository

import android.app.Application
import androidx.test.core.app.ApplicationProvider
import java.io.File
import kotlin.io.path.createTempDirectory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
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
class DictionaryRepositoryFactoryTest {
    @Test
    fun create_returnsWorkingRepositoriesForBothBackends() {
        val application = ApplicationProvider.getApplicationContext<Application>()
        val databaseFile = importDatabase()

        DictionaryRepositoryBackend.entries.forEach { backend ->
            val repository = DictionaryRepositoryFactory.create(
                context = application,
                databaseFile = databaseFile,
                backend = backend,
            )

            val bundle = repository.loadBundle()
            val searchResults = repository.search("辭典")

            assertEquals(1, bundle.entryCount)
            assertEquals(1, searchResults.size)
            assertEquals("辭典", searchResults.first().hanji)

            if (repository is AutoCloseable) {
                repository.close()
            }
        }
    }

    @Test
    fun create_usesRequestedImplementation() {
        val application = ApplicationProvider.getApplicationContext<Application>()
        val databaseFile = importDatabase()

        val sqliteRepository = DictionaryRepositoryFactory.create(
            context = application,
            databaseFile = databaseFile,
            backend = DictionaryRepositoryBackend.SQLite,
        )
        val roomRepository = DictionaryRepositoryFactory.create(
            context = application,
            databaseFile = databaseFile,
            backend = DictionaryRepositoryBackend.Room,
        )

        assertTrue(sqliteRepository is SQLiteDictionaryRepository)
        assertTrue(roomRepository is RoomDictionaryRepository)

        (roomRepository as AutoCloseable).close()
    }

    @Test
    fun parse_defaultsToSqliteForUnknownValues() {
        assertEquals(
            DictionaryRepositoryBackend.SQLite,
            DictionaryRepositoryBackend.parse("unexpected"),
        )
        assertEquals(
            DictionaryRepositoryBackend.Room,
            DictionaryRepositoryBackend.parse("ROOM"),
        )
    }

    private fun importDatabase(): File {
        val tempDirectory = createTempDirectory(prefix = "dict-repository-factory-").toFile()
        val databaseFile = File(tempDirectory, "dictionary.sqlite")
        val validatedPackage = ValidatedDictionaryPackage(
            manifest = DictionaryManifest(
                schemaVersion = 1,
                builtAt = "2026-05-06T00:00:00Z",
                sourceModifiedAt = "2026-05-06T00:00:00Z",
                entryCount = 1,
                senseCount = 1,
                exampleCount = 0,
                entriesFileName = "dictionary_entries.jsonl",
            ),
            entriesBytes = """
                {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","senses":[{"partOfSpeech":"名詞","definition":"工具書。","examples":[]}]}
            """.trimIndent().toByteArray(),
            firstEntry = DictionaryJsonlReader().readFirstEntry(
                """
                    {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","senses":[{"partOfSpeech":"名詞","definition":"工具書。","examples":[]}]}
                """.trimIndent().toByteArray(),
            )!!,
        )

        DictionaryImportService(
            databaseFile = databaseFile,
            packageLoader = object : DictionaryPackageLoading {
                override fun validateBundledPackage(): ValidatedDictionaryPackage = validatedPackage
            },
            jsonlReader = DictionaryJsonlReader(),
        ).ensureBundledDatabase()

        return databaseFile
    }
}
