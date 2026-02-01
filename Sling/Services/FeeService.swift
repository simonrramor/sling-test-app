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
    
    
    // MARK: - Initialization
    
    private init() {
        // Sync display currency with display currency service
        displayCurrency = DisplayCurrencyService.shared.displayCurrency
    }
    
    // MARK: - Fee Calculation
    
    /// Calculate fee for a transaction
    /// - Parameters:
    ///   - type: Type of transaction (deposit, withdrawal, p2p)
    ///   - paymentInstrumentCurrency: Currency of the payment instrument (bank account, card, etc.)
    /// - Returns: FeeResult with fee details
    func calculateFee(
        for type: FeeTransactionType,
        paymentInstrumentCurrency: String
    ) -> FeeResult {
        // P2P is always free
        if type == .p2pSend || type == .p2pRequest {
            return .free
        }
        
        // Get current display currency
        let currentDisplayCurrency = DisplayCurrencyService.shared.displayCurrency
        
        // Fee applies when payment instrument currency differs from display currency
        let needsFee = paymentInstrumentCurrency.uppercased() != currentDisplayCurrency.uppercased()
        
        if !needsFee {
            return .free
        }
        
        // Calculate fee in the payment instrument's currency (convert $0.50 to that currency)
        let feeInPaymentCurrency = convertFeeToPaymentCurrency(paymentInstrumentCurrency)
        
        return FeeResult(
            amount: feeInPaymentCurrency,
            stablecoin: paymentInstrumentCurrency,
            displayAmount: feeInPaymentCurrency,
            displayCurrency: paymentInstrumentCurrency,
            isWaived: false,
            waiverReason: nil
        )
    }
    
    /// Legacy method for compatibility
    func calculateFee(
        for type: FeeTransactionType,
        sourceCurrency: String,
        destinationCurrency: String
    ) -> FeeResult {
        // Use the source currency as the payment instrument currency
        return calculateFee(for: type, paymentInstrumentCurrency: sourceCurrency)
    }
    
    /// Convert the base $0.50 USD fee to the payment instrument's currency
    private func convertFeeToPaymentCurrency(_ currency: String) -> Double {
        let normalizedCurrency = currency.uppercased()
        
        // If already USD, return base fee
        if normalizedCurrency == "USD" {
            return baseFee
        }
        
        // Use cached exchange rate for synchronous conversion
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: normalizedCurrency) {
            return baseFee * rate
        }
        
        // Fallback: use approximate rates if cache not available
        let fallbackRates: [String: Double] = [
            "GBP": 0.79,
            "EUR": 0.92,
            "JPY": 149.0,
            "CHF": 0.88,
            "CAD": 1.36,
            "AUD": 1.53
        ]
        
        if let rate = fallbackRates[normalizedCurrency] {
            return baseFee * rate
        }
        
        return baseFee
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
}
