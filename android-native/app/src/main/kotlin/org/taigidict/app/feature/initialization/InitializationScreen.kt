package org.taigidict.app.feature.initialization

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.Button
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlin.math.roundToInt
import org.taigidict.app.R

@Composable
fun InitializationScreen(
    uiState: InitializationUiState,
    onRetry: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = stringResource(R.string.initialization_title),
            style = MaterialTheme.typography.headlineMedium,
            textAlign = TextAlign.Center,
        )
        Text(
            modifier = Modifier.padding(top = 12.dp),
            text = stringResource(R.string.initialization_body),
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
        )
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 24.dp),
        ) {
            Column(
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 18.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(
                    text = uiState.phase.label(),
                    style = MaterialTheme.typography.titleMedium,
                )
                LinearProgressIndicator(
                    modifier = Modifier.fillMaxWidth(),
                    progress = { uiState.progress ?: 0f },
                )
                uiState.progress?.let { progress ->
                    Text(
                        text = "${(progress * 100).roundToInt()}%",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                if (uiState.processedEntries != null && uiState.totalEntries != null) {
                    Text(
                        text = "${uiState.processedEntries} / ${uiState.totalEntries}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                if (uiState.errorMessage != null) {
                    Text(
                        text = uiState.errorMessage,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            }
        }
        if (uiState.phase == InitializationPhase.Error) {
            Button(
                modifier = Modifier.padding(top = 24.dp),
                onClick = onRetry,
            ) {
                Text(text = stringResource(R.string.retry))
            }
        }
    }
}

@Composable
private fun InitializationPhase.label(): String {
    return when (this) {
        InitializationPhase.CheckingResources -> stringResource(R.string.initialization_phase_checking_resources)
        InitializationPhase.RestoringBundledSource -> stringResource(R.string.initialization_phase_restoring_bundled_source)
        InitializationPhase.DownloadingSource -> stringResource(R.string.initialization_phase_downloading_source)
        InitializationPhase.RebuildingDatabase -> stringResource(R.string.initialization_phase_rebuilding_database)
        InitializationPhase.Ready -> stringResource(R.string.initialization_phase_ready)
        InitializationPhase.Error -> stringResource(R.string.initialization_phase_error)
    }
}
