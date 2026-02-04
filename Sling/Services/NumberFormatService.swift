import Foundation

/// Centralized number formatting service for consistent number display across the app.
/// All monetary and numeric values should use this service for formatting.
class NumberFormatService {
    static let shared = NumberFormatService()
    
    private init() {}
    
    // MARK: - Shared Formatters (cached for performance)
    
    /// Formatter for currency with 2 decimal places and comma grouping
    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        return formatter
    }()
    
    /// Formatter for whole numbers with comma grouping
    private lazy var wholeNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        return formatter
    }()
    
    /// Formatter for numbers with variable decimals and comma grouping
    private lazy var flexibleFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        return formatter
    }()
    
    // MARK: - Currency Formatting
    
    /// Formats a number as currency with symbol, 2 decimal places, and comma grouping.
    /// Example: formatCurrency(24477.78, symbol: "£") -> "£24,477.78"
    func formatCurrency(_ amount: Double, symbol: String) -> String {
        let formatted = currencyFormatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "\(symbol)\(formatted)"
    }
    
    /// Formats a number as USD currency.
    /// Example: formatUSD(24477.78) -> "$24,477.78"
    func formatUSD(_ amount: Double) -> String {
        formatCurrency(amount, symbol: "$")
    }
    
    /// Formats a number as GBP currency.
    /// Example: formatGBP(24477.78) -> "£24,477.78"
    func formatGBP(_ amount: Double) -> String {
        formatCurrency(amount, symbol: "£")
    }
    
    /// Formats a number as EUR currency.
    /// Example: formatEUR(24477.78) -> "€24,477.78"
    func formatEUR(_ amount: Double) -> String {
        formatCurrency(amount, symbol: "€")
    }
    
    // MARK: - Number Formatting
    
    /// Formats a number with comma grouping and specified decimal places.
    /// Example: formatNumber(24477.78, decimals: 2) -> "24,477.78"
    func formatNumber(_ value: Double, decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value)
    }
    
    /// Formats a whole number with comma grouping.
    /// Example: formatWholeNumber(24477) -> "24,477"
    func formatWholeNumber(_ value: Double) -> String {
        wholeNumberFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }
    
    /// Formats a whole number (Int) with comma grouping.
    /// Example: formatWholeNumber(24477) -> "24,477"
    func formatWholeNumber(_ value: Int) -> String {
        wholeNumberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    /// Formats a number with comma grouping, showing decimals only if needed.
    /// Example: formatFlexible(24477.00) -> "24,477", formatFlexible(24477.50) -> "24,477.5"
    func formatFlexible(_ value: Double) -> String {
        flexibleFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

// MARK: - Convenience Extensions

extension Double {
    /// Formats as currency with the given symbol.
    /// Example: 24477.78.asCurrency("£") -> "£24,477.78"
    func asCurrency(_ symbol: String) -> String {
        NumberFormatService.shared.formatCurrency(self, symbol: symbol)
    }
    
    /// Formats as USD currency.
    /// Example: 24477.78.asUSD -> "$24,477.78"
    var asUSD: String {
        NumberFormatService.shared.formatUSD(self)
    }
    
    /// Formats as GBP currency.
    /// Example: 24477.78.asGBP -> "£24,477.78"
    var asGBP: String {
        NumberFormatService.shared.formatGBP(self)
    }
    
    /// Formats as EUR currency.
    /// Example: 24477.78.asEUR -> "€24,477.78"
    var asEUR: String {
        NumberFormatService.shared.formatEUR(self)
    }
    
    /// Formats with comma grouping (2 decimal places).
    /// Example: 24477.78.formatted -> "24,477.78"
    var formattedWithCommas: String {
        NumberFormatService.shared.formatNumber(self)
    }
    
    /// Formats as whole number with comma grouping.
    /// Example: 24477.0.formattedWhole -> "24,477"
    var formattedWhole: String {
        NumberFormatService.shared.formatWholeNumber(self)
    }
}

extension Int {
    /// Formats with comma grouping.
    /// Example: 24477.formattedWithCommas -> "24,477"
    var formattedWithCommas: String {
        NumberFormatService.shared.formatWholeNumber(self)
    }
}
