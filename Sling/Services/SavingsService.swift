import SwiftUI
import Combine

// MARK: - Yield Display Mode

enum YieldDisplayMode: String, CaseIterable {
    case accumulating = "Accumulating"
    case rebasing = "Rebasing"
    
    var description: String {
        switch self {
        case .accumulating:
            return "USDY price increases, token count stays fixed"
        case .rebasing:
            return "Token count increases, price stays at $1.00"
        }
    }
}

// MARK: - Savings Service

class SavingsService: ObservableObject {
    static let shared = SavingsService()
    
    // MARK: - Published State
    
    /// Base USDY tokens held (before any rebasing adjustment)
    @Published var usdyBalance: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(usdyBalance, forKey: "usdyBalance")
        }
    }
    
    /// Timestamp of first deposit (for yield calculation)
    @Published var depositTimestamp: Date? {
        didSet {
            if let timestamp = depositTimestamp {
                UserDefaults.standard.set(timestamp, forKey: "usdyDepositTimestamp")
            } else {
                UserDefaults.standard.removeObject(forKey: "usdyDepositTimestamp")
            }
        }
    }
    
    /// Display mode toggle (accumulating vs rebasing)
    @Published var displayMode: YieldDisplayMode = .accumulating {
        didSet {
            UserDefaults.standard.set(displayMode.rawValue, forKey: "yieldDisplayMode")
        }
    }
    
    /// Total USDC deposited (for calculating total earnings)
    @Published var totalDeposited: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(totalDeposited, forKey: "totalUsdcDeposited")
        }
    }
    
    // MARK: - Constants
    
    /// Annual Percentage Yield (3.75%)
    let apyRate: Double = 0.0375
    
    /// Base USDY price (always $1.00 at time of first deposit)
    let baseUsdyPrice: Double = 1.0
    
    /// Demo mode: Time multiplier (1 second = this many seconds of yield)
    /// For prototype: 1 second = ~1 day of yield (86400x speed)
    let demoTimeMultiplier: Double = 86400.0
    
    // MARK: - Initialization
    
    private init() {
        // Load persisted state
        self.usdyBalance = UserDefaults.standard.double(forKey: "usdyBalance")
        self.totalDeposited = UserDefaults.standard.double(forKey: "totalUsdcDeposited")
        
        if let timestamp = UserDefaults.standard.object(forKey: "usdyDepositTimestamp") as? Date {
            self.depositTimestamp = timestamp
        }
        
        if let modeString = UserDefaults.standard.string(forKey: "yieldDisplayMode"),
           let mode = YieldDisplayMode(rawValue: modeString) {
            self.displayMode = mode
        }
    }
    
    // MARK: - Computed Properties
    
    /// Current USDY price based on time elapsed since first deposit
    /// In accumulating mode, this price grows. In rebasing mode, it's always $1.00 for display.
    var currentUsdyPrice: Double {
        guard let timestamp = depositTimestamp else { return baseUsdyPrice }
        let secondsElapsed = Date().timeIntervalSince(timestamp)
        // Apply demo time multiplier for prototype (1 sec real time = ~1 day of yield)
        let acceleratedSeconds = secondsElapsed * demoTimeMultiplier
        let yearsElapsed = acceleratedSeconds / (365.25 * 24 * 3600)
        // Compound interest formula: P * (1 + r)^t
        return baseUsdyPrice * pow(1 + apyRate, yearsElapsed)
    }
    
    /// Total USD value of holdings
    var totalValueUSD: Double {
        return usdyBalance * currentUsdyPrice
    }
    
    /// Display token count based on mode
    var displayTokens: Double {
        switch displayMode {
        case .accumulating:
            // Fixed token count, price grows
            return usdyBalance
        case .rebasing:
            // Token count grows, price stays $1.00
            return usdyBalance * currentUsdyPrice
        }
    }
    
    /// Display price based on mode
    var displayPrice: Double {
        switch displayMode {
        case .accumulating:
            return currentUsdyPrice
        case .rebasing:
            return 1.0  // Always $1.00 in rebasing mode
        }
    }
    
    /// Total earnings (current value - total deposited)
    var totalEarnings: Double {
        return max(0, totalValueUSD - totalDeposited)
    }
    
    /// Earnings display based on mode
    var earningsDisplay: String {
        switch displayMode {
        case .accumulating:
            return String(format: "+$%.2f", totalEarnings)
        case .rebasing:
            let earnedTokens = displayTokens - usdyBalance
            return String(format: "+%.4f USDY", earnedTokens)
        }
    }
    
    /// Check if user has any savings
    var hasSavings: Bool {
        return usdyBalance > 0
    }
    
    // MARK: - Actions
    
    /// Deposit USDC and receive USDY
    func deposit(usdcAmount: Double) {
        guard usdcAmount > 0 else { return }
        
        // If this is the first deposit, set the timestamp
        if depositTimestamp == nil {
            depositTimestamp = Date()
        }
        
        // Swap USDC for USDY at current price
        // New deposits always get USDY at current price
        let usdyReceived = usdcAmount / currentUsdyPrice
        usdyBalance += usdyReceived
        totalDeposited += usdcAmount
        
        // Deduct from portfolio cash balance
        PortfolioService.shared.deductCash(usdcAmount)
    }
    
    /// Withdraw USDY and receive USDC
    func withdraw(usdyAmount: Double) {
        guard usdyAmount > 0, usdyAmount <= usdyBalance else { return }
        
        // Swap USDY back to USDC at current price
        let usdcReceived = usdyAmount * currentUsdyPrice
        usdyBalance -= usdyAmount
        
        // Adjust total deposited proportionally
        let withdrawRatio = usdyAmount / (usdyBalance + usdyAmount)
        totalDeposited -= totalDeposited * withdrawRatio
        
        // Add to portfolio cash balance
        PortfolioService.shared.addCash(usdcReceived)
        
        // Clear timestamp if all withdrawn
        if usdyBalance <= 0 {
            depositTimestamp = nil
            totalDeposited = 0
        }
    }
    
    /// Withdraw all USDY
    func withdrawAll() {
        withdraw(usdyAmount: usdyBalance)
    }
    
    /// Reset savings (for testing)
    func reset() {
        usdyBalance = 0
        depositTimestamp = nil
        totalDeposited = 0
    }
    
    // MARK: - Formatting Helpers
    
    func formatTokens(_ amount: Double) -> String {
        return String(format: "%.2f", amount)
    }
    
    func formatPrice(_ price: Double) -> String {
        return String(format: "$%.4f", price)
    }
    
    func formatUSD(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
}
