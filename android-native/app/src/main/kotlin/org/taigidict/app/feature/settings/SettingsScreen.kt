package org.taigidict.app.feature.settings

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.ArrowDropDown
import androidx.compose.material.icons.outlined.Build
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.StarRate
import androidx.compose.material.icons.outlined.TextFields
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.TextButton
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.core.settings.AppLanguagePreference
import org.taigidict.app.core.settings.AppThemePreference
import org.taigidict.app.data.audio.AudioArchiveDownloadSnapshot
import org.taigidict.app.data.audio.DictionaryAudioArchiveType
import org.taigidict.app.feature.common.AppListDivider
import org.taigidict.app.feature.common.AppSettingsGroup
import org.taigidict.app.feature.common.AppSettingsRowIcon
import org.taigidict.app.feature.common.AppSettingsSectionHeader
import org.taigidict.app.feature.common.appSettingsPageContainerColor
import org.taigidict.app.feature.common.transparentListItemColors
import org.taigidict.app.feature.info.AboutScreen
import org.taigidict.app.feature.info.ReferenceArticleScreen
import org.taigidict.app.feature.info.LicenseSummaryScreen
import org.taigidict.app.feature.info.ThirdPartyLicensesScreen
import org.taigidict.app.feature.info.ThirdPartyLicenseCatalog
import org.taigidict.app.feature.info.ThirdPartyLicenseDetailScreen
import org.taigidict.app.feature.info.AppDocumentViewer
import org.taigidict.app.feature.info.AppDocument

private val RootHorizontalPadding = 16.dp
private val RootVerticalPadding = 16.dp
private val SettingsSectionSpacing = 22.dp
private val SettingsSectionInnerSpacing = 8.dp
private const val PlayStorePackageName = "com.android.vending"

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
    var selectedThirdPartyLicenseId by rememberSaveable { mutableStateOf<String?>(null) }
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
        BackHandler {
            selectedDocument = null
        }

        AppDocumentViewer(
            document = currentDocument,
            onBack = { selectedDocument = null },
        )
        return
    }

    val selectedThirdPartyLicense = selectedThirdPartyLicenseId?.let {
        ThirdPartyLicenseCatalog.findEntry(it)
    }
    if (selectedThirdPartyLicense != null) {
        BackHandler {
            selectedThirdPartyLicenseId = null
        }

        ThirdPartyLicenseDetailScreen(
            entry = selectedThirdPartyLicense,
            onBack = { selectedThirdPartyLicenseId = null },
            modifier = modifier,
        )
        return
    }

    val onBackFromCurrentRoute: (() -> Unit)? = when (route) {
        SettingsRoute.Main -> null
        SettingsRoute.LicenseInfo -> {
            { route = SettingsRoute.About }
        }
        SettingsRoute.ThirdPartyLicenses -> {
            { route = SettingsRoute.LicenseInfo }
        }
        SettingsRoute.About,
        SettingsRoute.Reference,
        SettingsRoute.Advanced,
        -> {
            { route = SettingsRoute.Main }
        }
    }

    onBackFromCurrentRoute?.let { onBack ->
        BackHandler(onBack = onBack)
    }

    BackHandler(enabled = pendingAction != null) {
        pendingAction = null
    }

    val showingRouteScreen = renderRouteScreen(
        route = route,
        modifier = modifier,
        assetDirectory = assetDirectory,
        uiState = uiState,
        wordSnapshot = wordSnapshot,
        sentenceSnapshot = sentenceSnapshot,
        onBackToMain = { route = SettingsRoute.Main },
        onBackFromLicenseInfo = { route = SettingsRoute.About },
        onBackFromThirdPartyLicenses = { route = SettingsRoute.LicenseInfo },
        onOpenDocument = { selectedDocument = it },
        onOpenLicenseInfo = { route = SettingsRoute.LicenseInfo },
        onOpenThirdPartyLicenses = { route = SettingsRoute.ThirdPartyLicenses },
        onOpenThirdPartyLicenseDetail = { selectedThirdPartyLicenseId = it },
        onRebuild = { pendingAction = SettingsDangerousAction.RebuildDatabase },
        onClear = { pendingAction = SettingsDangerousAction.ClearDatabase },
        onAudioArchiveAction = { type, action ->
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

    val displaySectionTitle = stringResource(R.string.settings_display_section)
    val languageValue = uiState.languagePreference.displayLabel()
    val themeValue = uiState.themePreference.displayLabel()
    val textScaleValue = String.format("%.1fx", uiState.readingTextScale)
    val infoSectionTitle = stringResource(R.string.settings_info_section)
    val advancedSummary = stringResource(R.string.settings_advanced_body)
    val aboutSummary = stringResource(R.string.settings_about_summary)
    val referenceSummary = stringResource(R.string.settings_reference_summary)
    val audioSectionTitle = stringResource(R.string.settings_offline_audio_title)

    Scaffold(
        modifier = modifier,
        containerColor = appSettingsPageContainerColor(),
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
        topBar = {
            TopAppBar(
                title = { Text(text = stringResource(R.string.settings_title)) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = appSettingsPageContainerColor(),
                ),
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = RootHorizontalPadding)
                .padding(top = RootVerticalPadding, bottom = RootVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(SettingsSectionSpacing),
        ) {
            item {
                SettingsSection(title = displaySectionTitle) {
                    DisplaySettingsGroup(
                        selectedLanguage = uiState.languagePreference,
                        selectedTheme = uiState.themePreference,
                        currentScale = uiState.readingTextScale,
                        languageValue = languageValue,
                        themeValue = themeValue,
                        textScaleValue = textScaleValue,
                        onSelectLanguage = viewModel::setLanguagePreference,
                        onSelectTheme = viewModel::setThemePreference,
                        onScaleChanged = viewModel::setReadingTextScale,
                    )
                }
            }

            item {
                SettingsSection(title = infoSectionTitle) {
                    InfoAndMaintenanceGroup(
                        advancedSummary = advancedSummary,
                        aboutSummary = aboutSummary,
                        referenceSummary = referenceSummary,
                        onOpenAdvancedSettings = { route = SettingsRoute.Advanced },
                        onOpenAbout = { route = SettingsRoute.About },
                        onRateApp = { openAppRating(context) },
                        onOpenReference = { route = SettingsRoute.Reference },
                    )
                }
            }

            item {
                AppSettingsSectionHeader(title = audioSectionTitle)
            }

            item {
                OfflineAudioResourcesGroup(
                    wordSnapshot = wordSnapshot,
                    sentenceSnapshot = sentenceSnapshot,
                    onAction = { type, action ->
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
    wordSnapshot: AudioArchiveDownloadSnapshot,
    sentenceSnapshot: AudioArchiveDownloadSnapshot,
    onBackToMain: () -> Unit,
    onBackFromLicenseInfo: () -> Unit,
    onBackFromThirdPartyLicenses: () -> Unit,
    onOpenDocument: (AppDocument) -> Unit,
    onOpenLicenseInfo: () -> Unit,
    onOpenThirdPartyLicenses: () -> Unit,
    onOpenThirdPartyLicenseDetail: (String) -> Unit,
    onRebuild: () -> Unit,
    onClear: () -> Unit,
    onAudioArchiveAction: (DictionaryAudioArchiveType, AudioArchiveAction) -> Unit,
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
                onOpenLicenseDetail = onOpenThirdPartyLicenseDetail,
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
                wordSnapshot = wordSnapshot,
                sentenceSnapshot = sentenceSnapshot,
                modifier = modifier,
                onBack = onBackToMain,
                onRebuild = onRebuild,
                onClear = onClear,
                onAudioArchiveAction = onAudioArchiveAction,
            )
            true
        }
    }
}

@Composable
private fun OfflineAudioResourcesGroup(
    wordSnapshot: AudioArchiveDownloadSnapshot,
    sentenceSnapshot: AudioArchiveDownloadSnapshot,
    onAction: (DictionaryAudioArchiveType, AudioArchiveAction) -> Unit,
) {
    AppSettingsGroup {
        AudioArchiveResourceRow(
            type = DictionaryAudioArchiveType.Word,
            snapshot = wordSnapshot,
            showRedownloadAction = false,
            onAction = { action -> onAction(DictionaryAudioArchiveType.Word, action) },
        )
        AppListDivider()
        AudioArchiveResourceRow(
            type = DictionaryAudioArchiveType.Sentence,
            snapshot = sentenceSnapshot,
            showRedownloadAction = false,
            onAction = { action -> onAction(DictionaryAudioArchiveType.Sentence, action) },
        )
    }
}

@Composable
private fun SettingsSection(
    title: String,
    content: @Composable () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(SettingsSectionInnerSpacing),
    ) {
        AppSettingsSectionHeader(title = title)
        content()
    }
}

@Composable
private fun DisplaySettingsGroup(
    selectedLanguage: AppLanguagePreference,
    selectedTheme: AppThemePreference,
    currentScale: Double,
    languageValue: String,
    themeValue: String,
    textScaleValue: String,
    onSelectLanguage: (AppLanguagePreference) -> Unit,
    onSelectTheme: (AppThemePreference) -> Unit,
    onScaleChanged: (Double) -> Unit,
) {
    AppSettingsGroup {
        PreferenceMenuRow(
            title = stringResource(R.string.settings_language_title),
            value = languageValue,
            options = AppLanguagePreference.entries,
            selectedOption = selectedLanguage,
            optionLabel = { it.displayLabel() },
            icon = Icons.Outlined.Language,
            iconContainerColor = MaterialTheme.colorScheme.primaryContainer,
            iconContentColor = MaterialTheme.colorScheme.onPrimaryContainer,
            onSelect = onSelectLanguage,
        )
        AppListDivider()
        PreferenceMenuRow(
            title = stringResource(R.string.settings_theme_title),
            value = themeValue,
            options = AppThemePreference.entries,
            selectedOption = selectedTheme,
            optionLabel = { it.displayLabel() },
            icon = Icons.Outlined.Palette,
            iconContainerColor = MaterialTheme.colorScheme.tertiaryContainer,
            iconContentColor = MaterialTheme.colorScheme.onTertiaryContainer,
            onSelect = onSelectTheme,
        )
        AppListDivider()
        ListItem(
            colors = transparentListItemColors(),
            leadingContent = {
                AppSettingsRowIcon(
                    imageVector = Icons.Outlined.TextFields,
                    containerColor = MaterialTheme.colorScheme.secondaryContainer,
                    contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                )
            },
            headlineContent = {
                Text(text = stringResource(R.string.settings_text_scale_title))
            },
            supportingContent = {
                Text(
                    text = textScaleValue,
                    style = MaterialTheme.typography.bodyMedium,
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun <T> PreferenceMenuRow(
    title: String,
    value: String,
    options: List<T>,
    selectedOption: T,
    optionLabel: @Composable (T) -> String,
    icon: ImageVector? = null,
    iconContainerColor: Color = MaterialTheme.colorScheme.secondaryContainer,
    iconContentColor: Color = MaterialTheme.colorScheme.onSecondaryContainer,
    onSelect: (T) -> Unit,
) {
    var expanded by androidx.compose.runtime.remember { mutableStateOf(false) }

    ListItem(
        modifier = Modifier.clickable { expanded = true },
        colors = transparentListItemColors(),
        leadingContent = icon?.let {
            {
                AppSettingsRowIcon(
                    imageVector = it,
                    containerColor = iconContainerColor,
                    contentColor = iconContentColor,
                )
            }
        },
        headlineContent = { Text(text = title) },
        supportingContent = {
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
        trailingContent = {
            Box {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
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
private fun InfoAndMaintenanceGroup(
    advancedSummary: String,
    aboutSummary: String,
    referenceSummary: String,
    onOpenAdvancedSettings: () -> Unit,
    onOpenAbout: () -> Unit,
    onRateApp: () -> Unit,
    onOpenReference: () -> Unit,
) {
    AppSettingsGroup {
        ListItem(
            modifier = Modifier.clickable(onClick = onOpenAdvancedSettings),
            colors = transparentListItemColors(),
            leadingContent = {
                AppSettingsRowIcon(
                    imageVector = Icons.Outlined.Build,
                    containerColor = MaterialTheme.colorScheme.tertiaryContainer,
                    contentColor = MaterialTheme.colorScheme.onTertiaryContainer,
                )
            },
            headlineContent = {
                Text(text = stringResource(R.string.settings_advanced_title))
            },
            supportingContent = {
                Text(
                    text = advancedSummary,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
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
        ListItem(
            modifier = Modifier.clickable(onClick = onOpenAbout),
            colors = transparentListItemColors(),
            leadingContent = {
                AppSettingsRowIcon(
                    imageVector = Icons.Outlined.Info,
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
                )
            },
            headlineContent = {
                Text(text = stringResource(R.string.settings_info_about))
            },
            supportingContent = {
                Text(
                    text = aboutSummary,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
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
        ListItem(
            modifier = Modifier.clickable(onClick = onRateApp),
            colors = transparentListItemColors(),
            leadingContent = {
                AppSettingsRowIcon(
                    imageVector = Icons.Outlined.StarRate,
                    containerColor = MaterialTheme.colorScheme.tertiaryContainer,
                    contentColor = MaterialTheme.colorScheme.onTertiaryContainer,
                )
            },
            headlineContent = {
                Text(text = stringResource(R.string.settings_rate_app))
            },
            supportingContent = {
                Text(
                    text = stringResource(R.string.settings_rate_app_summary),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
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
        ListItem(
            modifier = Modifier.clickable(onClick = onOpenReference),
            colors = transparentListItemColors(),
            leadingContent = {
                AppSettingsRowIcon(
                    imageVector = Icons.AutoMirrored.Outlined.MenuBook,
                    containerColor = MaterialTheme.colorScheme.secondaryContainer,
                    contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                )
            },
            headlineContent = {
                Text(text = stringResource(R.string.settings_info_reference))
            },
            supportingContent = {
                Text(
                    text = referenceSummary,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
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

private fun openAppRating(context: Context) {
    val packageName = context.packageName
    val marketIntent = Intent(
        Intent.ACTION_VIEW,
        Uri.parse("market://details?id=$packageName"),
    ).apply {
        setPackage(PlayStorePackageName)
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    val webIntent = Intent(
        Intent.ACTION_VIEW,
        Uri.parse("https://play.google.com/store/apps/details?id=$packageName"),
    ).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }

    runCatching {
        context.startActivity(marketIntent)
    }.recoverCatching {
        context.startActivity(webIntent)
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
    AppLanguagePreference.Japanese -> stringResource(R.string.settings_language_japanese)
}
