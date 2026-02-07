package com.sling.shared.models

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.Serializable
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

/**
 * Represents an activity/transaction item in the user's history
 */
@Serializable
data class ActivityItem @OptIn(ExperimentalUuidApi::class) constructor(
    val id: String = Uuid.random().toString(),
    val avatar: String,
    val titleLeft: String,
    val subtitleLeft: String,
    val titleRight: String,
    val subtitleRight: String = "",
    val dateMillis: Long? = null
) {
    /**
     * Get formatted date for display (short format: "24 Jan")
     */
    fun formattedDateShort(): String {
        val millis = dateMillis ?: return ""
        val instant = Instant.fromEpochMilliseconds(millis)
        val dateTime = instant.toLocalDateTime(TimeZone.currentSystemDefault())
        val months = listOf("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
        return "${dateTime.dayOfMonth} ${months[dateTime.monthNumber - 1]}"
    }
    
    /**
     * Get formatted date for detail view (long format: "24 Jan 2026, 14:30")
     */
    fun formattedDateLong(): String {
        val millis = dateMillis ?: return "—"
        val instant = Instant.fromEpochMilliseconds(millis)
        val dateTime = instant.toLocalDateTime(TimeZone.currentSystemDefault())
        val months = listOf("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
        val hour = dateTime.hour.toString().padStart(2, '0')
        val minute = dateTime.minute.toString().padStart(2, '0')
        return "${dateTime.dayOfMonth} ${months[dateTime.monthNumber - 1]} ${dateTime.year}, $hour:$minute"
    }
    
    /**
     * Get section title based on date (Today, Yesterday, or date)
     */
    fun sectionTitle(): String {
        val millis = dateMillis ?: return "Recent"
        val instant = Instant.fromEpochMilliseconds(millis)
        val dateTime = instant.toLocalDateTime(TimeZone.currentSystemDefault())
        
        val now = Clock.System.now()
        val today = now.toLocalDateTime(TimeZone.currentSystemDefault())
        
        return when {
            dateTime.date == today.date -> "Today"
            dateTime.date.toEpochDays() == today.date.toEpochDays() - 1 -> "Yesterday"
            else -> formattedDateShort()
        }
    }
    
    companion object {
        /**
         * Create an activity item for a card payment
         */
        fun cardPayment(
            merchantName: String,
            merchantAvatar: String,
            amount: Double
        ): ActivityItem {
            val formattedAmount = "-£${"%.2f".format(amount)}"
            return ActivityItem(
                avatar = merchantAvatar,
                titleLeft = merchantName,
                subtitleLeft = "Card payment",
                titleRight = formattedAmount,
                subtitleRight = "",
                dateMillis = Clock.System.now().toEpochMilliseconds()
            )
        }
        
        /**
         * Create an activity item for sending money
         */
        fun sendMoney(
            contactName: String,
            contactAvatar: String,
            amount: Double
        ): ActivityItem {
            val formattedAmount = "-£${"%.2f".format(amount)}"
            return ActivityItem(
                avatar = contactAvatar,
                titleLeft = contactName,
                subtitleLeft = "",
                titleRight = formattedAmount,
                subtitleRight = "",
                dateMillis = Clock.System.now().toEpochMilliseconds()
            )
        }
        
        /**
         * Create an activity item for receiving money
         */
        fun receiveMoney(
            contactName: String,
            contactAvatar: String,
            amount: Double
        ): ActivityItem {
            val formattedAmount = "+£${"%.2f".format(amount)}"
            return ActivityItem(
                avatar = contactAvatar,
                titleLeft = contactName,
                subtitleLeft = "Received",
                titleRight = formattedAmount,
                subtitleRight = "",
                dateMillis = Clock.System.now().toEpochMilliseconds()
            )
        }
        
        /**
         * Create an activity item for adding money
         */
        fun addMoney(
            accountName: String,
            accountAvatar: String,
            amount: Double,
            currency: String = "GBP"
        ): ActivityItem {
            val symbol = when (currency) {
                "GBP" -> "£"
                "USD" -> "$"
                "EUR" -> "€"
                else -> currency
            }
            val formattedAmount = "+$symbol${"%.2f".format(amount)}"
            return ActivityItem(
                avatar = accountAvatar,
                titleLeft = accountName,
                subtitleLeft = "",
                titleRight = formattedAmount,
                subtitleRight = "",
                dateMillis = Clock.System.now().toEpochMilliseconds()
            )
        }
        
        /**
         * Create an activity item for withdrawal
         */
        fun withdrawal(
            amount: Double,
            method: String = "ATM"
        ): ActivityItem {
            val formattedAmount = "-£${"%.2f".format(amount)}"
            return ActivityItem(
                avatar = "💳",
                titleLeft = "Withdrawal",
                subtitleLeft = method,
                titleRight = formattedAmount,
                subtitleRight = "",
                dateMillis = Clock.System.now().toEpochMilliseconds()
            )
        }
    }
}
