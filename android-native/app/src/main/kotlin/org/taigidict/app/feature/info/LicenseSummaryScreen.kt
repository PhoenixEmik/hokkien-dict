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
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.Code
import androidx.compose.material.icons.outlined.Copyright
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.Speaker
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
import org.taigidict.app.R
import org.taigidict.app.feature.common.AppListDivider
import org.taigidict.app.feature.common.AppSettingsGroup
import org.taigidict.app.feature.common.AppSettingsListIcon
import org.taigidict.app.feature.common.appSettingsPageContainerColor
import org.taigidict.app.feature.common.transparentListItemColors

private val LicenseHorizontalPadding = 16.dp
private val LicenseVerticalPadding = 24.dp

private const val MinistryCopyrightUrl = "https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/"

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LicenseSummaryScreen(
    onBack: () -> Unit,
    onOpenThirdPartyLicenses: () -> Unit,
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
                title = { Text(text = stringResource(R.string.settings_info_open_source_license)) },
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
                .padding(horizontal = LicenseHorizontalPadding)
                .padding(top = LicenseVerticalPadding, bottom = LicenseVerticalPadding),
        ) {
            item {
                AppSettingsGroup {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        LicenseValueRow(
                            icon = Icons.Outlined.Code,
                            title = stringResource(R.string.license_app_code_title),
                            value = stringResource(R.string.license_app_code_value),
                        )
                        LicenseDivider()
                        LicenseValueRow(
                            icon = Icons.AutoMirrored.Outlined.MenuBook,
                            title = stringResource(R.string.license_data_title),
                            value = stringResource(R.string.license_data_value),
                        )
                        LicenseDivider()
                        LicenseValueRow(
                            icon = Icons.Outlined.Speaker,
                            title = stringResource(R.string.license_audio_title),
                            value = stringResource(R.string.license_audio_value),
                        )
                        LicenseDivider()
                        ListItem(
                            modifier = Modifier.clickable {
                                uriHandler.openUri(MinistryCopyrightUrl)
                            },
                            colors = transparentListItemColors(),
                            leadingContent = {
                                AppSettingsListIcon(
                                    imageVector = Icons.Outlined.Copyright,
                                )
                            },
                            headlineContent = {
                                Text(
                                    text = stringResource(R.string.license_ministry_copyright),
                                    color = MaterialTheme.colorScheme.primary,
                                )
                            },
                        )
                    }
                }
            }

            item {
                AppSettingsGroup(
                    modifier = Modifier.padding(top = 16.dp),
                ) {
                    LicenseNavRow(
                        icon = Icons.Outlined.Inventory2,
                        title = stringResource(R.string.license_third_party_title),
                        onClick = onOpenThirdPartyLicenses,
                    )
                }
            }
        }
    }
}

@Composable
private fun LicenseDivider() {
    AppListDivider()
}

@Composable
private fun LicenseValueRow(
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
private fun LicenseNavRow(
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
