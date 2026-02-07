package com.sling.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sling.android.ui.components.GetStartedCard
import com.sling.android.ui.components.TertiaryButton
import com.sling.android.ui.components.TransactionRow
import com.sling.android.ui.theme.SlingColors
import com.sling.android.ui.theme.SlingDimensions
import com.sling.android.ui.theme.SlingTypography
import com.sling.shared.models.ActivityItem
import com.sling.shared.services.ServiceLocator
import java.text.NumberFormat
import java.util.Currency
import java.util.Locale

@Composable
fun HomeScreen() {
    val activityService = remember { ServiceLocator.activityService }
    val portfolioService = remember { ServiceLocator.portfolioService }
    
    val activities by activityService.activities.collectAsState()
    val cashBalance by portfolioService.cashBalance.collectAsState()
    val displayCurrency by portfolioService.displayCurrency.collectAsState()
    
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White),
        contentPadding = PaddingValues(bottom = 120.dp)
    ) {
        // Balance Section
        item {
            BalanceSection(
                balance = cashBalance,
                currency = displayCurrency,
                onAddMoney = {
                    // Demo: Add £100
                    portfolioService.addCash(100.0)
                    activityService.recordAddMoney("Bank Transfer", "🏦", 100.0)
                },
                onWithdraw = {
                    // Demo: Withdraw £50
                    if (cashBalance >= 50.0) {
                        portfolioService.deductCash(50.0)
                        activityService.recordWithdrawal(50.0)
                    }
                }
            )
        }
        
        // Get Started Section (only show if no activities)
        if (activities.isEmpty()) {
            item {
                GetStartedSection(
                    onAddMoney = {
                        portfolioService.addCash(100.0)
                        activityService.recordAddMoney("Bank Transfer", "🏦", 100.0)
                    },
                    onStartInvesting = {
                        // Navigate to invest tab
                    }
                )
            }
        }
        
        // Activity Section
        item {
            Text(
                text = "Activity",
                style = SlingTypography.bodyBold,
                color = SlingColors.TextSecondary,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp)
                    .padding(top = 24.dp, bottom = 8.dp)
            )
        }
        
        if (activities.isEmpty()) {
            item {
                EmptyActivityState(
                    onAddTransactions = {
                        activityService.generateRandomMix(5)
                    }
                )
            }
        } else {
            items(activities, key = { it.id }) { activity ->
                TransactionRow(
                    avatar = activity.avatar,
                    titleLeft = activity.titleLeft,
                    subtitleLeft = activity.subtitleLeft,
                    titleRight = activity.titleRight,
                    subtitleRight = activity.subtitleRight,
                    onClick = { /* Navigate to transaction detail */ },
                    modifier = Modifier.padding(horizontal = 8.dp)
                )
            }
        }
    }
}

@Composable
private fun BalanceSection(
    balance: Double,
    currency: String,
    onAddMoney: () -> Unit,
    onWithdraw: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .padding(top = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Currency label
        Text(
            text = when (currency) {
                "GBP" -> "GBP balance"
                "USD" -> "USD balance"
                "EUR" -> "EUR balance"
                else -> "$currency balance"
            },
            style = SlingTypography.caption,
            color = SlingColors.TextSecondary
        )
        
        Spacer(modifier = Modifier.height(4.dp))
        
        // Balance amount
        Text(
            text = formatCurrency(balance, currency),
            style = SlingTypography.amountExtraLarge,
            color = SlingColors.Dark
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Action buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            TertiaryButton(
                text = "Add money",
                onClick = onAddMoney,
                modifier = Modifier.weight(1f)
            )
            TertiaryButton(
                text = "Withdraw",
                onClick = onWithdraw,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun GetStartedSection(
    onAddMoney: () -> Unit,
    onStartInvesting: () -> Unit
) {
    Column(
        modifier = Modifier.padding(top = 24.dp)
    ) {
        Text(
            text = "Get started on Sling",
            style = SlingTypography.bodyBold,
            color = SlingColors.TextSecondary,
            modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp)
        )
        
        LazyRow(
            contentPadding = PaddingValues(horizontal = 24.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                GetStartedCard(
                    icon = {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(SlingColors.AccentGreenBg),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = null,
                                tint = SlingColors.AccentGreen,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    },
                    title = "Add money to your account",
                    subtitle = "Top up your balance to start sending and spending.",
                    buttonTitle = "Add money",
                    onClick = onAddMoney
                )
            }
            
            item {
                GetStartedCard(
                    icon = {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(SlingColors.AccentPurpleBg),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.ShowChart,
                                contentDescription = null,
                                tint = SlingColors.AccentPurple,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    },
                    title = "Start investing from just £1",
                    subtitle = "Buy stocks in your favorite companies to give your money a chance to grow.",
                    buttonTitle = "Start investing",
                    onClick = onStartInvesting
                )
            }
            
            item {
                GetStartedCard(
                    icon = {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(SlingColors.AccentOrangeBg),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.CreditCard,
                                contentDescription = null,
                                tint = SlingColors.AccentOrange,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    },
                    title = "Create your Sling Card today",
                    subtitle = "Get your new virtual debit card, and start spending around the world.",
                    buttonTitle = "Create Sling Card",
                    onClick = { }
                )
            }
        }
    }
}

@Composable
private fun EmptyActivityState(
    onAddTransactions: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Icon
        Text(
            text = "📋",
            style = SlingTypography.h2,
            modifier = Modifier.padding(bottom = 16.dp)
        )
        
        // Title
        Text(
            text = "Your activity feed",
            style = SlingTypography.h3,
            color = SlingColors.Dark,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(4.dp))
        
        // Subtitle
        Text(
            text = "When you send, spend, or receive money, it will show here.",
            style = SlingTypography.rowSubtitle,
            color = SlingColors.TextSecondary,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Add transactions button (for demo)
        com.sling.android.ui.components.SmallButton(
            text = "Add transactions",
            onClick = onAddTransactions
        )
    }
}

/**
 * Format currency amount
 */
private fun formatCurrency(amount: Double, currencyCode: String): String {
    return try {
        val format = NumberFormat.getCurrencyInstance(Locale.UK)
        format.currency = Currency.getInstance(currencyCode)
        format.format(amount)
    } catch (e: Exception) {
        val symbol = when (currencyCode) {
            "GBP" -> "£"
            "USD" -> "$"
            "EUR" -> "€"
            else -> currencyCode
        }
        "$symbol%.2f".format(amount)
    }
}
