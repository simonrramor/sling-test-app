package com.sling.android.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Sling App Color Palette - matches iOS DesignSystem.Colors
 */
object SlingColors {
    // Primary
    val Primary = Color(0xFFFF5113)           // Orange - primary action color
    
    // Dark/Light
    val Dark = Color(0xFF080808)              // Near black - primary text, dark backgrounds
    val White = Color(0xFFFFFFFF)             // White
    val BackgroundLight = Color(0xFFF5F5F5)   // Light gray background
    
    // Grays
    val Tertiary = Color(0xFFEDEDED)          // Tertiary button background
    val TextSecondary = Color(0xFF8E8E93)     // Secondary text
    val TextTertiary = Color(0xFF7B7B7B)      // Tertiary/body text
    val Divider = Color(0xFF2A2A2A)           // Divider on dark backgrounds
    val DividerLight = Color(0xFFE5E5E5)      // Divider on light backgrounds
    
    // Cards
    val CardDark = Color(0xFF1B1B1B)          // Dark card background
    val CardLight = Color(0xFFFFFFFF)         // Light card background
    val CardBorder = Color(0xFFF0F0F0)        // Card border on light backgrounds
    
    // Status Colors
    val PositiveGreen = Color(0xFF57CE43)     // Positive/increase state
    val NegativeRed = Color(0xFFE30000)       // Negative/decrease state
    
    // Accent Colors (from iOS GetStartedCards)
    val AccentBlue = Color(0xFF74CDFF)
    val AccentBlueBg = Color(0xFFE8F8FF)
    val AccentGreen = Color(0xFF78D381)
    val AccentGreenBg = Color(0xFFE9FAEB)
    val AccentYellow = Color(0xFFFFC774)
    val AccentYellowBg = Color(0xFFFFF5E5)
    val AccentPink = Color(0xFFFF74E0)
    val AccentPinkBg = Color(0xFFFFE8F9)
    val AccentPurple = Color(0xFF8B74FF)
    val AccentPurpleBg = Color(0xFFEDE8FF)
    val AccentOrange = Color(0xFFFF8C42)
    val AccentOrangeBg = Color(0xFFFFF0E8)
}
