package org.taigidict.app.feature.info

import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.clickable
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Android
import androidx.compose.material.icons.outlined.ShoppingBag
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import org.taigidict.app.R
import org.taigidict.app.feature.common.AppListDivider
import org.taigidict.app.feature.common.appCardColors
import org.taigidict.app.feature.common.appPageContainerColor
import org.taigidict.app.feature.common.transparentListItemColors

private val ThirdPartyHorizontalPadding = 16.dp
private val ThirdPartyVerticalPadding = 16.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ThirdPartyLicensesScreen(
    onBack: () -> Unit,
    onOpenLicenseDetail: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier,
        containerColor = appPageContainerColor(),
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
        topBar = {
            TopAppBar(
                title = { Text(text = stringResource(R.string.license_third_party_title)) },
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
                .padding(horizontal = ThirdPartyHorizontalPadding)
                .padding(top = ThirdPartyVerticalPadding, bottom = ThirdPartyVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            ThirdPartyLicenseCatalog.sections.forEach { section ->
                item {
                    SectionLabel(text = stringResource(section.titleRes))
                }
                item {
                    ThirdPartySectionCard(
                        entries = section.entries,
                        icon = when (section.titleRes) {
                            R.string.third_party_core_section -> Icons.Outlined.ShoppingBag
                            else -> Icons.Outlined.Android
                        },
                        onOpenLicenseDetail = onOpenLicenseDetail,
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(horizontal = 2.dp),
    )
}

@Composable
private fun ThirdPartySectionCard(
    entries: List<ThirdPartyLicenseEntry>,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onOpenLicenseDetail: (String) -> Unit,
) {
    Card(colors = appCardColors()) {
        Column(modifier = Modifier.fillMaxWidth()) {
            entries.forEachIndexed { index, entry ->
                ThirdPartyRow(
                    entry = entry,
                    icon = icon,
                    onOpenLicenseDetail = onOpenLicenseDetail,
                )
                if (index < entries.lastIndex) {
                    AppListDivider()
                }
            }
        }
    }
}

@Composable
private fun ThirdPartyRow(
    entry: ThirdPartyLicenseEntry,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onOpenLicenseDetail: (String) -> Unit,
) {
    ListItem(
        modifier = Modifier.clickable { onOpenLicenseDetail(entry.id) },
        colors = transparentListItemColors(),
        leadingContent = {
            Icon(imageVector = icon, contentDescription = null)
        },
        headlineContent = {
            Text(text = entry.name)
        },
        supportingContent = {
            Text(text = stringResource(R.string.third_party_license_version, entry.version))
        },
        trailingContent = {
            Column(horizontalAlignment = androidx.compose.ui.Alignment.End) {
                Text(
                    text = entry.license,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
    )
}
