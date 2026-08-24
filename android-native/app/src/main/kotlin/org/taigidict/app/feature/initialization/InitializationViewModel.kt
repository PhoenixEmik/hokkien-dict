package org.taigidict.app.feature.initialization

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.data.database.DictionaryDatabase
import org.taigidict.app.data.importer.BundledDictionaryImporting
import org.taigidict.app.data.importer.DictionaryImportResult
import org.taigidict.app.data.importer.DictionaryManifest
import org.taigidict.app.data.source.DictionarySourceResourceManaging

data class InitializationUiState(
    val phase: InitializationPhase = InitializationPhase.CheckingResources,
    val progress: Float? = null,
    val processedEntries: Int? = null,
    val totalEntries: Int? = null,
    val isReady: Boolean = false,
    val databaseGeneration: Int = 0,
    val errorMessage: String? = null,
)

class InitializationViewModel(application: Application) : AndroidViewModel(application) {
    private val appContainer = (application as TaigiDictApplication).appContainer
    private val bundledImportService = appContainer.dictionaryImportService
    private val localImportService = appContainer.localDictionaryImportService
    private val sourceStore = appContainer.dictionarySourceResourceStore
    private var databaseGeneration = 0
    private val _uiState = MutableStateFlow(initialUiState())
    val uiState: StateFlow<InitializationUiState> = _uiState.asStateFlow()
    private var initializationJob: Job? = null

    init {
        start()
    }

    fun retry() {
        start()
    }

    private fun start() {
        initializationJob?.cancel()
        if (hasUsableExistingDatabase()) {
            publishReadyState()
            initializationJob = viewModelScope.launch {
                withContext(Dispatchers.IO) {
                    refreshDatabaseInBackgroundIfNeeded()
                }
            }
            return
        }

        initializationJob = viewModelScope.launch {
            updateState(
                phase = InitializationPhase.CheckingResources,
                progress = 0.10f,
                processedEntries = null,
                totalEntries = null,
                isReady = false,
                errorMessage = null,
            )

            val rebuildResult = withContext(Dispatchers.IO) {
                runCatching {
                    ensureDictionaryDatabase(reportProgressToUi = true)
                }
            }

            _uiState.value = rebuildResult.fold(
                onSuccess = { rebuilt ->
                    if (rebuilt) {
                        databaseGeneration += 1
                    }
                    readyUiState()
                },
                onFailure = { error ->
                    InitializationUiState(
                        phase = InitializationPhase.Error,
                        progress = null,
                        processedEntries = null,
                        totalEntries = null,
                        isReady = false,
                        databaseGeneration = databaseGeneration,
                        errorMessage = error.message ?: error.toString(),
                    )
                },
            )
        }
    }

    private fun initialUiState(): InitializationUiState {
        return if (hasUsableExistingDatabase()) {
            readyUiState()
        } else {
            InitializationUiState(
                phase = InitializationPhase.CheckingResources,
                progress = 0.10f,
                processedEntries = null,
                totalEntries = null,
                isReady = false,
                databaseGeneration = databaseGeneration,
                errorMessage = null,
            )
        }
    }

    private fun hasUsableExistingDatabase(): Boolean {
        val metadata = runCatching {
            DictionaryDatabase.readMetadata(appContainer.dictionaryDatabaseFile)
        }.getOrNull() ?: return false
        val entryCount = metadata["entry_count"]?.toIntOrNull() ?: return false
        val senseCount = metadata["sense_count"]?.toIntOrNull() ?: return false
        val exampleCount = metadata["example_count"]?.toIntOrNull() ?: return false
        if (entryCount <= 0 || senseCount < 0 || exampleCount < 0) {
            return false
        }

        if (metadata["built_at"].isNullOrBlank()) {
            return false
        }

        val expectedManifest = expectedDictionaryManifestOrNull() ?: return true
        if (
            entryCount != expectedManifest.entryCount ||
            senseCount != expectedManifest.senseCount ||
            exampleCount != expectedManifest.exampleCount
        ) {
            return false
        }

        val expectedChecksum = expectedManifest.checksumSHA256?.takeIf(String::isNotBlank) ?: return true
        return expectedChecksum.equals(metadata[CHECKSUM_METADATA_KEY].orEmpty(), ignoreCase = true)
    }

    private suspend fun refreshDatabaseInBackgroundIfNeeded() {
        runCatching {
            ensureDictionaryDatabase(reportProgressToUi = false)
        }.onSuccess { rebuilt ->
            if (rebuilt) {
                databaseGeneration += 1
                _uiState.value = readyUiState()
            }
        }
    }

    private suspend fun ensureDictionaryDatabase(reportProgressToUi: Boolean): Boolean {
        if (reportProgressToUi) {
            updateState(
                phase = InitializationPhase.RestoringBundledSource,
                progress = 0.15f,
                processedEntries = null,
                totalEntries = null,
                isReady = false,
                errorMessage = null,
            )
        }
        val restoredBundledSource = sourceStore.restoreBundledSourceIfNewer().getOrThrow()

        val importedFromLocal = runCatching {
            importDatabase(
                importService = localImportService,
                baseProgress = 0.20f,
                range = 0.55f,
                reportProgressToUi = reportProgressToUi,
            )
        }.getOrNull()
        if (importedFromLocal != null) {
            return restoredBundledSource || importedFromLocal.imported
        }

        if (reportProgressToUi) {
            updateState(
                phase = InitializationPhase.RestoringBundledSource,
                progress = 0.25f,
                processedEntries = null,
                totalEntries = null,
                isReady = false,
                errorMessage = null,
            )
        }
        sourceStore.restoreBundledSource().getOrThrow()

        val importedAfterRestore = runCatching {
            importDatabase(
                importService = localImportService,
                baseProgress = 0.35f,
                range = 0.45f,
                reportProgressToUi = reportProgressToUi,
            )
        }.getOrNull()
        if (importedAfterRestore != null) {
            return importedAfterRestore.imported
        }

        if (reportProgressToUi) {
            updateState(
                phase = InitializationPhase.DownloadingSource,
                progress = 0.30f,
                processedEntries = null,
                totalEntries = null,
                isReady = false,
                errorMessage = null,
            )
        }
        sourceStore.downloadSource().getOrThrow()

        val importedAfterDownload = runCatching {
            importDatabase(
                importService = localImportService,
                baseProgress = 0.40f,
                range = 0.45f,
                reportProgressToUi = reportProgressToUi,
            )
        }.getOrNull()
        if (importedAfterDownload != null) {
            return importedAfterDownload.imported
        }

        return importDatabase(
            importService = bundledImportService,
            baseProgress = 0.45f,
            range = 0.45f,
            reportProgressToUi = reportProgressToUi,
        ).imported
    }

    private fun publishReadyState() {
        _uiState.value = readyUiState()
    }

    private fun readyUiState(): InitializationUiState {
        return InitializationUiState(
            phase = InitializationPhase.Ready,
            progress = 1f,
            processedEntries = null,
            totalEntries = null,
            isReady = true,
            databaseGeneration = databaseGeneration,
            errorMessage = null,
        )
    }

    private fun importDatabase(
        importService: BundledDictionaryImporting,
        baseProgress: Float,
        range: Float,
        reportProgressToUi: Boolean,
    ): DictionaryImportResult {
        return importService.ensureBundledDatabase(onProgress = { progress ->
            if (reportProgressToUi) {
                updateState(
                    phase = InitializationPhase.RebuildingDatabase,
                    progress = baseProgress + (progress.fraction * range),
                    processedEntries = progress.processedEntries,
                    totalEntries = progress.totalEntries,
                    isReady = false,
                    errorMessage = null,
                )
            }
        })
    }

    private fun updateState(
        phase: InitializationPhase,
        progress: Float?,
        processedEntries: Int?,
        totalEntries: Int?,
        isReady: Boolean,
        errorMessage: String?,
    ) {
        _uiState.value = InitializationUiState(
            phase = phase,
            progress = progress,
            processedEntries = processedEntries,
            totalEntries = totalEntries,
            isReady = isReady,
            databaseGeneration = databaseGeneration,
            errorMessage = errorMessage,
        )
    }

    private fun bundledDictionaryManifestOrNull(): DictionaryManifest? {
        return runCatching {
            val manifestString = appContainer.appContext.assets
                .open(appContainer.bundledDictionaryManifestAssetPath)
                .use { input -> input.readBytes().toString(Charsets.UTF_8) }
            ManifestJson.decodeFromString<DictionaryManifest>(manifestString)
        }.getOrNull()
    }

    private fun localDictionaryManifestOrNull(): DictionaryManifest? {
        return runCatching {
            val manifestFile = appContainer.localDictionarySourceDirectory.resolve("dictionary_manifest.json")
            val manifestString = manifestFile.readBytes().toString(Charsets.UTF_8)
            ManifestJson.decodeFromString<DictionaryManifest>(manifestString)
        }.getOrNull()
    }

    private fun expectedDictionaryManifestOrNull(): DictionaryManifest? {
        val bundledManifest = bundledDictionaryManifestOrNull()
        val localManifest = localDictionaryManifestOrNull()
        return when {
            bundledManifest == null -> localManifest
            localManifest == null -> bundledManifest
            bundledManifest.isNewerThan(localManifest) -> bundledManifest
            else -> localManifest
        }
    }

    private fun DictionaryManifest.isNewerThan(other: DictionaryManifest): Boolean {
        val checksum = checksumSHA256?.takeIf(String::isNotBlank)
        val otherChecksum = other.checksumSHA256?.takeIf(String::isNotBlank)
        if (checksum != null && checksum.equals(otherChecksum, ignoreCase = true)) {
            return false
        }

        val sourceModifiedAt = sourceModifiedAt?.takeIf(String::isNotBlank)
        val otherSourceModifiedAt = other.sourceModifiedAt?.takeIf(String::isNotBlank)
        if (sourceModifiedAt != null && otherSourceModifiedAt != null) {
            return sourceModifiedAt > otherSourceModifiedAt
        }

        return this != other
    }

    private companion object {
        const val CHECKSUM_METADATA_KEY = "checksum_sha256"
        val ManifestJson = Json {
            ignoreUnknownKeys = true
        }
    }
}
