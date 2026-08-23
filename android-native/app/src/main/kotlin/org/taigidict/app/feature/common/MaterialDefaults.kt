package org.taigidict.app.feature.common

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun appPageContainerColor(): Color = MaterialTheme.colorScheme.surfaceContainer

@Composable
fun appTopBarContainerColor(): Color = MaterialTheme.colorScheme.surfaceContainer

@Composable
fun appCardColors() = CardDefaults.cardColors(
    containerColor = appPanelContainerColor(),
)

@Composable
fun appPanelContainerColor(): Color = MaterialTheme.colorScheme.surfaceContainerLow

@Composable
fun appListContainerColor(): Color = appPanelContainerColor()

@Composable
fun appSelectedContainerColor(): Color = MaterialTheme.colorScheme.secondaryContainer

@Composable
fun transparentListItemColors() = ListItemDefaults.colors(
    containerColor = Color.Transparent,
)

@Composable
fun selectableListItemColors(isSelected: Boolean) = ListItemDefaults.colors(
    containerColor = if (isSelected) {
        appSelectedContainerColor()
    } else {
        Color.Transparent
    },
)

@Composable
fun AppListDivider(
    modifier: Modifier = Modifier,
    inset: Dp = 16.dp,
) {
    HorizontalDivider(
        modifier = modifier.padding(horizontal = inset),
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.38f),
    )
}
