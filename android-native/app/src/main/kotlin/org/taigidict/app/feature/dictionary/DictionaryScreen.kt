package org.taigidict.app.feature.dictionary

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import org.taigidict.app.R

@Composable
fun DictionaryScreen(
    manifestAssetPath: String,
    entriesAssetPath: String,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = stringResource(R.string.dictionary_placeholder_title),
            style = MaterialTheme.typography.headlineMedium,
        )
        Text(
            text = stringResource(R.string.dictionary_placeholder_body),
            style = MaterialTheme.typography.bodyLarge,
        )
        Text(
            text = stringResource(R.string.bundled_manifest_label, manifestAssetPath),
            style = MaterialTheme.typography.bodyMedium,
        )
        Text(
            text = stringResource(R.string.bundled_entries_label, entriesAssetPath),
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}
