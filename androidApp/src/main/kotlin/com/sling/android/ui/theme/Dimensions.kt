package com.sling.android.ui.theme

import androidx.compose.ui.unit.dp

/**
 * Sling Design System Dimensions - matches iOS DesignSystem
 */
object SlingDimensions {
    // Spacing
    object Spacing {
        val xs = 4.dp
        val sm = 8.dp
        val md = 16.dp
        val lg = 24.dp
        val xl = 32.dp
    }
    
    // Corner Radius
    object CornerRadius {
        val small = 12.dp      // Small elements like tags, badges
        val medium = 16.dp     // Cards, rows, containers
        val large = 20.dp      // Buttons, large cards
        val pill = 28.dp       // Pills, circular elements
        val extraLarge = 32.dp // Large cards like transfer menu
    }
    
    // Button Dimensions
    object Button {
        val height = 56.dp
        val loadingCircleSize = 64.dp
    }
    
    // Icon Sizes
    object IconSize {
        val small = 16.dp
        val medium = 24.dp
        val large = 48.dp
    }
    
    // Avatar/Profile
    object Avatar {
        val small = 32.dp
        val medium = 44.dp
        val large = 56.dp
    }
}

/**
 * Animation constants - matches iOS DesignSystem.Animation
 */
object SlingAnimation {
    const val pressedScale = 0.97f
    const val pressDurationMillis = 100
    const val shrinkDurationMillis = 300
    const val springStiffness = 400f
    const val springDamping = 0.8f
}
