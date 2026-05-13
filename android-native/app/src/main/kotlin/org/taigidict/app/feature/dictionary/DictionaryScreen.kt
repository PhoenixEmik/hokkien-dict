package org.taigidict.app.feature.dictionary

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SearchBar
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.launch
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.feature.common.AppListDivider
import org.taigidict.app.feature.common.DictionaryFallbackText
import org.taigidict.app.feature.common.appCardColors
import org.taigidict.app.feature.common.appListContainerColor
import org.taigidict.app.feature.common.appPageContainerColor
import org.taigidict.app.feature.common.transparentListItemColors

private val ScreenHorizontalPadding = 16.dp
private val ScreenVerticalPadding = 16.dp
private val TopContentPadding = 16.dp
private val SectionSpacing = 16.dp
private val ComponentSpacing = 8.dp
private val TwoPaneContentSpacing = 16.dp
private val TwoPaneSectionHeaderHeight = 40.dp

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
        var selectedPreviewEntryId by rememberSaveable { mutableStateOf<Long?>(null) }
        var showsDetailPage by rememberSaveable { mutableStateOf(false) }
        val showsFullscreenDetail = showsEntryDetail && (!usesTwoPaneLayout || showsDetailPage)

        LaunchedEffect(showsEntryDetail, usesTwoPaneLayout) {
            if (!showsEntryDetail || !usesTwoPaneLayout) {
                showsDetailPage = false
            }
        }

        LaunchedEffect(uiState.results) {
            if (selectedPreviewEntryId != null && uiState.results.none { it.id == selectedPreviewEntryId }) {
                selectedPreviewEntryId = null
                showsDetailPage = false
            }
        }

        val onResultSelected: (Long) -> Unit = { entryId ->
            if (shouldOpenTwoPaneDetailPage(
                    usesTwoPaneLayout = usesTwoPaneLayout,
                    selectedPreviewEntryId = selectedPreviewEntryId,
                    tappedEntryId = entryId,
                    isDetailPageVisible = showsDetailPage,
                )
            ) {
                showsDetailPage = true
            } else {
                selectedPreviewEntryId = entryId
                showsDetailPage = false
                viewModel.onEntrySelected(entryId)
            }
        }

        BackHandler(enabled = showsEntryDetail) {
            if (usesTwoPaneLayout && showsDetailPage) {
                showsDetailPage = false
            } else {
                selectedPreviewEntryId = null
                viewModel.onEntryDetailDismissed()
            }
        }

        if (showsFullscreenDetail) {
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
                onBack = {
                    if (usesTwoPaneLayout) {
                        showsDetailPage = false
                    } else {
                        selectedPreviewEntryId = null
                        viewModel.onEntryDetailDismissed()
                    }
                },
                onOpenLinkedWord = { word ->
                    selectedPreviewEntryId = null
                    viewModel.onLinkedWordSelected(word)
                },
                modifier = Modifier.fillMaxSize(),
            )
            return@BoxWithConstraints
        }

        Scaffold(
            modifier = Modifier.fillMaxSize(),
            containerColor = appPageContainerColor(),
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
                                Text(
                                    text = stringResource(R.string.dictionary_search_placeholder),
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                )
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

                    uiState.query.isBlank() -> {
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            verticalArrangement = Arrangement.spacedBy(SectionSpacing),
                        ) {
                            DictionaryHomeEmptyCard()

                            if (uiState.recentSearches.isNotEmpty()) {
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
                        }
                    }

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
                                TwoPaneResultsHeader()
                                Spacer(modifier = Modifier.height(ComponentSpacing))
                                DictionaryResultList(
                                    results = uiState.results,
                                    onEntrySelected = onResultSelected,
                                    modifier = Modifier.fillMaxSize(),
                                )
                            }

                            Column(
                                modifier = Modifier
                                    .weight(0.54f)
                                    .fillMaxHeight(),
                            ) {
                                TwoPaneResultsHeader(
                                    visible = false,
                                )
                                Spacer(modifier = Modifier.height(ComponentSpacing))

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
                                        onOpenLinkedWord = { word ->
                                            selectedPreviewEntryId = null
                                            viewModel.onLinkedWordSelected(word)
                                        },
                                        showTopBar = false,
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .weight(1f),
                                    )
                                } else {
                                    TwoPaneDetailPlaceholder(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .weight(1f),
                                    )
                                }
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
                                onEntrySelected = onResultSelected,
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
private fun TwoPaneResultsHeader(
    visible: Boolean = true,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = TwoPaneSectionHeaderHeight),
        contentAlignment = Alignment.CenterStart,
    ) {
        Text(
            text = stringResource(R.string.dictionary_search_results_title),
            style = MaterialTheme.typography.titleMedium,
            modifier = if (visible) Modifier else Modifier.alpha(0f),
        )
    }
}

internal fun shouldOpenTwoPaneDetailPage(
    usesTwoPaneLayout: Boolean,
    selectedPreviewEntryId: Long?,
    tappedEntryId: Long,
    isDetailPageVisible: Boolean,
): Boolean {
    return usesTwoPaneLayout &&
        selectedPreviewEntryId == tappedEntryId &&
        !isDetailPageVisible
}

@Composable
internal fun SearchLoadingPlaceholder(
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .testTag("dictionary-search-loading"),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
    ) {
        CircularProgressIndicator()
        Text(
            text = stringResource(R.string.dictionary_searching),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
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
            Card(colors = appCardColors()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Search,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(32.dp),
                    )

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
internal fun DictionaryResultList(
    results: List<org.taigidict.app.domain.model.DictionaryEntry>,
    onEntrySelected: (Long) -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        item {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = MaterialTheme.shapes.large,
                color = appListContainerColor(),
            ) {
                Column(modifier = Modifier.fillMaxWidth()) {
                    results.forEachIndexed { index, entry ->
                        ListItem(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onEntrySelected(entry.id) },
                            colors = transparentListItemColors(),
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
                        if (index < results.lastIndex) {
                            AppListDivider()
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TwoPaneDetailPlaceholder(
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier,
        colors = appCardColors(),
    ) {
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
    Card(colors = appCardColors()) {
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
    Card(colors = appCardColors()) {
        Column(modifier = Modifier.fillMaxWidth()) {
            recentSearches.take(8).forEachIndexed { index, query ->
                ListItem(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onRecentSearchSelected(query) },
                    colors = transparentListItemColors(),
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
                    AppListDivider()
                }
            }
        }
    }
}
