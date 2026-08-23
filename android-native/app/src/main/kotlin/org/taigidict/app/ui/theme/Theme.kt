package org.taigidict.app.ui.theme

import android.app.WallpaperColors
import android.app.WallpaperManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext

private val LightColors = lightColorScheme(
    primary = BrandBlueLightPrimary,
    onPrimary = BrandBlueLightOnPrimary,
    primaryContainer = BrandBlueLightPrimaryContainer,
    onPrimaryContainer = BrandBlueLightOnPrimaryContainer,
    secondaryContainer = BrandBlueLightSecondaryContainer,
    tertiaryContainer = BrandBlueLightTertiaryContainer,
)

private val DarkColors = darkColorScheme(
    primary = BrandBlueDarkPrimary,
    onPrimary = BrandBlueDarkOnPrimary,
    primaryContainer = BrandBlueDarkPrimaryContainer,
    onPrimaryContainer = BrandBlueDarkOnPrimaryContainer,
    secondaryContainer = BrandBlueDarkSecondaryContainer,
    tertiaryContainer = BrandBlueDarkTertiaryContainer,
)

@Composable
fun TaigiDictTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    readingTextScale: Float = 1f,
    content: @Composable () -> Unit,
) {
    val context = LocalContext.current
    val systemColorGeneration = rememberSystemColorGeneration()

    val colorScheme = when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && darkTheme -> {
            systemColorGeneration
            dynamicDarkColorScheme(context)
        }
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !darkTheme -> {
            systemColorGeneration
            dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColors
        else -> LightColors
    }

    val typography = remember(readingTextScale) {
        AppTypography.scaled(readingTextScale)
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = typography,
        content = content,
    )
}

@Composable
private fun rememberSystemColorGeneration(): Int {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
        return 0
    }

    val context = LocalContext.current
    val wallpaperManager = remember(context) {
        context.getSystemService(WallpaperManager::class.java)
    }
    var generation by remember { mutableIntStateOf(0) }

    DisposableEffect(wallpaperManager) {
        val listener = WallpaperManager.OnColorsChangedListener { _: WallpaperColors?, _: Int ->
            generation += 1
        }
        val handler = Handler(Looper.getMainLooper())
        wallpaperManager?.addOnColorsChangedListener(listener, handler)

        onDispose {
            wallpaperManager?.removeOnColorsChangedListener(listener)
        }
    }

    return generation
}
