import SwiftUI
import UIKit
import Combine

struct SavingsDepositSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var savingsService = SavingsService.shared
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @ObservedObject private var themeService = ThemeService.shared
    
    @State private var amountString = ""
    @State private var showConfirmation = false
    @State private var showingDisplayCurrencyOnTop = true // true = display currency primary, false = USD primary
    @State private var displayCurrencyAmount: Double = 0
    @State private var usdAmount: Double = 0
    @State private var exchangeRate: Double = 1.0
    
    private let exchangeService = ExchangeRateService.shared
    
    private var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    /// User's display currency (e.g., GBP)
    private var displayCurrency: String {
        displayCurrencyService.displayCurrency
    }
    
    /// Symbol for display currency
    private var displayCurrencySymbol: String {
        ExchangeRateService.symbol(for: displayCurrency)
    }
    
    /// Whether the display currency differs from USD
    private var hasCurrencyDifference: Bool {
        displayCurrency != "USD"
    }
    
    // USDY amount (what user will receive) - based on USD amount at $1.00 base price
    private var usdyAmount: Double {
        guard usdAmount > 0 else { return 0 }
        return usdAmount / savingsService.baseUsdyPrice
    }
    
    private var availableBalance: Double {
        portfolioService.cashBalance
    }
    
    private var isOverBalance: Bool {
        usdAmount > availableBalance && usdAmount > 0
    }
    
    private var canDeposit: Bool {
        usdAmount > 0 && usdAmount <= availableBalance
    }
    
    /// Available balance formatted in display currency
    private var formattedAvailableBalance: String {
        if displayCurrency == "USD" {
            return availableBalance.asUSD
        }
        // exchangeRate is displayCurrency to USD, so divide to convert USD to displayCurrency
        let convertedBalance = exchangeRate > 0 ? availableBalance / exchangeRate : availableBalance
        return convertedBalance.asCurrency(displayCurrencySymbol)
    }
    
    // Formatted display currency amount (e.g., £100)
    private var formattedDisplayCurrency: String {
        if amountString.isEmpty {
            return "\(displayCurrencySymbol)0"
        }
        
        // Show exactly what the user typed, with currency symbol
        // This preserves decimal behavior - only shows decimals after user presses "."
        return "\(displayCurrencySymbol)\(amountString)"
    }
    
    // Formatted USD amount
    private var formattedUSD: String {
        let value = showingDisplayCurrencyOnTop ? usdAmount : amountValue
        if amountString.isEmpty || value == 0 {
            return "$0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2  // Always show 2 decimals for USD
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? NumberFormatService.shared.formatNumber(value)
        return "$\(formattedNumber)"
    }
    
    // Formatted USDY amount (what user will receive)
    private var formattedUSDY: String {
        if amountString.isEmpty || usdyAmount == 0 {
            return "0 USDY"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: usdyAmount)) ?? NumberFormatService.shared.formatNumber(usdyAmount)
        return "\(formattedNumber) USDY"
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
                    
                    // Savings icon with deposit badge
                    ZStack(alignment: .bottomTrailing) {
                        // Black square background with savings icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "000000"))
                                .frame(width: 44, height: 44)
                            
                            Image("NavSavings")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                        }
                        
                        // Green badge with plus icon
                        ZStack {
                            Circle()
                                .fill(Color(hex: "78D381"))
                                .frame(width: 14, height: 14)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(themeService.currentTheme == .dark ? themeService.cardBackgroundColor : Color.white, lineWidth: 2)
                        )
                        .offset(x: 4, y: 4)
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Deposit to")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text("Savings")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                    
                    // USDY indicator - styled like currency badge
                    Text("USDY")
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "F7F7F7"))
                        )
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                Spacer()
                
                // Amount display - show display currency as primary, USDY as secondary
                VStack(spacing: 8) {
                    Text(formattedDisplayCurrency)
                        .font(.custom("Inter-Bold", size: 56))
                        .foregroundColor(themeService.textPrimaryColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    if isOverBalance {
                        Text("Insufficient balance")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(Color(hex: "E30000"))
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else {
                        Text(formattedUSDY)
                            .font(.custom("Inter-Medium", size: 18))
                            .foregroundColor(Color(hex: "7B7B7B"))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isOverBalance)
                
                Spacer()
                
                // Payment source row (From) with Max button
                PaymentInstrumentRow(
                    iconName: "SlingBalanceLogo",
                    title: "Sling balance",
                    subtitleParts: [formattedAvailableBalance],
                    actionButtonTitle: "Max",
                    onActionTap: {
                        // Set to max available balance in display currency
                        let maxInDisplayCurrency = exchangeRate > 0 ? availableBalance / exchangeRate : availableBalance
                        amountString = formatForInput(maxInDisplayCurrency)
                        updateAmounts()
                    },
                    showMenu: true
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Number pad
                NumberPadView(amountString: $amountString)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Next button
                SecondaryButton(
                    title: "Next",
                    isEnabled: canDeposit
                ) {
                    showConfirmation = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            // Confirmation overlay
            if showConfirmation {
                SavingsDepositConfirmView(
                    isPresented: $showConfirmation,
                    amount: usdAmount,
                    displayAmount: amountValue,  // Fiat amount user typed
                    usdyToReceive: usdyAmount,
                    onComplete: {
                        isPresented = false
                    }
                )
                .transition(.fluidConfirm)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showConfirmation)
        .onChange(of: amountString) { _, _ in
            updateAmounts()
        }
        .onAppear {
            updateAmounts()
        }
    }
    
    private func updateAmounts() {
        let inputAmount = amountValue
        
        guard hasCurrencyDifference else {
            // No conversion needed - USD to USD
            displayCurrencyAmount = inputAmount
            usdAmount = inputAmount
            exchangeRate = 1.0
            return
        }
        
        if showingDisplayCurrencyOnTop {
            // User is entering display currency (e.g., GBP), convert to USD
            displayCurrencyAmount = inputAmount
            Task {
                if let rate = await exchangeService.getRate(from: displayCurrency, to: "USD") {
                    await MainActor.run {
                        exchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: displayCurrency,
                    to: "USD"
                ) {
                    await MainActor.run {
                        usdAmount = converted
                    }
                }
            }
        } else {
            // User is entering USD, convert to display currency
            usdAmount = inputAmount
            Task {
                if let rate = await exchangeService.getRate(from: displayCurrency, to: "USD") {
                    await MainActor.run {
                        exchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: "USD",
                    to: displayCurrency
                ) {
                    await MainActor.run {
                        displayCurrencyAmount = converted
                    }
                }
            }
        }
    }
    
    private func formatForInput(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Deposit Confirm View

struct SavingsDepositConfirmView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var savingsService = SavingsService.shared
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    
    let amount: Double // USD amount for storage
    let displayAmount: Double // Fiat amount user inputted
    let usdyToReceive: Double
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    @State private var quoteTimeRemaining: Int = 30
    
    // Timer for quote countdown
    let quoteTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    /// Formatted display currency amount (what user typed)
    private var formattedDisplayAmount: String {
        let symbol = ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
        return displayAmount.asCurrency(symbol)
    }
    
    /// Price formatted as "1 [display currency] = X USDY"
    private var formattedPrice: String {
        let displayCurrency = displayCurrencyService.displayCurrency
        let symbol = ExchangeRateService.symbol(for: displayCurrency)
        let usdyPriceInUSD = savingsService.liveUsdyPrice
        
        // Get exchange rate from display currency to USD
        var exchangeRate: Double = 1.0
        if displayCurrency != "USD" {
            if let rate = ExchangeRateService.shared.getCachedRate(from: displayCurrency, to: "USD") {
                exchangeRate = rate
            } else {
                // Fallback rates
                let fallbackRates: [String: Double] = ["EUR": 1.09, "GBP": 1.27]
                exchangeRate = fallbackRates[displayCurrency] ?? 1.0
            }
        }
        
        // Calculate: 1 display currency = how many USDY?
        // 1 display currency = exchangeRate USD
        // 1 USDY = usdyPriceInUSD USD
        // So 1 display currency = exchangeRate / usdyPriceInUSD USDY
        let usdyPerDisplayCurrency = exchangeRate / usdyPriceInUSD
        
        return "1\(symbol) = \(savingsService.formatTokens(usdyPerDisplayCurrency)) USDY"
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - styled like BuyConfirmView
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
                    
                    // Savings icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "000000"))
                            .frame(width: 44, height: 44)
                        
                        Image("NavSavings")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Add to")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text("Savings")
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
                
                // Amount display (fiat amount user inputted)
                Text(formattedDisplayAmount)
                    .font(.custom("Inter-Bold", size: 62))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                // Details section - styled like BuyConfirmView
                VStack(spacing: 4) {
                    // From
                    DetailRow(
                        label: "From",
                        value: "Sling balance",
                        showSlingIcon: true
                    )
                    
                    // Quote validity countdown
                    QuoteValidityRow(secondsRemaining: quoteTimeRemaining)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    // Amount (fiat amount user inputted)
                    DetailRow(label: "Amount", value: formattedDisplayAmount)
                    
                    // Price (how many USDY per display currency unit)
                    DetailRow(
                        label: "Price",
                        value: formattedPrice,
                        isHighlighted: true
                    )
                    
                    // You receive (estimated tokens)
                    DetailRow(
                        label: "You receive",
                        value: "~\(savingsService.formatTokens(usdyToReceive)) USDY"
                    )
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
                .padding(.horizontal, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Confirm button - styled like BuyConfirmView
                LoadingButton(
                    title: "Confirm",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    // Deduct from Sling balance
                    portfolioService.addCash(-amount)
                    
                    // Add to savings
                    savingsService.deposit(usdcAmount: amount)
                    
                    // Record activity
                    ActivityService.shared.addActivity(
                        avatar: "IconSavings",
                        titleLeft: "Savings",
                        subtitleLeft: "Deposit",
                        titleRight: "+\(savingsService.formatTokens(usdyToReceive)) USDY",
                        subtitleRight: formattedDisplayAmount
                    )
                    
                    // Complete and dismiss
                    onComplete()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
        .onAppear {
            // Fetch fresh live USDY price
            savingsService.fetchLiveUsdyPrice()
        }
        .onReceive(quoteTimer) { _ in
            // Don't count down if loading
            guard !isButtonLoading else { return }
            
            if quoteTimeRemaining > 0 {
                quoteTimeRemaining -= 1
            } else {
                // Refresh price and reset timer
                savingsService.fetchLiveUsdyPrice()
                quoteTimeRemaining = 30
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
}

#Preview {
    SavingsDepositSheet(isPresented: .constant(true))
}
