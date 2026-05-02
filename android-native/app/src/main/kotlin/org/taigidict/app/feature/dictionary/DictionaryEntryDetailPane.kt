package org.taigidict.app.feature.dictionary

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AssistChip
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import org.taigidict.app.R
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
            entry = entry,
            openableLinkedWords = openableLinkedWords,
            isBookmarked = isBookmarked,
            onToggleBookmark = onToggleBookmark,
            onOpenLinkedWord = onOpenLinkedWord,
        )
    }
}

@Composable
private fun DictionaryEntryDetailContent(
    entry: DictionaryEntry,
    openableLinkedWords: Set<String>,
    isBookmarked: Boolean,
    onToggleBookmark: () -> Unit,
    onOpenLinkedWord: (String) -> Unit,
) {
    LazyColumn(
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
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
                val metadataLine = listOf(entry.type, entry.category)
                    .filter { it.isNotBlank() }
                    .joinToString(separator = " · ")
                if (metadataLine.isNotBlank()) {
                    Text(
                        text = metadataLine,
                        style = MaterialTheme.typography.bodyMedium,
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
                    DictionaryExampleBlock(example = example)
                }
            }
        }
    }
}

@Composable
private fun DictionaryExampleBlock(example: DictionaryExample) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
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