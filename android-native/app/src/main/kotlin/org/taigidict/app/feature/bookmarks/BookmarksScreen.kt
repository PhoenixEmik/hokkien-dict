package org.taigidict.app.feature.bookmarks

import android.app.Activity
import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
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
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxDefaults
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.launch
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.feature.common.DictionaryFallbackText
import org.taigidict.app.feature.dictionary.DictionaryEntryDetailPane
import org.taigidict.app.feature.dictionary.DictionaryShareFormatter

private val RootHorizontalPadding = 16.dp
private val RootVerticalPadding = 16.dp
private val BookmarksGridMinCellWidth = 320.dp
private val BookmarksGridSpacing = 12.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookmarksScreen(
    dataVersion: Int,
    modifier: Modifier = Modifier,
    viewModel: BookmarksViewModel = viewModel(key = "bookmarks-$dataVersion"),
) {
    val uiState = viewModel.uiState.collectAsStateWithLifecycle().value
    val context = LocalContext.current
    val appContainer = (context.applicationContext as TaigiDictApplication).appContainer
    val bookmarkedIds by appContainer.bookmarkStore.bookmarkedIds.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    val bookmarkRemovedMessage = stringResource(R.string.bookmarks_removed_message)
    val undoAction = stringResource(R.string.undo)
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
                    scope.launch {
                        appContainer.bookmarkStore.toggleBookmark(entry.id)
                    }
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
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = RootHorizontalPadding)
                .padding(top = RootVerticalPadding, bottom = RootVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
                when {
                    uiState.isLoadingEntries -> {
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            CircularProgressIndicator(strokeWidth = 2.dp)
                            Text(
                                text = stringResource(R.string.bookmarks_loading),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }

                    uiState.entriesErrorMessage != null -> {
                        Text(
                            text = stringResource(R.string.bookmarks_load_error, uiState.entriesErrorMessage),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.error,
                        )
                    }

                    uiState.entries.isEmpty() -> {
                        BookmarksEmptyCard()
                    }

                    else -> {
                        BoxWithConstraints(modifier = Modifier.weight(1f, fill = true)) {
                            if (BookmarksAdaptiveLayoutPolicy.shouldUseGrid(maxWidth)) {
                                LazyVerticalGrid(
                                    columns = GridCells.Adaptive(minSize = BookmarksGridMinCellWidth),
                                    modifier = Modifier.fillMaxSize(),
                                    horizontalArrangement = Arrangement.spacedBy(BookmarksGridSpacing),
                                    verticalArrangement = Arrangement.spacedBy(BookmarksGridSpacing),
                                ) {
                                    items(
                                        count = uiState.entries.size,
                                        key = { index -> uiState.entries[index].id },
                                    ) { index ->
                                        BookmarkEntryGridItem(
                                            entry = uiState.entries[index],
                                            onClick = { viewModel.onEntrySelected(uiState.entries[index].id) },
                                        )
                                    }
                                }
                            } else {
                                LazyColumn(
                                    modifier = Modifier.fillMaxSize(),
                                    verticalArrangement = Arrangement.spacedBy(0.dp),
                                ) {
                                    itemsIndexed(uiState.entries, key = { _, entry -> entry.id }) { index, entry ->
                                        BookmarkEntryListItem(
                                            entry = entry,
                                            onClick = { viewModel.onEntrySelected(entry.id) },
                                            onRemove = {
                                                viewModel.removeBookmark(entry.id)
                                                scope.launch {
                                                    val result = snackbarHostState.showSnackbar(
                                                        message = bookmarkRemovedMessage,
                                                        actionLabel = undoAction,
                                                        withDismissAction = true,
                                                    )
                                                    if (result == SnackbarResult.ActionPerformed) {
                                                        viewModel.addBookmark(entry.id, index)
                                                    }
                                                }
                                            },
                                            onShare = {
                                                shareBookmarkedEntry(
                                                    context = context,
                                                    entry = entry,
                                                    fallbackTitle = context.getString(R.string.dictionary_share_title_fallback),
                                                    footer = context.getString(R.string.dictionary_share_footer),
                                                )
                                            },
                                        )
                                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp)
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
internal fun BookmarksEmptyCard() {
    Card {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(
                imageVector = Icons.Outlined.BookmarkBorder,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(
                text = stringResource(R.string.bookmarks_empty_title),
                style = MaterialTheme.typography.titleLarge,
            )
            Text(
                text = stringResource(R.string.bookmarks_empty_body),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun BookmarkEntryListItem(
    entry: DictionaryEntry,
    onClick: () -> Unit,
    onRemove: () -> Unit,
    onShare: () -> Unit,
) {
    val dismissState = rememberSwipeToDismissBoxState(
        positionalThreshold = SwipeToDismissBoxDefaults.positionalThreshold,
        confirmValueChange = { value ->
            when (value) {
                SwipeToDismissBoxValue.EndToStart -> {
                    onRemove()
                    true
                }
                SwipeToDismissBoxValue.StartToEnd,
                SwipeToDismissBoxValue.Settled -> false
            }
        },
    )

    SwipeToDismissBox(
        state = dismissState,
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            val swipeValue = dismissState.dismissDirection ?: SwipeToDismissBoxValue.Settled
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        if (swipeValue == SwipeToDismissBoxValue.EndToStart) {
                            MaterialTheme.colorScheme.errorContainer
                        } else {
                            MaterialTheme.colorScheme.surface
                        },
                    )
                    .testTag("bookmark-swipe-actions-background-${entry.id}"),
            ) {
                if (swipeValue == SwipeToDismissBoxValue.EndToStart) {
                    Icon(
                        imageVector = Icons.Outlined.Delete,
                        contentDescription = stringResource(R.string.dictionary_detail_remove_bookmark),
                        tint = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier
                            .align(Alignment.CenterEnd)
                            .padding(end = 24.dp),
                    )
                }
            }
        },
        content = {
            ListItem(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onClick)
                    .testTag("bookmark-list-item-${entry.id}"),
                headlineContent = {
                    DictionaryFallbackText(
                        text = entry.hanji,
                        style = MaterialTheme.typography.titleMedium,
                    )
                },
                supportingContent = {
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
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
                    IconButton(
                        onClick = onShare,
                        modifier = Modifier.testTag("bookmark-share-action-${entry.id}"),
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Share,
                            contentDescription = stringResource(R.string.dictionary_share_action),
                        )
                    }
                },
            )
        },
    )
}

@Composable
internal fun BookmarkEntryGridItem(
    entry: DictionaryEntry,
    onClick: () -> Unit,
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
    ) {
        ListItem(
            headlineContent = {
                DictionaryFallbackText(
                    text = entry.hanji,
                    style = MaterialTheme.typography.titleMedium,
                )
            },
            supportingContent = {
                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
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
    }
}

private fun shareBookmarkedEntry(
    context: android.content.Context,
    entry: DictionaryEntry,
    fallbackTitle: String,
    footer: String,
) {
    val title = DictionaryShareFormatter.buildShareTitle(
        entry = entry,
        fallbackTitle = fallbackTitle,
    )
    val text = DictionaryShareFormatter.buildShareText(
        entry = entry,
        fallbackHanji = fallbackTitle,
        footer = footer,
    )
    val shareIntent = Intent(Intent.ACTION_SEND)
        .setType("text/plain")
        .putExtra(Intent.EXTRA_SUBJECT, title)
        .putExtra(Intent.EXTRA_TITLE, title)
        .putExtra(Intent.EXTRA_TEXT, text)
    val chooserIntent = Intent.createChooser(shareIntent, title)
    if (context !is Activity) {
        chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    context.startActivity(chooserIntent)
}
