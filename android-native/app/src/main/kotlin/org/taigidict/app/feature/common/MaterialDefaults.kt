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
fun appPageContainerColor(): Color = MaterialTheme.colorScheme.surfaceContainerLowest

@Composable
fun appCardColors() = CardDefaults.cardColors(
    containerColor = MaterialTheme.colorScheme.surface,
)

@Composable
fun appListContainerColor(): Color = MaterialTheme.colorScheme.surface

@Composable
fun transparentListItemColors() = ListItemDefaults.colors(
    containerColor = Color.Transparent,
)

@Composable
fun selectableListItemColors(isSelected: Boolean) = ListItemDefaults.colors(
    containerColor = if (isSelected) {
        MaterialTheme.colorScheme.secondaryContainer
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
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f),
    )
}
