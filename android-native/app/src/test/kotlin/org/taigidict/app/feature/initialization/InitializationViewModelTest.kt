package org.taigidict.app.feature.initialization

import android.content.Context
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import java.io.File
import java.time.Duration
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.taigidict.app.app.AppContainer
import org.taigidict.app.app.AppContainerOverrides
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.core.constants.AppConstants
import org.taigidict.app.data.database.DictionaryDatabase
import org.taigidict.app.data.importer.BundledDictionaryImporting
import org.taigidict.app.data.importer.DictionaryImportProgress
import org.taigidict.app.data.importer.DictionaryImportResult
import org.taigidict.app.data.importer.DictionaryManifest
import org.taigidict.app.data.source.DictionarySourceResourceManaging
import org.taigidict.app.data.source.DownloadSnapshot

@RunWith(RobolectricTestRunner::class)
@Config(
    manifest = Config.NONE,
    sdk = [34],
    application = InitializationViewModelTestApplication::class,
)
class InitializationViewModelTest {
    @After
    fun tearDown() {
        InitializationViewModelTestApplication.appContainerFactory = null
    }

    @Test
    fun existingDatabase_becomesReadyBeforeBackgroundRefreshCompletes() {
        val importer = BlockingBundledDictionaryImporter(imported = false)
        val application = configureApplication(importer) { databaseFile, bundledManifest ->
            writeDatabaseMetadata(databaseFile, bundledManifest)
        }

        val viewModel = InitializationViewModel(application)

        assertTrue(viewModel.uiState.value.isReady)
        assertEquals(InitializationPhase.Ready, viewModel.uiState.value.phase)
        waitUntil(timeoutMillis = 1_000) {
            importer.ensureCalls > 0
        }

        importer.release()
    }

    @Test
    fun missingDatabase_doesNotSkipBlockingInitialization() {
        val importer = BlockingBundledDictionaryImporter(imported = true)
        val application = configureApplication(importer) { databaseFile, _ ->
            if (databaseFile.exists()) {
                databaseFile.delete()
            }
        }

        val viewModel = InitializationViewModel(application)

        waitUntil(timeoutMillis = 1_000) {
            importer.ensureCalls > 0
        }

        assertFalse(viewModel.uiState.value.isReady)
        assertEquals(InitializationPhase.RestoringBundledSource, viewModel.uiState.value.phase)

        importer.release()

        waitUntil(timeoutMillis = 1_000) {
            viewModel.uiState.value.isReady
        }
        assertTrue(viewModel.uiState.value.isReady)
    }

    private fun configureApplication(
        importer: BlockingBundledDictionaryImporter,
        prepareDatabase: (File, DictionaryManifest?) -> Unit,
    ): InitializationViewModelTestApplication {
        InitializationViewModelTestApplication.appContainerFactory = { context ->
            val fixtureDirectory = File(context.filesDir, "initialization-viewmodel-test")
            fixtureDirectory.deleteRecursively()
            fixtureDirectory.mkdirs()
            val databaseFile = File(fixtureDirectory, "dictionary.sqlite")
            prepareDatabase(databaseFile, currentBundledManifest(context))
            importer.databaseFile = databaseFile
            AppContainer(
                context = context,
                overrides = AppContainerOverrides(
                    dictionaryDatabaseFile = databaseFile,
                    dictionaryImportService = importer,
                    localDictionaryImportService = importer,
                    dictionarySourceResourceStore = IdleDictionarySourceStore(),
                ),
            )
        }

        return ApplicationProvider.getApplicationContext()
    }

    private fun waitUntil(
        timeoutMillis: Long,
        condition: () -> Boolean,
    ) {
        val deadline = System.currentTimeMillis() + timeoutMillis
        while (System.currentTimeMillis() < deadline) {
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(20))
            if (condition()) {
                return
            }
            Thread.sleep(10)
        }

        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(condition())
    }

    private fun writeDatabaseMetadata(databaseFile: File, bundledManifest: DictionaryManifest?) {
        if (databaseFile.exists()) {
            databaseFile.delete()
        }
        val entryCount = bundledManifest?.entryCount ?: 2
        val senseCount = bundledManifest?.senseCount ?: 3
        val exampleCount = bundledManifest?.exampleCount ?: 1

        DictionaryDatabase.openWritable(databaseFile).use { database ->
            DictionaryDatabase.createSchema(database)
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('built_at', '2026-05-07T00:00:00Z')")
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('source_modified_at', '2026-05-07T00:00:00Z')")
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('entry_count', ?)", arrayOf(entryCount.toString()))
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('sense_count', ?)", arrayOf(senseCount.toString()))
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('example_count', ?)", arrayOf(exampleCount.toString()))
            bundledManifest?.checksumSHA256?.let { checksum ->
                database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('checksum_sha256', ?)", arrayOf(checksum))
            }
        }
    }

    private fun currentBundledManifest(context: Context): DictionaryManifest? {
        return runCatching {
            val manifestString = context.assets
                .open(AppConstants.BUNDLED_DICTIONARY_MANIFEST_ASSET_PATH)
                .use { input -> input.readBytes().toString(Charsets.UTF_8) }
            Json.decodeFromString<DictionaryManifest>(manifestString)
        }.getOrNull()
    }
}

class InitializationViewModelTestApplication : TaigiDictApplication() {
    override fun createAppContainer(): AppContainer {
        return checkNotNull(appContainerFactory) {
            "InitializationViewModelTestApplication.appContainerFactory must be set before use."
        }.invoke(applicationContext)
    }

    companion object {
        var appContainerFactory: ((Context) -> AppContainer)? = null
    }
}

private class BlockingBundledDictionaryImporter(
    private val imported: Boolean,
) : BundledDictionaryImporting {
    lateinit var databaseFile: File

    @Volatile
    var ensureCalls: Int = 0
        private set

    private val releaseLatch = CountDownLatch(1)

    override fun ensureBundledDatabase(
        onProgress: ((DictionaryImportProgress) -> Unit)?,
        forceRebuild: Boolean,
    ): DictionaryImportResult {
        ensureCalls += 1
        releaseLatch.await(5, TimeUnit.SECONDS)
        if (imported) {
            if (databaseFile.exists()) {
                databaseFile.delete()
            }
            DictionaryDatabase.openWritable(databaseFile).use { database ->
                DictionaryDatabase.createSchema(database)
                database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('built_at', '2026-05-07T00:00:00Z')")
                database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('source_modified_at', '2026-05-07T00:00:00Z')")
                database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('entry_count', '2')")
                database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('sense_count', '3')")
                database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('example_count', '1')")
            }
        }

        return DictionaryImportResult(
            databaseFile = databaseFile,
            manifest = DictionaryManifest(
                schemaVersion = 1,
                builtAt = "2026-05-07T00:00:00Z",
                sourceModifiedAt = "2026-05-07T00:00:00Z",
                entryCount = 2,
                senseCount = 3,
                exampleCount = 1,
                entriesFileName = "dictionary_entries.jsonl",
            ),
            imported = imported,
        )
    }

    fun release() {
        releaseLatch.countDown()
    }
}

private class IdleDictionarySourceStore : DictionarySourceResourceManaging {
    private val snapshotFlow = MutableStateFlow(DownloadSnapshot())
    override val snapshot: StateFlow<DownloadSnapshot> = snapshotFlow.asStateFlow()

    override suspend fun refresh(): Result<Unit> = Result.success(Unit)

    override suspend fun restoreBundledSource(): Result<Unit> = Result.success(Unit)

    override suspend fun restoreBundledSourceIfNewer(): Result<Boolean> = Result.success(false)

    override suspend fun downloadSource(): Result<Unit> = Result.success(Unit)

    override suspend fun pauseDownload(): Result<Unit> = Result.success(Unit)

    override suspend fun resumeDownload(): Result<Unit> = Result.success(Unit)
}
