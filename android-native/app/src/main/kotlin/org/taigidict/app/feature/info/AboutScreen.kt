package org.taigidict.app.feature.info

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.automirrored.outlined.TextSnippet
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.Code
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.ImportContacts
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.Policy
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import org.taigidict.app.BuildConfig
import org.taigidict.app.R
import org.taigidict.app.feature.common.AppListDivider
import org.taigidict.app.feature.common.AppSettingsGroup
import org.taigidict.app.feature.common.AppSettingsListIcon
import org.taigidict.app.feature.common.AppSettingsSectionHeader
import org.taigidict.app.feature.common.appSettingsPageContainerColor
import org.taigidict.app.feature.common.transparentListItemColors

private val AboutHorizontalPadding = 16.dp
private val AboutVerticalPadding = 16.dp

private const val RepoUrl = "https://github.com/PhoenixEmik/taigi-dict"
private const val PrivacyPolicyUrl = "https://github.com/PhoenixEmik/taigi-dict/blob/main/PRIVACY_POLICY.md"
private const val ReferencePageUrl = "https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/"
private const val TailoGuideUrl = "https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/"
private const val HanjiGuideUrl = "https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/"

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun AboutScreen(
    onBack: () -> Unit,
    onOpenDocument: (AppDocument) -> Unit,
    onOpenLicenses: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val uriHandler = LocalUriHandler.current

    Scaffold(
        modifier = modifier,
        containerColor = appSettingsPageContainerColor(),
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
        topBar = {
            TopAppBar(
                title = { Text(text = stringResource(R.string.about_title)) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = appSettingsPageContainerColor(),
                ),
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                            contentDescription = stringResource(R.string.settings_info_back),
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
                .padding(horizontal = AboutHorizontalPadding)
                .padding(top = AboutVerticalPadding, bottom = AboutVerticalPadding),
        ) {
            item {
                AppSettingsSectionHeader(title = stringResource(R.string.about_app_section))
            }
            item {
                AppSettingsGroup {
                    AboutValueRow(
                        icon = Icons.Outlined.Info,
                        title = stringResource(R.string.about_version),
                        value = BuildConfig.VERSION_NAME,
                    )
                    AboutDivider()
                    AboutValueRow(
                        icon = Icons.Outlined.AccountCircle,
                        title = stringResource(R.string.about_author),
                        value = stringResource(R.string.about_author_value),
                    )
                    AboutDivider()
                    AboutLinkRow(
                        icon = Icons.Outlined.Code,
                        title = stringResource(R.string.about_github),
                        value = stringResource(R.string.about_github_value),
                        onClick = { uriHandler.openUri(RepoUrl) },
                    )
                }
            }

            item {
                AppSettingsSectionHeader(title = stringResource(R.string.about_project_section))
            }
            item {
                AppSettingsGroup {
                    AboutNavRow(
                        icon = Icons.Outlined.Description,
                        title = stringResource(R.string.settings_info_open_source_license),
                        onClick = onOpenLicenses,
                    )
                    AboutDivider()
                    AboutNavRow(
                        icon = Icons.Outlined.Policy,
                        title = stringResource(R.string.settings_info_privacy_policy),
                        onClick = { uriHandler.openUri(PrivacyPolicyUrl) },
                    )
                }
            }

            item {
                AppSettingsSectionHeader(title = stringResource(R.string.settings_info_reference))
            }
            item {
                AppSettingsGroup {
                    AboutNavRow(
                        icon = Icons.Outlined.Link,
                        title = stringResource(R.string.about_reference_page),
                        onClick = { uriHandler.openUri(ReferencePageUrl) },
                    )
                    AboutDivider()
                    AboutNavRow(
                        icon = Icons.Outlined.ImportContacts,
                        title = stringResource(R.string.about_tailo_title),
                        onClick = { uriHandler.openUri(TailoGuideUrl) },
                    )
                    AboutDivider()
                    AboutNavRow(
                        icon = Icons.AutoMirrored.Outlined.TextSnippet,
                        title = stringResource(R.string.about_hanji_title),
                        onClick = { uriHandler.openUri(HanjiGuideUrl) },
                    )
                }
            }
        }
    }
}

@Composable
private fun AboutDivider() {
    AppListDivider()
}

@Composable
private fun AboutValueRow(
    icon: ImageVector,
    title: String,
    value: String,
) {
    ListItem(
        colors = transparentListItemColors(),
        leadingContent = {
            AppSettingsListIcon(
                imageVector = icon,
            )
        },
        headlineContent = { Text(text = title) },
        supportingContent = {
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
    )
}

@Composable
private fun AboutLinkRow(
    icon: ImageVector,
    title: String,
    value: String,
    onClick: () -> Unit,
) {
    ListItem(
        modifier = Modifier.clickable(onClick = onClick),
        colors = transparentListItemColors(),
        leadingContent = {
            AppSettingsListIcon(
                imageVector = icon,
            )
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
            Icon(
                imageVector = Icons.AutoMirrored.Outlined.OpenInNew,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
    )
}

@Composable
private fun AboutNavRow(
    icon: ImageVector,
    title: String,
    onClick: () -> Unit,
) {
    ListItem(
        modifier = Modifier.clickable(onClick = onClick),
        colors = transparentListItemColors(),
        leadingContent = {
            AppSettingsListIcon(
                imageVector = icon,
            )
        },
        headlineContent = { Text(text = title) },
        trailingContent = {
            Icon(
                imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
    )
}
