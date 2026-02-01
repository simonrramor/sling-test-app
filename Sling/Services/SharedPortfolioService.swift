//
//  SharedPortfolioService.swift
//  sling-test-app-2
//
//  Swift wrapper for KMP PortfolioService
//  Bridges Kotlin StateFlow to SwiftUI's ObservableObject pattern
//

import Foundation
import Combine
// Note: Import Shared framework when KMP build is available
// import Shared

/**
 * Swift wrapper for the KMP PortfolioService
 * 
 * This provides a SwiftUI-compatible interface to the shared Kotlin business logic.
 * The wrapper collects Kotlin StateFlow values and publishes them as @Published properties.
 * 
 * Usage:
 * 1. Build the shared KMP framework: ./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
 * 2. Run pod install
 * 3. Uncomment the 'import Shared' line above
 * 4. Replace PortfolioService.shared with SharedPortfolioService.shared in your views
 */
class SharedPortfolioService: ObservableObject {
    static let shared = SharedPortfolioService()
    
    // Published properties that mirror the KMP service's StateFlow
    @Published var holdings: [String: Holding] = [:]
    @Published var cashBalance: Double = 0.0
    @Published var history: [PortfolioEvent] = []
    @Published var displayCurrency: String = "GBP" {
        didSet {
            UserDefaults.standard.set(displayCurrency, forKey: "displayCurrency")
        }
    }
    
    private let persistence = PersistenceService.shared
    
    private init() {
        // Load display currency preference
        displayCurrency = UserDefaults.standard.string(forKey: "displayCurrency") ?? "GBP"
        
        // Load persisted data
        loadFromPersistence()
        
        // TODO: When KMP is integrated, initialize the KMP service and collect its StateFlow
    }
    
    // MARK: - Persistence
    
    private func loadFromPersistence() {
        if let persisted = persistence.loadPortfolio() {
            // Restore holdings
            for (key, h) in persisted.holdings {
                holdings[key] = Holding(
                    symbol: h.symbol,
                    iconName: h.iconName,
                    shares: h.shares,
                    averageCost: h.averageCost
                )
            }
            cashBalance = persisted.cashBalance
            
            // Restore history
            for e in persisted.history {
                let event = PortfolioEvent(
                    timestamp: e.timestamp,
                    type: e.type == "buy" ? .buy : .sell,
                    portfolioValueAfter: e.portfolioValueAfter,
                    iconName: e.iconName,
                    shares: e.shares,
                    pricePerShare: e.pricePerShare
                )
                history.append(event)
            }
        }
    }
    
    private func saveToCloud() {
        var persistedHoldings: [String: PersistedHolding] = [:]
        for (key, h) in holdings {
            persistedHoldings[key] = PersistedHolding(
                symbol: h.symbol,
                iconName: h.iconName,
                shares: h.shares,
                averageCost: h.averageCost
            )
        }
        
        let persistedHistory = history.map { e in
            PersistedPortfolioEvent(
                timestamp: e.timestamp,
                type: e.type == .buy ? "buy" : "sell",
                portfolioValueAfter: e.portfolioValueAfter,
                iconName: e.iconName,
                shares: e.shares,
                pricePerShare: e.pricePerShare
            )
        }
        
        persistence.savePortfolio(
            holdings: persistedHoldings,
            cashBalance: cashBalance,
            history: persistedHistory
        )
    }
    
    // MARK: - Portfolio Calculations
    
    func portfolioValue() -> Double {
        return holdings.values.reduce(0) { $0 + $1.totalCost }
    }
    
    var totalBalance: Double {
        portfolioValue() + cashBalance
    }
    
    func holdingValue(for iconName: String) -> Double {
        guard let holding = holdings[iconName] else { return 0 }
        return holding.totalCost
    }
    
    func sharesOwned(for iconName: String) -> Double {
        holdings[iconName]?.shares ?? 0
    }
    
    func ownsStock(_ iconName: String) -> Bool {
        guard let holding = holdings[iconName] else { return false }
        return holding.shares > 0.0001
    }
    
    // MARK: - Trading
    
    @discardableResult
    func buy(iconName: String, symbol: String, shares: Double, pricePerShare: Double) -> Bool {
        let totalCost = shares * pricePerShare
        
        guard totalCost <= cashBalance else { return false }
        
        cashBalance -= totalCost
        
        if var existing = holdings[iconName] {
            let totalShares = existing.shares + shares
            let totalValue = existing.totalCost + totalCost
            existing.averageCost = totalValue / totalShares
            existing.shares = totalShares
            holdings[iconName] = existing
        } else {
            holdings[iconName] = Holding(
                symbol: symbol,
                iconName: iconName,
                shares: shares,
                averageCost: pricePerShare
            )
        }
        
        recordEvent(type: .buy, iconName: iconName, shares: shares, pricePerShare: pricePerShare)
        return true
    }
    
    @discardableResult
    func sell(iconName: String, shares: Double, pricePerShare: Double) -> Bool {
        guard var holding = holdings[iconName] else { return false }
        guard shares <= holding.shares else { return false }
        
        let saleValue = shares * pricePerShare
        cashBalance += saleValue
        
        holding.shares -= shares
        
        if holding.shares <= 0.0001 {
            holdings.removeValue(forKey: iconName)
        } else {
            holdings[iconName] = holding
        }
        
        recordEvent(type: .sell, iconName: iconName, shares: shares, pricePerShare: pricePerShare)
        return true
    }
    
    private func recordEvent(type: PortfolioEventType, iconName: String, shares: Double, pricePerShare: Double) {
        let event = PortfolioEvent(
            timestamp: Date(),
            type: type,
            portfolioValueAfter: portfolioValue(),
            iconName: iconName,
            shares: shares,
            pricePerShare: pricePerShare
        )
        history.append(event)
        saveToCloud()
    }
    
    // MARK: - Cash Management
    
    func addCash(_ amount: Double) {
        cashBalance += amount
        saveToCloud()
    }
    
    func deductCash(_ amount: Double) {
        cashBalance = max(0, cashBalance - amount)
        saveToCloud()
    }
    
    func reset() {
        holdings = [:]
        cashBalance = 0.0
        history = []
        saveToCloud()
    }
}
