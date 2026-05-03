package org.taigidict.app.feature.dictionary

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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SearchBar
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.feature.common.DictionaryFallbackText

private val ScreenHorizontalPadding = 16.dp
private val ScreenVerticalPadding = 16.dp
private val TopContentPadding = 16.dp
private val SectionSpacing = 16.dp
private val ComponentSpacing = 8.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DictionaryScreen(
    @Suppress("UNUSED_PARAMETER") manifestAssetPath: String,
    @Suppress("UNUSED_PARAMETER") entriesAssetPath: String,
    dataVersion: Int,
    modifier: Modifier = Modifier,
    viewModel: DictionarySearchViewModel = viewModel(key = "dictionary-$dataVersion"),
) {
    val uiState = viewModel.uiState.collectAsStateWithLifecycle().value
    val appContainer = (LocalContext.current.applicationContext as TaigiDictApplication).appContainer
    val bookmarkedIds = appContainer.bookmarkStore.bookmarkedIds.collectAsStateWithLifecycle().value
    val showsEntryDetail = uiState.isLoadingEntryDetail || uiState.selectedEntry != null || uiState.entryDetailErrorMessage != null

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
            modifier = modifier.fillMaxSize(),
        )
        return
    }

    Scaffold(
        modifier = modifier,
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Top + WindowInsetsSides.Horizontal,
        ),
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = ScreenHorizontalPadding)
                .padding(top = TopContentPadding, bottom = ScreenVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(SectionSpacing),
        ) {

            SearchBar(
                modifier = Modifier.fillMaxWidth(),
                inputField = {
                    SearchBarDefaults.InputField(
                        query = uiState.query,
                        onQueryChange = viewModel::onQueryChange,
                        onSearch = {
                            viewModel.onSearchSubmitted()
                        },
                        expanded = false,
                        onExpandedChange = {},
                        placeholder = {
                            Text(text = stringResource(R.string.dictionary_search_placeholder))
                        },
                        leadingIcon = {
                            Icon(
                                imageVector = Icons.Outlined.Search,
                                contentDescription = null,
                            )
                        },
                        trailingIcon = {
                            if (uiState.query.isNotBlank()) {
                                IconButton(onClick = { viewModel.onQueryChange("") }) {
                                    Icon(
                                        imageVector = Icons.Outlined.Close,
                                        contentDescription = stringResource(R.string.dictionary_recent_searches_clear),
                                    )
                                }
                            }
                        },
                    )
                },
                expanded = false,
                onExpandedChange = {},
                content = {},
            )

            when {
                uiState.isLoadingBundle -> Text(
                    text = stringResource(R.string.dictionary_loading_bundle),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )

                uiState.bundle != null -> Unit

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
                    color = MaterialTheme.colorScheme.error,
                )

                uiState.query.isNotBlank() && uiState.results.isEmpty() && !uiState.isSearching -> Text(
                    text = stringResource(R.string.dictionary_no_results),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )

                uiState.query.isBlank() && uiState.recentSearches.isNotEmpty() -> {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = stringResource(R.string.dictionary_recent_searches_title),
                            style = MaterialTheme.typography.titleLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        TextButton(onClick = viewModel::onClearRecentSearches) {
                            Text(text = stringResource(R.string.dictionary_recent_searches_clear))
                        }
                    }

                    RecentSearchHistoryCard(
                        recentSearches = uiState.recentSearches,
                        onRecentSearchSelected = viewModel::onRecentSearchSelected,
                    )
                }

                uiState.query.isBlank() -> DictionaryHomeEmptyCard()

                uiState.results.isNotEmpty() -> {
                    Column(verticalArrangement = Arrangement.spacedBy(0.dp)) {
                        Text(
                            text = stringResource(R.string.dictionary_search_results_title),
                            style = MaterialTheme.typography.titleMedium,
                            modifier = Modifier.padding(bottom = ComponentSpacing),
                        )
                        LazyColumn(
                            modifier = Modifier.weight(1f, fill = true),
                            verticalArrangement = Arrangement.spacedBy(0.dp),
                        ) {
                            items(
                                uiState.results,
                                key = { it.id },
                            ) { entry ->
                                ListItem(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable { viewModel.onEntrySelected(entry.id) },
                                    headlineContent = {
                                        DictionaryFallbackText(
                                            text = entry.hanji,
                                            style = MaterialTheme.typography.titleMedium,
                                        )
                                    },
                                    supportingContent = {
                                        Column(verticalArrangement = Arrangement.spacedBy(ComponentSpacing / 2)) {
                                            DictionaryFallbackText(
                                                text = entry.romanization,
                                                style = MaterialTheme.typography.bodyMedium,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                            )
                                            if (entry.briefSummary.isNotBlank()) {
                                                DictionaryFallbackText(
                                                    text = entry.briefSummary,
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                                )
                                            }
                                        }
                                    },
                                    trailingContent = {
                                        Icon(
                                            imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                        )
                                    },
                                )
                                HorizontalDivider(
                                    modifier = Modifier.padding(horizontal = 16.dp),
                                    thickness = 0.5.dp,
                                )
                            }
                        }
                    }
                }

                uiState.isSearching -> Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                    Text(
                        text = stringResource(R.string.dictionary_searching),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
        }
        }
    }
}

@Composable
private fun DictionaryHomeEmptyCard() {
    Card {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 24.dp),
            verticalArrangement = Arrangement.spacedBy(ComponentSpacing),
            horizontalAlignment = Alignment.Start,
        ) {
            Icon(
                imageVector = Icons.Outlined.Search,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(32.dp),
            )
            Text(
                text = stringResource(R.string.dictionary_empty_state_title),
                style = MaterialTheme.typography.titleLarge,
            )
            Text(
                text = stringResource(R.string.dictionary_empty_state_body),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun RecentSearchHistoryCard(
    recentSearches: List<String>,
    onRecentSearchSelected: (String) -> Unit,
) {
    Card {
        Column(modifier = Modifier.fillMaxWidth()) {
            recentSearches.take(8).forEachIndexed { index, query ->
                ListItem(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onRecentSearchSelected(query) },
                    leadingContent = {
                        Icon(
                            imageVector = Icons.Outlined.History,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                        )
                    },
                    headlineContent = {
                        DictionaryFallbackText(
                            text = query,
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.primary,
                        )
                    },
                )
                if (index < recentSearches.take(8).lastIndex) {
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
                }
            }
        }
    }
}

