package org.taigidict.app.feature.dictionary

import android.app.Activity
import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material.icons.outlined.VolumeUp
import androidx.compose.material3.AssistChip
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import org.taigidict.app.R
import org.taigidict.app.app.TaigiDictApplication
import org.taigidict.app.data.audio.DictionaryAudioPlaybackResult
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense

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
) {
    val context = LocalContext.current
    val appContainer = (context.applicationContext as TaigiDictApplication).appContainer
    val audioPlayer = appContainer.dictionaryAudioPlayer
    val scope = rememberCoroutineScope()
    var audioMessage by remember(entry?.id) { mutableStateOf<String?>(null) }

    FilledTonalButton(onClick = onBack) {
        Text(text = stringResource(R.string.dictionary_detail_back))
    }

    when {
        isLoading -> Text(
            text = stringResource(R.string.dictionary_detail_loading),
            style = MaterialTheme.typography.bodyMedium,
        )

        errorMessage != null -> Text(
            text = stringResource(R.string.dictionary_detail_error, errorMessage),
            style = MaterialTheme.typography.bodyMedium,
        )

        entry != null -> DictionaryEntryDetailContent(
            audioMessage = audioMessage,
            entry = entry,
            openableLinkedWords = openableLinkedWords,
            isBookmarked = isBookmarked,
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
        )
    }
}

@Composable
private fun DictionaryEntryDetailContent(
    audioMessage: String?,
    entry: DictionaryEntry,
    openableLinkedWords: Set<String>,
    isBookmarked: Boolean,
    onToggleBookmark: () -> Unit,
    onShareEntry: () -> Unit,
    onPlayEntryAudio: () -> Unit,
    onPlayExampleAudio: (DictionaryExample) -> Unit,
    onOpenLinkedWord: (String) -> Unit,
) {
    LazyColumn(
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.Top,
                ) {
                    Column(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Text(
                            text = entry.hanji,
                            style = MaterialTheme.typography.headlineMedium,
                        )
                        if (entry.romanization.isNotBlank()) {
                            Text(
                                text = entry.romanization,
                                style = MaterialTheme.typography.titleMedium,
                            )
                        }
                    }
                    if (entry.audioId.isNotBlank()) {
                        IconButton(onClick = onPlayEntryAudio) {
                            Icon(
                                imageVector = Icons.Outlined.VolumeUp,
                                contentDescription = stringResource(R.string.dictionary_play_word_audio),
                            )
                        }
                    }
                }
                val metadataLine = listOf(entry.type, entry.category)
                    .filter { it.isNotBlank() }
                    .joinToString(separator = " · ")
                if (metadataLine.isNotBlank()) {
                    Text(
                        text = metadataLine,
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedButton(onClick = onShareEntry) {
                        Icon(
                            imageVector = Icons.Outlined.Share,
                            contentDescription = null,
                        )
                        Text(
                            text = stringResource(R.string.dictionary_share_action),
                            modifier = Modifier.padding(start = 8.dp),
                        )
                    }
                    OutlinedButton(onClick = onToggleBookmark) {
                        Text(
                            text = if (isBookmarked) {
                                stringResource(R.string.dictionary_detail_remove_bookmark)
                            } else {
                                stringResource(R.string.dictionary_detail_add_bookmark)
                            },
                        )
                    }
                }
                if (audioMessage != null) {
                    Text(
                        text = audioMessage,
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
            }
        }

        if (entry.variantChars.isNotEmpty()) {
            item {
                DictionaryDetailRelationshipSection(
                    title = stringResource(R.string.dictionary_detail_variants),
                    values = entry.variantChars,
                    openableLinkedWords = openableLinkedWords,
                    onOpenLinkedWord = onOpenLinkedWord,
                )
            }
        }

        if (entry.wordSynonyms.isNotEmpty()) {
            item {
                DictionaryDetailRelationshipSection(
                    title = stringResource(R.string.dictionary_detail_synonyms),
                    values = entry.wordSynonyms,
                    openableLinkedWords = openableLinkedWords,
                    onOpenLinkedWord = onOpenLinkedWord,
                )
            }
        }

        if (entry.wordAntonyms.isNotEmpty()) {
            item {
                DictionaryDetailRelationshipSection(
                    title = stringResource(R.string.dictionary_detail_antonyms),
                    values = entry.wordAntonyms,
                    openableLinkedWords = openableLinkedWords,
                    onOpenLinkedWord = onOpenLinkedWord,
                )
            }
        }

        items(entry.senses.size, key = { index -> "sense-${entry.id}-$index" }) { index ->
            DictionarySenseSection(
                index = index,
                sense = entry.senses[index],
                openableLinkedWords = openableLinkedWords,
                onPlayExampleAudio = onPlayExampleAudio,
                onOpenLinkedWord = onOpenLinkedWord,
            )
        }

        item {
            Spacer(modifier = Modifier.padding(bottom = 8.dp))
        }
    }
}

@Composable
private fun DictionarySenseSection(
    index: Int,
    sense: DictionarySense,
    openableLinkedWords: Set<String>,
    onPlayExampleAudio: (DictionaryExample) -> Unit,
    onOpenLinkedWord: (String) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = stringResource(R.string.dictionary_detail_sense_title, index + 1),
            style = MaterialTheme.typography.titleMedium,
        )
        if (sense.partOfSpeech.isNotBlank()) {
            Text(
                text = sense.partOfSpeech,
                style = MaterialTheme.typography.labelLarge,
            )
        }
        Text(
            text = sense.definition,
            style = MaterialTheme.typography.bodyLarge,
        )
        if (sense.definitionSynonyms.isNotEmpty()) {
            DictionaryDetailRelationshipSection(
                title = stringResource(R.string.dictionary_detail_synonyms),
                values = sense.definitionSynonyms,
                openableLinkedWords = openableLinkedWords,
                onOpenLinkedWord = onOpenLinkedWord,
            )
        }
        if (sense.definitionAntonyms.isNotEmpty()) {
            DictionaryDetailRelationshipSection(
                title = stringResource(R.string.dictionary_detail_antonyms),
                values = sense.definitionAntonyms,
                openableLinkedWords = openableLinkedWords,
                onOpenLinkedWord = onOpenLinkedWord,
            )
        }
        if (sense.examples.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = stringResource(R.string.dictionary_detail_examples),
                    style = MaterialTheme.typography.labelLarge,
                )
                sense.examples.forEach { example ->
                    DictionaryExampleBlock(
                        example = example,
                        onPlayExampleAudio = onPlayExampleAudio,
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
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            if (example.hanji.isNotBlank()) {
                Text(
                    text = example.hanji,
                    style = MaterialTheme.typography.bodyLarge,
                )
            }
            if (example.romanization.isNotBlank()) {
                Text(
                    text = example.romanization,
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
            if (example.mandarin.isNotBlank()) {
                Text(
                    text = example.mandarin,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
        if (example.audioId.isNotBlank()) {
            IconButton(onClick = { onPlayExampleAudio(example) }) {
                Icon(
                    imageVector = Icons.Outlined.VolumeUp,
                    contentDescription = stringResource(R.string.dictionary_play_example_audio),
                )
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
) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(
            text = title,
            style = MaterialTheme.typography.labelLarge,
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
                        Text(text = value)
                    },
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
            DictionaryAudioPlaybackResult.FailureReason.AudioNotAvailable -> unavailableMessage
        }
    }
}