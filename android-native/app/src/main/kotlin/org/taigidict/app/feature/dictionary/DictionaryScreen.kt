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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication

@Composable
fun DictionaryScreen(
    manifestAssetPath: String,
    entriesAssetPath: String,
    dataVersion: Int,
    viewModel: DictionarySearchViewModel = viewModel(key = "dictionary-$dataVersion"),
) {
    val uiState = viewModel.uiState.collectAsStateWithLifecycle().value
    val appContainer = (LocalContext.current.applicationContext as TaigiDictApplication).appContainer
    val bookmarkedIds = appContainer.bookmarkStore.bookmarkedIds.collectAsStateWithLifecycle().value
    val showsEntryDetail = uiState.isLoadingEntryDetail || uiState.selectedEntry != null || uiState.entryDetailErrorMessage != null

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (showsEntryDetail) {
            DictionaryEntryDetailPane(
                isLoading = uiState.isLoadingEntryDetail,
                entry = uiState.selectedEntry,
                openableLinkedWords = uiState.openableLinkedWords,
                errorMessage = uiState.entryDetailErrorMessage,
                isBookmarked = uiState.selectedEntry?.id in bookmarkedIds,
                onToggleBookmark = {
                    uiState.selectedEntry?.let { entry ->
                        appContainer.bookmarkStore.toggleBookmark(entry.id)
                    }
                },
                onBack = viewModel::onEntryDetailDismissed,
                onOpenLinkedWord = viewModel::onLinkedWordSelected,
            )
        } else {
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
                value = uiState.query,
                onValueChange = viewModel::onQueryChange,
                label = {
                    Text(text = stringResource(R.string.dictionary_search_label))
                },
                placeholder = {
                    Text(text = stringResource(R.string.dictionary_search_placeholder))
                },
                singleLine = true,
            )
            when {
                uiState.isLoadingBundle -> Text(
                    text = stringResource(R.string.dictionary_loading_bundle),
                    style = MaterialTheme.typography.bodyMedium,
                )

                uiState.bundle != null -> {
                    val bundle = requireNotNull(uiState.bundle)
                    Text(
                        text = stringResource(R.string.dictionary_database_label, bundle.databasePath.orEmpty()),
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
                }
                uiState.bundleErrorMessage != null -> Text(
                    text = stringResource(
                        R.string.dictionary_bundle_error,
                        uiState.bundleErrorMessage,
                    ),
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
            when {
                uiState.searchErrorMessage != null -> Text(
                    text = stringResource(
                        R.string.dictionary_search_error,
                        uiState.searchErrorMessage,
                    ),
                    style = MaterialTheme.typography.bodyMedium,
                )

                uiState.query.isNotBlank() && uiState.results.isEmpty() && !uiState.isSearching -> Text(
                    text = stringResource(R.string.dictionary_no_results),
                    style = MaterialTheme.typography.bodyMedium,
                )

                uiState.results.isNotEmpty() -> {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(uiState.results, key = { it.id }) { entry ->
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { viewModel.onEntrySelected(entry.id) }
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

                uiState.isSearching -> Text(
                    text = stringResource(R.string.dictionary_searching),
                    style = MaterialTheme.typography.bodyMedium,
                )
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
}

