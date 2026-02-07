package com.sling.android.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sling.android.ui.components.PrimaryButton
import com.sling.android.ui.theme.SlingColors
import com.sling.android.ui.theme.SlingDimensions
import com.sling.android.ui.theme.SlingTypography
import com.sling.shared.services.ServiceLocator

/**
 * Sample contact data
 */
data class Contact(
    val name: String,
    val avatar: String,
    val username: String = ""
)

private val sampleContacts = listOf(
    Contact("Emma", "E", "@emma"),
    Contact("James", "J", "@james"),
    Contact("Sarah", "S", "@sarah"),
    Contact("Michael", "M", "@michael"),
    Contact("Lucy", "L", "@lucy"),
    Contact("Tom", "T", "@tom"),
    Contact("Sophie", "S", "@sophie"),
    Contact("Ben", "B", "@ben")
)

@Composable
fun SendScreen() {
    var selectedContact by remember { mutableStateOf<Contact?>(null) }
    var amount by remember { mutableStateOf("") }
    var searchQuery by remember { mutableStateOf("") }
    var showConfirmation by remember { mutableStateOf(false) }
    
    val portfolioService = remember { ServiceLocator.portfolioService }
    val activityService = remember { ServiceLocator.activityService }
    val cashBalance by portfolioService.cashBalance.collectAsState()
    
    val filteredContacts = remember(searchQuery) {
        if (searchQuery.isEmpty()) {
            sampleContacts
        } else {
            sampleContacts.filter { 
                it.name.contains(searchQuery, ignoreCase = true) ||
                it.username.contains(searchQuery, ignoreCase = true)
            }
        }
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        if (showConfirmation) {
            // Confirmation screen
            SendConfirmationScreen(
                contact = selectedContact!!,
                amount = amount.toDoubleOrNull() ?: 0.0,
                onConfirm = {
                    val sendAmount = amount.toDoubleOrNull() ?: 0.0
                    if (sendAmount > 0 && sendAmount <= cashBalance) {
                        portfolioService.deductCash(sendAmount)
                        activityService.recordSendMoney(
                            selectedContact!!.name,
                            selectedContact!!.avatar,
                            sendAmount
                        )
                        // Reset state
                        selectedContact = null
                        amount = ""
                        showConfirmation = false
                    }
                },
                onCancel = {
                    showConfirmation = false
                }
            )
        } else if (selectedContact != null) {
            // Amount input screen
            AmountInputScreen(
                contact = selectedContact!!,
                amount = amount,
                onAmountChange = { amount = it },
                balance = cashBalance,
                onContinue = {
                    showConfirmation = true
                },
                onBack = {
                    selectedContact = null
                    amount = ""
                }
            )
        } else {
            // Contact picker screen
            ContactPickerScreen(
                searchQuery = searchQuery,
                onSearchChange = { searchQuery = it },
                contacts = filteredContacts,
                recentContacts = sampleContacts.take(5),
                onContactSelect = { contact ->
                    selectedContact = contact
                }
            )
        }
    }
}

@Composable
private fun ContactPickerScreen(
    searchQuery: String,
    onSearchChange: (String) -> Unit,
    contacts: List<Contact>,
    recentContacts: List<Contact>,
    onContactSelect: (Contact) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 120.dp)
    ) {
        // Header
        item {
            Text(
                text = "Send money",
                style = SlingTypography.h2,
                color = SlingColors.Dark,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp)
                    .padding(top = 16.dp, bottom = 24.dp)
            )
        }
        
        // Search bar
        item {
            SearchBar(
                query = searchQuery,
                onQueryChange = onSearchChange,
                modifier = Modifier.padding(horizontal = 24.dp)
            )
            Spacer(modifier = Modifier.height(24.dp))
        }
        
        // Recent contacts (horizontal scroll)
        if (searchQuery.isEmpty()) {
            item {
                Text(
                    text = "Recent",
                    style = SlingTypography.bodyBold,
                    color = SlingColors.TextSecondary,
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp)
                )
            }
            
            item {
                LazyRow(
                    contentPadding = PaddingValues(horizontal = 24.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(recentContacts) { contact ->
                        ContactChip(
                            contact = contact,
                            onClick = { onContactSelect(contact) }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
        
        // All contacts
        item {
            Text(
                text = if (searchQuery.isEmpty()) "All contacts" else "Results",
                style = SlingTypography.bodyBold,
                color = SlingColors.TextSecondary,
                modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp)
            )
        }
        
        items(contacts) { contact ->
            ContactRow(
                contact = contact,
                onClick = { onContactSelect(contact) },
                modifier = Modifier.padding(horizontal = 16.dp)
            )
        }
        
        if (contacts.isEmpty()) {
            item {
                Text(
                    text = "No contacts found",
                    style = SlingTypography.bodyRegular,
                    color = SlingColors.TextSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp)
                )
            }
        }
    }
}

@Composable
private fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(48.dp)
            .clip(RoundedCornerShape(SlingDimensions.CornerRadius.medium))
            .background(SlingColors.BackgroundLight)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Default.Search,
            contentDescription = null,
            tint = SlingColors.TextSecondary,
            modifier = Modifier.size(20.dp)
        )
        
        Spacer(modifier = Modifier.width(12.dp))
        
        BasicTextField(
            value = query,
            onValueChange = onQueryChange,
            textStyle = SlingTypography.bodyRegular.copy(color = SlingColors.Dark),
            cursorBrush = SolidColor(SlingColors.Primary),
            modifier = Modifier.weight(1f),
            decorationBox = { innerTextField ->
                Box {
                    if (query.isEmpty()) {
                        Text(
                            text = "Search contacts",
                            style = SlingTypography.bodyRegular,
                            color = SlingColors.TextSecondary
                        )
                    }
                    innerTextField()
                }
            }
        )
    }
}

@Composable
private fun ContactChip(
    contact: Contact,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(8.dp)
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(SlingColors.BackgroundLight),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = contact.avatar,
                style = SlingTypography.h3,
                color = SlingColors.Dark
            )
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = contact.name,
            style = SlingTypography.rowSubtitle,
            color = SlingColors.Dark
        )
    }
}

@Composable
private fun ContactRow(
    contact: Contact,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(SlingDimensions.CornerRadius.medium))
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(SlingColors.BackgroundLight),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = contact.avatar,
                style = SlingTypography.bodyBold,
                color = SlingColors.Dark
            )
        }
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column {
            Text(
                text = contact.name,
                style = SlingTypography.rowTitle,
                color = SlingColors.Dark
            )
            if (contact.username.isNotEmpty()) {
                Text(
                    text = contact.username,
                    style = SlingTypography.rowSubtitle,
                    color = SlingColors.TextSecondary
                )
            }
        }
    }
}

@Composable
private fun AmountInputScreen(
    contact: Contact,
    amount: String,
    onAmountChange: (String) -> Unit,
    balance: Double,
    onContinue: () -> Unit,
    onBack: () -> Unit
) {
    val amountValue = amount.toDoubleOrNull() ?: 0.0
    val isValidAmount = amountValue > 0 && amountValue <= balance
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        // Back button
        IconButton(
            onClick = onBack,
            modifier = Modifier.align(Alignment.Start)
        ) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = "Back",
                tint = SlingColors.Dark
            )
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Contact info
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(64.dp)
                    .clip(CircleShape)
                    .background(SlingColors.BackgroundLight),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = contact.avatar,
                    style = SlingTypography.h2,
                    color = SlingColors.Dark
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = "Send to ${contact.name}",
                style = SlingTypography.h3,
                color = SlingColors.Dark
            )
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Amount input
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "£",
                style = SlingTypography.amountLarge,
                color = SlingColors.Dark
            )
            
            BasicTextField(
                value = amount,
                onValueChange = { newValue ->
                    // Only allow numeric input with one decimal point
                    if (newValue.isEmpty() || newValue.matches(Regex("^\\d*\\.?\\d{0,2}$"))) {
                        onAmountChange(newValue)
                    }
                },
                textStyle = SlingTypography.amountLarge.copy(
                    color = SlingColors.Dark,
                    textAlign = TextAlign.Start
                ),
                cursorBrush = SolidColor(SlingColors.Primary),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.width(200.dp),
                decorationBox = { innerTextField ->
                    Box {
                        if (amount.isEmpty()) {
                            Text(
                                text = "0",
                                style = SlingTypography.amountLarge,
                                color = SlingColors.TextTertiary
                            )
                        }
                        innerTextField()
                    }
                }
            )
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Balance indicator
        Text(
            text = "Balance: £%.2f".format(balance),
            style = SlingTypography.caption,
            color = if (amountValue > balance) SlingColors.NegativeRed else SlingColors.TextSecondary,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Continue button
        PrimaryButton(
            text = "Continue",
            onClick = onContinue,
            enabled = isValidAmount
        )
    }
}

@Composable
private fun SendConfirmationScreen(
    contact: Contact,
    amount: Double,
    onConfirm: () -> Unit,
    onCancel: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Cancel button
        IconButton(
            onClick = onCancel,
            modifier = Modifier.align(Alignment.Start)
        ) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = "Cancel",
                tint = SlingColors.Dark
            )
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Contact avatar
        Box(
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(SlingColors.BackgroundLight),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = contact.avatar,
                style = SlingTypography.h1,
                color = SlingColors.Dark
            )
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Amount
        Text(
            text = "£%.2f".format(amount),
            style = SlingTypography.amountLarge,
            color = SlingColors.Dark
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Sending to
        Text(
            text = "to ${contact.name}",
            style = SlingTypography.bodyRegular,
            color = SlingColors.TextSecondary
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Confirm button
        PrimaryButton(
            text = "Send £%.2f".format(amount),
            onClick = onConfirm,
            backgroundColor = SlingColors.Primary
        )
    }
}
