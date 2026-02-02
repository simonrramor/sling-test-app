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

/// Service for managing the user's currency preferences
/// - Storage currency: The currency the balance is stored/denominated in
/// - Display currency: The currency used to display balances to the user
class DisplayCurrencyService: ObservableObject {
    static let shared = DisplayCurrencyService()
    
    /// The user's storage/base currency (what the balance is stored in)
    @Published var storageCurrency: String = "USD" {
        didSet {
            UserDefaults.standard.set(storageCurrency, forKey: "storageCurrency")
        }
    }
    
    /// The user's preferred display currency
    @Published var displayCurrency: String = "GBP" {
        didSet {
            UserDefaults.standard.set(displayCurrency, forKey: "displayCurrency")
        }
    }
    
    /// Quick-access currencies shown in the tab bar (storage currency and current display currency)
    var quickAccessCurrencies: [DisplayCurrencyInfo] {
        var currencies: [DisplayCurrencyInfo] = []
        if let storage = allCurrencies.first(where: { $0.code == storageCurrency }) {
            currencies.append(storage)
        }
        if displayCurrency != storageCurrency, let current = allCurrencies.first(where: { $0.code == displayCurrency }) {
            currencies.append(current)
        }
        return currencies
    }
    
    /// Symbol for the storage currency
    var storageCurrencySymbol: String {
        ExchangeRateService.symbol(for: storageCurrency)
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
        self.storageCurrency = UserDefaults.standard.string(forKey: "storageCurrency") ?? "USD"
        self.displayCurrency = UserDefaults.standard.string(forKey: "displayCurrency") ?? "GBP"
    }
    
    /// Symbol for the current display currency
    var currencySymbol: String {
        ExchangeRateService.symbol(for: displayCurrency)
    }
    
    /// Whether the display currency differs from the storage currency
    var hasCurrencyDifference: Bool {
        displayCurrency != storageCurrency
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
