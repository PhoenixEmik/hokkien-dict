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

data class InitializationUiState(
    val phase: InitializationPhase = InitializationPhase.CheckingResources,
    val progress: Float? = null,
    val isReady: Boolean = false,
)

class InitializationViewModel(application: Application) : AndroidViewModel(application) {
    private val _uiState = MutableStateFlow(InitializationUiState())
    val uiState: StateFlow<InitializationUiState> = _uiState.asStateFlow()
    private val dictionaryImportService =
        (application as TaigiDictApplication).appContainer.dictionaryImportService
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
            _uiState.value = InitializationUiState(
                phase = InitializationPhase.CheckingResources,
                progress = 0.15f,
                isReady = false,
            )

            val importSucceeded = withContext(Dispatchers.IO) {
                runCatching {
                    dictionaryImportService.ensureBundledDatabase { progress ->
                        _uiState.value = InitializationUiState(
                            phase = InitializationPhase.RebuildingDatabase,
                            progress = 0.15f + (progress.fraction * 0.85f),
                            isReady = false,
                        )
                    }
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
}
