import Foundation
import Combine

// MARK: - Exchange Rate Service

class ExchangeRateService: ObservableObject {
    static let shared = ExchangeRateService()
    
    @Published var rates: [String: Double] = [:]
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    
    private let baseCurrency = "GBP" // Sling wallet base currency
    private let cacheTimeout: TimeInterval = 3600 // 1 hour cache
    private var cachedRates: [String: [String: Double]] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    
    private init() {
        // Prefetch common rates on init
        Task {
            await fetchRates(base: "GBP")
            await fetchRates(base: "USD")
            await fetchRates(base: "EUR")
        }
    }
    
    // MARK: - Public Methods
    
    /// Convert an amount from one currency to another
    func convert(amount: Double, from sourceCurrency: String, to targetCurrency: String) async -> Double? {
        // Same currency, no conversion needed
        if sourceCurrency == targetCurrency {
            return amount
        }
        
        // Try to get the rate
        guard let rate = await getRate(from: sourceCurrency, to: targetCurrency) else {
            return nil
        }
        
        return amount * rate
    }
    
    /// Get the exchange rate from one currency to another
    func getRate(from sourceCurrency: String, to targetCurrency: String) async -> Double? {
        // Check if we have cached rates for the source currency
        if let cached = cachedRates[sourceCurrency],
           let timestamp = cacheTimestamps[sourceCurrency],
           Date().timeIntervalSince(timestamp) < cacheTimeout,
           let rate = cached[targetCurrency] {
            return rate
        }
        
        // Fetch fresh rates
        await fetchRates(base: sourceCurrency)
        
        return cachedRates[sourceCurrency]?[targetCurrency]
    }
    
    /// Get cached rate synchronously (returns nil if not cached)
    func getCachedRate(from sourceCurrency: String, to targetCurrency: String) -> Double? {
        if sourceCurrency == targetCurrency {
            return 1.0
        }
        return cachedRates[sourceCurrency]?[targetCurrency]
    }
    
    // MARK: - Private Methods
    
    private func fetchRates(base: String) async {
        await MainActor.run { self.isLoading = true }
        
        // Using Frankfurter API (free, no API key required)
        // https://www.frankfurter.app/docs/
        let urlString = "https://api.frankfurter.app/latest?from=\(base)"
        
        guard let url = URL(string: urlString) else {
            await MainActor.run { self.isLoading = false }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
            
            // Store rates with the base currency as 1.0
            var allRates = response.rates
            allRates[base] = 1.0
            
            await MainActor.run {
                self.cachedRates[base] = allRates
                self.cacheTimestamps[base] = Date()
                self.lastUpdated = Date()
                self.isLoading = false
            }
        } catch {
            print("ExchangeRateService: Failed to fetch rates - \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

// MARK: - API Response Models

private struct FrankfurterResponse: Codable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
}

// MARK: - Currency Helpers

extension ExchangeRateService {
    /// Get the symbol for a currency code
    static func symbol(for currencyCode: String) -> String {
        switch currencyCode.uppercased() {
        case "GBP": return "£"
        case "USD": return "$"
        case "EUR": return "€"
        case "JPY": return "¥"
        case "CHF": return "CHF"
        case "CAD": return "CA$"
        case "AUD": return "A$"
        case "USDC": return "$" // Stablecoin pegged to USD
        default: return currencyCode
        }
    }
    
    /// Format an amount with the appropriate currency symbol
    static func format(amount: Double, currency: String) -> String {
        let symbol = self.symbol(for: currency)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        
        let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? NumberFormatService.shared.formatNumber(amount)
        return "\(symbol)\(formattedNumber)"
    }
}
