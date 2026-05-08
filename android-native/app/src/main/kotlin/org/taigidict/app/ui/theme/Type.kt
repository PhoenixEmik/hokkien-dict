package org.taigidict.app.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.TextUnit

val AppTypography = Typography()

fun Typography.scaled(scale: Float): Typography {
    if (scale == 1f) {
        return this
    }

    return copy(
        displayLarge = displayLarge.scaled(scale),
        displayMedium = displayMedium.scaled(scale),
        displaySmall = displaySmall.scaled(scale),
        headlineLarge = headlineLarge.scaled(scale),
        headlineMedium = headlineMedium.scaled(scale),
        headlineSmall = headlineSmall.scaled(scale),
        titleLarge = titleLarge.scaled(scale),
        titleMedium = titleMedium.scaled(scale),
        titleSmall = titleSmall.scaled(scale),
        bodyLarge = bodyLarge.scaled(scale),
        bodyMedium = bodyMedium.scaled(scale),
        bodySmall = bodySmall.scaled(scale),
        labelLarge = labelLarge.scaled(scale),
        labelMedium = labelMedium.scaled(scale),
        labelSmall = labelSmall.scaled(scale),
    )
}

private fun TextStyle.scaled(scale: Float): TextStyle {
    return copy(
        fontSize = fontSize.scaled(scale),
        lineHeight = lineHeight.scaled(scale),
    )
}

private fun TextUnit.scaled(scale: Float): TextUnit {
    return if (this == TextUnit.Unspecified) this else this * scale
}
