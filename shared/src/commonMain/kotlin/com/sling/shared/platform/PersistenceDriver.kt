package com.sling.shared.platform

import com.sling.shared.models.ActivityItem
import com.sling.shared.models.Holding
import com.sling.shared.models.PortfolioEvent

/**
 * Platform-specific persistence driver interface
 * 
 * Implementations:
 * - Android: SharedPreferences
 * - iOS: NSUserDefaults
 */
expect class PersistenceDriver {
    /**
     * Save a string value
     */
    fun saveString(key: String, value: String)
    
    /**
     * Get a string value
     */
    fun getString(key: String): String?
    
    /**
     * Save a boolean value
     */
    fun saveBoolean(key: String, value: Boolean)
    
    /**
     * Get a boolean value
     */
    fun getBoolean(key: String, defaultValue: Boolean = false): Boolean
    
    /**
     * Save a double value
     */
    fun saveDouble(key: String, value: Double)
    
    /**
     * Get a double value
     */
    fun getDouble(key: String, defaultValue: Double = 0.0): Double
    
    /**
     * Remove a value
     */
    fun remove(key: String)
    
    /**
     * Clear all values
     */
    fun clear()
}

/**
 * Keys for persistence
 */
object PersistenceKeys {
    const val ACTIVITIES = "activities"
    const val HOLDINGS = "holdings"
    const val CASH_BALANCE = "cashBalance"
    const val PORTFOLIO_HISTORY = "portfolioHistory"
    const val IS_ACTIVE_USER = "isActiveUser"
    const val DISPLAY_CURRENCY = "displayCurrency"
    const val IS_LOGGED_IN = "isLoggedIn"
}
