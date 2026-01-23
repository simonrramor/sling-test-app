import SwiftUI
import Combine

// MARK: - Transaction Type

enum FeeTransactionType {
    case deposit
    case withdrawal
    case p2pSend
    case p2pRequest
}

// MARK: - Fee Result

struct FeeResult {
    let amount: Double           // Fee in stablecoin (e.g., 0.50)
    let stablecoin: String       // "USDP" or "EURC"
    let displayAmount: Double    // Converted to display currency
    let displayCurrency: String  // User's display currency
    let isWaived: Bool
    let waiverReason: String?    // e.g., "First 3 transfers free"
    
    /// Returns true if no fee applies (either free or waived)
    var isFree: Bool {
        amount == 0 || isWaived
    }
    
    /// Formatted fee string in stablecoin (e.g., "$0.50")
    var formattedStablecoinAmount: String {
        let symbol = stablecoin == "EURC" ? "€" : "$"
        return "\(symbol)\(String(format: "%.2f", amount))"
    }
    
    /// Formatted fee string in display currency (e.g., "£0.38")
    var formattedDisplayAmount: String {
        let symbol = ExchangeRateService.symbol(for: displayCurrency)
        return "\(symbol)\(String(format: "%.2f", displayAmount))"
    }
    
    /// Combined display (e.g., "$0.50 (£0.38)")
    var formattedCombined: String {
        if displayCurrency == stablecoin || displayCurrency == (stablecoin == "USDP" ? "USD" : "EUR") {
            return formattedStablecoinAmount
        }
        return "\(formattedStablecoinAmount) (\(formattedDisplayAmount))"
    }
    
    /// Static free result
    static var free: FeeResult {
        FeeResult(
            amount: 0,
            stablecoin: "USDP",
            displayAmount: 0,
            displayCurrency: "USD",
            isWaived: false,
            waiverReason: nil
        )
    }
}

// MARK: - Fee Service

/// Service for calculating transaction fees
/// Fees are charged in stablecoin (USDP or EURC) based on account type
class FeeService: ObservableObject {
    static let shared = FeeService()
    
    // MARK: - Account Configuration
    
    /// Account stablecoin (USDP for UK/US accounts, EURC for EU accounts)
    @Published var accountStablecoin: String = "USDP"
    
    /// User's local currency based on account region
    @Published var localCurrency: String = "GBP"
    
    /// User's display currency preference
    @Published var displayCurrency: String = "GBP"
    
    // MARK: - Fee Configuration
    
    /// Base fee amount in stablecoin
    let baseFee: Double = 0.50
    
    // MARK: - Fee Waiver State
    
    /// Number of free transfers remaining for new user promotion
    @AppStorage("freeTransfersRemaining") var freeTransfersRemaining: Int = 3
    
    /// Whether user is an early adopter (grandfathered with no fees)
    @AppStorage("isEarlyAdopter") var isEarlyAdopter: Bool = false
    
    /// Date until which early adopter status is valid
    @AppStorage("earlyAdopterExpiryTimestamp") private var earlyAdopterExpiryTimestamp: Double = 0
    
    var earlyAdopterExpiry: Date? {
        get { earlyAdopterExpiryTimestamp > 0 ? Date(timeIntervalSince1970: earlyAdopterExpiryTimestamp) : nil }
        set { earlyAdopterExpiryTimestamp = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Sync display currency with portfolio service
        displayCurrency = PortfolioService.shared.displayCurrency
    }
    
    // MARK: - Fee Calculation
    
    /// Calculate fee for a transaction
    /// - Parameters:
    ///   - type: Type of transaction (deposit, withdrawal, p2p)
    ///   - sourceCurrency: Currency being sent from
    ///   - destinationCurrency: Currency being sent to
    /// - Returns: FeeResult with fee details
    func calculateFee(
        for type: FeeTransactionType,
        sourceCurrency: String,
        destinationCurrency: String
    ) -> FeeResult {
        // P2P is always free
        if type == .p2pSend || type == .p2pRequest {
            return .free
        }
        
        // Determine if this is a foreign currency transaction
        let isForeignTransaction: Bool
        switch type {
        case .deposit:
            // Foreign deposit = source currency is not local currency
            isForeignTransaction = isForeignCurrency(sourceCurrency)
        case .withdrawal:
            // Foreign withdrawal = destination currency is not local currency
            isForeignTransaction = isForeignCurrency(destinationCurrency)
        case .p2pSend, .p2pRequest:
            isForeignTransaction = false
        }
        
        // No fee for local currency transactions
        if !isForeignTransaction {
            return .free
        }
        
        // Check for fee waivers
        if let waiverResult = checkWaivers() {
            return waiverResult
        }
        
        // Calculate fee in display currency
        let displayAmount = convertToDisplayCurrency(baseFee)
        
        return FeeResult(
            amount: baseFee,
            stablecoin: accountStablecoin,
            displayAmount: displayAmount,
            displayCurrency: displayCurrency,
            isWaived: false,
            waiverReason: nil
        )
    }
    
    /// Check if a currency is foreign (not the user's local currency)
    func isForeignCurrency(_ currency: String) -> Bool {
        // Normalize currency codes
        let normalizedCurrency = currency.uppercased()
        let normalizedLocal = localCurrency.uppercased()
        
        // Also consider stablecoin equivalents
        let stablecoinBase = accountStablecoin == "EURC" ? "EUR" : "USD"
        
        return normalizedCurrency != normalizedLocal && normalizedCurrency != stablecoinBase
    }
    
    // MARK: - Fee Waivers
    
    /// Check if any fee waivers apply
    private func checkWaivers() -> FeeResult? {
        // Check early adopter status
        if isEarlyAdopter {
            if let expiry = earlyAdopterExpiry, Date() < expiry {
                return FeeResult(
                    amount: baseFee,
                    stablecoin: accountStablecoin,
                    displayAmount: convertToDisplayCurrency(baseFee),
                    displayCurrency: displayCurrency,
                    isWaived: true,
                    waiverReason: "Early adopter - fees waived"
                )
            } else if earlyAdopterExpiry == nil {
                // No expiry set = permanent early adopter
                return FeeResult(
                    amount: baseFee,
                    stablecoin: accountStablecoin,
                    displayAmount: convertToDisplayCurrency(baseFee),
                    displayCurrency: displayCurrency,
                    isWaived: true,
                    waiverReason: "Early adopter - fees waived"
                )
            }
        }
        
        // Check free transfers remaining
        if freeTransfersRemaining > 0 {
            return FeeResult(
                amount: baseFee,
                stablecoin: accountStablecoin,
                displayAmount: convertToDisplayCurrency(baseFee),
                displayCurrency: displayCurrency,
                isWaived: true,
                waiverReason: "\(freeTransfersRemaining) free transfer\(freeTransfersRemaining == 1 ? "" : "s") remaining"
            )
        }
        
        return nil
    }
    
    /// Use a free transfer (decrements counter)
    func useFreeTransfer() {
        if freeTransfersRemaining > 0 {
            freeTransfersRemaining -= 1
        }
    }
    
    // MARK: - Currency Conversion
    
    /// Convert stablecoin amount to display currency
    private func convertToDisplayCurrency(_ amount: Double) -> Double {
        // Get exchange rate from stablecoin to display currency
        let stablecoinBase = accountStablecoin == "EURC" ? "EUR" : "USD"
        
        if displayCurrency == stablecoinBase {
            return amount
        }
        
        // Use cached exchange rate for synchronous conversion
        if let rate = ExchangeRateService.shared.getCachedRate(from: stablecoinBase, to: displayCurrency) {
            return amount * rate
        }
        
        // Fallback: use approximate rates if cache not available
        let fallbackRates: [String: [String: Double]] = [
            "USD": ["GBP": 0.79, "EUR": 0.92, "JPY": 149.0, "CHF": 0.88, "CAD": 1.36, "AUD": 1.53],
            "EUR": ["GBP": 0.86, "USD": 1.09, "JPY": 162.0, "CHF": 0.96, "CAD": 1.48, "AUD": 1.66]
        ]
        
        if let rateMap = fallbackRates[stablecoinBase], let rate = rateMap[displayCurrency] {
            return amount * rate
        }
        
        return amount
    }
    
    // MARK: - Configuration
    
    /// Configure service for a specific account region
    func configure(localCurrency: String, accountStablecoin: String) {
        self.localCurrency = localCurrency
        self.accountStablecoin = accountStablecoin
    }
    
    /// Set early adopter status with optional expiry
    func setEarlyAdopterStatus(_ isEarlyAdopter: Bool, expiryDate: Date? = nil) {
        self.isEarlyAdopter = isEarlyAdopter
        self.earlyAdopterExpiry = expiryDate
    }
    
    /// Reset free transfers (for testing or promotions)
    func resetFreeTransfers(count: Int = 3) {
        freeTransfersRemaining = count
    }
}
