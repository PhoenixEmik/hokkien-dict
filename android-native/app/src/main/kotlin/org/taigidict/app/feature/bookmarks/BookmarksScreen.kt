package org.taigidict.app.feature.bookmarks

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
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
import org.taigidict.app.feature.common.selectableListItemColors
import org.taigidict.app.feature.dictionary.DictionaryEntryDetailPane

private val RootHorizontalPadding = 16.dp
private val RootVerticalPadding = 16.dp
private val BookmarkItemSpacing = 6.dp

@Composable
private fun bookmarksPageContainerColor() = MaterialTheme.colorScheme.surfaceContainer

@Composable
private fun bookmarksPanelColor() = MaterialTheme.colorScheme.surfaceContainerLow

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
    var selectedBookmarkIds by remember { mutableStateOf(emptySet<Long>()) }
    val isSelectionMode = selectedBookmarkIds.isNotEmpty()

    BackHandler(enabled = isSelectionMode) {
        selectedBookmarkIds = emptySet()
    }

    BackHandler(enabled = showsEntryDetail) {
        if (uiState.canNavigateBackInDetail) {
            viewModel.onEntryDetailBack()
        } else {
            viewModel.onEntryDetailDismissed()
        }
    }

    LaunchedEffect(uiState.entries) {
        val visibleEntryIds = uiState.entries.mapTo(mutableSetOf()) { it.id }
        selectedBookmarkIds = selectedBookmarkIds.intersect(visibleEntryIds)
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
            onBack = {
                if (uiState.canNavigateBackInDetail) {
                    viewModel.onEntryDetailBack()
                } else {
                    viewModel.onEntryDetailDismissed()
                }
            },
            onOpenLinkedWord = viewModel::onLinkedWordSelected,
            modifier = modifier.fillMaxSize(),
        )
        return
    }

    Scaffold(
        modifier = modifier,
        containerColor = bookmarksPageContainerColor(),
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
        topBar = {
            if (isSelectionMode) {
                TopAppBar(
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = bookmarksPageContainerColor(),
                    ),
                    title = {
                        Text(
                            text = stringResource(
                                R.string.bookmarks_selected_count,
                                selectedBookmarkIds.size,
                            ),
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = { selectedBookmarkIds = emptySet() }) {
                            Icon(
                                imageVector = Icons.Outlined.Close,
                                contentDescription = stringResource(R.string.bookmarks_clear_selection),
                            )
                        }
                    },
                    actions = {
                        IconButton(
                            onClick = {
                                val removedEntries = uiState.entries.mapIndexedNotNull { index, entry ->
                                    if (entry.id in selectedBookmarkIds) {
                                        entry.id to index
                                    } else {
                                        null
                                    }
                                }
                                if (removedEntries.isEmpty()) {
                                    selectedBookmarkIds = emptySet()
                                    return@IconButton
                                }

                                viewModel.removeBookmarks(removedEntries.map { it.first })
                                selectedBookmarkIds = emptySet()

                                scope.launch {
                                    val message = if (removedEntries.size == 1) {
                                        bookmarkRemovedMessage
                                    } else {
                                        context.resources.getString(
                                            R.string.bookmarks_removed_count_message,
                                            removedEntries.size,
                                        )
                                    }
                                    val result = snackbarHostState.showSnackbar(
                                        message = message,
                                        actionLabel = undoAction,
                                        withDismissAction = true,
                                    )
                                    if (result == SnackbarResult.ActionPerformed) {
                                        viewModel.restoreBookmarks(removedEntries)
                                    }
                                }
                            },
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Delete,
                                contentDescription = stringResource(R.string.bookmarks_delete_selected),
                            )
                        }
                    },
                )
            } else {
                TopAppBar(
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = bookmarksPageContainerColor(),
                    ),
                    title = {
                        Text(text = stringResource(R.string.bookmarks_title))
                    },
                )
            }
        },
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
                        CircularProgressIndicator()
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
                    LazyColumn(
                        modifier = Modifier.weight(1f, fill = true),
                        verticalArrangement = Arrangement.spacedBy(BookmarkItemSpacing),
                    ) {
                        items(
                            items = uiState.entries,
                            key = { entry -> entry.id },
                        ) { entry ->
                            val isSelected = entry.id in selectedBookmarkIds
                            Surface(
                                modifier = Modifier.fillMaxWidth(),
                                shape = MaterialTheme.shapes.large,
                                color = bookmarksPanelColor(),
                            ) {
                                BookmarkEntryListItem(
                                    entry = entry,
                                    isSelectionMode = isSelectionMode,
                                    isSelected = isSelected,
                                    onClick = { viewModel.onEntrySelected(entry.id) },
                                    onLongClick = {
                                        selectedBookmarkIds = selectedBookmarkIds + entry.id
                                    },
                                    onToggleSelected = {
                                        selectedBookmarkIds = if (isSelected) {
                                            selectedBookmarkIds - entry.id
                                        } else {
                                            selectedBookmarkIds + entry.id
                                        }
                                    },
                                )
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
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.extraLarge,
        color = bookmarksPanelColor(),
    ) {
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
    onLongClick: () -> Unit = {},
    onToggleSelected: () -> Unit = {},
    isSelectionMode: Boolean = false,
    isSelected: Boolean = false,
) {
    ListItem(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(
                onClick = {
                    if (isSelectionMode) {
                        onToggleSelected()
                    } else {
                        onClick()
                    }
                },
                onLongClick = onLongClick,
            )
            .testTag("bookmark-list-item-${entry.id}"),
        colors = selectableListItemColors(isSelected = isSelected),
        leadingContent = if (isSelectionMode) {
            {
                Checkbox(
                    checked = isSelected,
                    onCheckedChange = { onToggleSelected() },
                    modifier = Modifier.testTag("bookmark-selection-checkbox-${entry.id}"),
                )
            }
        } else {
            null
        },
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
                    color = MaterialTheme.colorScheme.primary,
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
        trailingContent = if (isSelectionMode) {
            null
        } else {
            {
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
    )
}
