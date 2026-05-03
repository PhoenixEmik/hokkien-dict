package org.taigidict.app.feature.info

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.taigidict.app.R

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
    ReferenceLinks(
        titleRes = R.string.settings_info_reference,
        assetPath = "docs/REFERENCE_LINKS.md",
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
                    SelectionContainer {
                        Text(
                            text = text,
                            modifier = Modifier
                                .fillMaxSize()
                                .verticalScroll(rememberScrollState())
                                .padding(innerPadding)
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    }
                }
            }
        }
    }
}
