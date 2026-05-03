package org.taigidict.app.feature.info

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Card
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
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
    PrivacyPolicy(
        titleRes = R.string.settings_info_privacy_policy,
        assetPath = "docs/PRIVACY_POLICY.md",
    ),
    DataLicense(
        titleRes = R.string.settings_info_data_license,
        assetPath = "docs/DATA_LICENSE.md",
    ),
}

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

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        FilledTonalButton(onClick = onBack) {
            Text(text = stringResource(R.string.settings_info_back))
        }

        Text(
            text = stringResource(document.titleRes),
            style = MaterialTheme.typography.headlineMedium,
        )

        when (val result = documentText) {
            null -> Text(
                text = stringResource(R.string.settings_info_loading),
                style = MaterialTheme.typography.bodyMedium,
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
                    )
                } else {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        SelectionContainer {
                            Text(
                                text = text,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .verticalScroll(rememberScrollState())
                                    .padding(16.dp),
                                style = MaterialTheme.typography.bodyMedium,
                            )
                        }
                    }
                }
            }
        }
    }
}