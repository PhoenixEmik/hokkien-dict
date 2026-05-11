package org.taigidict.app.data.importer

import java.io.File
import kotlin.io.path.createTempDirectory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.taigidict.app.data.repository.SQLiteDictionaryRepository

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class DictionaryImportServiceTest {
    @Test
    fun ensureBundledDatabase_importsThenReusesCurrentDatabase() {
        val tempDirectory = createTempDirectory(prefix = "dict-import-").toFile()
        val databaseFile = File(tempDirectory, "dictionary.sqlite")
        val jsonl = sampleJsonl(entryCount = 2)
        val manifest = DictionaryManifest(
            schemaVersion = 1,
            builtAt = "2026-04-30T00:00:00Z",
            sourceModifiedAt = "2026-04-30T00:00:00Z",
            entryCount = 2,
            senseCount = 2,
            exampleCount = 1,
            entriesFileName = "dictionary_entries.jsonl",
        )
        val service = DictionaryImportService(
            databaseFile = databaseFile,
            packageLoader = FakeDictionaryPackageLoader(
                ValidatedDictionaryPackage(
                    manifest = manifest,
                    entriesBytes = jsonl.toByteArray(),
                    firstEntry = DictionaryJsonlReader().readFirstEntry(jsonl.toByteArray())!!,
                ),
            ),
            jsonlReader = DictionaryJsonlReader(),
        )

        val firstResult = service.ensureBundledDatabase()
        val secondResult = service.ensureBundledDatabase()
        val bundle = SQLiteDictionaryRepository(databaseFile).loadBundle()

        assertTrue(firstResult.imported)
        assertFalse(secondResult.imported)
        assertEquals(2, bundle.entryCount)
        assertEquals(2, bundle.senseCount)
        assertEquals(1, bundle.exampleCount)
    }

    @Test
    fun ensureBundledDatabase_rejectsMismatchedCounts() {
        val tempDirectory = createTempDirectory(prefix = "dict-import-mismatch-").toFile()
        val databaseFile = File(tempDirectory, "dictionary.sqlite")
        val jsonl = sampleJsonl(entryCount = 1)
        val manifest = DictionaryManifest(
            schemaVersion = 1,
            builtAt = "2026-04-30T00:00:00Z",
            sourceModifiedAt = "2026-04-30T00:00:00Z",
            entryCount = 2,
            senseCount = 1,
            exampleCount = 1,
            entriesFileName = "dictionary_entries.jsonl",
        )
        val service = DictionaryImportService(
            databaseFile = databaseFile,
            packageLoader = FakeDictionaryPackageLoader(
                ValidatedDictionaryPackage(
                    manifest = manifest,
                    entriesBytes = jsonl.toByteArray(),
                    firstEntry = DictionaryJsonlReader().readFirstEntry(jsonl.toByteArray())!!,
                ),
            ),
            jsonlReader = DictionaryJsonlReader(),
        )

        val error = runCatching {
            service.ensureBundledDatabase()
        }.exceptionOrNull()

        require(error is DictionaryImportException.EntryCountMismatch)
        assertEquals("Entry count mismatch. Expected 2 but imported 1.", error.message)
    }

    private fun sampleJsonl(entryCount: Int): String {
        return buildList {
            add(
                """
                {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"su-tian","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","senses":[{"partOfSpeech":"名詞","definition":"一種工具書。","examples":[{"order":1,"hanji":"辭典是真重要的工具冊。","romanization":"Sû-tián sī tsin tiōng-iàu ê kang-kū-tsheh.","mandarin":"辭典是很重要的工具書。","audio":"ex-1"}]}]}
                """.trimIndent(),
            )
            if (entryCount > 1) {
                add(
                    """
                    {"id":2,"type":"名詞","hanji":"字典","romanization":"jī-tián","category":"","audio":"","aliasTargetEntryId":1,"hokkienSearch":"字典 ji tian","mandarinSearch":"字典","senses":[{"partOfSpeech":"","definition":"","examples":[]}]}
                    """.trimIndent(),
                )
            }
        }.joinToString(separator = "\n")
    }
}

private class FakeDictionaryPackageLoader(
    private val validatedPackage: ValidatedDictionaryPackage,
) : DictionaryPackageLoading {
    override fun validateBundledPackage(): ValidatedDictionaryPackage = validatedPackage
}