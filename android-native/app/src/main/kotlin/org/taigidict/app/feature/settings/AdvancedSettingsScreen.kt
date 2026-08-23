package org.taigidict.app.feature.settings

import android.text.format.Formatter
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.Pause
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import java.text.DateFormat
import java.text.NumberFormat
import java.time.OffsetDateTime
import java.util.Date
import java.util.Locale
import org.taigidict.app.R
import org.taigidict.app.data.audio.AudioArchiveDownloadSnapshot
import org.taigidict.app.data.audio.AudioArchiveDownloadState
import org.taigidict.app.data.audio.DictionaryAudioArchiveType
import org.taigidict.app.domain.model.DictionaryBundle
import org.taigidict.app.feature.common.AppListDivider
import org.taigidict.app.feature.common.AppSettingsGroup
import org.taigidict.app.feature.common.AppSettingsListIcon
import org.taigidict.app.feature.common.AppSettingsSectionHeader
import org.taigidict.app.feature.common.appSettingsPageContainerColor
import org.taigidict.app.feature.common.transparentListItemColors

private val AdvancedHorizontalPadding = 16.dp
private val AdvancedVerticalPadding = 16.dp

internal enum class AudioArchiveAction {
    Download,
    Pause,
    Resume,
    Redownload,
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun AdvancedSettingsScreen(
    uiState: SettingsUiState,
    @Suppress("UNUSED_PARAMETER")
    assetDirectory: String,
    wordSnapshot: AudioArchiveDownloadSnapshot,
    sentenceSnapshot: AudioArchiveDownloadSnapshot,
    modifier: Modifier = Modifier,
    onBack: () -> Unit,
    onRebuild: () -> Unit,
    onClear: () -> Unit,
    onAudioArchiveAction: (DictionaryAudioArchiveType, AudioArchiveAction) -> Unit,
) {
    val snackbarHostState = remember { SnackbarHostState() }
    var lastShownStatus by remember { mutableStateOf<SettingsStatus?>(null) }
    var lastShownError by remember { mutableStateOf<String?>(null) }

    val statusMessage = when (uiState.status) {
        SettingsStatus.DatabaseRebuilt -> stringResource(R.string.settings_status_rebuild_completed)
        SettingsStatus.DatabaseCleared -> stringResource(R.string.settings_status_clear_completed)
        null -> null
    }
    val errorMessageForSnackbar = uiState.errorMessage?.let {
        stringResource(R.string.settings_dictionary_error, it)
    }

    LaunchedEffect(statusMessage, uiState.status) {
        val currentStatus = uiState.status ?: return@LaunchedEffect
        if (currentStatus == lastShownStatus || statusMessage == null) {
            return@LaunchedEffect
        }
        snackbarHostState.showSnackbar(statusMessage)
        lastShownStatus = currentStatus
    }

    LaunchedEffect(uiState.errorMessage, errorMessageForSnackbar) {
        val error = uiState.errorMessage ?: return@LaunchedEffect
        val errorMessage = errorMessageForSnackbar ?: return@LaunchedEffect
        if (error == lastShownError) {
            return@LaunchedEffect
        }
        snackbarHostState.showSnackbar(errorMessage)
        lastShownError = error
    }

    Scaffold(
        modifier = modifier,
        containerColor = appSettingsPageContainerColor(),
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Text(text = stringResource(R.string.settings_advanced_title))
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = appSettingsPageContainerColor(),
                ),
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                            contentDescription = stringResource(R.string.settings_advanced_back),
                        )
                    }
                },
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = AdvancedHorizontalPadding)
                .padding(top = AdvancedVerticalPadding, bottom = AdvancedVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                AppSettingsSectionHeader(title = stringResource(R.string.settings_maintenance_section))
            }

            item {
                MaintenanceActionsCard(
                    uiState = uiState,
                    runningAction = uiState.runningAction,
                    wordSnapshot = wordSnapshot,
                    sentenceSnapshot = sentenceSnapshot,
                    onRebuild = onRebuild,
                    onClear = onClear,
                    onAudioArchiveAction = onAudioArchiveAction,
                )
            }

            if (uiState.bundle != null) {
                item {
                    AppSettingsSectionHeader(title = stringResource(R.string.settings_dictionary_title))
                }
                item {
                    DictionarySummaryCard(bundle = uiState.bundle)
                }
            }

            if (uiState.builtAt != null || uiState.sourceModifiedAt != null) {
                item {
                    AppSettingsSectionHeader(title = stringResource(R.string.settings_source_time_title))
                }
                item {
                    DictionaryMetadataCard(
                        builtAt = uiState.builtAt,
                        sourceModifiedAt = uiState.sourceModifiedAt,
                    )
                }
            }

        }
    }
}

@Composable
private fun MaintenanceActionsCard(
    uiState: SettingsUiState,
    runningAction: SettingsMaintenanceAction?,
    wordSnapshot: AudioArchiveDownloadSnapshot,
    sentenceSnapshot: AudioArchiveDownloadSnapshot,
    onRebuild: () -> Unit,
    onClear: () -> Unit,
    onAudioArchiveAction: (DictionaryAudioArchiveType, AudioArchiveAction) -> Unit,
) {
    AppSettingsGroup {
        Column(modifier = Modifier.fillMaxWidth()) {
            ListItem(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(enabled = !uiState.isRunningMaintenance, onClick = onRebuild),
                colors = transparentListItemColors(),
                leadingContent = {
                    AppSettingsListIcon(
                        imageVector = Icons.Outlined.Refresh,
                    )
                },
                headlineContent = {
                    Text(text = stringResource(R.string.settings_action_rebuild))
                },
                trailingContent = {
                    Icon(
                        imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                },
            )

            AppListDivider()

            ListItem(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(enabled = !uiState.isRunningMaintenance, onClick = onClear),
                colors = transparentListItemColors(),
                leadingContent = {
                    AppSettingsListIcon(
                        imageVector = Icons.Outlined.DeleteOutline,
                        tint = MaterialTheme.colorScheme.error,
                    )
                },
                headlineContent = {
                    Text(
                        text = stringResource(R.string.settings_action_clear),
                        color = MaterialTheme.colorScheme.error,
                    )
                },
                trailingContent = {
                    Icon(
                        imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                },
            )

            AppListDivider()

            AudioArchiveMaintenanceRow(
                type = DictionaryAudioArchiveType.Word,
                snapshot = wordSnapshot,
                onClick = { onAudioArchiveAction(DictionaryAudioArchiveType.Word, AudioArchiveAction.Redownload) },
            )

            AppListDivider()

            AudioArchiveMaintenanceRow(
                type = DictionaryAudioArchiveType.Sentence,
                snapshot = sentenceSnapshot,
                onClick = { onAudioArchiveAction(DictionaryAudioArchiveType.Sentence, AudioArchiveAction.Redownload) },
            )

            if (uiState.isRunningMaintenance) {
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                Text(
                    text = when (runningAction) {
                        SettingsMaintenanceAction.Rebuild -> stringResource(R.string.settings_running_rebuild)
                        SettingsMaintenanceAction.Clear -> stringResource(R.string.settings_running_clear)
                        null -> stringResource(R.string.settings_running_rebuild)
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                )
            }
        }
    }
}

@Composable
private fun AudioArchiveMaintenanceRow(
    type: DictionaryAudioArchiveType,
    snapshot: AudioArchiveDownloadSnapshot,
    onClick: () -> Unit,
) {
    val context = LocalContext.current
    val fileSize = Formatter.formatFileSize(context, type.archiveBytes)
    val downloadedSize = Formatter.formatFileSize(context, snapshot.downloadedBytes)
    val totalSize = Formatter.formatFileSize(
        context,
        if (snapshot.totalBytes > 0) snapshot.totalBytes else type.archiveBytes,
    )
    val title = when (type) {
        DictionaryAudioArchiveType.Word -> stringResource(R.string.settings_redownload_word_audio)
        DictionaryAudioArchiveType.Sentence -> stringResource(R.string.settings_redownload_sentence_audio)
    }
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
        AudioArchiveDownloadState.Completed -> null
        AudioArchiveDownloadState.Failed -> stringResource(
            R.string.settings_audio_status_failed,
            snapshot.errorMessage ?: stringResource(R.string.unknown_error),
        )
    }
    val isActionable = snapshot.state == AudioArchiveDownloadState.Completed ||
        snapshot.state == AudioArchiveDownloadState.Failed

    ListItem(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = isActionable, onClick = onClick),
        colors = transparentListItemColors(),
        leadingContent = {
            AppSettingsListIcon(
                imageVector = Icons.Outlined.Refresh,
                tint = snapshot.iconTint(),
            )
        },
        headlineContent = {
            Text(text = title)
        },
        supportingContent = statusText?.let {
            {
                Text(
                    text = it,
                    color = snapshot.statusTextColor(),
                )
            }
        },
        trailingContent = if (isActionable) {
            {
                FilledTonalButton(onClick = onClick) {
                    Text(text = AudioArchiveAction.Redownload.label())
                }
            }
        } else {
            null
        },
    )
}

@Composable
private fun DictionarySummaryCard(
    bundle: DictionaryBundle,
) {
    val locale = LocalContext.current.resources.configuration.locales[0] ?: Locale.getDefault()
    val numberFormatter = NumberFormat.getIntegerInstance(locale)

    AppSettingsGroup {
        Column(modifier = Modifier.fillMaxWidth()) {
            SettingsKeyValueRow(
                key = stringResource(R.string.settings_entry_count_label),
                value = numberFormatter.format(bundle.entryCount),
            )
            AppListDivider()
            SettingsKeyValueRow(
                key = stringResource(R.string.settings_sense_count_label),
                value = numberFormatter.format(bundle.senseCount),
            )
            AppListDivider()
            SettingsKeyValueRow(
                key = stringResource(R.string.settings_example_count_label),
                value = numberFormatter.format(bundle.exampleCount),
            )
        }
    }
}

@Composable
private fun DictionaryMetadataCard(
    builtAt: String?,
    sourceModifiedAt: String?,
) {
    val locale = LocalContext.current.resources.configuration.locales[0] ?: Locale.getDefault()

    AppSettingsGroup {
        Column(modifier = Modifier.fillMaxWidth()) {
            builtAt?.let {
                SettingsKeyValueRow(
                    key = stringResource(R.string.settings_time_built_label),
                    value = formatTimestampForDisplay(raw = it, locale = locale),
                )
            }
            sourceModifiedAt?.let {
                if (builtAt != null) {
                    AppListDivider()
                }
                SettingsKeyValueRow(
                    key = stringResource(R.string.settings_time_source_updated_label),
                    value = formatTimestampForDisplay(raw = it, locale = locale),
                )
            }
        }
    }
}

@Composable
private fun SettingsKeyValueRow(
    key: String,
    value: String,
) {
    ListItem(
        colors = transparentListItemColors(),
        headlineContent = {
            Text(text = key)
        },
        supportingContent = {
            Text(
                text = value,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
    )
}

private fun formatTimestampForDisplay(raw: String, locale: Locale): String {
    return runCatching {
        val instant = OffsetDateTime.parse(raw).toInstant()
        DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT, locale)
            .format(Date.from(instant))
    }.getOrElse {
        raw
    }
}

@Composable
internal fun AudioArchiveResourceCard(
    type: DictionaryAudioArchiveType,
    snapshot: AudioArchiveDownloadSnapshot,
    showRedownloadAction: Boolean = true,
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
        AudioArchiveDownloadState.Completed -> stringResource(R.string.settings_audio_status_completed)
        AudioArchiveDownloadState.Failed -> stringResource(
            R.string.settings_audio_status_failed,
            snapshot.errorMessage ?: stringResource(R.string.unknown_error),
        )
    }
    val actions = availableActions(snapshot, showRedownloadAction)

    AppSettingsGroup {
        ListItem(
            colors = transparentListItemColors(),
            leadingContent = {
                AppSettingsListIcon(
                    imageVector = Icons.Outlined.FileDownload,
                    tint = snapshot.iconTint(),
                )
            },
            headlineContent = {
                Text(text = title)
            },
            supportingContent = {
                Column(
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text(
                        text = statusText,
                        color = snapshot.statusTextColor(),
                    )
                }
            },
            trailingContent = if (actions.isNotEmpty()) {
                {
                    Column(horizontalAlignment = Alignment.End) {
                        actions.forEach { action ->
                            FilledTonalIconButton(onClick = { onAction(action) }) {
                                Icon(
                                    imageVector = action.icon(),
                                    contentDescription = action.label(),
                                )
                            }
                        }
                    }
                }
            } else {
                null
            },
        )
        snapshot.progress?.let { progress ->
            if (snapshot.state == AudioArchiveDownloadState.Downloading || snapshot.state == AudioArchiveDownloadState.Paused) {
                LinearProgressIndicator(
                    progress = { progress.coerceIn(0f, 1f) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                        .padding(bottom = 12.dp),
                )
            }
        }
    }
}

@Composable
private fun AudioArchiveDownloadSnapshot.iconTint() = when (state) {
    AudioArchiveDownloadState.Failed -> MaterialTheme.colorScheme.error
    AudioArchiveDownloadState.Completed,
    AudioArchiveDownloadState.Downloading,
    AudioArchiveDownloadState.Paused
    -> MaterialTheme.colorScheme.primary
    AudioArchiveDownloadState.Idle -> MaterialTheme.colorScheme.onSurfaceVariant
}

@Composable
private fun AudioArchiveDownloadSnapshot.statusTextColor() = when (state) {
    AudioArchiveDownloadState.Failed -> MaterialTheme.colorScheme.error
    AudioArchiveDownloadState.Completed -> MaterialTheme.colorScheme.primary
    AudioArchiveDownloadState.Idle,
    AudioArchiveDownloadState.Downloading,
    AudioArchiveDownloadState.Paused
    -> MaterialTheme.colorScheme.onSurfaceVariant
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

private fun AudioArchiveAction.icon(): ImageVector {
    return when (this) {
        AudioArchiveAction.Download -> Icons.Outlined.FileDownload
        AudioArchiveAction.Pause -> Icons.Outlined.Pause
        AudioArchiveAction.Resume -> Icons.Outlined.PlayArrow
        AudioArchiveAction.Redownload -> Icons.Outlined.Refresh
    }
}

private fun availableActions(
    snapshot: AudioArchiveDownloadSnapshot,
    showRedownloadAction: Boolean,
): List<AudioArchiveAction> {
    return when (snapshot.state) {
        AudioArchiveDownloadState.Idle -> listOf(AudioArchiveAction.Download)
        AudioArchiveDownloadState.Downloading -> listOf(AudioArchiveAction.Pause)
        AudioArchiveDownloadState.Paused -> listOf(AudioArchiveAction.Resume)
        AudioArchiveDownloadState.Completed -> if (showRedownloadAction) {
            listOf(AudioArchiveAction.Redownload)
        } else {
            emptyList()
        }
        AudioArchiveDownloadState.Failed -> if (showRedownloadAction) {
            listOf(AudioArchiveAction.Redownload)
        } else {
            listOf(AudioArchiveAction.Download)
        }
    }
}
