package org.taigidict.app.feature.dictionary

import android.app.Activity
import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.outlined.Bookmark
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.data.audio.DictionaryAudioPlaybackResult
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense
import org.taigidict.app.feature.common.DictionaryFallbackText

private val DetailHorizontalPadding = 16.dp
private val DetailVerticalPadding = 12.dp
private val DetailSectionSpacing = 16.dp

@Composable
fun DictionaryEntryDetailPane(
    isLoading: Boolean,
    entry: DictionaryEntry?,
    openableLinkedWords: Set<String>,
    errorMessage: String?,
    isBookmarked: Boolean,
    onToggleBookmark: () -> Unit,
    onBack: () -> Unit,
    onOpenLinkedWord: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val appContainer = (context.applicationContext as TaigiDictApplication).appContainer
    val audioPlayer = appContainer.dictionaryAudioPlayer
    val readingTextScale = appContainer.appSettingsStore.readingTextScale
        .collectAsState(initial = 1.0).value
    val scope = rememberCoroutineScope()
    var audioMessage by remember(entry?.id) { mutableStateOf<String?>(null) }

    when {
        isLoading -> DetailStatusScreen(
            title = entry?.hanji.orEmpty(),
            message = stringResource(R.string.dictionary_detail_loading),
            onBack = onBack,
            onShareEntry = {},
            onToggleBookmark = {},
            isBookmarked = isBookmarked,
            showActions = false,
            modifier = modifier,
        )

        errorMessage != null -> DetailStatusScreen(
            title = entry?.hanji.orEmpty(),
            message = stringResource(R.string.dictionary_detail_error, errorMessage),
            onBack = onBack,
            onShareEntry = {},
            onToggleBookmark = {},
            isBookmarked = isBookmarked,
            showActions = false,
            modifier = modifier,
        )

        entry != null -> DictionaryEntryDetailContent(
            audioMessage = audioMessage,
            entry = entry,
            openableLinkedWords = openableLinkedWords,
            isBookmarked = isBookmarked,
            readingTextScale = readingTextScale,
            onBack = onBack,
            onToggleBookmark = onToggleBookmark,
            onShareEntry = {
                shareEntry(
                    context = context,
                    title = DictionaryShareFormatter.buildShareTitle(
                        entry = entry,
                        fallbackTitle = context.getString(R.string.dictionary_share_title_fallback),
                    ),
                    text = DictionaryShareFormatter.buildShareText(
                        entry = entry,
                        fallbackHanji = context.getString(R.string.dictionary_share_title_fallback),
                        footer = context.getString(R.string.dictionary_share_footer),
                    ),
                )
            },
            onPlayEntryAudio = {
                scope.launch {
                    audioMessage = audioResultMessage(
                        result = audioPlayer.playEntryAudio(entry),
                        missingClipMessage = context.getString(R.string.dictionary_audio_missing_clip),
                        unavailableMessage = context.getString(R.string.dictionary_audio_unavailable),
                    )
                }
            },
            onPlayExampleAudio = { example ->
                scope.launch {
                    audioMessage = audioResultMessage(
                        result = audioPlayer.playExampleAudio(example),
                        missingClipMessage = context.getString(R.string.dictionary_audio_missing_clip),
                        unavailableMessage = context.getString(R.string.dictionary_audio_unavailable),
                    )
                }
            },
            onOpenLinkedWord = onOpenLinkedWord,
            modifier = modifier,
        )
    }
}

@Composable
private fun DetailStatusScreen(
    title: String,
    message: String,
    onBack: () -> Unit,
    onShareEntry: () -> Unit,
    onToggleBookmark: () -> Unit,
    isBookmarked: Boolean,
    showActions: Boolean,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier,
        topBar = {
            DetailTopBar(
                title = title,
                onBack = onBack,
                onShareEntry = onShareEntry,
                onToggleBookmark = onToggleBookmark,
                isBookmarked = isBookmarked,
                showActions = showActions,
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = DetailHorizontalPadding, vertical = DetailVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(DetailSectionSpacing),
        ) {
            Card(
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                shape = RoundedCornerShape(16.dp),
            ) {
                Text(
                    text = message,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 18.dp),
                )
            }
        }
    }
}

@Composable
private fun DictionaryEntryDetailContent(
    audioMessage: String?,
    entry: DictionaryEntry,
    openableLinkedWords: Set<String>,
    isBookmarked: Boolean,
    readingTextScale: Double,
    onBack: () -> Unit,
    onToggleBookmark: () -> Unit,
    onShareEntry: () -> Unit,
    onPlayEntryAudio: () -> Unit,
    onPlayExampleAudio: (DictionaryExample) -> Unit,
    onOpenLinkedWord: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val scaledHeadlineStyle = MaterialTheme.typography.headlineLarge.copy(
        fontSize = MaterialTheme.typography.headlineMedium.fontSize * readingTextScale.toFloat(),
    )
    val scaledTitleStyle = MaterialTheme.typography.titleLarge.copy(
        fontSize = MaterialTheme.typography.titleMedium.fontSize * readingTextScale.toFloat(),
    )

    Scaffold(
        modifier = modifier,
        topBar = {
            DetailTopBar(
                title = entry.hanji,
                onBack = onBack,
                onShareEntry = onShareEntry,
                onToggleBookmark = onToggleBookmark,
                isBookmarked = isBookmarked,
                showActions = true,
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = DetailHorizontalPadding, vertical = DetailVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(DetailSectionSpacing),
        ) {
            item {
            Card(
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
                shape = RoundedCornerShape(16.dp),
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 18.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top,
                    ) {
                        Column(
                            modifier = Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            DictionaryFallbackText(
                                text = entry.hanji,
                                style = scaledHeadlineStyle,
                            )
                            if (entry.romanization.isNotBlank()) {
                                DictionaryFallbackText(
                                    text = entry.romanization,
                                    style = scaledTitleStyle,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            }
                        }

                        if (entry.audioId.isNotBlank()) {
                            IconButton(onClick = onPlayEntryAudio) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Outlined.VolumeUp,
                                    contentDescription = stringResource(R.string.dictionary_play_word_audio),
                                    tint = MaterialTheme.colorScheme.primary,
                                )
                            }
                        }
                    }

                    val metadataLine = listOf(entry.type, entry.category)
                        .filter { it.isNotBlank() }
                        .joinToString(separator = " · ")
                    if (metadataLine.isNotBlank()) {
                        DictionaryFallbackText(
                            text = metadataLine,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }

                    if (audioMessage != null) {
                        Text(
                            text = audioMessage,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary,
                        )
                    }
                }
            }
        }

            items(entry.senses.size, key = { index -> "sense-${entry.id}-$index" }) { index ->
                DictionarySenseSection(
                    index = index,
                    sense = entry.senses[index],
                    readingTextScale = readingTextScale,
                    openableLinkedWords = openableLinkedWords,
                    onPlayExampleAudio = onPlayExampleAudio,
                    onOpenLinkedWord = onOpenLinkedWord,
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DetailTopBar(
    title: String,
    onBack: () -> Unit,
    onShareEntry: () -> Unit,
    onToggleBookmark: () -> Unit,
    isBookmarked: Boolean,
    showActions: Boolean,
) {
    TopAppBar(
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = MaterialTheme.colorScheme.surface,
            navigationIconContentColor = MaterialTheme.colorScheme.onSurface,
            titleContentColor = MaterialTheme.colorScheme.onSurface,
            actionIconContentColor = MaterialTheme.colorScheme.onSurface,
        ),
        title = {
            DictionaryFallbackText(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(end = 4.dp),
            )
        },
        navigationIcon = {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                    contentDescription = stringResource(R.string.dictionary_detail_back),
                )
            }
        },
        actions = {
            if (showActions) {
                IconButton(onClick = onToggleBookmark) {
                    Icon(
                        imageVector = if (isBookmarked) Icons.Outlined.Bookmark else Icons.Outlined.BookmarkBorder,
                        contentDescription = if (isBookmarked) {
                            stringResource(R.string.dictionary_detail_remove_bookmark)
                        } else {
                            stringResource(R.string.dictionary_detail_add_bookmark)
                        },
                    )
                }
                IconButton(onClick = onShareEntry) {
                    Icon(
                        imageVector = Icons.Outlined.Share,
                        contentDescription = stringResource(R.string.dictionary_share_action),
                    )
                }
            }
        },
    )
}

@Composable
private fun DictionarySenseSection(
    index: Int,
    sense: DictionarySense,
    readingTextScale: Double,
    openableLinkedWords: Set<String>,
    onPlayExampleAudio: (DictionaryExample) -> Unit,
    onOpenLinkedWord: (String) -> Unit,
) {
    val scaledTitleStyle = MaterialTheme.typography.titleLarge.copy(
        fontSize = MaterialTheme.typography.titleMedium.fontSize * readingTextScale.toFloat(),
    )
    val scaledLabelStyle = MaterialTheme.typography.titleMedium.copy(
        fontSize = MaterialTheme.typography.labelLarge.fontSize * readingTextScale.toFloat(),
    )
    val scaledBodyStyle = MaterialTheme.typography.bodyLarge.copy(
        fontSize = MaterialTheme.typography.bodyLarge.fontSize * readingTextScale.toFloat(),
    )

    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(16.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = stringResource(R.string.dictionary_detail_sense_title, index + 1),
                style = scaledTitleStyle,
            )

            if (sense.partOfSpeech.isNotBlank()) {
                DictionaryFallbackText(
                    text = sense.partOfSpeech,
                    style = scaledLabelStyle,
                    color = MaterialTheme.colorScheme.primary,
                )
            }

            DictionaryFallbackText(
                text = sense.definition,
                style = scaledBodyStyle,
            )

            if (sense.definitionSynonyms.isNotEmpty()) {
                DictionaryDetailRelationshipSection(
                    title = stringResource(R.string.dictionary_detail_synonyms),
                    values = sense.definitionSynonyms,
                    openableLinkedWords = openableLinkedWords,
                    onOpenLinkedWord = onOpenLinkedWord,
                    readingTextScale = readingTextScale,
                )
            }

            if (sense.definitionAntonyms.isNotEmpty()) {
                DictionaryDetailRelationshipSection(
                    title = stringResource(R.string.dictionary_detail_antonyms),
                    values = sense.definitionAntonyms,
                    openableLinkedWords = openableLinkedWords,
                    onOpenLinkedWord = onOpenLinkedWord,
                    readingTextScale = readingTextScale,
                )
            }

            if (sense.examples.isNotEmpty()) {
                Text(
                    text = stringResource(R.string.dictionary_detail_examples),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )

                sense.examples.forEach { example ->
                    DictionaryExampleBlock(
                        example = example,
                        onPlayExampleAudio = onPlayExampleAudio,
                        readingTextScale = readingTextScale,
                    )
                }
            }
        }
    }
}

@Composable
private fun DictionaryExampleBlock(
    example: DictionaryExample,
    onPlayExampleAudio: (DictionaryExample) -> Unit,
    readingTextScale: Double,
) {
    val scaledBodyLargeStyle = MaterialTheme.typography.bodyLarge.copy(
        fontSize = MaterialTheme.typography.bodyLarge.fontSize * readingTextScale.toFloat(),
    )
    val scaledBodyMediumStyle = MaterialTheme.typography.bodyMedium.copy(
        fontSize = MaterialTheme.typography.bodyMedium.fontSize * readingTextScale.toFloat(),
    )
    val scaledBodySmallStyle = MaterialTheme.typography.bodySmall.copy(
        fontSize = MaterialTheme.typography.bodySmall.fontSize * readingTextScale.toFloat(),
    )

    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.Top,
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                if (example.hanji.isNotBlank()) {
                    DictionaryFallbackText(
                        text = example.hanji,
                        style = scaledBodyLargeStyle,
                    )
                }
                if (example.romanization.isNotBlank()) {
                    DictionaryFallbackText(
                        text = example.romanization,
                        style = scaledBodyMediumStyle,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                if (example.mandarin.isNotBlank()) {
                    DictionaryFallbackText(
                        text = example.mandarin,
                        style = scaledBodySmallStyle,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            if (example.audioId.isNotBlank()) {
                IconButton(onClick = { onPlayExampleAudio(example) }) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Outlined.VolumeUp,
                        contentDescription = stringResource(R.string.dictionary_play_example_audio),
                        tint = MaterialTheme.colorScheme.primary,
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun DictionaryDetailRelationshipSection(
    title: String,
    values: List<String>,
    openableLinkedWords: Set<String>,
    onOpenLinkedWord: (String) -> Unit,
    readingTextScale: Double,
) {
    val scaledLabelStyle = MaterialTheme.typography.labelLarge.copy(
        fontSize = MaterialTheme.typography.labelLarge.fontSize * readingTextScale.toFloat(),
    )
    val scaledChipStyle = MaterialTheme.typography.bodySmall.copy(
        fontSize = MaterialTheme.typography.bodySmall.fontSize * readingTextScale.toFloat(),
    )

    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            text = title,
            style = scaledLabelStyle,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            values.forEach { value ->
                AssistChip(
                    onClick = { onOpenLinkedWord(value) },
                    enabled = openableLinkedWords.contains(value),
                    label = {
                        DictionaryFallbackText(
                            text = value,
                            style = scaledChipStyle,
                        )
                    },
                    colors = AssistChipDefaults.assistChipColors(),
                )
            }
        }
    }
}

private fun shareEntry(
    context: android.content.Context,
    title: String,
    text: String,
) {
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

private fun audioResultMessage(
    result: DictionaryAudioPlaybackResult,
    missingClipMessage: String,
    unavailableMessage: String,
): String? {
    return when (result) {
        DictionaryAudioPlaybackResult.Played -> null
        is DictionaryAudioPlaybackResult.Failed -> when (result.reason) {
            DictionaryAudioPlaybackResult.FailureReason.MissingClipId -> missingClipMessage
            DictionaryAudioPlaybackResult.FailureReason.ArchiveNotDownloaded -> unavailableMessage
            DictionaryAudioPlaybackResult.FailureReason.AudioClipNotFound -> unavailableMessage
            DictionaryAudioPlaybackResult.FailureReason.AudioNotAvailable -> unavailableMessage
        }
    }
}
