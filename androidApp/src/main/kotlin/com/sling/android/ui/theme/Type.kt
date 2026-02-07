package com.sling.android.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.sling.android.R

/**
 * Inter font family - matches iOS
 */
val InterFontFamily = FontFamily(
    Font(R.font.inter_regular, FontWeight.Normal),
    Font(R.font.inter_medium, FontWeight.Medium),
    Font(R.font.inter_bold, FontWeight.Bold)
)

/**
 * Sling Typography - matches iOS DesignSystem.Typography
 */
object SlingTypography {
    // Large display text (balance)
    val amountExtraLarge = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 62.sp,
        letterSpacing = (-1.24).sp // -2%
    )
    
    val amountLarge = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 56.sp,
        letterSpacing = (-1.12).sp // -2%
    )
    
    // H1 - Largest heading
    val h1 = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 40.sp,
        letterSpacing = (-0.80).sp // -2%
    )
    
    // H2 - Page headings
    val h2 = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 32.sp,
        letterSpacing = (-0.64).sp // -2%
    )
    
    // H3 - Card titles
    val h3 = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 20.sp,
        letterSpacing = (-0.40).sp // -2%
    )
    
    // Header title
    val headerTitle = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 17.sp,
        letterSpacing = (-0.34).sp // -2%
    )
    
    // Body text variants
    val bodyRegular = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        letterSpacing = (-0.32).sp, // -2%
        lineHeight = 24.sp // 1.5 line height
    )
    
    val bodyMedium = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp,
        letterSpacing = (-0.32).sp
    )
    
    val bodyBold = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 16.sp,
        letterSpacing = (-0.32).sp
    )
    
    // Row/List text
    val rowTitle = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 16.sp,
        letterSpacing = (-0.32).sp
    )
    
    val rowSubtitle = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        letterSpacing = (-0.28).sp
    )
    
    // Button text
    val button = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 16.sp,
        letterSpacing = (-0.32).sp
    )
    
    // Small text
    val caption = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 13.sp,
        letterSpacing = (-0.26).sp
    )
    
    // Label text
    val label = TextStyle(
        fontFamily = InterFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 13.sp,
        letterSpacing = (-0.26).sp
    )
}

/**
 * Material3 Typography using Inter font
 */
val SlingMaterial3Typography = Typography(
    displayLarge = SlingTypography.amountLarge,
    displayMedium = SlingTypography.h1,
    displaySmall = SlingTypography.h2,
    headlineLarge = SlingTypography.h2,
    headlineMedium = SlingTypography.h3,
    headlineSmall = SlingTypography.headerTitle,
    titleLarge = SlingTypography.headerTitle,
    titleMedium = SlingTypography.bodyBold,
    titleSmall = SlingTypography.rowTitle,
    bodyLarge = SlingTypography.bodyRegular,
    bodyMedium = SlingTypography.rowSubtitle,
    bodySmall = SlingTypography.caption,
    labelLarge = SlingTypography.button,
    labelMedium = SlingTypography.label,
    labelSmall = SlingTypography.caption
)
