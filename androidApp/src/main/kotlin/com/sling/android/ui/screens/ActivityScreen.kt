package com.sling.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sling.android.ui.components.SmallButton
import com.sling.android.ui.components.TransactionRow
import com.sling.android.ui.theme.SlingColors
import com.sling.android.ui.theme.SlingTypography
import com.sling.shared.models.ActivityItem
import com.sling.shared.services.ServiceLocator

@Composable
fun ActivityScreen() {
    val activityService = remember { ServiceLocator.activityService }
    val activities by activityService.activities.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        // Header
        Text(
            text = "Activity",
            style = SlingTypography.h2,
            color = SlingColors.Dark,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(top = 16.dp, bottom = 24.dp)
        )
        
        if (activities.isEmpty()) {
            // Empty state
            EmptyActivityView(
                onAddTransactions = {
                    activityService.generateRandomMix(8)
                }
            )
        } else {
            // Activity list grouped by section
            ActivityList(activities = activities)
        }
    }
}

@Composable
private fun EmptyActivityView(
    onAddTransactions: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.weight(1f))
        
        // Icon
        Text(
            text = "📋",
            style = SlingTypography.h1,
            modifier = Modifier.padding(bottom = 24.dp)
        )
        
        // Title
        Text(
            text = "No activity yet",
            style = SlingTypography.h3,
            color = SlingColors.Dark,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Subtitle
        Text(
            text = "When you send, spend, or receive money, your transactions will appear here.",
            style = SlingTypography.bodyRegular,
            color = SlingColors.TextSecondary,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        // Demo button
        SmallButton(
            text = "Add sample transactions",
            onClick = onAddTransactions
        )
        
        Spacer(modifier = Modifier.weight(1f))
    }
}

@Composable
private fun ActivityList(
    activities: List<ActivityItem>
) {
    // Group activities by section title
    val groupedActivities = remember(activities) {
        activities.groupBy { it.sectionTitle() }
    }
    
    LazyColumn(
        contentPadding = PaddingValues(bottom = 120.dp)
    ) {
        groupedActivities.forEach { (sectionTitle, sectionActivities) ->
            // Section header
            item(key = "header_$sectionTitle") {
                Text(
                    text = sectionTitle,
                    style = SlingTypography.bodyBold,
                    color = SlingColors.TextSecondary,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp)
                        .padding(top = 16.dp, bottom = 8.dp)
                )
            }
            
            // Section activities
            items(
                items = sectionActivities,
                key = { it.id }
            ) { activity ->
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
