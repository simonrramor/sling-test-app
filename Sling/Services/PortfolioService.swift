import Foundation
import Combine
import CoreGraphics

// #region agent log
private let debugLogPath = "/Users/simonamor/Desktop/sling-test-app-2/.cursor/debug.log"
private var generateChartDataCount = 0
private func debugLog(_ location: String, _ message: String, _ data: [String: Any] = [:]) {
    let entry: [String: Any] = [
        "timestamp": Date().timeIntervalSince1970 * 1000,
        "location": location,
        "message": message,
        "data": data,
        "sessionId": "debug-session"
    ]
    if let jsonData = try? JSONSerialization.data(withJSONObject: entry),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        if let handle = FileHandle(forWritingAtPath: debugLogPath) {
            handle.seekToEndOfFile()
            handle.write((jsonString + "\n").data(using: .utf8)!)
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: debugLogPath, contents: (jsonString + "\n").data(using: .utf8))
        }
    }
}
// #endregion

// MARK: - Portfolio Event Model

enum PortfolioEventType {
    case buy
    case sell
}

struct PortfolioEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: PortfolioEventType
    let portfolioValueAfter: Double
    let iconName: String
    let shares: Double
    let pricePerShare: Double
}

// MARK: - Holding Model

struct Holding: Identifiable {
    let id = UUID()
    let symbol: String      // Stock symbol (e.g., "AAPL")
    let iconName: String    // Asset icon name (e.g., "StockApple")
    var shares: Double      // Number of shares owned
    var averageCost: Double // Average purchase price per share
    
    var totalCost: Double {
        shares * averageCost
    }
}

// MARK: - Portfolio Service

class PortfolioService: ObservableObject {
    static let shared = PortfolioService()
    
    @Published var holdings: [String: Holding] = [:] // iconName -> Holding
    @Published var cashBalance: Double = 0.0 // Sling wallet balance in USD
    @Published var history: [PortfolioEvent] = [] // Portfolio event history
    @Published var displayCurrency: String = "GBP" {
        didSet {
            UserDefaults.standard.set(displayCurrency, forKey: "displayCurrency")
        }
    }
    
    private let ondoService = OndoService.shared
    private let persistence = PersistenceService.shared
    
    private init() {
        // Load display currency preference (default to GBP)
        self.displayCurrency = UserDefaults.standard.string(forKey: "displayCurrency") ?? "GBP"
        
        // Try to load from iCloud first
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
            
            print("PortfolioService: Restored from iCloud - \(holdings.count) holdings, £\(cashBalance) cash")
        } else {
            // No saved data - start fresh with £0
            print("PortfolioService: No saved data, starting fresh")
        }
    }
    
    // MARK: - Persistence
    
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
    
    // MARK: - History Tracking
    
    /// Record a portfolio event
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
        print("PortfolioService: Recorded \(type) event, portfolio now worth $\(event.portfolioValueAfter)")
        
        // Save to iCloud
        saveToCloud()
    }
    
    /// Get the first event timestamp (when portfolio was created)
    var portfolioCreatedAt: Date? {
        history.first?.timestamp
    }
    
    // MARK: - Portfolio Calculations
    
    /// Total value of all holdings at current market prices
    func portfolioValue() -> Double {
        var total: Double = 0
        for (iconName, holding) in holdings {
            if let tokenData = ondoService.tokenData[iconName] {
                total += holding.shares * tokenData.currentPrice
            } else {
                // Use average cost if no current price available
                total += holding.totalCost
            }
        }
        return total
    }
    
    /// Total portfolio including cash
    var totalBalance: Double {
        portfolioValue() + cashBalance
    }
    
    /// Get value of a specific holding at current price
    func holdingValue(for iconName: String) -> Double {
        guard let holding = holdings[iconName] else { return 0 }
        if let tokenData = ondoService.tokenData[iconName] {
            return holding.shares * tokenData.currentPrice
        }
        return holding.totalCost
    }
    
    /// Get profit/loss for a specific holding
    func holdingProfitLoss(for iconName: String) -> (value: Double, percent: Double, isPositive: Bool) {
        guard let holding = holdings[iconName],
              let tokenData = ondoService.tokenData[iconName] else {
            return (0, 0, true)
        }
        
        let currentValue = holding.shares * tokenData.currentPrice
        let costBasis = holding.totalCost
        let profitLoss = currentValue - costBasis
        let percent = costBasis > 0 ? (profitLoss / costBasis) * 100 : 0
        
        return (profitLoss, percent, profitLoss >= 0)
    }
    
    /// Get total portfolio profit/loss
    func totalProfitLoss() -> (value: Double, percent: Double, isPositive: Bool) {
        var totalCost: Double = 0
        var totalValue: Double = 0
        
        for (iconName, holding) in holdings {
            totalCost += holding.totalCost
            if let tokenData = ondoService.tokenData[iconName] {
                totalValue += holding.shares * tokenData.currentPrice
            } else {
                totalValue += holding.totalCost
            }
        }
        
        let profitLoss = totalValue - totalCost
        let percent = totalCost > 0 ? (profitLoss / totalCost) * 100 : 0
        
        return (profitLoss, percent, profitLoss >= 0)
    }
    
    // MARK: - Trading Methods
    
    /// Buy shares of a stock
    /// - Parameters:
    ///   - iconName: The icon/asset name for the stock
    ///   - symbol: The stock symbol
    ///   - shares: Number of shares to buy
    ///   - pricePerShare: Price per share at time of purchase
    /// - Returns: True if purchase was successful
    @discardableResult
    func buy(iconName: String, symbol: String, shares: Double, pricePerShare: Double) -> Bool {
        let totalCost = shares * pricePerShare
        
        // Check if we have enough cash
        guard totalCost <= cashBalance else {
            return false
        }
        
        // Deduct from cash balance
        cashBalance -= totalCost
        
        // Update or create holding
        if var existing = holdings[iconName] {
            // Calculate new average cost
            let totalShares = existing.shares + shares
            let totalValue = existing.totalCost + totalCost
            existing.averageCost = totalValue / totalShares
            existing.shares = totalShares
            holdings[iconName] = existing
        } else {
            // Create new holding
            let holding = Holding(
                symbol: symbol,
                iconName: iconName,
                shares: shares,
                averageCost: pricePerShare
            )
            holdings[iconName] = holding
        }
        
        print("PortfolioService: Bought \(shares) shares of \(symbol) at $\(pricePerShare)")
        print("PortfolioService: Cash balance: $\(cashBalance)")
        
        // Record the event
        recordEvent(type: .buy, iconName: iconName, shares: shares, pricePerShare: pricePerShare)
        
        return true
    }
    
    /// Sell shares of a stock
    /// - Parameters:
    ///   - iconName: The icon/asset name for the stock
    ///   - shares: Number of shares to sell
    ///   - pricePerShare: Price per share at time of sale
    /// - Returns: True if sale was successful
    @discardableResult
    func sell(iconName: String, shares: Double, pricePerShare: Double) -> Bool {
        guard var holding = holdings[iconName] else {
            return false
        }
        
        // Check if we have enough shares
        guard shares <= holding.shares else {
            return false
        }
        
        let saleValue = shares * pricePerShare
        
        // Add to cash balance
        cashBalance += saleValue
        
        // Update holding
        holding.shares -= shares
        
        if holding.shares <= 0.0001 { // Essentially zero
            holdings.removeValue(forKey: iconName)
        } else {
            holdings[iconName] = holding
        }
        
        print("PortfolioService: Sold \(shares) shares of \(holding.symbol) at $\(pricePerShare)")
        print("PortfolioService: Cash balance: $\(cashBalance)")
        
        // Record the event
        recordEvent(type: .sell, iconName: iconName, shares: shares, pricePerShare: pricePerShare)
        
        return true
    }
    
    /// Get the number of shares owned for a stock
    func sharesOwned(for iconName: String) -> Double {
        holdings[iconName]?.shares ?? 0
    }
    
    /// Check if user owns any shares of a stock
    func ownsStock(_ iconName: String) -> Bool {
        guard let holding = holdings[iconName] else { return false }
        return holding.shares > 0.0001
    }
    
    // MARK: - Chart Data Generation
    
    /// Total cost basis (what was paid for all holdings)
    var totalCostBasis: Double {
        holdings.values.reduce(0) { $0 + $1.totalCost }
    }
    
    /// Generate chart data points for portfolio VALUE over time
    /// This shows portfolio growth including purchases
    /// - Parameters:
    ///   - period: Time period (1H or 1D)
    ///   - sampleCount: Number of points to generate
    /// - Returns: Array of normalized values (0-1) for the chart
    func generateChartData(period: String, sampleCount: Int = 10) -> [CGFloat] {
        // #region agent log
        generateChartDataCount += 1
        debugLog("PortfolioService.swift:generateChartData", "H3: Generating chart data", ["period": period, "sampleCount": sampleCount, "callCount": generateChartDataCount, "historyCount": history.count])
        // #endregion
        guard !history.isEmpty else { return [] }
        
        let now = Date()
        let periodStart: Date
        
        switch period {
        case "1H":
            periodStart = Calendar.current.date(byAdding: .hour, value: -1, to: now) ?? now
        case "1D":
            periodStart = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        default:
            periodStart = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        }
        
        // Generate sample points across the time period
        var chartValues: [Double] = []
        let timeRange = now.timeIntervalSince(periodStart)
        
        for i in 0..<sampleCount {
            let progress = Double(i) / Double(sampleCount - 1)
            let sampleTime = periodStart.addingTimeInterval(timeRange * progress)
            
            // Find the portfolio value at this time
            let value = portfolioValueAt(time: sampleTime)
            chartValues.append(value)
        }
        
        // Normalize to 0-1 range
        guard let minValue = chartValues.min(),
              let maxValue = chartValues.max() else {
            return chartValues.map { _ in CGFloat(0.5) }
        }
        
        // If no change in value, show flat line at middle
        if maxValue == minValue {
            return chartValues.map { _ in CGFloat(0.5) }
        }
        
        let range = maxValue - minValue
        return chartValues.map { CGFloat(($0 - minValue) / range) }
    }
    
    /// Get portfolio value at a specific point in time
    /// - Parameter time: The time to check
    /// - Returns: Portfolio value at that time
    func portfolioValueAt(time: Date) -> Double {
        // Find the most recent event before or at this time
        let eventsBeforeTime = history.filter { $0.timestamp <= time }
        
        guard let lastEvent = eventsBeforeTime.last else {
            // No events before this time - portfolio was empty
            return 0
        }
        
        // Start with the value right after the last event
        let baseValue = lastEvent.portfolioValueAfter
        
        // If we have current holdings, adjust for price changes since the event
        if time > lastEvent.timestamp {
            // Calculate current holdings value with interpolated prices
            var adjustedValue: Double = 0
            
            for (iconName, holding) in holdings {
                if let tokenData = ondoService.tokenData[iconName], !tokenData.rawPrices.isEmpty {
                    // Calculate how much time has passed since event relative to token data period
                    let timeSinceEvent = time.timeIntervalSince(lastEvent.timestamp)
                    let totalPeriod = Date().timeIntervalSince(lastEvent.timestamp)
                    
                    if totalPeriod > 0 {
                        let progress = min(timeSinceEvent / totalPeriod, 1.0)
                        let price = tokenData.priceAt(progress: progress)
                        adjustedValue += holding.shares * price
                    } else {
                        adjustedValue += holding.shares * tokenData.currentPrice
                    }
                } else {
                    // No price data, use event value
                    adjustedValue += holding.totalCost
                }
            }
            
            // If we have holdings, use adjusted value; otherwise use event value
            if !holdings.isEmpty {
                return adjustedValue
            }
        }
        
        return baseValue
    }
    
    /// Get portfolio value at start of a time period
    func portfolioValueAtPeriodStart(period: String) -> Double {
        let now = Date()
        let periodStart: Date
        
        switch period {
        case "1H":
            periodStart = Calendar.current.date(byAdding: .hour, value: -1, to: now) ?? now
        case "1D":
            periodStart = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        default:
            periodStart = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        }
        
        return portfolioValueAt(time: periodStart)
    }
    
    /// Add cash to balance (for demo purposes)
    func addCash(_ amount: Double) {
        cashBalance += amount
        saveToCloud()
    }
    
    /// Deduct cash from balance (for sending money, etc.)
    func deductCash(_ amount: Double) {
        cashBalance = max(0, cashBalance - amount)
        saveToCloud()
    }
    
    /// Reset portfolio to initial state (for demo purposes)
    func reset() {
        holdings = [:]
        cashBalance = 0.0
        history = []
        saveToCloud()
    }
}
