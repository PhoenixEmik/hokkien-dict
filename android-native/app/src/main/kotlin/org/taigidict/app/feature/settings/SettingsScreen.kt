package org.taigidict.app.feature.settings

import android.text.format.Formatter
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.Build
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.TextButton
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.getValue
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.core.settings.AppLanguagePreference
import org.taigidict.app.core.settings.AppThemePreference
import org.taigidict.app.data.audio.AudioArchiveDownloadSnapshot
import org.taigidict.app.data.audio.AudioArchiveDownloadState
import org.taigidict.app.data.audio.DictionaryAudioArchiveType
import org.taigidict.app.feature.info.AppDocument
import org.taigidict.app.feature.info.AppDocumentViewer

private val RootHorizontalPadding = 16.dp
private val RootVerticalPadding = 16.dp
private val RootTopContentPadding = 16.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    assetDirectory: String,
    onDictionaryDataChanged: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    var selectedDocument by rememberSaveable { mutableStateOf<AppDocument?>(null) }
    var pendingAction by rememberSaveable { mutableStateOf<SettingsDangerousAction?>(null) }
    var showAdvancedSettings by rememberSaveable { mutableStateOf(false) }
    var showThemeDialog by rememberSaveable { mutableStateOf(false) }
    var showLanguageDialog by rememberSaveable { mutableStateOf(false) }
    val context = LocalContext.current
    val appContainer = (context.applicationContext as TaigiDictApplication).appContainer
    val audioArchiveManager = appContainer.offlineAudioArchiveManager
    val wordSnapshot = audioArchiveManager.snapshotFlow(DictionaryAudioArchiveType.Word).collectAsStateWithLifecycle().value
    val sentenceSnapshot = audioArchiveManager.snapshotFlow(DictionaryAudioArchiveType.Sentence).collectAsStateWithLifecycle().value
    val viewModel: SettingsViewModel = viewModel()
    val uiState = viewModel.uiState.collectAsStateWithLifecycle().value

    val currentDocument = selectedDocument
    if (currentDocument != null) {
        AppDocumentViewer(
            document = currentDocument,
            onBack = { selectedDocument = null },
        )
        return
    }

    pendingAction?.let { action ->
        AlertDialog(
            onDismissRequest = { pendingAction = null },
            title = {
                Text(text = stringResource(R.string.settings_confirm_title))
            },
            text = {
                Text(text = action.message())
            },
            dismissButton = {
                TextButton(onClick = { pendingAction = null }) {
                    Text(text = stringResource(R.string.settings_confirm_cancel))
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        when (action) {
                            SettingsDangerousAction.RebuildDatabase -> viewModel.rebuildDatabase()
                            SettingsDangerousAction.ClearDatabase -> viewModel.clearDatabase()
                            SettingsDangerousAction.RestoreDictionarySource -> viewModel.restoreDictionarySource()
                            SettingsDangerousAction.DownloadDictionarySource -> viewModel.downloadDictionarySource()
                            SettingsDangerousAction.RedownloadWordArchive -> {
                                audioArchiveManager.restartDownload(DictionaryAudioArchiveType.Word)
                            }
                            SettingsDangerousAction.RedownloadSentenceArchive -> {
                                audioArchiveManager.restartDownload(DictionaryAudioArchiveType.Sentence)
                            }
                        }
                        pendingAction = null
                    },
                ) {
                    Text(text = stringResource(R.string.settings_confirm_continue))
                }
            },
        )
    }

    if (showThemeDialog) {
        PreferenceSelectionDialog(
            title = stringResource(R.string.settings_theme_title),
            options = AppThemePreference.entries,
            selectedOption = uiState.themePreference,
            optionLabel = { it.displayLabel() },
            onSelect = {
                viewModel.setThemePreference(it)
                showThemeDialog = false
            },
            onDismiss = { showThemeDialog = false },
        )
    }

    if (showLanguageDialog) {
        PreferenceSelectionDialog(
            title = stringResource(R.string.settings_language_title),
            options = AppLanguagePreference.entries,
            selectedOption = uiState.languagePreference,
            optionLabel = { it.displayLabel() },
            onSelect = {
                viewModel.setLanguagePreference(it)
                showLanguageDialog = false
            },
            onDismiss = { showLanguageDialog = false },
        )
    }

    if (showAdvancedSettings) {
        AdvancedSettingsScreen(
            uiState = uiState,
            sourceSnapshot = uiState.sourceSnapshot,
            wordSnapshot = wordSnapshot,
            sentenceSnapshot = sentenceSnapshot,
            assetDirectory = assetDirectory,
            modifier = modifier,
            onBack = { showAdvancedSettings = false },
            onRebuild = {
                pendingAction = SettingsDangerousAction.RebuildDatabase
            },
            onClear = {
                pendingAction = SettingsDangerousAction.ClearDatabase
            },
            onSourceAction = { action ->
                when (action) {
                    DictionarySourceAction.Restore -> {
                        pendingAction = SettingsDangerousAction.RestoreDictionarySource
                    }

                    DictionarySourceAction.Download -> {
                        pendingAction = SettingsDangerousAction.DownloadDictionarySource
                    }

                    DictionarySourceAction.Pause -> viewModel.pauseDictionarySourceDownload()
                    DictionarySourceAction.Resume -> viewModel.resumeDictionarySourceDownload()
                }
            },
            onAudioAction = { type, action ->
                when (action) {
                    AudioArchiveAction.Download -> audioArchiveManager.startDownload(type)
                    AudioArchiveAction.Pause -> audioArchiveManager.pauseDownload(type)
                    AudioArchiveAction.Resume -> audioArchiveManager.resumeDownload(type)
                    AudioArchiveAction.Redownload -> {
                        pendingAction = when (type) {
                            DictionaryAudioArchiveType.Word -> SettingsDangerousAction.RedownloadWordArchive
                            DictionaryAudioArchiveType.Sentence -> SettingsDangerousAction.RedownloadSentenceArchive
                        }
                    }
                }
            },
        )
        return
    }

    LaunchedEffect(audioArchiveManager) {
        audioArchiveManager.refreshAll()
    }

    LaunchedEffect(uiState.status) {
        if (uiState.status != null) {
            onDictionaryDataChanged()
        }
    }

    Scaffold(
        modifier = modifier,
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Top + WindowInsetsSides.Horizontal,
        ),
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = RootHorizontalPadding)
                .padding(top = RootTopContentPadding, bottom = RootVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                Text(
                    text = stringResource(R.string.settings_title),
                    style = MaterialTheme.typography.headlineLarge,
                )
            }

            item {
                SectionHeader(text = stringResource(R.string.settings_display_section))
            }

            item {
                DisplaySettingsCard(
                    selectedLanguage = uiState.languagePreference,
                    selectedTheme = uiState.themePreference,
                    currentScale = uiState.readingTextScale,
                    onOpenLanguage = { showLanguageDialog = true },
                    onOpenTheme = { showThemeDialog = true },
                    onScaleChanged = viewModel::setReadingTextScale,
                )
            }

            item {
                SectionHeader(text = stringResource(R.string.settings_info_section))
            }

            item {
                InfoAndMaintenanceCard(
                    onOpenAdvancedSettings = { showAdvancedSettings = true },
                    onOpenAbout = { selectedDocument = AppDocument.About },
                    onOpenReference = { selectedDocument = AppDocument.ReferenceLinks },
                )
            }

            item {
                SectionHeader(text = stringResource(R.string.settings_offline_audio_title))
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
                            AudioArchiveAction.Redownload -> {
                                pendingAction = when (type) {
                                    DictionaryAudioArchiveType.Word -> SettingsDangerousAction.RedownloadWordArchive
                                    DictionaryAudioArchiveType.Sentence -> SettingsDangerousAction.RedownloadSentenceArchive
                                }
                            }
                        }
                    },
                )
            }
        }
    }
}

@Composable
private fun SectionHeader(
    text: String,
) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = 2.dp),
    )
}

@Composable
private fun DisplaySettingsCard(
    selectedLanguage: AppLanguagePreference,
    selectedTheme: AppThemePreference,
    currentScale: Double,
    onOpenLanguage: () -> Unit,
    onOpenTheme: () -> Unit,
    onScaleChanged: (Double) -> Unit,
) {
    Card {
        Column(modifier = Modifier.fillMaxWidth()) {
            SettingsNavigationRow(
                title = stringResource(R.string.settings_language_title),
                value = selectedLanguage.displayLabel(),
                onClick = onOpenLanguage,
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp)
            SettingsNavigationRow(
                title = stringResource(R.string.settings_theme_title),
                value = selectedTheme.displayLabel(),
                onClick = onOpenTheme,
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = stringResource(R.string.settings_text_scale_title),
                        style = MaterialTheme.typography.titleMedium,
                    )
                    Text(
                        text = String.format("%.2fx", currentScale),
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                Slider(
                    value = currentScale.toFloat(),
                    onValueChange = { onScaleChanged(it.toDouble()) },
                    valueRange = org.taigidict.app.core.settings.AppSettingsConstants.MIN_READING_TEXT_SCALE.toFloat()
                        ..org.taigidict.app.core.settings.AppSettingsConstants.MAX_READING_TEXT_SCALE.toFloat(),
                    steps = org.taigidict.app.core.settings.AppSettingsConstants.READING_TEXT_SCALE_DIVISIONS,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}

@Composable
private fun SettingsNavigationRow(
    title: String,
    value: String,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
        )

        Row(
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = value,
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Icon(
                imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun InfoAndMaintenanceCard(
    onOpenAdvancedSettings: () -> Unit,
    onOpenAbout: () -> Unit,
    onOpenReference: () -> Unit,
) {
    Card {
        Column(modifier = Modifier.fillMaxWidth()) {
            ListItem(
                modifier = Modifier.clickable(onClick = onOpenAdvancedSettings),
                leadingContent = {
                    Icon(
                        imageVector = Icons.Outlined.Build,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                    )
                },
                headlineContent = {
                    Text(
                        text = stringResource(R.string.settings_advanced_title),
                        style = MaterialTheme.typography.titleLarge,
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
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp)
            ListItem(
                modifier = Modifier.clickable(onClick = onOpenAbout),
                leadingContent = {
                    Icon(
                        imageVector = Icons.Outlined.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                    )
                },
                headlineContent = {
                    Text(
                        text = stringResource(R.string.settings_info_about),
                        style = MaterialTheme.typography.titleLarge,
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
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp)
            ListItem(
                modifier = Modifier.clickable(onClick = onOpenReference),
                leadingContent = {
                    Icon(
                        imageVector = Icons.AutoMirrored.Outlined.MenuBook,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                    )
                },
                headlineContent = {
                    Text(
                        text = stringResource(R.string.settings_info_reference),
                        style = MaterialTheme.typography.titleLarge,
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
        }
    }
}

@Composable
private fun <T> PreferenceSelectionDialog(
    title: String,
    options: List<T>,
    selectedOption: T,
    optionLabel: @Composable (T) -> String,
    onSelect: (T) -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = title)
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                options.forEach { option ->
                    val selected = option == selectedOption
                    ListItem(
                        modifier = Modifier.clickable {
                            onSelect(option)
                        },
                        headlineContent = {
                            Text(text = optionLabel(option))
                        },
                        trailingContent = {
                            if (selected) {
                                Text(
                                    text = "✓",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = MaterialTheme.colorScheme.primary,
                                )
                            }
                        },
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(text = stringResource(R.string.settings_confirm_cancel))
            }
        },
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AdvancedSettingsScreen(
    uiState: SettingsUiState,
    sourceSnapshot: org.taigidict.app.data.source.DownloadSnapshot,
    wordSnapshot: AudioArchiveDownloadSnapshot,
    sentenceSnapshot: AudioArchiveDownloadSnapshot,
    assetDirectory: String,
    modifier: Modifier = Modifier,
    onBack: () -> Unit,
    onRebuild: () -> Unit,
    onClear: () -> Unit,
    onSourceAction: (DictionarySourceAction) -> Unit,
    onAudioAction: (DictionaryAudioArchiveType, AudioArchiveAction) -> Unit,
) {
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = {
                    Text(text = stringResource(R.string.settings_advanced_title))
                },
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
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                Text(
                    text = stringResource(R.string.settings_advanced_body),
                    style = MaterialTheme.typography.bodyMedium,
                )
            }

            item {
                DictionaryMaintenanceCard(
                    uiState = uiState,
                    onRebuild = onRebuild,
                    onClear = onClear,
                )
            }

            item {
                DictionarySourceCard(
                    snapshot = sourceSnapshot,
                    onAction = onSourceAction,
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
                        onAudioAction(type, action)
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
}

@Composable
private fun AdvancedSettingsEntryCard(
    onOpenAdvancedSettings: () -> Unit,
) {
    Card {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = stringResource(R.string.settings_advanced_title),
                style = MaterialTheme.typography.titleMedium,
            )
            Text(
                text = stringResource(R.string.settings_advanced_body),
                style = MaterialTheme.typography.bodyMedium,
            )
            OutlinedButton(onClick = onOpenAdvancedSettings) {
                Text(text = stringResource(R.string.settings_advanced_open))
            }
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
            verticalArrangement = Arrangement.spacedBy(12.dp),
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
            verticalArrangement = Arrangement.spacedBy(12.dp),
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

private enum class DictionarySourceAction {
    Restore,
    Download,
    Pause,
    Resume,
}

@Composable
private fun DictionarySourceAction.label(): String {
    return when (this) {
        DictionarySourceAction.Restore -> stringResource(R.string.settings_source_action_restore)
        DictionarySourceAction.Download -> stringResource(R.string.settings_source_action_download)
        DictionarySourceAction.Pause -> stringResource(R.string.settings_source_action_pause)
        DictionarySourceAction.Resume -> stringResource(R.string.settings_source_action_resume)
    }
}

private fun availableSourceActions(
    snapshot: org.taigidict.app.data.source.DownloadSnapshot,
): List<DictionarySourceAction> {
    return when (snapshot.state) {
        org.taigidict.app.data.source.DownloadSnapshot.State.Downloading -> {
            listOf(DictionarySourceAction.Pause)
        }

        org.taigidict.app.data.source.DownloadSnapshot.State.Paused -> {
            listOf(DictionarySourceAction.Resume)
        }

        else -> {
            listOf(DictionarySourceAction.Restore, DictionarySourceAction.Download)
        }
    }
}

private enum class SettingsDangerousAction {
    RebuildDatabase,
    ClearDatabase,
    RestoreDictionarySource,
    DownloadDictionarySource,
    RedownloadWordArchive,
    RedownloadSentenceArchive,
}

@Composable
private fun SettingsDangerousAction.message(): String {
    return when (this) {
        SettingsDangerousAction.RebuildDatabase ->
            stringResource(R.string.settings_confirm_rebuild_database)
        SettingsDangerousAction.ClearDatabase ->
            stringResource(R.string.settings_confirm_clear_database)
        SettingsDangerousAction.RestoreDictionarySource ->
            stringResource(R.string.settings_confirm_restore_source)
        SettingsDangerousAction.DownloadDictionarySource ->
            stringResource(R.string.settings_confirm_download_source)
        SettingsDangerousAction.RedownloadWordArchive ->
            stringResource(R.string.settings_confirm_redownload_word_audio)
        SettingsDangerousAction.RedownloadSentenceArchive ->
            stringResource(R.string.settings_confirm_redownload_sentence_audio)
    }
}

@Composable
private fun SettingsInfoCard(
    onOpenDocument: (AppDocument) -> Unit,
) {
    Card {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = stringResource(R.string.settings_info_title),
                style = MaterialTheme.typography.titleMedium,
            )
            Text(
                text = stringResource(R.string.settings_info_body),
                style = MaterialTheme.typography.bodyMedium,
            )
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedButton(onClick = { onOpenDocument(AppDocument.About) }) {
                    Text(text = stringResource(R.string.settings_info_about))
                }
                OutlinedButton(onClick = { onOpenDocument(AppDocument.PrivacyPolicy) }) {
                    Text(text = stringResource(R.string.settings_info_privacy_policy))
                }
                OutlinedButton(onClick = { onOpenDocument(AppDocument.DataLicense) }) {
                    Text(text = stringResource(R.string.settings_info_data_license))
                }
                OutlinedButton(onClick = { onOpenDocument(AppDocument.OpenSourceLicense) }) {
                    Text(text = stringResource(R.string.settings_info_open_source_license))
                }
                OutlinedButton(onClick = { onOpenDocument(AppDocument.ReferenceLinks) }) {
                    Text(text = stringResource(R.string.settings_info_reference))
                }
            }
        }
    }
}

@Composable
private fun ThemePreferenceCard(
    selectedTheme: AppThemePreference,
    onThemeSelected: (AppThemePreference) -> Unit,
) {
    Card {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = stringResource(R.string.settings_theme_title),
                style = MaterialTheme.typography.titleMedium,
            )
            Column(modifier = Modifier.selectableGroup()) {
                AppThemePreference.entries.forEach { pref ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .selectable(
                                selected = selectedTheme == pref,
                                onClick = { onThemeSelected(pref) },
                                role = Role.RadioButton,
                            )
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(
                            selected = selectedTheme == pref,
                            onClick = null,
                        )
                        Text(
                            text = pref.displayLabel(),
                            modifier = Modifier.padding(start = 12.dp),
                            style = MaterialTheme.typography.bodyLarge,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun AppThemePreference.displayLabel(): String = when (this) {
    AppThemePreference.System -> stringResource(R.string.settings_theme_system)
    AppThemePreference.Light -> stringResource(R.string.settings_theme_light)
    AppThemePreference.Dark -> stringResource(R.string.settings_theme_dark)
}

@Composable
private fun LanguagePreferenceCard(
    selectedLanguage: AppLanguagePreference,
    onLanguageSelected: (AppLanguagePreference) -> Unit,
) {
    Card {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = stringResource(R.string.settings_language_title),
                style = MaterialTheme.typography.titleMedium,
            )
            Column(modifier = Modifier.selectableGroup()) {
                AppLanguagePreference.entries.forEach { pref ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .selectable(
                                selected = selectedLanguage == pref,
                                onClick = { onLanguageSelected(pref) },
                                role = Role.RadioButton,
                            )
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(
                            selected = selectedLanguage == pref,
                            onClick = null,
                        )
                        Text(
                            text = pref.displayLabel(),
                            modifier = Modifier.padding(start = 12.dp),
                            style = MaterialTheme.typography.bodyLarge,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun AppLanguagePreference.displayLabel(): String = when (this) {
    AppLanguagePreference.System -> stringResource(R.string.settings_language_system)
    AppLanguagePreference.TraditionalChinese -> stringResource(R.string.settings_language_traditional_chinese)
    AppLanguagePreference.SimplifiedChinese -> stringResource(R.string.settings_language_simplified_chinese)
    AppLanguagePreference.English -> stringResource(R.string.settings_language_english)
}

@Composable
private fun DictionarySourceCard(
    snapshot: org.taigidict.app.data.source.DownloadSnapshot,
    onAction: (DictionarySourceAction) -> Unit,
) {
    val context = LocalContext.current
    Card {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = stringResource(R.string.settings_dictionary_source_title),
                style = MaterialTheme.typography.titleMedium,
            )

            val stateLabel = snapshot.state.label()
            val sizeLabel = snapshot.totalBytes?.let { total ->
                Formatter.formatFileSize(context, total)
            } ?: "?"

            Text(
                text = "$stateLabel · $sizeLabel",
                style = MaterialTheme.typography.bodyMedium,
            )

            if (snapshot.progress != null && snapshot.state == org.taigidict.app.data.source.DownloadSnapshot.State.Downloading) {
                LinearProgressIndicator(
                    progress = { snapshot.progress!!.toFloat() },
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                availableSourceActions(snapshot).forEach { action ->
                    OutlinedButton(
                        onClick = { onAction(action) },
                        modifier = Modifier.weight(1f),
                    ) {
                        Text(action.label())
                    }
                }
            }
        }
    }
}

@Composable
private fun org.taigidict.app.data.source.DownloadSnapshot.State.label(): String = when (this) {
    org.taigidict.app.data.source.DownloadSnapshot.State.Idle -> stringResource(R.string.source_status_idle)
    org.taigidict.app.data.source.DownloadSnapshot.State.Downloading -> stringResource(R.string.source_status_downloading)
    org.taigidict.app.data.source.DownloadSnapshot.State.Paused -> stringResource(R.string.source_status_paused)
    org.taigidict.app.data.source.DownloadSnapshot.State.Completed -> stringResource(R.string.source_status_completed)
    org.taigidict.app.data.source.DownloadSnapshot.State.Failed -> stringResource(R.string.source_status_failed)
}

@Composable
private fun TextScaleCard(
    currentScale: Double,
    onScaleChanged: (Double) -> Unit,
) {
    Card {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = stringResource(R.string.settings_text_scale_title),
                style = MaterialTheme.typography.titleMedium,
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = stringResource(R.string.settings_text_scale_label),
                    style = MaterialTheme.typography.bodyMedium,
                )
                Text(
                    text = String.format("%.1f", currentScale),
                    style = MaterialTheme.typography.bodyMedium,
                )
            }

            Slider(
                value = currentScale.toFloat(),
                onValueChange = { newValue ->
                    onScaleChanged(newValue.toDouble())
                },
                valueRange = org.taigidict.app.core.settings.AppSettingsConstants.MIN_READING_TEXT_SCALE.toFloat()
                    ..org.taigidict.app.core.settings.AppSettingsConstants.MAX_READING_TEXT_SCALE.toFloat(),
                steps = org.taigidict.app.core.settings.AppSettingsConstants.READING_TEXT_SCALE_DIVISIONS,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

