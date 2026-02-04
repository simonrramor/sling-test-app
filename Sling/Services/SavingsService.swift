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

// MARK: - Savings Transaction

struct SavingsTransaction: Identifiable, Codable {
    let id: UUID
    let type: TransactionType
    let usdAmount: Double
    let usdyAmount: Double
    let date: Date
    
    enum TransactionType: String, Codable {
        case deposit
        case withdrawal
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var isDeposit: Bool {
        type == .deposit
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
    
    /// Transaction history
    @Published var transactions: [SavingsTransaction] = [] {
        didSet {
            saveTransactions()
        }
    }
    
    // MARK: - Constants
    
    /// Annual Percentage Yield (3.50%)
    let apyRate: Double = 0.0350
    
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
        self.transactions = loadTransactions()
        
        if let timestamp = UserDefaults.standard.object(forKey: "usdyDepositTimestamp") as? Date {
            self.depositTimestamp = timestamp
        }
        
        if let modeString = UserDefaults.standard.string(forKey: "yieldDisplayMode"),
           let mode = YieldDisplayMode(rawValue: modeString) {
            self.displayMode = mode
        }
        
        // Migration: Fix USDY balance if it was deposited with inflated pricing
        // USDY should be roughly 1:1 with USD at base price
        let hasMigrated = UserDefaults.standard.bool(forKey: "usdyBalanceMigrated_v2")
        if !hasMigrated && totalDeposited > 0 && usdyBalance > 0 {
            // Recalculate USDY at base price (1:1 with USD)
            usdyBalance = totalDeposited / baseUsdyPrice
            // Reset timestamp to now so yield starts fresh
            depositTimestamp = Date()
            UserDefaults.standard.set(true, forKey: "usdyBalanceMigrated_v2")
        }
        
        // Migration: Create historical transaction for existing balances
        let hasTransactionMigration = UserDefaults.standard.bool(forKey: "savingsTransactionsMigrated_v1")
        if !hasTransactionMigration && totalDeposited > 0 && transactions.isEmpty {
            // Create a historical deposit transaction
            let historicalTransaction = SavingsTransaction(
                id: UUID(),
                type: .deposit,
                usdAmount: totalDeposited,
                usdyAmount: usdyBalance,
                date: depositTimestamp ?? Date()
            )
            transactions = [historicalTransaction]
            UserDefaults.standard.set(true, forKey: "savingsTransactionsMigrated_v1")
        }
    }
    
    // MARK: - Transaction Persistence
    
    private func saveTransactions() {
        if let data = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(data, forKey: "savingsTransactions")
        }
    }
    
    private func loadTransactions() -> [SavingsTransaction] {
        guard let data = UserDefaults.standard.data(forKey: "savingsTransactions"),
              let transactions = try? JSONDecoder().decode([SavingsTransaction].self, from: data) else {
            return []
        }
        return transactions
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
            return "+" + totalEarnings.asUSD
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
        
        // Swap USDC for USDY at base price ($1.00)
        // This gives users 1:1 USDY for their USD deposit
        // The time multiplier only affects yield display, not deposit pricing
        let usdyReceived = usdcAmount / baseUsdyPrice
        usdyBalance += usdyReceived
        totalDeposited += usdcAmount
        
        // Record transaction
        let transaction = SavingsTransaction(
            id: UUID(),
            type: .deposit,
            usdAmount: usdcAmount,
            usdyAmount: usdyReceived,
            date: Date()
        )
        transactions.insert(transaction, at: 0)
        
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
        
        // Record transaction
        let transaction = SavingsTransaction(
            id: UUID(),
            type: .withdrawal,
            usdAmount: usdcReceived,
            usdyAmount: usdyAmount,
            date: Date()
        )
        transactions.insert(transaction, at: 0)
        
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
        return amount.asUSD
    }
}
