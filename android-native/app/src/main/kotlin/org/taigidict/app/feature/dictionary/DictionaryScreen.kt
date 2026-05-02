package org.taigidict.app.feature.dictionary

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.taigidict.app.R
import org.taigidict.app.data.repository.SQLiteDictionaryRepository
import org.taigidict.app.domain.model.DictionaryBundle

@Composable
fun DictionaryScreen(
    manifestAssetPath: String,
    entriesAssetPath: String,
    databasePath: String,
    repository: SQLiteDictionaryRepository,
) {
    val bundleState by produceState<Result<DictionaryBundle>?>(initialValue = null, repository) {
        value = withContext(Dispatchers.IO) {
            runCatching {
                repository.loadBundle()
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = stringResource(R.string.dictionary_placeholder_title),
            style = MaterialTheme.typography.headlineMedium,
        )
        Text(
            text = stringResource(R.string.dictionary_placeholder_body),
            style = MaterialTheme.typography.bodyLarge,
        )
        when (val currentBundleState = bundleState) {
            null -> Text(
                text = stringResource(R.string.dictionary_loading_bundle),
                style = MaterialTheme.typography.bodyMedium,
            )

            else -> {
                val bundle = currentBundleState.getOrNull()
                if (bundle != null) {
                    Text(
                        text = stringResource(R.string.dictionary_database_label, bundle.databasePath ?: databasePath),
                        style = MaterialTheme.typography.bodyMedium,
                    )
                    Text(
                        text = stringResource(R.string.dictionary_entry_count_label, bundle.entryCount),
                        style = MaterialTheme.typography.bodyMedium,
                    )
                    Text(
                        text = stringResource(R.string.dictionary_sense_count_label, bundle.senseCount),
                        style = MaterialTheme.typography.bodyMedium,
                    )
                    Text(
                        text = stringResource(R.string.dictionary_example_count_label, bundle.exampleCount),
                        style = MaterialTheme.typography.bodyMedium,
                    )
                } else {
                    Text(
                        text = stringResource(
                            R.string.dictionary_bundle_error,
                            currentBundleState.exceptionOrNull()?.message ?: stringResource(R.string.unknown_error),
                        ),
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }
        }
        Text(
            text = stringResource(R.string.bundled_manifest_label, manifestAssetPath),
            style = MaterialTheme.typography.bodyMedium,
        )
        Text(
            text = stringResource(R.string.bundled_entries_label, entriesAssetPath),
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}
