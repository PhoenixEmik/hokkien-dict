package org.taigidict.app.feature.dictionary

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
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
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.launch
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.feature.common.DictionaryFallbackText

private val ScreenHorizontalPadding = 16.dp
private val ScreenVerticalPadding = 16.dp
private val TopContentPadding = 16.dp
private val SectionSpacing = 16.dp
private val ComponentSpacing = 8.dp
private val TwoPaneContentSpacing = 16.dp

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
    val scope = rememberCoroutineScope()
    val showsEntryDetail = uiState.isLoadingEntryDetail ||
        uiState.selectedEntry != null ||
        uiState.entryDetailErrorMessage != null

    BoxWithConstraints(modifier = modifier.fillMaxSize()) {
        val usesTwoPaneLayout = DictionaryAdaptiveLayoutPolicy.shouldUseTwoPane(maxWidth)

        if (showsEntryDetail && !usesTwoPaneLayout) {
            DictionaryEntryDetailPane(
                isLoading = uiState.isLoadingEntryDetail,
                entry = uiState.selectedEntry,
                openableLinkedWords = uiState.openableLinkedWords,
                errorMessage = uiState.entryDetailErrorMessage,
                isBookmarked = uiState.selectedEntry?.id in bookmarkedIds,
                onToggleBookmark = {
                    uiState.selectedEntry?.let { entry ->
                        scope.launch {
                            appContainer.bookmarkStore.toggleBookmark(entry.id)
                        }
                    }
                },
                onBack = viewModel::onEntryDetailDismissed,
                onOpenLinkedWord = viewModel::onLinkedWordSelected,
                modifier = Modifier.fillMaxSize(),
            )
            return@BoxWithConstraints
        }

        Scaffold(
            modifier = Modifier.fillMaxSize(),
            contentWindowInsets = WindowInsets.safeDrawing.only(
                WindowInsetsSides.Horizontal,
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

                    uiState.query.isNotBlank() && uiState.results.isEmpty() && !uiState.isSearching -> {
                        DictionaryNoResultsState(
                            query = uiState.query,
                            recentSearches = uiState.recentSearches,
                            onClearQuery = { viewModel.onQueryChange("") },
                            onRecentSearchSelected = viewModel::onRecentSearchSelected,
                        )
                    }

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

                    uiState.query.isBlank() &&
                        uiState.hasLoadedRecentSearches &&
                        uiState.recentSearches.isEmpty() -> DictionaryHomeEmptyCard()

                    uiState.isSearching -> SearchLoadingPlaceholder(
                        modifier = Modifier.fillMaxSize(),
                    )

                    uiState.results.isNotEmpty() && usesTwoPaneLayout -> {
                        Row(
                            modifier = Modifier.fillMaxSize(),
                            horizontalArrangement = Arrangement.spacedBy(TwoPaneContentSpacing),
                        ) {
                            Column(
                                modifier = Modifier.weight(0.46f),
                                verticalArrangement = Arrangement.spacedBy(0.dp),
                            ) {
                                Text(
                                    text = stringResource(R.string.dictionary_search_results_title),
                                    style = MaterialTheme.typography.titleMedium,
                                    modifier = Modifier.padding(bottom = ComponentSpacing),
                                )
                                DictionaryResultList(
                                    results = uiState.results,
                                    onEntrySelected = viewModel::onEntrySelected,
                                    modifier = Modifier.fillMaxSize(),
                                )
                            }

                            if (showsEntryDetail) {
                                DictionaryEntryDetailPane(
                                    isLoading = uiState.isLoadingEntryDetail,
                                    entry = uiState.selectedEntry,
                                    openableLinkedWords = uiState.openableLinkedWords,
                                    errorMessage = uiState.entryDetailErrorMessage,
                                    isBookmarked = uiState.selectedEntry?.id in bookmarkedIds,
                                    onToggleBookmark = {
                                        uiState.selectedEntry?.let { entry ->
                                            scope.launch {
                                                appContainer.bookmarkStore.toggleBookmark(entry.id)
                                            }
                                        }
                                    },
                                    onBack = viewModel::onEntryDetailDismissed,
                                    onOpenLinkedWord = viewModel::onLinkedWordSelected,
                                    modifier = Modifier
                                        .weight(0.54f)
                                        .fillMaxHeight(),
                                )
                            } else {
                                TwoPaneDetailPlaceholder(
                                    modifier = Modifier
                                        .weight(0.54f)
                                        .fillMaxHeight(),
                                )
                            }
                        }
                    }

                    uiState.results.isNotEmpty() -> {
                        Column(verticalArrangement = Arrangement.spacedBy(0.dp)) {
                            Text(
                                text = stringResource(R.string.dictionary_search_results_title),
                                style = MaterialTheme.typography.titleMedium,
                                modifier = Modifier.padding(bottom = ComponentSpacing),
                            )
                            DictionaryResultList(
                                results = uiState.results,
                                onEntrySelected = viewModel::onEntrySelected,
                                modifier = Modifier.weight(1f, fill = true),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
internal fun SearchLoadingPlaceholder(
    modifier: Modifier = Modifier,
) {
    val transition = rememberInfiniteTransition(label = "dictionary-search-loading")
    val pulseAlpha by transition.animateFloat(
        initialValue = 0.45f,
        targetValue = 0.95f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 900),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "dictionary-search-loading-alpha",
    )

    LazyColumn(
        modifier = modifier.testTag("dictionary-search-loading"),
        verticalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        items(4, key = { index -> "search-loading-$index" }) { index ->
            SearchLoadingRow(
                headlineWidthFraction = if (index % 2 == 0) 0.34f else 0.26f,
                romanizationWidthFraction = if (index % 2 == 0) 0.42f else 0.36f,
                summaryWidthFraction = if (index % 2 == 0) 0.72f else 0.58f,
                alpha = pulseAlpha,
            )
            HorizontalDivider(
                modifier = Modifier.padding(horizontal = 16.dp),
                thickness = 0.5.dp,
            )
        }
    }
}

@Composable
internal fun DictionaryNoResultsState(
    query: String,
    recentSearches: List<String>,
    onClearQuery: () -> Unit,
    onRecentSearchSelected: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier
            .fillMaxWidth()
            .testTag("dictionary-no-results"),
        verticalArrangement = Arrangement.spacedBy(SectionSpacing),
    ) {
        item("no-results-card") {
            Card {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Box(
                        modifier = Modifier
                            .size(44.dp)
                            .background(
                                color = MaterialTheme.colorScheme.surfaceVariant,
                                shape = MaterialTheme.shapes.medium,
                            ),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Search,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }

                    Text(
                        text = stringResource(R.string.dictionary_no_results_title),
                        style = MaterialTheme.typography.titleLarge,
                    )
                    Text(
                        text = stringResource(R.string.dictionary_no_results_body, query),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )

                    TextButton(onClick = onClearQuery) {
                        Text(text = stringResource(R.string.dictionary_no_results_clear_query))
                    }
                }
            }
        }

        if (recentSearches.isNotEmpty()) {
            item("recent-searches-title") {
                Text(
                    text = stringResource(R.string.dictionary_recent_searches_title),
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            item("recent-searches-card") {
                RecentSearchHistoryCard(
                    recentSearches = recentSearches,
                    onRecentSearchSelected = onRecentSearchSelected,
                )
            }
        }
    }
}

@Composable
private fun SearchLoadingRow(
    headlineWidthFraction: Float,
    romanizationWidthFraction: Float,
    summaryWidthFraction: Float,
    alpha: Float,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            SearchLoadingLine(
                widthFraction = headlineWidthFraction,
                height = 22.dp,
                alpha = alpha,
            )
            SearchLoadingLine(
                widthFraction = romanizationWidthFraction,
                height = 16.dp,
                alpha = alpha,
            )
            SearchLoadingLine(
                widthFraction = summaryWidthFraction,
                height = 14.dp,
                alpha = alpha,
            )
        }

        Box(
            modifier = Modifier
                .size(18.dp)
                .background(
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = alpha),
                    shape = MaterialTheme.shapes.small,
                ),
        )
    }
}

@Composable
private fun SearchLoadingLine(
    widthFraction: Float,
    height: androidx.compose.ui.unit.Dp,
    alpha: Float,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .fillMaxWidth(widthFraction.coerceIn(0f, 1f))
            .height(height)
            .background(
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = alpha),
                shape = MaterialTheme.shapes.extraLarge,
            ),
    )
}

@Composable
internal fun DictionaryResultList(
    results: List<org.taigidict.app.domain.model.DictionaryEntry>,
    onEntrySelected: (Long) -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        items(
            results,
            key = { it.id },
        ) { entry ->
            ListItem(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onEntrySelected(entry.id) },
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

@Composable
private fun TwoPaneDetailPlaceholder(
    modifier: Modifier = Modifier,
) {
    Card(modifier = modifier) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp, vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = stringResource(R.string.dictionary_search_results_title),
                style = MaterialTheme.typography.titleMedium,
                textAlign = TextAlign.Center,
            )
            Text(
                text = stringResource(R.string.dictionary_empty_state_body),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp),
            )
        }
    }
}

@Composable
internal fun DictionaryHomeEmptyCard() {
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
internal fun RecentSearchHistoryCard(
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
