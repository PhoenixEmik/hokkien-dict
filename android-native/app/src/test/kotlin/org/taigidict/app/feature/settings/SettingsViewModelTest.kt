package org.taigidict.app.feature.settings

import android.app.Application
import androidx.test.core.app.ApplicationProvider
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.taigidict.app.data.database.DictionaryDatabase
import org.taigidict.app.data.importer.BundledDictionaryImporting
import org.taigidict.app.data.importer.DictionaryImportProgress
import org.taigidict.app.data.importer.DictionaryImportResult
import org.taigidict.app.data.importer.DictionaryManifest
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.domain.model.DictionaryBundle
import org.taigidict.app.domain.model.DictionaryEntry

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class SettingsViewModelTest {
    private val dispatcher = StandardTestDispatcher()

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun init_loadsBundleAndMetadata() = runTest(dispatcher) {
        val databaseFile = Files.createTempFile("settings-viewmodel", ".sqlite").toFile()
        seedMetadata(databaseFile)
        val repository = FakeSettingsRepository(
            bundle = DictionaryBundle(
                entryCount = 10,
                senseCount = 20,
                exampleCount = 30,
                databasePath = databaseFile.path,
            ),
        )
        val viewModel = createViewModel(
            repository = repository,
            importService = FakeBundledDictionaryImporter(databaseFile),
            databaseFile = databaseFile,
        )

        advanceUntilIdle()

        val uiState = viewModel.uiState.value
        assertEquals(10, uiState.bundle?.entryCount)
        assertEquals("2026-05-01T12:00:00Z", uiState.builtAt)
        assertEquals("2026-04-20T08:30:00Z", uiState.sourceModifiedAt)
    }

    @Test
    fun rebuildDatabase_refreshesSummaryAndPublishesStatus() = runTest(dispatcher) {
        val databaseFile = Files.createTempFile("settings-rebuild", ".sqlite").toFile()
        seedMetadata(databaseFile)
        val repository = FakeSettingsRepository(
            bundle = DictionaryBundle(
                entryCount = 5,
                senseCount = 8,
                exampleCount = 3,
                databasePath = databaseFile.path,
            ),
        )
        val importer = FakeBundledDictionaryImporter(databaseFile)
        val viewModel = createViewModel(repository, importer, databaseFile)
        advanceUntilIdle()

        viewModel.rebuildDatabase()
        advanceUntilIdle()

        assertTrue(importer.ensureCalls > 0)
        assertEquals(SettingsStatus.DatabaseRebuilt, viewModel.uiState.value.status)
        assertFalse(viewModel.uiState.value.isRunningMaintenance)
    }

    @Test
    fun clearDatabase_removesFileAndClearsBundle() = runTest(dispatcher) {
        val databaseFile = Files.createTempFile("settings-clear", ".sqlite").toFile()
        seedMetadata(databaseFile)
        val repository = FakeSettingsRepository(bundle = null)
        val viewModel = createViewModel(
            repository = repository,
            importService = FakeBundledDictionaryImporter(databaseFile),
            databaseFile = databaseFile,
        )
        advanceUntilIdle()

        viewModel.clearDatabase()
        advanceUntilIdle()

        assertFalse(databaseFile.exists())
        assertEquals(SettingsStatus.DatabaseCleared, viewModel.uiState.value.status)
        assertEquals(null, viewModel.uiState.value.builtAt)
    }

    private fun createViewModel(
        repository: DictionaryRepositoryDataSource,
        importService: BundledDictionaryImporting,
        databaseFile: File,
    ): SettingsViewModel {
        val application = ApplicationProvider.getApplicationContext<Application>()
        return SettingsViewModel(
            application = application,
            repository = repository,
            importService = importService,
            databaseFile = databaseFile,
            settingsStore = FakeAppSettingsStore(),
            ioDispatcher = dispatcher,
        )
    }

    private fun seedMetadata(databaseFile: File) {
        DictionaryDatabase.openWritable(databaseFile).use { database ->
            DictionaryDatabase.createSchema(database)
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('built_at', '2026-05-01T12:00:00Z')")
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('source_modified_at', '2026-04-20T08:30:00Z')")
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('entry_count', '10')")
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('sense_count', '20')")
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('example_count', '30')")
        }
    }
}

private class FakeSettingsRepository(
    private val bundle: DictionaryBundle?,
) : DictionaryRepositoryDataSource {
    override fun loadBundle(): DictionaryBundle {
        return bundle ?: error("missing bundle")
    }

    override fun search(rawQuery: String, limit: Int): List<DictionaryEntry> = emptyList()

    override fun entries(ids: List<Long>): List<DictionaryEntry> = emptyList()

    override fun entry(id: Long): DictionaryEntry? = null

    override fun findLinkedEntry(rawWord: String): DictionaryEntry? = null
}

private class FakeBundledDictionaryImporter(
    private val databaseFile: File,
) : BundledDictionaryImporting {
    var ensureCalls = 0

    override fun ensureBundledDatabase(
        onProgress: ((DictionaryImportProgress) -> Unit)?,
    ): DictionaryImportResult {
        ensureCalls += 1
        if (databaseFile.exists()) {
            databaseFile.delete()
        }
        DictionaryDatabase.openWritable(databaseFile).use { database ->
            DictionaryDatabase.createSchema(database)
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('built_at', '2026-05-03T00:00:00Z')")
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('source_modified_at', '2026-05-01T00:00:00Z')")
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('entry_count', '5')")
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('sense_count', '8')")
            database.execSQL("INSERT INTO dictionary_metadata (key, value) VALUES ('example_count', '3')")
        }
        return DictionaryImportResult(
            databaseFile = databaseFile,
            manifest = DictionaryManifest(
                schemaVersion = 1,
                builtAt = "2026-05-03T00:00:00Z",
                sourceModifiedAt = "2026-05-01T00:00:00Z",
                entryCount = 5,
                senseCount = 8,
                exampleCount = 3,
                entriesFileName = "dictionary_entries.jsonl",
            ),
            imported = true,
        )
    }
}

private class FakeAppSettingsStore : org.taigidict.app.core.settings.AppSettingsStoring {
    private val _themePreference = kotlinx.coroutines.flow.MutableStateFlow(
        org.taigidict.app.core.settings.AppThemePreference.System
    )
    override val themePreference: kotlinx.coroutines.flow.Flow<org.taigidict.app.core.settings.AppThemePreference>
        get() = _themePreference

    override fun setThemePreference(preference: org.taigidict.app.core.settings.AppThemePreference) {
        _themePreference.value = preference
    }
}