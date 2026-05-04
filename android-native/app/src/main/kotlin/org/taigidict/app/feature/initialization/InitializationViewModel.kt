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
    val isReady: Boolean = false,
    val databaseGeneration: Int = 0,
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
                isReady = false,
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
                        isReady = false,
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
                        isReady = false,
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
                        isReady = true,
                        databaseGeneration = databaseGeneration,
                    )
                },
                onFailure = {
                    InitializationUiState(
                        phase = InitializationPhase.Error,
                        progress = null,
                        isReady = false,
                        databaseGeneration = databaseGeneration,
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
                isReady = false,
            )
        }
    }

    private fun updateState(
        phase: InitializationPhase,
        progress: Float?,
        isReady: Boolean,
    ) {
        _uiState.value = InitializationUiState(
            phase = phase,
            progress = progress,
            isReady = isReady,
            databaseGeneration = databaseGeneration,
        )
    }
}
