package com.sling.android.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sling.android.ui.theme.SlingAnimation
import com.sling.android.ui.theme.SlingColors
import com.sling.android.ui.theme.SlingDimensions
import com.sling.android.ui.theme.SlingTypography

/**
 * Primary button - matches iOS PrimaryButton
 */
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    backgroundColor: Color = SlingColors.Dark,
    textColor: Color = Color.White
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (isPressed) SlingAnimation.pressedScale else 1f,
        animationSpec = tween(SlingAnimation.pressDurationMillis),
        label = "button_scale"
    )
    
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(SlingDimensions.Button.height)
            .scale(scale)
            .clip(RoundedCornerShape(SlingDimensions.CornerRadius.large))
            .background(if (enabled) backgroundColor else SlingColors.Tertiary)
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                enabled = enabled,
                onClick = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            style = SlingTypography.button,
            color = if (enabled) textColor else SlingColors.TextSecondary
        )
    }
}

/**
 * Tertiary button - light gray background
 */
@Composable
fun TertiaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (isPressed) SlingAnimation.pressedScale else 1f,
        animationSpec = tween(SlingAnimation.pressDurationMillis),
        label = "button_scale"
    )
    
    Box(
        modifier = modifier
            .height(SlingDimensions.Button.height)
            .scale(scale)
            .clip(RoundedCornerShape(SlingDimensions.CornerRadius.large))
            .background(SlingColors.Tertiary)
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                enabled = enabled,
                onClick = onClick
            )
            .padding(horizontal = 24.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            style = SlingTypography.button,
            color = SlingColors.Dark
        )
    }
}

/**
 * Small button - used in cards and secondary actions
 */
@Composable
fun SmallButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    backgroundColor: Color = SlingColors.Tertiary,
    textColor: Color = SlingColors.Dark
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (isPressed) SlingAnimation.pressedScale else 1f,
        animationSpec = tween(SlingAnimation.pressDurationMillis),
        label = "button_scale"
    )
    
    Box(
        modifier = modifier
            .height(36.dp)
            .scale(scale)
            .clip(RoundedCornerShape(12.dp))
            .background(backgroundColor)
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            )
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            style = SlingTypography.bodyBold.copy(fontSize = androidx.compose.ui.unit.TextUnit(14f, androidx.compose.ui.unit.TextUnitType.Sp)),
            color = textColor
        )
    }
}
