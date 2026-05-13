package org.taigidict.app.feature.info

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.taigidict.app.R
import org.taigidict.app.feature.common.AppListDivider
import org.taigidict.app.feature.common.appCardColors
import org.taigidict.app.feature.common.appPageContainerColor
import org.taigidict.app.feature.common.transparentListItemColors

private val LicenseDetailHorizontalPadding = 16.dp
private val LicenseDetailVerticalPadding = 16.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ThirdPartyLicenseDetailScreen(
    entry: ThirdPartyLicenseEntry,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val uriHandler = LocalUriHandler.current
    val licenseText by produceState<Result<String>?>(initialValue = null, entry.assetPath) {
        value = withContext(Dispatchers.IO) {
            runCatching {
                context.assets.open(entry.assetPath).bufferedReader().use { reader ->
                    reader.readText()
                }
            }
        }
    }

    Scaffold(
        modifier = modifier,
        containerColor = appPageContainerColor(),
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
        topBar = {
            TopAppBar(
                title = { Text(text = entry.name) },
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(innerPadding)
                .padding(horizontal = LicenseDetailHorizontalPadding)
                .padding(top = LicenseDetailVerticalPadding, bottom = LicenseDetailVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Card(colors = appCardColors()) {
                Column(modifier = Modifier.fillMaxWidth()) {
                    LicenseMetadataRow(
                        label = stringResource(R.string.third_party_license_package),
                        value = entry.name,
                    )
                    AppListDivider()
                    LicenseMetadataRow(
                        label = stringResource(R.string.third_party_license_version_label),
                        value = entry.version,
                    )
                    AppListDivider()
                    LicenseMetadataRow(
                        label = stringResource(R.string.third_party_license_license_label),
                        value = entry.license,
                    )
                    AppListDivider()
                    ListItem(
                        modifier = Modifier.clickable {
                            uriHandler.openUri(entry.sourceUrl)
                        },
                        colors = transparentListItemColors(),
                        headlineContent = {
                            Text(text = stringResource(R.string.third_party_license_source))
                        },
                        supportingContent = {
                            Text(text = entry.sourceUrl)
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
            }

            Card(colors = appCardColors()) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text(
                        text = stringResource(R.string.third_party_license_notice),
                        style = MaterialTheme.typography.titleMedium,
                    )
                    Text(
                        text = stringResource(entry.descriptionRes),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            Card(colors = appCardColors()) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text(
                        text = stringResource(R.string.third_party_license_text),
                        style = MaterialTheme.typography.titleMedium,
                    )
                    when (val result = licenseText) {
                        null -> {
                            Text(
                                text = stringResource(R.string.settings_info_loading),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }

                        else -> {
                            val text = result.getOrNull()
                            if (text == null) {
                                Text(
                                    text = stringResource(
                                        R.string.settings_info_load_error,
                                        result.exceptionOrNull()?.localizedMessage
                                            ?: stringResource(R.string.unknown_error),
                                    ),
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.error,
                                )
                            } else {
                                SelectionContainer {
                                    Text(
                                        text = text,
                                        style = MaterialTheme.typography.bodySmall,
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun LicenseMetadataRow(
    label: String,
    value: String,
) {
    ListItem(
        colors = transparentListItemColors(),
        headlineContent = {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text(text = label)
                Text(
                    text = value,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
    )
}
