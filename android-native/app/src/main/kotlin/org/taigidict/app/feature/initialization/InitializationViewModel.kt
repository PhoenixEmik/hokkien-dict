package org.taigidict.app.feature.initialization

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class InitializationUiState(
    val phase: InitializationPhase = InitializationPhase.CheckingResources,
    val progress: Float? = null,
    val isReady: Boolean = false,
)

class InitializationViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(InitializationUiState())
    val uiState: StateFlow<InitializationUiState> = _uiState.asStateFlow()

    init {
        start()
    }

    fun retry() {
        start()
    }

    private fun start() {
        viewModelScope.launch {
            _uiState.value = InitializationUiState(
                phase = InitializationPhase.CheckingResources,
                progress = 0.15f,
                isReady = false,
            )
            _uiState.value = InitializationUiState(
                phase = InitializationPhase.Ready,
                progress = 1f,
                isReady = true,
            )
        }
    }
}
