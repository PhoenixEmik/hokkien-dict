package org.taigidict.app.feature.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.widthIn
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
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.ArrowDropDown
import androidx.compose.material.icons.outlined.Build
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.Card
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.TextButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.core.settings.AppLanguagePreference
import org.taigidict.app.core.settings.AppThemePreference
import org.taigidict.app.data.audio.AudioArchiveDownloadSnapshot
import org.taigidict.app.data.audio.DictionaryAudioArchiveType
import org.taigidict.app.feature.info.AboutScreen
import org.taigidict.app.feature.info.ReferenceArticleScreen
import org.taigidict.app.feature.info.LicenseSummaryScreen
import org.taigidict.app.feature.info.ThirdPartyLicensesScreen
import org.taigidict.app.feature.info.AppDocumentViewer
import org.taigidict.app.feature.info.AppDocument

private val RootHorizontalPadding = 16.dp
private val RootVerticalPadding = 16.dp

private enum class SettingsRoute {
    Main,
    About,
    LicenseInfo,
    ThirdPartyLicenses,
    Reference,
    Advanced,
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    assetDirectory: String,
    onDictionaryDataChanged: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    var selectedDocument by rememberSaveable { mutableStateOf<AppDocument?>(null) }
    var route by rememberSaveable { mutableStateOf(SettingsRoute.Main) }
    var pendingAction by rememberSaveable { mutableStateOf<SettingsDangerousAction?>(null) }
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

    val showingRouteScreen = renderRouteScreen(
        route = route,
        modifier = modifier,
        assetDirectory = assetDirectory,
        uiState = uiState,
        onBackToMain = { route = SettingsRoute.Main },
        onBackFromLicenseInfo = { route = SettingsRoute.About },
        onBackFromThirdPartyLicenses = { route = SettingsRoute.LicenseInfo },
        onOpenDocument = { selectedDocument = it },
        onOpenLicenseInfo = { route = SettingsRoute.LicenseInfo },
        onOpenThirdPartyLicenses = { route = SettingsRoute.ThirdPartyLicenses },
        onRebuild = { pendingAction = SettingsDangerousAction.RebuildDatabase },
        onClear = { pendingAction = SettingsDangerousAction.ClearDatabase },
    )
    ConfirmDangerousActionDialog(
        pendingAction = pendingAction,
        onDismiss = { pendingAction = null },
        onConfirm = { action ->
            when (action) {
                SettingsDangerousAction.RebuildDatabase -> viewModel.rebuildDatabase()
                SettingsDangerousAction.ClearDatabase -> viewModel.clearDatabase()
                SettingsDangerousAction.RedownloadWordArchive -> {
                    audioArchiveManager.restartDownload(DictionaryAudioArchiveType.Word)
                }
                SettingsDangerousAction.RedownloadSentenceArchive -> {
                    audioArchiveManager.restartDownload(DictionaryAudioArchiveType.Sentence)
                }
            }
            pendingAction = null
        },
    )
    if (showingRouteScreen) return

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
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = RootHorizontalPadding)
                .padding(top = RootVerticalPadding, bottom = RootVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                SectionHeader(text = stringResource(R.string.settings_display_section))
            }

            item {
                DisplaySettingsCard(
                    selectedLanguage = uiState.languagePreference,
                    selectedTheme = uiState.themePreference,
                    currentScale = uiState.readingTextScale,
                    onSelectLanguage = viewModel::setLanguagePreference,
                    onSelectTheme = viewModel::setThemePreference,
                    onScaleChanged = viewModel::setReadingTextScale,
                )
            }

            item {
                SectionHeader(text = stringResource(R.string.settings_info_section))
            }

            item {
                InfoAndMaintenanceCard(
                    onOpenAdvancedSettings = { route = SettingsRoute.Advanced },
                    onOpenAbout = { route = SettingsRoute.About },
                    onOpenReference = { route = SettingsRoute.Reference },
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
private fun ConfirmDangerousActionDialog(
    pendingAction: SettingsDangerousAction?,
    onDismiss: () -> Unit,
    onConfirm: (SettingsDangerousAction) -> Unit,
) {
    val action = pendingAction ?: return

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = stringResource(R.string.settings_confirm_title))
        },
        text = {
            Text(text = action.message())
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(text = stringResource(R.string.settings_confirm_cancel))
            }
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(action) }) {
                Text(text = stringResource(R.string.settings_confirm_continue))
            }
        },
    )
}

@Composable
private fun renderRouteScreen(
    route: SettingsRoute,
    modifier: Modifier,
    assetDirectory: String,
    uiState: SettingsUiState,
    onBackToMain: () -> Unit,
    onBackFromLicenseInfo: () -> Unit,
    onBackFromThirdPartyLicenses: () -> Unit,
    onOpenDocument: (AppDocument) -> Unit,
    onOpenLicenseInfo: () -> Unit,
    onOpenThirdPartyLicenses: () -> Unit,
    onRebuild: () -> Unit,
    onClear: () -> Unit,
): Boolean {
    return when (route) {
        SettingsRoute.Main -> false
        SettingsRoute.About -> {
            AboutScreen(
                onBack = onBackToMain,
                onOpenDocument = onOpenDocument,
                onOpenLicenses = onOpenLicenseInfo,
            )
            true
        }

        SettingsRoute.LicenseInfo -> {
            LicenseSummaryScreen(
                onBack = onBackFromLicenseInfo,
                onOpenThirdPartyLicenses = onOpenThirdPartyLicenses,
                modifier = modifier,
            )
            true
        }

        SettingsRoute.ThirdPartyLicenses -> {
            ThirdPartyLicensesScreen(
                onBack = onBackFromThirdPartyLicenses,
                modifier = modifier,
            )
            true
        }

        SettingsRoute.Reference -> {
            ReferenceArticleScreen(
                onBack = onBackToMain,
                modifier = modifier,
            )
            true
        }

        SettingsRoute.Advanced -> {
            AdvancedSettingsScreen(
                uiState = uiState,
                assetDirectory = assetDirectory,
                modifier = modifier,
                onBack = onBackToMain,
                onRebuild = onRebuild,
                onClear = onClear,
            )
            true
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
    onSelectLanguage: (AppLanguagePreference) -> Unit,
    onSelectTheme: (AppThemePreference) -> Unit,
    onScaleChanged: (Double) -> Unit,
) {
    Card {
        Column(modifier = Modifier.fillMaxWidth()) {
            PreferenceMenuRow(
                title = stringResource(R.string.settings_language_title),
                value = selectedLanguage.displayLabel(),
                options = AppLanguagePreference.entries,
                selectedOption = selectedLanguage,
                optionLabel = { it.displayLabel() },
                onSelect = onSelectLanguage,
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            PreferenceMenuRow(
                title = stringResource(R.string.settings_theme_title),
                value = selectedTheme.displayLabel(),
                options = AppThemePreference.entries,
                selectedOption = selectedTheme,
                optionLabel = { it.displayLabel() },
                onSelect = onSelectTheme,
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            ListItem(
                headlineContent = {
                    Text(text = stringResource(R.string.settings_text_scale_title))
                },
                trailingContent = {
                    Text(
                        text = String.format("%.1fx", currentScale),
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                },
            )
            Slider(
                value = currentScale.toFloat(),
                onValueChange = { onScaleChanged(it.toDouble()) },
                valueRange = org.taigidict.app.core.settings.AppSettingsConstants.MIN_READING_TEXT_SCALE.toFloat()
                    ..org.taigidict.app.core.settings.AppSettingsConstants.MAX_READING_TEXT_SCALE.toFloat(),
                steps = org.taigidict.app.core.settings.AppSettingsConstants.READING_TEXT_SCALE_STEPS,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 12.dp),
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun <T> PreferenceMenuRow(
    title: String,
    value: String,
    options: List<T>,
    selectedOption: T,
    optionLabel: @Composable (T) -> String,
    onSelect: (T) -> Unit,
) {
    var expanded by androidx.compose.runtime.remember { mutableStateOf(false) }

    ListItem(
        modifier = Modifier.clickable { expanded = true },
        headlineContent = { Text(text = title) },
        trailingContent = {
            Box {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        modifier = Modifier.widthIn(min = 72.dp),
                        text = value,
                        style = MaterialTheme.typography.bodyLarge,
                        textAlign = TextAlign.End,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Icon(
                        imageVector = Icons.Outlined.ArrowDropDown,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                DropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false },
                ) {
                    options.forEach { option ->
                        DropdownMenuItem(
                            text = { Text(text = optionLabel(option)) },
                            onClick = {
                                expanded = false
                                onSelect(option)
                            },
                            trailingIcon = if (option == selectedOption) ({
                                Icon(
                                    imageVector = Icons.Outlined.Check,
                                    contentDescription = null,
                                )
                            }) else null,
                        )
                    }
                }
            }
        },
    )
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
                    Text(text = stringResource(R.string.settings_advanced_title))
                },
                trailingContent = {
                    Icon(
                        imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                },
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
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
                    Text(text = stringResource(R.string.settings_info_about))
                },
                trailingContent = {
                    Icon(
                        imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                },
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
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
                    Text(text = stringResource(R.string.settings_info_reference))
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




private enum class SettingsDangerousAction {
    RebuildDatabase,
    ClearDatabase,
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
        SettingsDangerousAction.RedownloadWordArchive ->
            stringResource(R.string.settings_confirm_redownload_word_audio)
        SettingsDangerousAction.RedownloadSentenceArchive ->
            stringResource(R.string.settings_confirm_redownload_sentence_audio)
    }
}

@Composable
private fun AppThemePreference.displayLabel(): String = when (this) {
    AppThemePreference.System -> stringResource(R.string.settings_theme_system)
    AppThemePreference.Light -> stringResource(R.string.settings_theme_light)
    AppThemePreference.Dark -> stringResource(R.string.settings_theme_dark)
}

@Composable
private fun AppLanguagePreference.displayLabel(): String = when (this) {
    AppLanguagePreference.System -> stringResource(R.string.settings_language_system)
    AppLanguagePreference.TraditionalChinese -> stringResource(R.string.settings_language_traditional_chinese)
    AppLanguagePreference.SimplifiedChinese -> stringResource(R.string.settings_language_simplified_chinese)
    AppLanguagePreference.English -> stringResource(R.string.settings_language_english)
}
