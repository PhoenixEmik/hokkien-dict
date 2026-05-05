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
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.data.importer.BundledDictionaryImporting
import org.taigidict.app.data.importer.DictionaryImportResult
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
    private val _uiState = MutableStateFlow(InitializationUiState())
    val uiState: StateFlow<InitializationUiState> = _uiState.asStateFlow()
    private val appContainer = (application as TaigiDictApplication).appContainer
    private val bundledImportService = appContainer.dictionaryImportService
    private val localImportService = appContainer.localDictionaryImportService
    private val sourceStore = appContainer.dictionarySourceResourceStore
    private var initializationJob: Job? = null
    private var databaseGeneration = 0

    init {
        start()
    }

    fun retry() {
        start()
    }

    private fun start() {
        initializationJob?.cancel()
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
                    // Try local source first (downloaded/restored dictionary package).
                    val importedFromLocal = runCatching {
                        importDatabase(localImportService, baseProgress = 0.20f, range = 0.55f)
                    }.getOrNull()
                    if (importedFromLocal != null) {
                        return@runCatching importedFromLocal.imported
                    }

                    updateState(
                        phase = InitializationPhase.RestoringBundledSource,
                        progress = 0.25f,
                        processedEntries = null,
                        totalEntries = null,
                        isReady = false,
                        errorMessage = null,
                    )
                    sourceStore.restoreBundledSource().getOrThrow()

                    val importedAfterRestore = runCatching {
                        importDatabase(localImportService, baseProgress = 0.35f, range = 0.45f)
                    }.getOrNull()
                    if (importedAfterRestore != null) {
                        return@runCatching importedAfterRestore.imported
                    }

                    updateState(
                        phase = InitializationPhase.DownloadingSource,
                        progress = 0.30f,
                        processedEntries = null,
                        totalEntries = null,
                        isReady = false,
                        errorMessage = null,
                    )
                    sourceStore.downloadSource().getOrThrow()

                    val importedAfterDownload = runCatching {
                        importDatabase(localImportService, baseProgress = 0.40f, range = 0.45f)
                    }.getOrNull()
                    if (importedAfterDownload != null) {
                        return@runCatching importedAfterDownload.imported
                    }

                    importDatabase(bundledImportService, baseProgress = 0.45f, range = 0.45f).imported
                }
            }

            _uiState.value = rebuildResult.fold(
                onSuccess = { rebuilt ->
                    if (rebuilt) {
                        databaseGeneration += 1
                    }
                    InitializationUiState(
                        phase = InitializationPhase.Ready,
                        progress = 1f,
                        processedEntries = null,
                        totalEntries = null,
                        isReady = true,
                        databaseGeneration = databaseGeneration,
                        errorMessage = null,
                    )
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

    private fun importDatabase(
        importService: BundledDictionaryImporting,
        baseProgress: Float,
        range: Float,
    ): DictionaryImportResult {
        return importService.ensureBundledDatabase { progress ->
            updateState(
                phase = InitializationPhase.RebuildingDatabase,
                progress = baseProgress + (progress.fraction * range),
                processedEntries = progress.processedEntries,
                totalEntries = progress.totalEntries,
                isReady = false,
                errorMessage = null,
            )
        }
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
}
