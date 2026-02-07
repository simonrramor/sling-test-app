package com.sling.shared.models

import kotlinx.serialization.Serializable
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

/**
 * Represents a stock holding in the user's portfolio
 */
@Serializable
data class Holding @OptIn(ExperimentalUuidApi::class) constructor(
    val id: String = Uuid.random().toString(),
    val symbol: String,      // Stock symbol (e.g., "AAPL")
    val iconName: String,    // Asset icon name (e.g., "StockApple")
    val shares: Double,      // Number of shares owned
    val averageCost: Double  // Average purchase price per share
) {
    /**
     * Total cost basis for this holding
     */
    val totalCost: Double
        get() = shares * averageCost
}

/**
 * Portfolio event type for tracking buy/sell history
 */
enum class PortfolioEventType {
    BUY,
    SELL
}

/**
 * Represents a portfolio event (buy or sell)
 */
@Serializable
data class PortfolioEvent @OptIn(ExperimentalUuidApi::class) constructor(
    val id: String = Uuid.random().toString(),
    val timestampMillis: Long,
    val type: PortfolioEventType,
    val portfolioValueAfter: Double,
    val iconName: String,
    val shares: Double,
    val pricePerShare: Double
)
