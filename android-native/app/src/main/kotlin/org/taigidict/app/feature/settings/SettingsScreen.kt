package org.taigidict.app.feature.settings

import android.text.format.Formatter
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.TextButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.data.audio.AudioArchiveDownloadSnapshot
import org.taigidict.app.data.audio.AudioArchiveDownloadState
import org.taigidict.app.data.audio.DictionaryAudioArchiveType

@Composable
fun SettingsScreen(assetDirectory: String) {
    val context = LocalContext.current
    val appContainer = (context.applicationContext as TaigiDictApplication).appContainer
    val audioArchiveManager = appContainer.offlineAudioArchiveManager
    val wordSnapshot = audioArchiveManager.snapshotFlow(DictionaryAudioArchiveType.Word).collectAsStateWithLifecycle().value
    val sentenceSnapshot = audioArchiveManager.snapshotFlow(DictionaryAudioArchiveType.Sentence).collectAsStateWithLifecycle().value
    val viewModel: SettingsViewModel = viewModel()
    val uiState = viewModel.uiState.collectAsStateWithLifecycle().value

    LaunchedEffect(audioArchiveManager) {
        audioArchiveManager.refreshAll()
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = stringResource(R.string.settings_title),
                    style = MaterialTheme.typography.headlineMedium,
                )
                Text(
                    text = stringResource(R.string.settings_placeholder_body),
                    style = MaterialTheme.typography.bodyLarge,
                )
            }
        }

        item {
            DictionaryMaintenanceCard(
                uiState = uiState,
                onRebuild = viewModel::rebuildDatabase,
                onClear = viewModel::clearDatabase,
            )
        }

        item {
            Text(
                text = stringResource(R.string.settings_offline_audio_title),
                style = MaterialTheme.typography.titleMedium,
            )
        }

        items(
            listOf(
                DictionaryAudioArchiveType.Word to wordSnapshot,
                DictionaryAudioArchiveType.Sentence to sentenceSnapshot,
            ),
            key = { (type, _) -> type.storageKey },
        ) { (type, snapshot) ->
            AudioArchiveResourceCard(
                type = type,
                snapshot = snapshot,
                onAction = { action ->
                    when (action) {
                        AudioArchiveAction.Download -> audioArchiveManager.startDownload(type)
                        AudioArchiveAction.Pause -> audioArchiveManager.pauseDownload(type)
                        AudioArchiveAction.Resume -> audioArchiveManager.resumeDownload(type)
                        AudioArchiveAction.Redownload -> audioArchiveManager.restartDownload(type)
                    }
                },
            )
        }

        item {
            Text(
                text = stringResource(R.string.bundled_package_label, assetDirectory),
                style = MaterialTheme.typography.bodyMedium,
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun DictionaryMaintenanceCard(
    uiState: SettingsUiState,
    onRebuild: () -> Unit,
    onClear: () -> Unit,
) {
    Card {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                text = stringResource(R.string.settings_dictionary_title),
                style = MaterialTheme.typography.titleMedium,
            )
            Text(
                text = stringResource(R.string.settings_database_path_label, uiState.databasePath),
                style = MaterialTheme.typography.bodyMedium,
            )
            if (uiState.bundle != null) {
                Text(
                    text = stringResource(R.string.settings_entry_count_label, uiState.bundle.entryCount),
                    style = MaterialTheme.typography.bodyMedium,
                )
                Text(
                    text = stringResource(R.string.settings_sense_count_label, uiState.bundle.senseCount),
                    style = MaterialTheme.typography.bodyMedium,
                )
                Text(
                    text = stringResource(R.string.settings_example_count_label, uiState.bundle.exampleCount),
                    style = MaterialTheme.typography.bodyMedium,
                )
            } else {
                Text(
                    text = stringResource(R.string.settings_dictionary_empty),
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
            uiState.builtAt?.let { builtAt ->
                Text(
                    text = stringResource(R.string.settings_dictionary_built_at, builtAt),
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            uiState.sourceModifiedAt?.let { sourceModifiedAt ->
                Text(
                    text = stringResource(R.string.settings_dictionary_source_updated, sourceModifiedAt),
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            if (uiState.isRunningMaintenance) {
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                Text(
                    text = when (uiState.runningAction) {
                        SettingsMaintenanceAction.Rebuild -> stringResource(R.string.settings_running_rebuild)
                        SettingsMaintenanceAction.Clear -> stringResource(R.string.settings_running_clear)
                        null -> stringResource(R.string.settings_running_rebuild)
                    },
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
            uiState.status?.let { status ->
                Text(
                    text = when (status) {
                        SettingsStatus.DatabaseRebuilt -> stringResource(R.string.settings_status_rebuild_completed)
                        SettingsStatus.DatabaseCleared -> stringResource(R.string.settings_status_clear_completed)
                    },
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
            uiState.errorMessage?.let { errorMessage ->
                Text(
                    text = stringResource(R.string.settings_dictionary_error, errorMessage),
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedButton(
                    onClick = onRebuild,
                    enabled = !uiState.isRunningMaintenance,
                ) {
                    Text(text = stringResource(R.string.settings_action_rebuild))
                }
                TextButton(
                    onClick = onClear,
                    enabled = !uiState.isRunningMaintenance,
                ) {
                    Text(text = stringResource(R.string.settings_action_clear))
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun AudioArchiveResourceCard(
    type: DictionaryAudioArchiveType,
    snapshot: AudioArchiveDownloadSnapshot,
    onAction: (AudioArchiveAction) -> Unit,
) {
    val context = LocalContext.current
    val title = when (type) {
        DictionaryAudioArchiveType.Word -> stringResource(R.string.settings_word_audio)
        DictionaryAudioArchiveType.Sentence -> stringResource(R.string.settings_sentence_audio)
    }
    val fileSize = Formatter.formatFileSize(context, type.archiveBytes)
    val downloadedSize = Formatter.formatFileSize(context, snapshot.downloadedBytes)
    val totalSize = Formatter.formatFileSize(
        context,
        if (snapshot.totalBytes > 0) snapshot.totalBytes else type.archiveBytes,
    )
    val statusText = when (snapshot.state) {
        AudioArchiveDownloadState.Idle -> stringResource(R.string.settings_audio_status_idle, fileSize)
        AudioArchiveDownloadState.Downloading -> stringResource(
            R.string.settings_audio_status_downloading,
            downloadedSize,
            totalSize,
        )
        AudioArchiveDownloadState.Paused -> stringResource(
            R.string.settings_audio_status_paused,
            downloadedSize,
            totalSize,
        )
        AudioArchiveDownloadState.Completed -> stringResource(
            R.string.settings_audio_status_completed,
            downloadedSize,
        )
        AudioArchiveDownloadState.Failed -> stringResource(
            R.string.settings_audio_status_failed,
            snapshot.errorMessage ?: stringResource(R.string.unknown_error),
        )
    }

    Card {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
            )
            Text(
                text = type.archiveFileName,
                style = MaterialTheme.typography.bodyMedium,
            )
            Text(
                text = statusText,
                style = MaterialTheme.typography.bodyMedium,
            )
            snapshot.progress?.let { progress ->
                if (snapshot.state == AudioArchiveDownloadState.Downloading || snapshot.state == AudioArchiveDownloadState.Paused) {
                    LinearProgressIndicator(progress = { progress.coerceIn(0f, 1f) })
                }
            }
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                availableActions(snapshot).forEach { action ->
                    OutlinedButton(onClick = { onAction(action) }) {
                        Text(text = action.label())
                    }
                }
            }
        }
    }
}

@Composable
private fun AudioArchiveAction.label(): String {
    return when (this) {
        AudioArchiveAction.Download -> stringResource(R.string.settings_audio_action_download)
        AudioArchiveAction.Pause -> stringResource(R.string.settings_audio_action_pause)
        AudioArchiveAction.Resume -> stringResource(R.string.settings_audio_action_resume)
        AudioArchiveAction.Redownload -> stringResource(R.string.settings_audio_action_redownload)
    }
}

private fun availableActions(snapshot: AudioArchiveDownloadSnapshot): List<AudioArchiveAction> {
    return when (snapshot.state) {
        AudioArchiveDownloadState.Idle -> listOf(AudioArchiveAction.Download)
        AudioArchiveDownloadState.Downloading -> listOf(AudioArchiveAction.Pause, AudioArchiveAction.Redownload)
        AudioArchiveDownloadState.Paused -> listOf(AudioArchiveAction.Resume, AudioArchiveAction.Redownload)
        AudioArchiveDownloadState.Completed -> listOf(AudioArchiveAction.Redownload)
        AudioArchiveDownloadState.Failed -> listOf(AudioArchiveAction.Redownload)
    }
}

private enum class AudioArchiveAction {
    Download,
    Pause,
    Resume,
    Redownload,
}
