package org.taigidict.app.feature.dictionary

import android.app.Activity
import android.content.Intent
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
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
import androidx.compose.material.icons.outlined.Pause
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.data.audio.DictionaryAudioPlaybackState
import org.taigidict.app.data.audio.DictionaryAudioPlaybackResult
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense
import org.taigidict.app.feature.common.DictionaryFallbackText
import org.taigidict.app.feature.common.buildDictionaryAnnotatedString

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
    val playbackState = audioPlayer.playbackState.collectAsState(initial = DictionaryAudioPlaybackState.Idle).value
    val scope = rememberCoroutineScope()
    var audioMessage by remember(entry?.id) { mutableStateOf<String?>(null) }

    when {
        isLoading -> DetailLoadingScreen(
            title = entry?.hanji.orEmpty(),
            onBack = onBack,
            isBookmarked = isBookmarked,
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
            playbackState = playbackState,
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
private fun DetailLoadingScreen(
    title: String,
    onBack: () -> Unit,
    isBookmarked: Boolean,
    modifier: Modifier = Modifier,
) {
    val transition = rememberInfiniteTransition(label = "dictionary-detail-loading")
    val pulseAlpha by transition.animateFloat(
        initialValue = 0.45f,
        targetValue = 0.95f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 900),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "dictionary-detail-loading-alpha",
    )

    Scaffold(
        modifier = modifier,
        topBar = {
            DetailTopBar(
                title = title,
                onBack = onBack,
                onShareEntry = {},
                onToggleBookmark = {},
                isBookmarked = isBookmarked,
                showActions = false,
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = DetailHorizontalPadding, vertical = DetailVerticalPadding)
                .testTag("dictionary-detail-loading"),
            verticalArrangement = Arrangement.spacedBy(DetailSectionSpacing),
        ) {
            item("header") {
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
                    shape = RoundedCornerShape(16.dp),
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 20.dp, vertical = 18.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        DetailSkeletonLine(
                            widthFraction = 0.48f,
                            height = 34.dp,
                            alpha = pulseAlpha,
                        )
                        DetailSkeletonLine(
                            widthFraction = 0.24f,
                            height = 22.dp,
                            alpha = pulseAlpha,
                        )
                        DetailSkeletonLine(
                            widthFraction = 0.36f,
                            height = 18.dp,
                            alpha = pulseAlpha,
                        )
                    }
                }
            }

            items(2, key = { index -> "sense-loading-$index" }) {
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
                        DetailSkeletonLine(
                            widthFraction = 0.18f,
                            height = 20.dp,
                            alpha = pulseAlpha,
                        )
                        DetailSkeletonLine(
                            widthFraction = 0.92f,
                            height = 18.dp,
                            alpha = pulseAlpha,
                        )
                        DetailSkeletonLine(
                            widthFraction = 0.76f,
                            height = 18.dp,
                            alpha = pulseAlpha,
                        )
                        DetailSkeletonLine(
                            widthFraction = 0.28f,
                            height = 16.dp,
                            alpha = pulseAlpha,
                        )
                        Card(
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceContainerLow,
                            ),
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
                                    verticalArrangement = Arrangement.spacedBy(6.dp),
                                ) {
                                    DetailSkeletonLine(
                                        widthFraction = 0.58f,
                                        height = 18.dp,
                                        alpha = pulseAlpha,
                                    )
                                    DetailSkeletonLine(
                                        widthFraction = 0.72f,
                                        height = 16.dp,
                                        alpha = pulseAlpha,
                                    )
                                    DetailSkeletonLine(
                                        widthFraction = 0.44f,
                                        height = 14.dp,
                                        alpha = pulseAlpha,
                                    )
                                }
                                Box(
                                    modifier = Modifier
                                        .size(20.dp)
                                        .background(
                                            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = pulseAlpha),
                                            shape = RoundedCornerShape(10.dp),
                                        ),
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
private fun DetailSkeletonLine(
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
                shape = RoundedCornerShape(999.dp),
            ),
    )
}

@Composable
private fun DictionaryEntryDetailContent(
    audioMessage: String?,
    entry: DictionaryEntry,
    openableLinkedWords: Set<String>,
    playbackState: DictionaryAudioPlaybackState,
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
    val entryAudioUiState = remember(playbackState, entry.audioId) {
        resolveAudioUiState(
            playbackState = playbackState,
            clipKey = clipKeyForWord(entry.audioId),
        )
    }

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
                    verticalArrangement = Arrangement.spacedBy(12.dp),
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

                        AudioActionButton(
                            uiState = entryAudioUiState,
                            enabled = entry.audioId.isNotBlank(),
                            contentDescription = stringResource(R.string.dictionary_play_word_audio),
                            onClick = onPlayEntryAudio,
                        )
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

            if (entry.variantChars.isNotEmpty()) {
                item("variants-${entry.id}") {
                    DictionaryDetailRelationshipSection(
                        title = stringResource(R.string.dictionary_detail_variants),
                        values = entry.variantChars,
                        openableLinkedWords = openableLinkedWords,
                        onOpenLinkedWord = onOpenLinkedWord,
                        readingTextScale = readingTextScale,
                    )
                }
            }

            if (entry.wordSynonyms.isNotEmpty()) {
                item("word-synonyms-${entry.id}") {
                    DictionaryDetailRelationshipSection(
                        title = stringResource(R.string.dictionary_detail_synonyms),
                        values = entry.wordSynonyms,
                        openableLinkedWords = openableLinkedWords,
                        onOpenLinkedWord = onOpenLinkedWord,
                        readingTextScale = readingTextScale,
                    )
                }
            }

            if (entry.wordAntonyms.isNotEmpty()) {
                item("word-antonyms-${entry.id}") {
                    DictionaryDetailRelationshipSection(
                        title = stringResource(R.string.dictionary_detail_antonyms),
                        values = entry.wordAntonyms,
                        openableLinkedWords = openableLinkedWords,
                        onOpenLinkedWord = onOpenLinkedWord,
                        readingTextScale = readingTextScale,
                    )
                }
            }

            if (entry.alternativePronunciations.isNotEmpty()) {
                item("alt-pronunciations-${entry.id}") {
                    DictionaryDetailStaticSection(
                        title = stringResource(R.string.dictionary_detail_alternative_pronunciations),
                        values = entry.alternativePronunciations,
                        readingTextScale = readingTextScale,
                    )
                }
            }

            if (entry.contractedPronunciations.isNotEmpty()) {
                item("contracted-pronunciations-${entry.id}") {
                    DictionaryDetailStaticSection(
                        title = stringResource(R.string.dictionary_detail_contracted_pronunciations),
                        values = entry.contractedPronunciations,
                        readingTextScale = readingTextScale,
                    )
                }
            }

            if (entry.colloquialPronunciations.isNotEmpty()) {
                item("colloquial-pronunciations-${entry.id}") {
                    DictionaryDetailStaticSection(
                        title = stringResource(R.string.dictionary_detail_colloquial_pronunciations),
                        values = entry.colloquialPronunciations,
                        readingTextScale = readingTextScale,
                    )
                }
            }

            items(entry.senses.size, key = { index -> "sense-${entry.id}-$index" }) { index ->
                DictionarySenseSection(
                    sense = entry.senses[index],
                    readingTextScale = readingTextScale,
                    openableLinkedWords = openableLinkedWords,
                    playbackState = playbackState,
                    onPlayExampleAudio = onPlayExampleAudio,
                    onOpenLinkedWord = onOpenLinkedWord,
                )
            }

            if (entry.vocabularyComparisons.isNotEmpty()) {
                item("vocabulary-comparisons-${entry.id}") {
                    DictionaryDetailListSection(
                        title = stringResource(R.string.dictionary_detail_vocabulary_comparisons),
                        values = entry.vocabularyComparisons,
                        readingTextScale = readingTextScale,
                    )
                }
            }

            if (entry.phoneticDifferences.isNotEmpty()) {
                item("phonetic-differences-${entry.id}") {
                    DictionaryDetailListSection(
                        title = stringResource(R.string.dictionary_detail_phonetic_differences),
                        values = entry.phoneticDifferences,
                        readingTextScale = readingTextScale,
                    )
                }
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
    sense: DictionarySense,
    readingTextScale: Double,
    openableLinkedWords: Set<String>,
    playbackState: DictionaryAudioPlaybackState,
    onPlayExampleAudio: (DictionaryExample) -> Unit,
    onOpenLinkedWord: (String) -> Unit,
) {
    val scaledTitleStyle = MaterialTheme.typography.titleLarge.copy(
        fontSize = MaterialTheme.typography.titleMedium.fontSize * readingTextScale.toFloat(),
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
            if (sense.partOfSpeech.isNotBlank()) {
                DictionaryFallbackText(
                    text = sense.partOfSpeech,
                    style = scaledTitleStyle,
                    color = MaterialTheme.colorScheme.primary,
                )
            }

            LinkedDefinitionText(
                text = sense.definition,
                style = scaledBodyStyle,
                openableLinkedWords = openableLinkedWords,
                onOpenLinkedWord = onOpenLinkedWord,
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
                        playbackState = playbackState,
                        onPlayExampleAudio = onPlayExampleAudio,
                        readingTextScale = readingTextScale,
                    )
                }
            }
        }
    }
}

@Composable
private fun DictionaryDetailListSection(
    title: String,
    values: List<String>,
    readingTextScale: Double,
) {
    val scaledLabelStyle = MaterialTheme.typography.labelLarge.copy(
        fontSize = MaterialTheme.typography.labelLarge.fontSize * readingTextScale.toFloat(),
    )
    val scaledBodyStyle = MaterialTheme.typography.bodyMedium.copy(
        fontSize = MaterialTheme.typography.bodyMedium.fontSize * readingTextScale.toFloat(),
    )

    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(16.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                text = title,
                style = scaledLabelStyle,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            values.forEachIndexed { index, value ->
                DictionaryFallbackText(
                    text = value,
                    style = scaledBodyStyle,
                )
                if (index < values.lastIndex) {
                    HorizontalDivider(thickness = 0.5.dp)
                }
            }
        }
    }
}

@Composable
private fun DictionaryExampleBlock(
    example: DictionaryExample,
    playbackState: DictionaryAudioPlaybackState,
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

    val audioUiState = remember(playbackState, example.audioId) {
        resolveAudioUiState(
            playbackState = playbackState,
            clipKey = clipKeyForSentence(example.audioId),
        )
    }

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
            AudioActionButton(
                uiState = audioUiState,
                enabled = example.audioId.isNotBlank(),
                contentDescription = stringResource(R.string.dictionary_play_example_audio),
                onClick = { onPlayExampleAudio(example) },
            )
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

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun DictionaryDetailStaticSection(
    title: String,
    values: List<String>,
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
                    onClick = {},
                    enabled = false,
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

@Composable
private fun LinkedDefinitionText(
    text: String,
    style: TextStyle,
    openableLinkedWords: Set<String>,
    onOpenLinkedWord: (String) -> Unit,
) {
    val linkStyle = SpanStyle(
        color = MaterialTheme.colorScheme.primary,
        textDecoration = TextDecoration.Underline,
    )
    val annotatedText = remember(text, openableLinkedWords, linkStyle, onOpenLinkedWord) {
        val links = DictionaryLinkedWordMatcher.findLinks(text, openableLinkedWords)
        buildDictionaryAnnotatedString(
            text = text,
            links = links,
            linkStyle = linkStyle,
            onClickLink = onOpenLinkedWord,
        )
    }

    Text(
        text = annotatedText,
        style = style.copy(color = MaterialTheme.colorScheme.onSurface),
    )
}

@Composable
private fun AudioActionButton(
    uiState: DictionaryAudioUiState,
    enabled: Boolean,
    contentDescription: String,
    onClick: () -> Unit,
) {
    if (!enabled) {
        return
    }

    when (uiState) {
        DictionaryAudioUiState.Loading -> {
            Box(
                modifier = Modifier.size(48.dp),
                contentAlignment = Alignment.Center,
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                )
            }
        }

        DictionaryAudioUiState.Playing -> {
            IconButton(onClick = onClick) {
                Icon(
                    imageVector = Icons.Outlined.Pause,
                    contentDescription = contentDescription,
                    tint = MaterialTheme.colorScheme.primary,
                )
            }
        }

        DictionaryAudioUiState.Idle -> {
            IconButton(onClick = onClick) {
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.VolumeUp,
                    contentDescription = contentDescription,
                    tint = MaterialTheme.colorScheme.primary,
                )
            }
        }
    }
}

private enum class DictionaryAudioUiState {
    Idle,
    Loading,
    Playing,
}

private fun resolveAudioUiState(
    playbackState: DictionaryAudioPlaybackState,
    clipKey: String,
): DictionaryAudioUiState {
    return when (playbackState) {
        DictionaryAudioPlaybackState.Idle -> DictionaryAudioUiState.Idle
        is DictionaryAudioPlaybackState.Loading ->
            if (playbackState.clipKey == clipKey) DictionaryAudioUiState.Loading else DictionaryAudioUiState.Idle
        is DictionaryAudioPlaybackState.Playing ->
            if (playbackState.clipKey == clipKey) DictionaryAudioUiState.Playing else DictionaryAudioUiState.Idle
    }
}

private fun clipKeyForWord(audioId: String): String = "word:${audioId.trim()}"

private fun clipKeyForSentence(audioId: String): String = "sentence:${audioId.trim()}"
