import SwiftUI
import UIKit

struct AddMoneyConfirmView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var feeService = FeeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @AppStorage("hasAddedMoney") private var hasAddedMoney = false
    let sourceAccount: PaymentAccount // The selected payment account
    let sourceAmount: Double // Amount in source currency (e.g., GBP)
    let sourceCurrency: String // Source currency code (e.g., "GBP")
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
    
    /// Amount received after fee deduction
    private var amountAfterFee: Double {
        if depositFee.isFree {
            return destinationAmount
        }
        return max(0, destinationAmount - depositFee.amount)
    }
    
    // Extract avatar asset name from account icon type
    private var sourceAccountAvatar: String {
        switch sourceAccount.iconType {
        case .asset(let assetName):
            return assetName
        }
    }
    
    var hasCurrencyDifference: Bool {
        sourceCurrency != slingCurrency
    }
    
    var formattedSourceAmount: String {
        let symbol = ExchangeRateService.symbol(for: sourceCurrency)
        return sourceAmount.asCurrency(symbol)
    }
    
    var formattedDestinationAmount: String {
        return destinationAmount.asUSD
    }
    
    var formattedAmountAfterFee: String {
        return amountAfterFee.asUSD
    }
    
    /// Amount after fee in display currency
    var formattedAmountAfterFeeInDisplayCurrency: String {
        let displayCurrency = displayCurrencyService.displayCurrency
        if displayCurrency == "USD" {
            return amountAfterFee.asUSD
        }
        // Convert from USD to display currency
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: displayCurrency) {
            let displayAmount = amountAfterFee * rate
            let symbol = ExchangeRateService.symbol(for: displayCurrency)
            return displayAmount.asCurrency(symbol)
        }
        // Fallback to USD if no rate available
        return amountAfterFee.asUSD
    }
    
    /// Amount exchanged after fee deduction (in source currency)
    private var amountExchangedAfterFee: Double {
        if depositFee.isFree {
            return sourceAmount
        }
        // Convert the $0.50 fee to source currency and subtract
        let feeInSourceCurrency = 0.50 / exchangeRate // Convert USD fee to source currency
        return max(0, sourceAmount - feeInSourceCurrency)
    }
    
    var formattedAmountExchanged: String {
        let symbol = ExchangeRateService.symbol(for: sourceCurrency)
        return amountExchangedAfterFee.asCurrency(symbol)
    }
    
    var formattedExchangeRate: String {
        let sourceSymbol = ExchangeRateService.symbol(for: sourceCurrency)
        return "\(sourceSymbol)1 = \(exchangeRate.asUSD)"
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    // Back button
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
                    
                    // Sling logo
                    Image("SlingBalanceLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    
                    // Title
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Add to")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text("Sling Balance")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Amount display - centered (shows amount you'll receive in display currency)
                Text(formattedAmountAfterFeeInDisplayCurrency)
                    .font(.custom("Inter-Bold", size: 56))
                    .foregroundColor(themeService.textPrimaryColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Spacer()
                
                // Details section
                VStack(spacing: 4) {
                    // From row
                    HStack {
                        Text("From")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            // Account icon
                            switch sourceAccount.iconType {
                            case .asset(let assetName):
                                Image(assetName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 20, height: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            
                            Text(sourceAccount.name)
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(themeService.textPrimaryColor)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    
                    // Transfer speed row
                    HStack {
                        Text("Transfer speed")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Spacer()
                        
                        Text("Instant")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    
                    // Divider
                    Rectangle()
                        .fill(Color(hex: "EDEDED"))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    
                    // Total withdrawn row (in source currency)
                    HStack {
                        Text("Total withdrawn")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Spacer()
                        
                        Text(formattedSourceAmount)
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    
                    // Fees row
                    FeeRow(fee: depositFee, paymentInstrumentCurrency: sourceCurrency, onTap: { showFeesSheet = true })
                    
                    // Amount exchanged row (only show when there's a fee)
                    if !depositFee.isFree {
                        HStack {
                            Text("Amount exchanged")
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(themeService.textSecondaryColor)
                            
                            Spacer()
                            
                            Text(formattedAmountExchanged)
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(themeService.textPrimaryColor)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 16)
                    }
                    
                    // Exchange rate row (only show if currencies differ)
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
                    
                    // You receive row (in display currency, after fees)
                    HStack {
                        Text("You receive")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: "EDEDED"))
                                .frame(width: 6, height: 6)
                            
                            Text(formattedAmountAfterFeeInDisplayCurrency)
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(themeService.textPrimaryColor)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeService.cardBackgroundColor)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Add button with smooth loading animation
                LoadingButton(
                    title: "Add \(formattedAmountAfterFeeInDisplayCurrency)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    // Add money to portfolio (in USD, after fees)
                    portfolioService.addCash(amountAfterFee)
                    
                    // Record the transaction in activity feed
                    activityService.recordAddMoney(
                        fromAccountName: sourceAccount.name,
                        fromAccountAvatar: sourceAccountAvatar,
                        amount: amountAfterFee,
                        currency: slingCurrency
                    )
                    
                    // Mark as completed for Get Started cards
                    hasAddedMoney = true
                    
                    // Navigate home and complete
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    onComplete()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
        .fullScreenCover(isPresented: $showFeesSheet) {
            FeesSettingsView(isPresented: $showFeesSheet)
        }
    }
}

#Preview {
    AddMoneyConfirmView(
        isPresented: .constant(true),
        sourceAccount: .monzoBankLimited,
        sourceAmount: 100,
        sourceCurrency: "GBP",
        destinationAmount: 126.50,
        exchangeRate: 1.265
    )
}
