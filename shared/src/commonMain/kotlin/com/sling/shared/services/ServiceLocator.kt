package com.sling.shared.services

import com.sling.shared.platform.PersistenceDriver

/**
 * Simple service locator for dependency injection
 * 
 * Initialize in platform-specific code:
 * - Android: in Application.onCreate()
 * - iOS: in AppDelegate
 */
object ServiceLocator {
    private var _persistenceDriver: PersistenceDriver? = null
    private var _activityService: ActivityService? = null
    private var _portfolioService: PortfolioService? = null
    
    /**
     * Initialize the service locator with platform-specific dependencies
     */
    fun initialize(persistenceDriver: PersistenceDriver) {
        _persistenceDriver = persistenceDriver
        _activityService = ActivityService(persistenceDriver)
        _portfolioService = PortfolioService(persistenceDriver)
    }
    
    /**
     * Get the persistence driver
     */
    val persistenceDriver: PersistenceDriver
        get() = _persistenceDriver ?: error("ServiceLocator not initialized. Call initialize() first.")
    
    /**
     * Get the activity service
     */
    val activityService: ActivityService
        get() = _activityService ?: error("ServiceLocator not initialized. Call initialize() first.")
    
    /**
     * Get the portfolio service
     */
    val portfolioService: PortfolioService
        get() = _portfolioService ?: error("ServiceLocator not initialized. Call initialize() first.")
    
    /**
     * Check if the service locator is initialized
     */
    val isInitialized: Boolean
        get() = _persistenceDriver != null
    
    /**
     * Reset the service locator (for testing)
     */
    fun reset() {
        _persistenceDriver = null
        _activityService = null
        _portfolioService = null
    }
}
