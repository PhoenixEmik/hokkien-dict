package org.taigidict.app.ui.theme

import org.junit.Assert.assertEquals
import org.junit.Test

class TypographyScaleTest {
    @Test
    fun scaled_scalesMaterialTypographyStyles() {
        val scaled = AppTypography.scaled(1.2f)

        assertEquals(
            AppTypography.bodyLarge.fontSize.value * 1.2f,
            scaled.bodyLarge.fontSize.value,
            0.001f,
        )
        assertEquals(
            AppTypography.titleMedium.fontSize.value * 1.2f,
            scaled.titleMedium.fontSize.value,
            0.001f,
        )
    }
}
