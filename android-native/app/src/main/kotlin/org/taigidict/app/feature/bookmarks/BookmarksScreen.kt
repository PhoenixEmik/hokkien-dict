package org.taigidict.app.feature.bookmarks

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.feature.common.DictionaryFallbackText
import org.taigidict.app.feature.dictionary.DictionaryEntryDetailPane

@Composable
fun BookmarksScreen(
    dataVersion: Int,
    viewModel: BookmarksViewModel = viewModel(key = "bookmarks-$dataVersion"),
) {
    val uiState = viewModel.uiState.collectAsStateWithLifecycle().value
    val appContainer = (LocalContext.current.applicationContext as TaigiDictApplication).appContainer
    val bookmarkedIds by appContainer.bookmarkStore.bookmarkedIds.collectAsStateWithLifecycle()
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
                text = stringResource(R.string.bookmarks_title),
                style = MaterialTheme.typography.headlineMedium,
            )

            when {
                uiState.isLoadingEntries -> Text(
                    text = stringResource(R.string.bookmarks_loading),
                    style = MaterialTheme.typography.bodyLarge,
                )

                uiState.entriesErrorMessage != null -> Text(
                    text = stringResource(R.string.bookmarks_load_error, uiState.entriesErrorMessage),
                    style = MaterialTheme.typography.bodyLarge,
                )

                uiState.entries.isEmpty() -> {
                    Text(
                        text = stringResource(R.string.bookmarks_empty_title),
                        style = MaterialTheme.typography.titleMedium,
                    )
                    Text(
                        text = stringResource(R.string.bookmarks_empty_body),
                        style = MaterialTheme.typography.bodyLarge,
                    )
                }

                else -> {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(uiState.entries, key = { it.id }) { entry ->
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { viewModel.onEntrySelected(entry.id) }
                                    .padding(vertical = 4.dp),
                                verticalArrangement = Arrangement.spacedBy(4.dp),
                            ) {
                                DictionaryFallbackText(
                                    text = entry.hanji,
                                    style = MaterialTheme.typography.titleMedium,
                                )
                                DictionaryFallbackText(
                                    text = entry.romanization,
                                    style = MaterialTheme.typography.bodyMedium,
                                )
                                if (entry.briefSummary.isNotBlank()) {
                                    DictionaryFallbackText(
                                        text = entry.briefSummary,
                                        style = MaterialTheme.typography.bodySmall,
                                    )
                                }
                                Text(
                                    text = stringResource(R.string.bookmarks_remove_action),
                                    modifier = Modifier.clickable { viewModel.removeBookmark(entry.id) },
                                    style = MaterialTheme.typography.labelLarge,
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
