package com.sling.shared.services

import com.sling.shared.models.Holding
import com.sling.shared.models.PortfolioEvent
import com.sling.shared.models.PortfolioEventType
import com.sling.shared.platform.PersistenceDriver
import com.sling.shared.platform.PersistenceKeys
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.datetime.Clock
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Service for managing user portfolio (holdings, cash balance, trading)
 */
class PortfolioService(
    private val persistence: PersistenceDriver
) {
    private val json = Json { ignoreUnknownKeys = true }
    
    private val _holdings = MutableStateFlow<Map<String, Holding>>(emptyMap())
    val holdings: StateFlow<Map<String, Holding>> = _holdings.asStateFlow()
    
    private val _cashBalance = MutableStateFlow(0.0)
    val cashBalance: StateFlow<Double> = _cashBalance.asStateFlow()
    
    private val _history = MutableStateFlow<List<PortfolioEvent>>(emptyList())
    val history: StateFlow<List<PortfolioEvent>> = _history.asStateFlow()
    
    private val _displayCurrency = MutableStateFlow("GBP")
    val displayCurrency: StateFlow<String> = _displayCurrency.asStateFlow()
    
    init {
        loadFromPersistence()
    }
    
    /**
     * Load portfolio data from persistence
     */
    private fun loadFromPersistence() {
        // Load holdings
        val holdingsJson = persistence.getString(PersistenceKeys.HOLDINGS)
        if (holdingsJson != null) {
            try {
                val loaded = json.decodeFromString<Map<String, Holding>>(holdingsJson)
                _holdings.value = loaded
            } catch (e: Exception) {
                println("PortfolioService: Failed to load holdings: ${e.message}")
            }
        }
        
        // Load cash balance
        _cashBalance.value = persistence.getDouble(PersistenceKeys.CASH_BALANCE, 0.0)
        
        // Load history
        val historyJson = persistence.getString(PersistenceKeys.PORTFOLIO_HISTORY)
        if (historyJson != null) {
            try {
                val loaded = json.decodeFromString<List<PortfolioEvent>>(historyJson)
                _history.value = loaded
            } catch (e: Exception) {
                println("PortfolioService: Failed to load history: ${e.message}")
            }
        }
        
        // Load display currency preference
        _displayCurrency.value = persistence.getString(PersistenceKeys.DISPLAY_CURRENCY) ?: "GBP"
    }
    
    /**
     * Save holdings to persistence
     */
    private fun saveHoldings() {
        try {
            val holdingsJson = json.encodeToString(_holdings.value)
            persistence.saveString(PersistenceKeys.HOLDINGS, holdingsJson)
        } catch (e: Exception) {
            println("PortfolioService: Failed to save holdings: ${e.message}")
        }
    }
    
    /**
     * Save cash balance to persistence
     */
    private fun saveCashBalance() {
        persistence.saveDouble(PersistenceKeys.CASH_BALANCE, _cashBalance.value)
    }
    
    /**
     * Save history to persistence
     */
    private fun saveHistory() {
        try {
            val historyJson = json.encodeToString(_history.value)
            persistence.saveString(PersistenceKeys.PORTFOLIO_HISTORY, historyJson)
        } catch (e: Exception) {
            println("PortfolioService: Failed to save history: ${e.message}")
        }
    }
    
    /**
     * Set display currency preference
     */
    fun setDisplayCurrency(currency: String) {
        _displayCurrency.value = currency
        persistence.saveString(PersistenceKeys.DISPLAY_CURRENCY, currency)
    }
    
    /**
     * Total value of all holdings at current market prices
     * Note: In MVP, we use average cost as current price placeholder
     */
    fun portfolioValue(): Double {
        return _holdings.value.values.sumOf { it.totalCost }
    }
    
    /**
     * Total portfolio including cash
     */
    val totalBalance: Double
        get() = portfolioValue() + _cashBalance.value
    
    /**
     * Get value of a specific holding
     */
    fun holdingValue(iconName: String): Double {
        return _holdings.value[iconName]?.totalCost ?: 0.0
    }
    
    /**
     * Get shares owned for a stock
     */
    fun sharesOwned(iconName: String): Double {
        return _holdings.value[iconName]?.shares ?: 0.0
    }
    
    /**
     * Check if user owns any shares of a stock
     */
    fun ownsStock(iconName: String): Boolean {
        val holding = _holdings.value[iconName] ?: return false
        return holding.shares > 0.0001
    }
    
    /**
     * Buy shares of a stock
     * @return true if purchase was successful
     */
    fun buy(
        iconName: String,
        symbol: String,
        shares: Double,
        pricePerShare: Double
    ): Boolean {
        val totalCost = shares * pricePerShare
        
        // Check if we have enough cash
        if (totalCost > _cashBalance.value) {
            return false
        }
        
        // Deduct from cash balance
        _cashBalance.value -= totalCost
        
        // Update or create holding
        val existingHolding = _holdings.value[iconName]
        val updatedHoldings = _holdings.value.toMutableMap()
        
        if (existingHolding != null) {
            // Calculate new average cost
            val totalShares = existingHolding.shares + shares
            val totalValue = existingHolding.totalCost + totalCost
            val newAverageCost = totalValue / totalShares
            
            updatedHoldings[iconName] = existingHolding.copy(
                shares = totalShares,
                averageCost = newAverageCost
            )
        } else {
            // Create new holding
            updatedHoldings[iconName] = Holding(
                symbol = symbol,
                iconName = iconName,
                shares = shares,
                averageCost = pricePerShare
            )
        }
        
        _holdings.value = updatedHoldings
        
        // Record the event
        recordEvent(PortfolioEventType.BUY, iconName, shares, pricePerShare)
        
        // Save to persistence
        saveHoldings()
        saveCashBalance()
        
        return true
    }
    
    /**
     * Sell shares of a stock
     * @return true if sale was successful
     */
    fun sell(
        iconName: String,
        shares: Double,
        pricePerShare: Double
    ): Boolean {
        val holding = _holdings.value[iconName] ?: return false
        
        // Check if we have enough shares
        if (shares > holding.shares) {
            return false
        }
        
        val saleValue = shares * pricePerShare
        
        // Add to cash balance
        _cashBalance.value += saleValue
        
        // Update holding
        val updatedHoldings = _holdings.value.toMutableMap()
        val remainingShares = holding.shares - shares
        
        if (remainingShares <= 0.0001) {
            // Remove holding
            updatedHoldings.remove(iconName)
        } else {
            updatedHoldings[iconName] = holding.copy(shares = remainingShares)
        }
        
        _holdings.value = updatedHoldings
        
        // Record the event
        recordEvent(PortfolioEventType.SELL, iconName, shares, pricePerShare)
        
        // Save to persistence
        saveHoldings()
        saveCashBalance()
        
        return true
    }
    
    /**
     * Record a portfolio event
     */
    private fun recordEvent(
        type: PortfolioEventType,
        iconName: String,
        shares: Double,
        pricePerShare: Double
    ) {
        val event = PortfolioEvent(
            timestampMillis = Clock.System.now().toEpochMilliseconds(),
            type = type,
            portfolioValueAfter = portfolioValue(),
            iconName = iconName,
            shares = shares,
            pricePerShare = pricePerShare
        )
        
        _history.value = _history.value + event
        saveHistory()
    }
    
    /**
     * Add cash to balance
     */
    fun addCash(amount: Double) {
        _cashBalance.value += amount
        saveCashBalance()
    }
    
    /**
     * Deduct cash from balance
     */
    fun deductCash(amount: Double) {
        _cashBalance.value = maxOf(0.0, _cashBalance.value - amount)
        saveCashBalance()
    }
    
    /**
     * Reset portfolio to initial state
     */
    fun reset() {
        _holdings.value = emptyMap()
        _cashBalance.value = 0.0
        _history.value = emptyList()
        
        persistence.remove(PersistenceKeys.HOLDINGS)
        persistence.remove(PersistenceKeys.CASH_BALANCE)
        persistence.remove(PersistenceKeys.PORTFOLIO_HISTORY)
    }
    
    /**
     * Portfolio created timestamp (first event)
     */
    val portfolioCreatedAt: Long?
        get() = _history.value.firstOrNull()?.timestampMillis
    
    /**
     * Total cost basis (what was paid for all holdings)
     */
    val totalCostBasis: Double
        get() = _holdings.value.values.sumOf { it.totalCost }
}
