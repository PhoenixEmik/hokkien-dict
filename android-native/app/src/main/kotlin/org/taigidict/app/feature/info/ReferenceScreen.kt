package org.taigidict.app.feature.info

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Deprecated(
    message = "Use ReferenceArticleScreen instead.",
    replaceWith = ReplaceWith("ReferenceArticleScreen(onBack, modifier)"),
)
@Composable
fun ReferenceScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    ReferenceArticleScreen(
        onBack = onBack,
        modifier = modifier,
    )
}
