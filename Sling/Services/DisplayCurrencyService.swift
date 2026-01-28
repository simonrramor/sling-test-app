import SwiftUI
import Combine

/// Represents a currency with its display information
struct DisplayCurrencyInfo: Identifiable, Equatable {
    let id: String // Currency code (e.g., "USD")
    let name: String // Full name (e.g., "US Dollar")
    let flagAsset: String // Asset name for flag image (e.g., "FlagUS")
    
    var code: String { id }
    var symbol: String { ExchangeRateService.symbol(for: id) }
}

/// Service for managing the user's display currency preference
/// The underlying wallet currency is always USD, but users can choose to display balances in their preferred currency
class DisplayCurrencyService: ObservableObject {
    static let shared = DisplayCurrencyService()
    
    /// The user's preferred display currency
    @Published var displayCurrency: String = "GBP" {
        didSet {
            UserDefaults.standard.set(displayCurrency, forKey: "displayCurrency")
        }
    }
    
    /// Quick-access currencies shown in the tab bar (USD and current display currency)
    var quickAccessCurrencies: [DisplayCurrencyInfo] {
        var currencies = [allCurrencies.first { $0.code == "USD" }!]
        if displayCurrency != "USD", let current = allCurrencies.first(where: { $0.code == displayCurrency }) {
            currencies.append(current)
        }
        return currencies
    }
    
    /// All available currencies for display
    let allCurrencies: [DisplayCurrencyInfo] = [
        DisplayCurrencyInfo(id: "USD", name: "US Dollar", flagAsset: "FlagUS"),
        DisplayCurrencyInfo(id: "GBP", name: "British Pound", flagAsset: "FlagGB"),
        DisplayCurrencyInfo(id: "EUR", name: "Euro", flagAsset: "FlagEUR"),
        DisplayCurrencyInfo(id: "AUD", name: "Australian Dollar", flagAsset: "FlagAU"),
        DisplayCurrencyInfo(id: "BRL", name: "Brazilian Real", flagAsset: "FlagBR"),
        DisplayCurrencyInfo(id: "CAD", name: "Canadian Dollar", flagAsset: "FlagCA"),
        DisplayCurrencyInfo(id: "CHF", name: "Swiss Franc", flagAsset: "FlagCH"),
        DisplayCurrencyInfo(id: "CNY", name: "Chinese Yuan", flagAsset: "FlagCN"),
        DisplayCurrencyInfo(id: "HKD", name: "Hong Kong Dollar", flagAsset: "FlagHK"),
        DisplayCurrencyInfo(id: "INR", name: "Indian Rupee", flagAsset: "FlagIN"),
        DisplayCurrencyInfo(id: "JPY", name: "Japanese Yen", flagAsset: "FlagJP"),
        DisplayCurrencyInfo(id: "KES", name: "Kenyan Shilling", flagAsset: "FlagKE"),
        DisplayCurrencyInfo(id: "MXN", name: "Mexican Peso", flagAsset: "FlagMX"),
        DisplayCurrencyInfo(id: "NGN", name: "Nigerian Naira", flagAsset: "FlagNG"),
        DisplayCurrencyInfo(id: "NZD", name: "New Zealand Dollar", flagAsset: "FlagNZ"),
        DisplayCurrencyInfo(id: "SGD", name: "Singapore Dollar", flagAsset: "FlagSG"),
        DisplayCurrencyInfo(id: "ZAR", name: "South African Rand", flagAsset: "FlagZA")
    ]
    
    /// Available currencies for display (legacy - currency codes only)
    var availableCurrencies: [String] {
        allCurrencies.map { $0.code }
    }
    
    private init() {
        self.displayCurrency = UserDefaults.standard.string(forKey: "displayCurrency") ?? "GBP"
    }
    
    /// Symbol for the current display currency
    var currencySymbol: String {
        ExchangeRateService.symbol(for: displayCurrency)
    }
    
    /// Whether the display currency differs from USD (the underlying currency)
    var hasCurrencyDifference: Bool {
        displayCurrency != "USD"
    }
    
    /// Get currency info by code
    func currencyInfo(for code: String) -> DisplayCurrencyInfo? {
        allCurrencies.first { $0.code == code }
    }
    
    /// Current display currency info
    var currentCurrencyInfo: DisplayCurrencyInfo? {
        currencyInfo(for: displayCurrency)
    }
}
