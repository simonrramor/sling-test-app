package com.sling.android.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * Light color scheme for Sling
 */
private val LightColorScheme = lightColorScheme(
    primary = SlingColors.Primary,
    onPrimary = Color.White,
    primaryContainer = SlingColors.Primary,
    onPrimaryContainer = Color.White,
    secondary = SlingColors.Dark,
    onSecondary = Color.White,
    secondaryContainer = SlingColors.Tertiary,
    onSecondaryContainer = SlingColors.Dark,
    tertiary = SlingColors.AccentBlue,
    onTertiary = Color.White,
    background = Color.White,
    onBackground = SlingColors.Dark,
    surface = Color.White,
    onSurface = SlingColors.Dark,
    surfaceVariant = SlingColors.BackgroundLight,
    onSurfaceVariant = SlingColors.TextSecondary,
    outline = SlingColors.DividerLight,
    outlineVariant = SlingColors.CardBorder,
    error = SlingColors.NegativeRed,
    onError = Color.White
)

/**
 * Dark color scheme for Sling
 */
private val DarkColorScheme = darkColorScheme(
    primary = SlingColors.Primary,
    onPrimary = Color.White,
    primaryContainer = SlingColors.Primary,
    onPrimaryContainer = Color.White,
    secondary = Color.White,
    onSecondary = SlingColors.Dark,
    secondaryContainer = SlingColors.CardDark,
    onSecondaryContainer = Color.White,
    tertiary = SlingColors.AccentBlue,
    onTertiary = SlingColors.Dark,
    background = SlingColors.Dark,
    onBackground = Color.White,
    surface = SlingColors.Dark,
    onSurface = Color.White,
    surfaceVariant = SlingColors.CardDark,
    onSurfaceVariant = SlingColors.TextSecondary,
    outline = SlingColors.Divider,
    outlineVariant = SlingColors.Divider,
    error = SlingColors.NegativeRed,
    onError = Color.White
)

@Composable
fun SlingTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.background.toArgb()
            window.navigationBarColor = colorScheme.background.toArgb()
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !darkTheme
                isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = SlingMaterial3Typography,
        content = content
    )
}
