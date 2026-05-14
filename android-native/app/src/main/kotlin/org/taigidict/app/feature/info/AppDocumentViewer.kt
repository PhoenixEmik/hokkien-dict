package org.taigidict.app.feature.info

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.horizontalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.taigidict.app.R
import org.taigidict.app.feature.common.AppListDivider
import org.taigidict.app.feature.common.appCardColors
import org.taigidict.app.feature.common.appPageContainerColor

enum class AppDocument(
    val titleRes: Int,
    val assetPath: String,
) {
    About(
        titleRes = R.string.settings_info_about,
        assetPath = "docs/ABOUT_APP.md",
    ),
    PrivacyPolicy(
        titleRes = R.string.settings_info_privacy_policy,
        assetPath = "docs/PRIVACY_POLICY.md",
    ),
    DataLicense(
        titleRes = R.string.settings_info_data_license,
        assetPath = "docs/DATA_LICENSE.md",
    ),
    OpenSourceLicense(
        titleRes = R.string.settings_info_open_source_license,
        assetPath = "docs/LICENSE.md",
    ),
    ThirdPartyLicenses(
        titleRes = R.string.license_third_party_title,
        assetPath = "docs/LICENSE.md",
    ),
    ReferenceLinks(
        titleRes = R.string.settings_info_reference,
        assetPath = "docs/REFERENCE_LINKS.md",
    ),
    TailoGuide(
        titleRes = R.string.about_tailo_title,
        assetPath = "docs/TAILO_GUIDE.md",
    ),
    HanjiGuide(
        titleRes = R.string.about_hanji_title,
        assetPath = "docs/HANJI_GUIDE.md",
    ),
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppDocumentViewer(
    document: AppDocument,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val documentText by produceState<Result<String>?>(initialValue = null, document) {
        value = withContext(Dispatchers.IO) {
            runCatching {
                context.assets.open(document.assetPath).bufferedReader().use { reader ->
                    reader.readText()
                }
            }
        }
    }

    Scaffold(
        containerColor = appPageContainerColor(),
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
        topBar = {
            TopAppBar(
                title = { Text(text = stringResource(document.titleRes)) },
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
        when (val result = documentText) {
            null -> Text(
                text = stringResource(R.string.settings_info_loading),
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(innerPadding).padding(16.dp),
            )

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
                        modifier = Modifier.padding(innerPadding).padding(16.dp),
                    )
                } else {
                    val blocks = remember(text) { SimpleMarkdownParser.parse(text) }
                    SelectionContainer {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .verticalScroll(rememberScrollState())
                                .padding(innerPadding)
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            blocks.forEach { block ->
                                when (block) {
                                    is MarkdownBlock.Heading -> {
                                        Text(
                                            text = block.text,
                                            style = when (block.level) {
                                                1 -> MaterialTheme.typography.headlineSmall
                                                2 -> MaterialTheme.typography.titleLarge
                                                else -> MaterialTheme.typography.titleMedium
                                            },
                                        )
                                    }

                                    is MarkdownBlock.Paragraph -> {
                                        Text(
                                            text = block.text,
                                            style = MaterialTheme.typography.bodyMedium,
                                        )
                                    }

                                    is MarkdownBlock.ListBlock -> {
                                        Column(
                                            verticalArrangement = Arrangement.spacedBy(6.dp),
                                        ) {
                                            block.items.forEachIndexed { index, item ->
                                                Row(
                                                    verticalAlignment = Alignment.Top,
                                                ) {
                                                    Text(
                                                        text = if (block.ordered) "${index + 1}." else "•",
                                                        style = MaterialTheme.typography.bodyMedium,
                                                        modifier = Modifier.padding(end = 8.dp),
                                                    )
                                                    Text(
                                                        text = item,
                                                        style = MaterialTheme.typography.bodyMedium,
                                                        modifier = Modifier.weight(1f),
                                                    )
                                                }
                                            }
                                        }
                                    }

                                    is MarkdownBlock.Table -> {
                                        MarkdownTable(block)
                                    }
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
private fun MarkdownTable(table: MarkdownBlock.Table) {
    val horizontalScroll = rememberScrollState()

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = appCardColors(),
    ) {
        Column(
            modifier = Modifier
                .horizontalScroll(horizontalScroll)
                .padding(vertical = 8.dp),
        ) {
            MarkdownTableRow(
                cells = table.headers,
                isHeader = true,
            )
            AppListDivider(
                modifier = Modifier.padding(vertical = 4.dp),
                inset = 8.dp,
            )
            table.rows.forEachIndexed { index, row ->
                MarkdownTableRow(cells = row, isHeader = false)
                if (index < table.rows.lastIndex) {
                    AppListDivider(
                        modifier = Modifier.padding(vertical = 4.dp),
                        inset = 8.dp,
                    )
                }
            }
        }
    }
}

@Composable
private fun MarkdownTableRow(
    cells: List<String>,
    isHeader: Boolean,
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(horizontal = 8.dp),
    ) {
        cells.forEach { cell ->
            Text(
                text = cell,
                style = if (isHeader) MaterialTheme.typography.titleSmall else MaterialTheme.typography.bodyMedium,
                modifier = Modifier.widthIn(min = 140.dp),
            )
        }
    }
}
