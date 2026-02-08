import SwiftUI
import UIKit

struct AddMoneyConfirmView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var feeService = FeeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @AppStorage("hasAddedMoney") private var hasAddedMoney = false
    let sourceAccount: PaymentAccount // The selected payment account (bank)
    let sourceAmount: Double // Amount in display currency (what user typed, e.g., EUR)
    let sourceCurrency: String // Bank account currency code (e.g., "GBP")
    let linkedAccountAmount: Double // Amount in linked account currency (what will be taken from bank)
    let destinationAmount: Double // Amount in USD (Sling balance currency)
    let exchangeRate: Double // Rate from source to USD
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    @State private var showFeesSheet = false
    
    private let portfolioService = PortfolioService.shared
    private let activityService = ActivityService.shared
    private let slingCurrency = "USD" // Sling balance is always in USD
    
    /// Calculate fee for this deposit
    /// Fee applies when payment instrument currency differs from display currency
    private var depositFee: FeeResult {
        feeService.calculateFee(
            for: .deposit,
            paymentInstrumentCurrency: sourceCurrency
        )
    }
    
    /// Amount received = what the user asked for (fee is added to withdrawal, not deducted from received)
    private var amountAfterFee: Double {
        return destinationAmount
    }
    
    // Extract avatar asset name from account icon type
    private var sourceAccountAvatar: String {
        switch sourceAccount.iconType {
        case .asset(let assetName):
            return assetName
        }
    }
    
    var hasCurrencyDifference: Bool {
        sourceCurrency != displayCurrencyService.displayCurrency
    }
    
    var formattedSourceAmount: String {
        let symbol = ExchangeRateService.symbol(for: sourceCurrency)
        return sourceAmount.asCurrency(symbol)
    }
    
    /// Original input amount formatted in display currency (what user typed)
    var formattedInputAmount: String {
        let displayCurrency = displayCurrencyService.displayCurrency
        let symbol = ExchangeRateService.symbol(for: displayCurrency)
        return sourceAmount.asCurrency(symbol)
    }
    
    var formattedDestinationAmount: String {
        return destinationAmount.asUSD
    }
    
    var formattedAmountAfterFee: String {
        return amountAfterFee.asUSD
    }
    
    /// You receive = exactly what the user asked for (the sourceAmount in display currency)
    private var youReceiveAmount: Double {
        return sourceAmount
    }
    
    /// Amount after fee formatted in display currency
    var formattedAmountAfterFeeInDisplayCurrency: String {
        let displayCurrency = displayCurrencyService.displayCurrency
        let symbol = ExchangeRateService.symbol(for: displayCurrency)
        return youReceiveAmount.asCurrency(symbol)
    }
    
    /// Amount to store in USD (converts youReceiveAmount from display currency to USD)
    private var amountToStoreInUSD: Double {
        let displayCurrency = displayCurrencyService.displayCurrency
        
        // If display currency is already USD, just return the amount
        if displayCurrency == "USD" {
            return youReceiveAmount
        }
        
        // Convert from display currency to USD
        if let rate = ExchangeRateService.shared.getCachedRate(from: displayCurrency, to: "USD") {
            return youReceiveAmount * rate
        }
        
        // Fallback rates to USD
        let fallbackRatesToUSD: [String: Double] = [
            "EUR": 1.09,
            "GBP": 1.27
        ]
        
        if let rate = fallbackRatesToUSD[displayCurrency] {
            return youReceiveAmount * rate
        }
        
        // Last resort: return the amount as-is
        return youReceiveAmount
    }
    
    /// Fee converted to linked account (bank) currency
    private var feeInLinkedCurrency: Double {
        if depositFee.isFree { return 0 }
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: sourceCurrency) {
            return 0.50 * rate
        }
        let fallback: [String: Double] = ["GBP": 0.79, "EUR": 0.92]
        return 0.50 * (fallback[sourceCurrency] ?? 1.0)
    }
    
    /// Total withdrawn from bank = amount needed + fee (user pays more so they receive exactly what they asked for)
    private var totalWithdrawn: Double {
        linkedAccountAmount + feeInLinkedCurrency
    }
    
    /// Formatted total withdrawn (what will be taken from bank including fee)
    var formattedLinkedAccountAmount: String {
        let symbol = ExchangeRateService.symbol(for: sourceCurrency)
        return totalWithdrawn.asCurrency(symbol)
    }
    
    /// Amount actually exchanged (= linkedAccountAmount, before fee is added)
    private var amountExchangedAfterFee: Double {
        return linkedAccountAmount
    }
    
    var formattedAmountExchanged: String {
        let symbol = ExchangeRateService.symbol(for: sourceCurrency)
        return amountExchangedAfterFee.asCurrency(symbol)
    }
    
    /// Formatted fee in linked account currency
    var formattedFeeInLinkedCurrency: String {
        let symbol = ExchangeRateService.symbol(for: sourceCurrency)
        return feeInLinkedCurrency.asCurrency(symbol)
    }
    
    /// Exchange rate: source (bank) currency on left, destination (display) currency on right
    /// Money flows FROM bank TO Sling balance, so bank currency is the starting currency
    var formattedExchangeRate: String {
        let displayCurrency = displayCurrencyService.displayCurrency
        let displaySymbol = ExchangeRateService.symbol(for: displayCurrency)
        let bankSymbol = ExchangeRateService.symbol(for: sourceCurrency)
        
        if displayCurrency == sourceCurrency {
            return "\(bankSymbol)1 = \(displaySymbol)1"
        }
        
        // Rate: 1 bank currency = X display currency
        if let rate = ExchangeRateService.shared.getCachedRate(from: sourceCurrency, to: displayCurrency) {
            return "\(bankSymbol)1 = \(displaySymbol)\(String(format: "%.2f", rate))"
        }
        
        let fallbackRates: [String: [String: Double]] = [
            "GBP": ["EUR": 1.16, "USD": 1.27],
            "EUR": ["GBP": 0.86, "USD": 1.09],
            "USD": ["GBP": 0.79, "EUR": 0.92]
        ]
        
        if let rate = fallbackRates[sourceCurrency]?[displayCurrency] {
            return "\(bankSymbol)1 = \(displaySymbol)\(String(format: "%.2f", rate))"
        }
        
        return "\(bankSymbol)1 = \(displaySymbol)\(String(format: "%.2f", 1.0 / exchangeRate))"
    }
    
    /// Attributed title with green amount
    private var addMoneyTitle: AttributedString {
        var result = AttributedString("Add ")
        result.foregroundColor = UIColor(Color(hex: "080808"))
        var amount = AttributedString(shortInputAmount)
        amount.foregroundColor = UIColor(Color(hex: "57CE43"))
        var suffix = AttributedString(" from \(sourceAccount.name)")
        suffix.foregroundColor = UIColor(Color(hex: "080808"))
        return result + amount + suffix
    }
    
    /// Short formatted amount for title (no decimals for whole numbers)
    private var shortInputAmount: String {
        if sourceAmount.truncatingRemainder(dividingBy: 1) == 0 {
            let symbol = ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
            return "\(symbol)\(Int(sourceAmount))"
        }
        return formattedInputAmount
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - back arrow only
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image("ArrowLeft")
                            .renderingMode(.template)
                            .foregroundColor(themeService.textSecondaryColor)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Go back")
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 48)
                .opacity(isButtonLoading ? 0 : 1)
                
                Spacer()
                
                // Main content - icon and title
                VStack(alignment: .leading, spacing: 24) {
                    // Source account icon
                    switch sourceAccount.iconType {
                    case .asset(let assetName):
                        Image(assetName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                    }
                    
                    // Title: "Add €100 from Monzo bank Limited"
                    Text(addMoneyTitle)
                        .font(.custom("Inter-Bold", size: 32))
                        .tracking(-0.64)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.bottom, isButtonLoading ? 0 : 16)
                
                Spacer()
                    .frame(maxHeight: isButtonLoading ? .infinity : 0)
                
                // Details section - fades out when loading
                if !isButtonLoading {
                    VStack(spacing: 4) {
                        // Transfer speed
                        InfoListItem(label: "Transfer speed", detail: "Instant")
                        
                        // Divider
                        Rectangle()
                            .fill(Color.black.opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        // Total withdrawn (bank currency, includes fee)
                        InfoListItem(label: "Total withdrawn", detail: formattedLinkedAccountAmount)
                        
                        // Fees (red, in bank currency)
                        if !depositFee.isFree {
                            HStack {
                                Text("Fees")
                                    .font(.custom("Inter-Regular", size: 16))
                                    .foregroundColor(themeService.textSecondaryColor)
                                
                                Spacer()
                                
                                Text("-\(formattedFeeInLinkedCurrency)")
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(Color(hex: "E30000"))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 16)
                        } else {
                            InfoListItem(label: "Fees", detail: "No fee")
                        }
                        
                        // Amount exchanged (after fee deducted)
                        if !depositFee.isFree {
                            InfoListItem(label: "Amount exchanged", detail: formattedAmountExchanged)
                        }
                        
                        // Exchange rate (only when currencies differ)
                        if hasCurrencyDifference {
                            HStack {
                                Text("Exchange rate")
                                    .font(.custom("Inter-Regular", size: 16))
                                    .foregroundColor(themeService.textSecondaryColor)
                                
                                Spacer()
                                
                                Text(formattedExchangeRate)
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(Color(hex: "FF5113"))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 16)
                        }
                        
                        // You receive
                        InfoListItem(label: "You receive", detail: formattedAmountAfterFeeInDisplayCurrency)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }
                
                Spacer()
                    .frame(height: 16)
                
                // Orange CTA button
                LoadingButton(
                    title: "Add \(formattedAmountAfterFeeInDisplayCurrency)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    portfolioService.addCash(amountToStoreInUSD)
                    activityService.recordAddMoney(
                        fromAccountName: sourceAccount.name,
                        fromAccountAvatar: sourceAccountAvatar,
                        amount: amountAfterFee,
                        currency: slingCurrency
                    )
                    hasAddedMoney = true
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    onComplete()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isButtonLoading)
        .fullScreenCover(isPresented: $showFeesSheet) {
            FeesSettingsView(isPresented: $showFeesSheet)
        }
    }
}

#Preview {
    AddMoneyConfirmView(
        isPresented: .constant(true),
        sourceAccount: .ukBank,
        sourceAmount: 100,  // Display currency amount
        sourceCurrency: "GBP",
        linkedAccountAmount: 86.23,  // Linked account amount
        destinationAmount: 126.50,
        exchangeRate: 1.265
    )
}
