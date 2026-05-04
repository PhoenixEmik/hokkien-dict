package org.taigidict.app.feature.info

import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Android
import androidx.compose.material.icons.outlined.ShoppingBag
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import org.taigidict.app.R

private data class ThirdPartyEntry(val name: String, val license: String)

private val CoreEntries = listOf(
    ThirdPartyEntry("android-opencc", "Apache 2.0"),
    ThirdPartyEntry("SQLite", "Public Domain"),
)

private val AndroidEntries = listOf(
    ThirdPartyEntry("Jetpack Compose", "Apache 2.0"),
    ThirdPartyEntry("AndroidX", "Apache 2.0"),
    ThirdPartyEntry("Material3", "Apache 2.0"),
    ThirdPartyEntry("Kotlin", "Apache 2.0"),
    ThirdPartyEntry("kotlinx.serialization", "Apache 2.0"),
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ThirdPartyLicensesScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier,
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
            modifier = Modifier.fillMaxSize(),
            contentPadding = innerPadding,
        ) {
            item {
                SectionLabel(text = stringResource(R.string.third_party_core_section))
            }
            items(CoreEntries.size) { index ->
                val entry = CoreEntries[index]
                ThirdPartyRow(entry = entry, icon = Icons.Outlined.ShoppingBag)
                if (index < CoreEntries.lastIndex) {
                    HorizontalDivider(thickness = 0.5.dp)
                }
            }
            item {
                SectionLabel(text = stringResource(R.string.third_party_android_section))
            }
            items(AndroidEntries.size) { index ->
                val entry = AndroidEntries[index]
                ThirdPartyRow(entry = entry, icon = Icons.Outlined.Android)
                if (index < AndroidEntries.lastIndex) {
                    HorizontalDivider(thickness = 0.5.dp)
                }
            }
        }
    }
}

@Composable
private fun SectionLabel(text: String) {
    ListItem(
        headlineContent = {
            Text(
                text = text,
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.primary,
            )
        },
        colors = ListItemDefaults.colors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f),
        ),
    )
}

@Composable
private fun ThirdPartyRow(
    entry: ThirdPartyEntry,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
) {
    ListItem(
        leadingContent = {
            Icon(imageVector = icon, contentDescription = null)
        },
        headlineContent = {
            Text(text = entry.name)
        },
        trailingContent = {
            Text(
                text = entry.license,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
    )
}
