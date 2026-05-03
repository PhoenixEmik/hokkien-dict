package org.taigidict.app.feature.settings

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import java.io.File
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.data.database.DictionaryDatabase
import org.taigidict.app.data.importer.BundledDictionaryImporting
import org.taigidict.app.data.repository.DictionaryRepositoryDataSource
import org.taigidict.app.domain.model.DictionaryBundle

data class SettingsUiState(
    val bundle: DictionaryBundle? = null,
    val databasePath: String = "",
    val builtAt: String? = null,
    val sourceModifiedAt: String? = null,
    val isRunningMaintenance: Boolean = false,
    val runningAction: SettingsMaintenanceAction? = null,
    val status: SettingsStatus? = null,
    val errorMessage: String? = null,
)

enum class SettingsMaintenanceAction {
    Rebuild,
    Clear,
}

enum class SettingsStatus {
    DatabaseRebuilt,
    DatabaseCleared,
}

class SettingsViewModel(
    application: Application,
    private val repository: DictionaryRepositoryDataSource,
    private val importService: BundledDictionaryImporting,
    private val databaseFile: File,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : AndroidViewModel(application) {
    constructor(application: Application) : this(
        application = application,
        repository = (application as TaigiDictApplication).appContainer.dictionaryRepository,
        importService = application.appContainer.dictionaryImportService,
        databaseFile = application.appContainer.dictionaryDatabaseFile,
    )

    private val _uiState = MutableStateFlow(
        SettingsUiState(databasePath = databaseFile.path),
    )
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            val snapshot = withContext(ioDispatcher) {
                loadSnapshot()
            }
            _uiState.update { current ->
                current.copy(
                    bundle = snapshot.bundle,
                    builtAt = snapshot.builtAt,
                    sourceModifiedAt = snapshot.sourceModifiedAt,
                    errorMessage = snapshot.errorMessage,
                )
            }
        }
    }

    fun rebuildDatabase() {
        runMaintenance(SettingsMaintenanceAction.Rebuild) {
            if (databaseFile.exists()) {
                databaseFile.delete()
            }
            importService.ensureBundledDatabase()
            SettingsStatus.DatabaseRebuilt
        }
    }

    fun clearDatabase() {
        runMaintenance(SettingsMaintenanceAction.Clear) {
            if (databaseFile.exists()) {
                databaseFile.delete()
            }
            SettingsStatus.DatabaseCleared
        }
    }

    private fun runMaintenance(
        action: SettingsMaintenanceAction,
        operation: () -> SettingsStatus,
    ) {
        if (_uiState.value.isRunningMaintenance) {
            return
        }

        viewModelScope.launch {
            _uiState.update { current ->
                current.copy(
                    isRunningMaintenance = true,
                    runningAction = action,
                    status = null,
                    errorMessage = null,
                )
            }

            val result = withContext(ioDispatcher) {
                runCatching {
                    val status = operation()
                    val snapshot = loadSnapshot()
                    MaintenanceResult(
                        status = status,
                        snapshot = snapshot,
                    )
                }
            }

            _uiState.update { current ->
                result.fold(
                    onSuccess = { success ->
                        current.copy(
                            bundle = success.snapshot.bundle,
                            builtAt = success.snapshot.builtAt,
                            sourceModifiedAt = success.snapshot.sourceModifiedAt,
                            isRunningMaintenance = false,
                            runningAction = null,
                            status = success.status,
                            errorMessage = success.snapshot.errorMessage,
                        )
                    },
                    onFailure = { error ->
                        current.copy(
                            isRunningMaintenance = false,
                            runningAction = null,
                            status = null,
                            errorMessage = error.message ?: error.toString(),
                        )
                    },
                )
            }
        }
    }

    private fun loadSnapshot(): SettingsSnapshot {
        val bundle = runCatching { repository.loadBundle() }.getOrNull()
        val metadata = DictionaryDatabase.readMetadata(databaseFile)
        val metadataError = if (!databaseFile.exists()) {
            null
        } else if (metadata == null) {
            "Failed to read local dictionary metadata."
        } else {
            null
        }

        return SettingsSnapshot(
            bundle = bundle,
            builtAt = metadata?.get("built_at")?.takeIf(String::isNotBlank),
            sourceModifiedAt = metadata?.get("source_modified_at")?.takeIf(String::isNotBlank),
            errorMessage = metadataError,
        )
    }

    private data class SettingsSnapshot(
        val bundle: DictionaryBundle?,
        val builtAt: String?,
        val sourceModifiedAt: String?,
        val errorMessage: String?,
    )

    private data class MaintenanceResult(
        val status: SettingsStatus,
        val snapshot: SettingsSnapshot,
    )
}

private val Application.appContainer
    get() = (this as TaigiDictApplication).appContainer