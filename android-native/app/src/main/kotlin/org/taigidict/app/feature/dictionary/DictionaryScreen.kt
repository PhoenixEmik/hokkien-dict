package org.taigidict.app.feature.dictionary

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.taigidict.app.R
import org.taigidict.app.data.repository.SQLiteDictionaryRepository
import org.taigidict.app.domain.model.DictionaryBundle
import org.taigidict.app.domain.model.DictionaryEntry

@Composable
fun DictionaryScreen(
    manifestAssetPath: String,
    entriesAssetPath: String,
    databasePath: String,
    repository: SQLiteDictionaryRepository,
) {
    var query by remember { mutableStateOf("") }
    val bundleState by produceState<Result<DictionaryBundle>?>(initialValue = null, repository) {
        value = withContext(Dispatchers.IO) {
            runCatching {
                repository.loadBundle()
            }
        }
    }
    val resultsState by produceState<Result<List<DictionaryEntry>>?>(initialValue = null, query, repository) {
        value = if (query.isBlank()) {
            Result.success(emptyList())
        } else {
            withContext(Dispatchers.IO) {
                runCatching {
                    repository.search(query)
                }
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
        OutlinedTextField(
            modifier = Modifier.fillMaxWidth(),
            value = query,
            onValueChange = { query = it },
            label = {
                Text(text = stringResource(R.string.dictionary_search_label))
            },
            placeholder = {
                Text(text = stringResource(R.string.dictionary_search_placeholder))
            },
            singleLine = true,
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
        when (val currentResultsState = resultsState) {
            null -> Unit
            else -> {
                val results = currentResultsState.getOrNull()
                if (results != null) {
                    if (query.isNotBlank() && results.isEmpty()) {
                        Text(
                            text = stringResource(R.string.dictionary_no_results),
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    } else if (results.isNotEmpty()) {
                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            items(results, key = { it.id }) { entry ->
                                Column(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable { }
                                        .padding(vertical = 4.dp),
                                    verticalArrangement = Arrangement.spacedBy(4.dp),
                                ) {
                                    Text(
                                        text = entry.hanji,
                                        style = MaterialTheme.typography.titleMedium,
                                    )
                                    Text(
                                        text = entry.romanization,
                                        style = MaterialTheme.typography.bodyMedium,
                                    )
                                    if (entry.briefSummary.isNotBlank()) {
                                        Text(
                                            text = entry.briefSummary,
                                            style = MaterialTheme.typography.bodySmall,
                                        )
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text(
                        text = stringResource(
                            R.string.dictionary_search_error,
                            currentResultsState.exceptionOrNull()?.message ?: stringResource(R.string.unknown_error),
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
