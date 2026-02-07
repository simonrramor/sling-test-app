package com.sling.android

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.sling.android.ui.components.BottomNavBar
import com.sling.android.ui.components.Tab
import com.sling.android.ui.screens.ActivityScreen
import com.sling.android.ui.screens.HomeScreen
import com.sling.android.ui.screens.SendScreen

@Composable
fun SlingApp() {
    var selectedTab by remember { mutableStateOf(Tab.Home) }
    
    Scaffold(
        bottomBar = {
            BottomNavBar(
                selectedTab = selectedTab,
                onTabSelected = { selectedTab = it }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when (selectedTab) {
                Tab.Home -> HomeScreen()
                Tab.Send -> SendScreen()
                Tab.Activity -> ActivityScreen()
            }
        }
    }
}
