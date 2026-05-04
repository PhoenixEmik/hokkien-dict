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
import org.taigidict.app.data.source.DictionarySourceResourceManaging

data class InitializationUiState(
    val phase: InitializationPhase = InitializationPhase.CheckingResources,
    val progress: Float? = null,
    val isReady: Boolean = false,
)

class InitializationViewModel(application: Application) : AndroidViewModel(application) {
    private val _uiState = MutableStateFlow(InitializationUiState())
    val uiState: StateFlow<InitializationUiState> = _uiState.asStateFlow()
    private val appContainer = (application as TaigiDictApplication).appContainer
    private val bundledImportService = appContainer.dictionaryImportService
    private val localImportService = appContainer.localDictionaryImportService
    private val sourceStore = appContainer.dictionarySourceResourceStore
    private var initializationJob: Job? = null

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

            val importSucceeded = withContext(Dispatchers.IO) {
                runCatching {
                    // Try local source first (downloaded/restored dictionary package).
                    val importedFromLocal = runCatching {
                        importDatabase(localImportService, baseProgress = 0.20f, range = 0.55f)
                    }.isSuccess
                    if (importedFromLocal) {
                        return@runCatching
                    }

                    updateState(
                        phase = InitializationPhase.RestoringBundledSource,
                        progress = 0.25f,
                        isReady = false,
                    )
                    sourceStore.restoreBundledSource().getOrThrow()

                    val importedAfterRestore = runCatching {
                        importDatabase(localImportService, baseProgress = 0.35f, range = 0.45f)
                    }.isSuccess
                    if (importedAfterRestore) {
                        return@runCatching
                    }

                    updateState(
                        phase = InitializationPhase.DownloadingSource,
                        progress = 0.30f,
                        isReady = false,
                    )
                    sourceStore.downloadSource().getOrThrow()

                    val importedAfterDownload = runCatching {
                        importDatabase(localImportService, baseProgress = 0.40f, range = 0.45f)
                    }.isSuccess
                    if (importedAfterDownload) {
                        return@runCatching
                    }

                    importDatabase(bundledImportService, baseProgress = 0.45f, range = 0.45f)
                }.isSuccess
            }

            _uiState.value = if (importSucceeded) {
                InitializationUiState(
                    phase = InitializationPhase.Ready,
                    progress = 1f,
                    isReady = true,
                )
            } else {
                InitializationUiState(
                    phase = InitializationPhase.Error,
                    progress = null,
                    isReady = false,
                )
            }
        }
    }

    private fun importDatabase(
        importService: BundledDictionaryImporting,
        baseProgress: Float,
        range: Float,
    ) {
        importService.ensureBundledDatabase { progress ->
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
        )
    }
}
