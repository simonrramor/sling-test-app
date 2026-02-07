package com.sling.android.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sling.android.ui.theme.SlingAnimation
import com.sling.android.ui.theme.SlingColors
import com.sling.android.ui.theme.SlingDimensions
import com.sling.android.ui.theme.SlingTypography

/**
 * Activity/Transaction row - matches iOS TransactionRow
 */
@Composable
fun TransactionRow(
    avatar: String,
    titleLeft: String,
    subtitleLeft: String,
    titleRight: String,
    subtitleRight: String = "",
    onClick: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (isPressed) SlingAnimation.pressedScale else 1f,
        animationSpec = tween(SlingAnimation.pressDurationMillis),
        label = "row_scale"
    )
    
    Row(
        modifier = modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(SlingDimensions.CornerRadius.medium))
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            )
            .padding(SlingDimensions.Spacing.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Avatar
        Box(
            modifier = Modifier
                .size(SlingDimensions.Avatar.medium)
                .clip(RoundedCornerShape(12.dp))
                .background(SlingColors.BackgroundLight),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = avatar,
                style = SlingTypography.bodyBold
            )
        }
        
        Spacer(modifier = Modifier.width(SlingDimensions.Spacing.md))
        
        // Left column (title and subtitle)
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = titleLeft,
                style = SlingTypography.rowTitle,
                color = SlingColors.Dark
            )
            if (subtitleLeft.isNotEmpty()) {
                Text(
                    text = subtitleLeft,
                    style = SlingTypography.rowSubtitle,
                    color = SlingColors.TextSecondary
                )
            }
        }
        
        // Right column (amount and subtitle)
        Column(
            horizontalAlignment = Alignment.End
        ) {
            val amountColor = when {
                titleRight.startsWith("+") -> SlingColors.PositiveGreen
                titleRight.startsWith("-") -> SlingColors.Dark
                else -> SlingColors.Dark
            }
            Text(
                text = titleRight,
                style = SlingTypography.rowTitle,
                color = amountColor
            )
            if (subtitleRight.isNotEmpty()) {
                Text(
                    text = subtitleRight,
                    style = SlingTypography.rowSubtitle,
                    color = SlingColors.TextSecondary
                )
            }
        }
    }
}

/**
 * List row with icon and chevron - matches iOS ListRow
 */
@Composable
fun ListRow(
    icon: @Composable () -> Unit,
    title: String,
    subtitle: String = "",
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (isPressed) SlingAnimation.pressedScale else 1f,
        animationSpec = tween(SlingAnimation.pressDurationMillis),
        label = "row_scale"
    )
    
    Row(
        modifier = modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(SlingDimensions.CornerRadius.medium))
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            )
            .padding(SlingDimensions.Spacing.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Icon
        Box(
            modifier = Modifier.size(SlingDimensions.Avatar.medium),
            contentAlignment = Alignment.Center
        ) {
            icon()
        }
        
        Spacer(modifier = Modifier.width(SlingDimensions.Spacing.md))
        
        // Text
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = title,
                style = SlingTypography.rowTitle,
                color = SlingColors.Dark
            )
            if (subtitle.isNotEmpty()) {
                Text(
                    text = subtitle,
                    style = SlingTypography.rowSubtitle,
                    color = SlingColors.TextSecondary
                )
            }
        }
        
        // Chevron
        Icon(
            imageVector = Icons.Default.ChevronRight,
            contentDescription = null,
            tint = SlingColors.TextTertiary,
            modifier = Modifier.size(14.dp)
        )
    }
}

/**
 * Action card for "Get Started" section
 */
@Composable
fun GetStartedCard(
    icon: @Composable () -> Unit,
    title: String,
    subtitle: String,
    buttonTitle: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (isPressed) SlingAnimation.pressedScale else 1f,
        animationSpec = tween(SlingAnimation.pressDurationMillis),
        label = "card_scale"
    )
    
    Column(
        modifier = modifier
            .width(280.dp)
            .scale(scale)
            .clip(RoundedCornerShape(SlingDimensions.CornerRadius.extraLarge - 8.dp))
            .background(SlingColors.BackgroundLight)
            .border(
                width = 1.dp,
                color = SlingColors.CardBorder,
                shape = RoundedCornerShape(SlingDimensions.CornerRadius.extraLarge - 8.dp)
            )
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            )
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Icon
        Box(
            modifier = Modifier.height(80.dp),
            contentAlignment = Alignment.Center
        ) {
            icon()
        }
        
        Spacer(modifier = Modifier.height(SlingDimensions.Spacing.md))
        
        // Title
        Text(
            text = title,
            style = SlingTypography.h3,
            color = SlingColors.Dark,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(4.dp))
        
        // Subtitle
        Text(
            text = subtitle,
            style = SlingTypography.rowSubtitle,
            color = SlingColors.TextSecondary,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(SlingDimensions.Spacing.lg))
        
        // Button
        SmallButton(
            text = buttonTitle,
            onClick = onClick
        )
    }
}
