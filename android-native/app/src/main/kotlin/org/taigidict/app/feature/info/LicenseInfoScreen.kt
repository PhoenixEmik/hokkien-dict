package org.taigidict.app.feature.info

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Deprecated(
    message = "Use LicenseSummaryScreen instead.",
    replaceWith = ReplaceWith("LicenseSummaryScreen(onBack, onOpenThirdPartyLicenses, modifier)"),
)
@Composable
fun LicenseInfoScreen(
    onBack: () -> Unit,
    onOpenThirdPartyLicenses: () -> Unit,
    modifier: Modifier = Modifier,
) {
    LicenseSummaryScreen(
        onBack = onBack,
        onOpenThirdPartyLicenses = onOpenThirdPartyLicenses,
        modifier = modifier,
    )
}
