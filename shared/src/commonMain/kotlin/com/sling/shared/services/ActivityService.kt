package com.sling.shared.services

import com.sling.shared.models.ActivityItem
import com.sling.shared.platform.PersistenceDriver
import com.sling.shared.platform.PersistenceKeys
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Service for managing user activity/transaction history
 */
class ActivityService(
    private val persistence: PersistenceDriver
) {
    private val scope = CoroutineScope(Dispatchers.Default)
    private val json = Json { ignoreUnknownKeys = true }
    
    private val _activities = MutableStateFlow<List<ActivityItem>>(emptyList())
    val activities: StateFlow<List<ActivityItem>> = _activities.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()
    
    /**
     * Track if user is active (has made transactions)
     */
    var isActiveUser: Boolean
        get() = persistence.getBoolean(PersistenceKeys.IS_ACTIVE_USER, false)
        set(value) = persistence.saveBoolean(PersistenceKeys.IS_ACTIVE_USER, value)
    
    init {
        loadFromPersistence()
    }
    
    /**
     * Load activities from persistence
     */
    private fun loadFromPersistence() {
        val activitiesJson = persistence.getString(PersistenceKeys.ACTIVITIES)
        if (activitiesJson != null) {
            try {
                val loaded = json.decodeFromString<List<ActivityItem>>(activitiesJson)
                _activities.value = loaded.sortedByDescending { it.dateMillis ?: 0 }
                if (loaded.isNotEmpty()) {
                    isActiveUser = true
                }
            } catch (e: Exception) {
                println("ActivityService: Failed to load activities: ${e.message}")
            }
        }
    }
    
    /**
     * Save activities to persistence
     */
    private fun saveToPersistence() {
        try {
            val activitiesJson = json.encodeToString(_activities.value)
            persistence.saveString(PersistenceKeys.ACTIVITIES, activitiesJson)
        } catch (e: Exception) {
            println("ActivityService: Failed to save activities: ${e.message}")
        }
    }
    
    /**
     * Add a new activity
     */
    fun addActivity(item: ActivityItem) {
        val updated = listOf(item) + _activities.value
        _activities.value = updated.sortedByDescending { it.dateMillis ?: 0 }
        isActiveUser = true
        saveToPersistence()
    }
    
    /**
     * Record a send money transaction
     */
    fun recordSendMoney(
        contactName: String,
        contactAvatar: String,
        amount: Double
    ) {
        addActivity(ActivityItem.sendMoney(contactName, contactAvatar, amount))
    }
    
    /**
     * Record receiving money
     */
    fun recordReceivedMoney(
        contactName: String,
        contactAvatar: String,
        amount: Double
    ) {
        addActivity(ActivityItem.receiveMoney(contactName, contactAvatar, amount))
    }
    
    /**
     * Record a card payment
     */
    fun recordCardPayment(
        merchantName: String,
        merchantAvatar: String,
        amount: Double
    ) {
        addActivity(ActivityItem.cardPayment(merchantName, merchantAvatar, amount))
    }
    
    /**
     * Record adding money
     */
    fun recordAddMoney(
        accountName: String,
        accountAvatar: String,
        amount: Double,
        currency: String = "GBP"
    ) {
        addActivity(ActivityItem.addMoney(accountName, accountAvatar, amount, currency))
    }
    
    /**
     * Record withdrawal
     */
    fun recordWithdrawal(
        amount: Double,
        method: String = "ATM"
    ) {
        addActivity(ActivityItem.withdrawal(amount, method))
    }
    
    /**
     * Clear all activities (for reset functionality)
     */
    fun clearActivities() {
        _activities.value = emptyList()
        isActiveUser = false
        persistence.remove(PersistenceKeys.ACTIVITIES)
    }
    
    // Sample data for testing
    private val sampleMerchants = listOf(
        "Tesco" to "🛒",
        "Amazon" to "📦",
        "Uber" to "🚗",
        "Deliveroo" to "🍔",
        "Netflix" to "🎬",
        "Spotify" to "🎵",
        "Costa" to "☕️",
        "Apple" to "🍎",
        "TfL" to "🚇",
        "Sainsbury's" to "🛍️"
    )
    
    private val sampleContacts = listOf(
        "Emma" to "E",
        "James" to "J",
        "Sarah" to "S",
        "Michael" to "M",
        "Lucy" to "L",
        "Tom" to "T",
        "Sophie" to "S",
        "Ben" to "B"
    )
    
    /**
     * Generate a random card payment (for demo)
     */
    fun generateCardPayment() {
        val merchant = sampleMerchants.random()
        val amount = (250..8500).random() / 100.0
        recordCardPayment(merchant.first, merchant.second, amount)
    }
    
    /**
     * Generate a random P2P outbound (for demo)
     */
    fun generateP2POutbound() {
        val contact = sampleContacts.random()
        val amount = (500..10000).random() / 100.0
        recordSendMoney(contact.first, contact.second, amount)
    }
    
    /**
     * Generate a random P2P inbound (for demo)
     */
    fun generateP2PInbound() {
        val contact = sampleContacts.random()
        val amount = (500..15000).random() / 100.0
        recordReceivedMoney(contact.first, contact.second, amount)
    }
    
    /**
     * Generate a random mix of transactions (for demo)
     */
    fun generateRandomMix(count: Int = 8) {
        repeat(count) {
            when ((0..4).random()) {
                0 -> generateCardPayment()
                1 -> generateP2POutbound()
                2 -> generateP2PInbound()
                3 -> recordAddMoney("Bank Transfer", "🏦", (2000..50000).random() / 100.0)
                4 -> recordWithdrawal((1000..20000).random() / 100.0)
            }
        }
    }
}
