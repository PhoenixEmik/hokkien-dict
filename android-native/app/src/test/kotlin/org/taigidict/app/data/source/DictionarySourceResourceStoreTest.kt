package org.taigidict.app.data.source

import android.app.Application
import androidx.test.core.app.ApplicationProvider
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestDispatcher
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.taigidict.app.core.constants.AppConstants

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class DictionarySourceResourceStoreTest {
    @Test
    fun restoreBundledSource_writesValidatedPackageAndPublishesCompletedSnapshot() = runTest {
        val localSourceDirectory = Files.createTempDirectory("dictionary-source-restore").toFile()
        val store = createStore(localSourceDirectory, StandardTestDispatcher(testScheduler))

        val result = store.restoreBundledSource()

        assertTrue(result.isSuccess)
        val manifestFile = File(localSourceDirectory, "dictionary_manifest.json")
        val entriesFile = File(localSourceDirectory, "dictionary_entries.jsonl")
        assertTrue(manifestFile.exists())
        assertTrue(entriesFile.exists())
        assertEquals(DownloadSnapshot.State.Completed, store.snapshot.value.state)
        assertEquals(
            manifestFile.length() + entriesFile.length(),
            store.snapshot.value.downloadedBytes,
        )
    }

    @Test
    fun restoreBundledSourceIfNewer_replacesOlderLocalSource() = runTest {
        val localSourceDirectory = Files.createTempDirectory("dictionary-source-upgrade").toFile()
        localSourceDirectory.mkdirs()
        File(localSourceDirectory, "dictionary_manifest.json").writeText(
            """
            {
              "schemaVersion": 1,
              "builtAt": "2026-04-01T00:00:00Z",
              "source": "test",
              "sourceModifiedAt": "2026-04-01T00:00:00Z",
              "entryCount": 1,
              "senseCount": 1,
              "exampleCount": 0,
              "entriesFileName": "dictionary_entries.jsonl",
              "checksumSHA256": "old"
            }
            """.trimIndent()
        )
        File(localSourceDirectory, "dictionary_entries.jsonl").writeText("{}")
        val store = createStore(localSourceDirectory, StandardTestDispatcher(testScheduler))

        val result = store.restoreBundledSourceIfNewer()

        assertTrue(result.getOrThrow())
        assertEquals(DownloadSnapshot.State.Completed, store.snapshot.value.state)
        assertTrue(File(localSourceDirectory, "dictionary_entries.jsonl").length() > 2)
    }

    @Test
    fun refresh_withPausedStagingDownload_preservesExistingFilesAndPublishesPausedSnapshot() = runTest {
        val localSourceDirectory = Files.createTempDirectory("dictionary-source-invalid").toFile()
        File(localSourceDirectory, "dictionary_manifest.json").writeText(
            """
            {
              "schemaVersion": 1,
              "builtAt": "2026-05-06T00:00:00Z",
              "source": "test",
              "sourceModifiedAt": "2026-05-01T00:00:00Z",
              "entryCount": 1,
              "senseCount": 1,
              "exampleCount": 0,
              "entriesFileName": "dictionary_entries.jsonl",
              "checksumSHA256": "deadbeef"
            }
            """.trimIndent()
        )
        File(localSourceDirectory, "dictionary_entries.jsonl").writeText(
            """
            {"id":1,"type":"main","hanji":"試驗","romanization":"tshi3-giam7","category":"名詞","audio":"","hokkienSearch":"tshigiam","mandarinSearch":"試驗","senses":[{"partOfSpeech":"名詞","definition":"試驗","examples":[]}]}
            """.trimIndent()
        )
        val stagingDirectory = File(localSourceDirectory.parentFile, "${localSourceDirectory.name}.staging")
        stagingDirectory.mkdirs()
        File(stagingDirectory, "dictionary_manifest.json").writeText(
            """
            {
              "schemaVersion": 1,
              "builtAt": "2026-05-06T00:00:00Z",
              "source": "test",
              "sourceModifiedAt": "2026-05-01T00:00:00Z",
              "entryCount": 1,
              "senseCount": 1,
              "exampleCount": 0,
              "entriesFileName": "dictionary_entries.jsonl",
              "checksumSHA256": "deadbeef"
            }
            """.trimIndent()
        )
        File(stagingDirectory, "dictionary_entries.jsonl.download").writeText("partial")

        val store = createStore(localSourceDirectory, StandardTestDispatcher(testScheduler))

        val result = store.refresh()

        assertTrue(result.isSuccess)
        assertEquals(DownloadSnapshot.State.Paused, store.snapshot.value.state)
        assertTrue(File(localSourceDirectory, "dictionary_manifest.json").exists())
        assertTrue(File(localSourceDirectory, "dictionary_entries.jsonl").exists())
        assertTrue(File(stagingDirectory, "dictionary_entries.jsonl.download").exists())
    }

    @Test
    fun restoreBundledSource_failurePreservesExistingCommittedSource() = runTest {
        val localSourceDirectory = Files.createTempDirectory("dictionary-source-preserve").toFile()
        createStore(localSourceDirectory, StandardTestDispatcher(testScheduler))
            .restoreBundledSource()
            .getOrThrow()
        val existingManifest = File(localSourceDirectory, "dictionary_manifest.json")
        val existingEntries = File(localSourceDirectory, "dictionary_entries.jsonl")
        val beforeManifest = existingManifest.readText()
        val beforeEntries = existingEntries.readText()
        val store = createStore(
            localSourceDirectory = localSourceDirectory,
            dispatcher = StandardTestDispatcher(testScheduler),
            bundledManifestAssetPath = "missing_manifest.json",
        )

        val result = store.restoreBundledSource()

        assertTrue(result.isFailure)
        assertEquals(DownloadSnapshot.State.Failed, store.snapshot.value.state)
        assertTrue(existingManifest.exists())
        assertTrue(existingEntries.exists())
        assertEquals(beforeManifest, existingManifest.readText())
        assertEquals(beforeEntries, existingEntries.readText())
    }

    private fun createStore(
        localSourceDirectory: File,
        dispatcher: TestDispatcher,
        bundledManifestAssetPath: String = AppConstants.BUNDLED_DICTIONARY_MANIFEST_ASSET_PATH,
        bundledEntriesAssetPath: String = AppConstants.BUNDLED_DICTIONARY_ENTRIES_ASSET_PATH,
    ): DictionarySourceResourceStore {
        val application = ApplicationProvider.getApplicationContext<Application>()
        return DictionarySourceResourceStore(
            assetManager = application.assets,
            bundledManifestAssetPath = bundledManifestAssetPath,
            bundledEntriesAssetPath = bundledEntriesAssetPath,
            localSourceDirectory = localSourceDirectory,
            ioDispatcher = dispatcher,
        )
    }
}
