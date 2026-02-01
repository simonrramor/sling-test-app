import SwiftUI
import UIKit

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
    
    // USDY amount (what user will receive) - based on USD amount
    private var usdyAmount: Double {
        guard usdAmount > 0 else { return 0 }
        return usdAmount / savingsService.currentUsdyPrice
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
            return String(format: "$%.2f", availableBalance)
        }
        // exchangeRate is displayCurrency to USD, so divide to convert USD to displayCurrency
        let convertedBalance = exchangeRate > 0 ? availableBalance / exchangeRate : availableBalance
        return String(format: "%@%.2f", displayCurrencySymbol, convertedBalance)
    }
    
    // Formatted display currency amount (e.g., £100)
    private var formattedDisplayCurrency: String {
        let value = showingDisplayCurrencyOnTop ? amountValue : displayCurrencyAmount
        if amountString.isEmpty || value == 0 {
            return "\(displayCurrencySymbol)0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "\(displayCurrencySymbol)\(formattedNumber)"
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
        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "$\(formattedNumber)"
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
                    
                    // Savings icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "4CAF50"))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "dollarsign.arrow.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
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
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                Spacer()
                
                // Amount display with currency swap
                if hasCurrencyDifference {
                    AnimatedCurrencySwapView(
                        primaryDisplay: formattedDisplayCurrency,
                        secondaryDisplay: formattedUSD,
                        showingPrimaryOnTop: showingDisplayCurrencyOnTop,
                        onSwap: {
                            // Convert current amount to the other currency before swapping
                            if showingDisplayCurrencyOnTop {
                                // Switching to USD input
                                amountString = usdAmount > 0 ? formatForInput(usdAmount) : ""
                            } else {
                                // Switching to display currency input
                                amountString = displayCurrencyAmount > 0 ? formatForInput(displayCurrencyAmount) : ""
                            }
                            showingDisplayCurrencyOnTop.toggle()
                        },
                        errorMessage: isOverBalance ? "Insufficient balance" : nil
                    )
                } else {
                    // No currency difference - just show USD
                    VStack(spacing: 4) {
                        Text(formattedUSD)
                            .font(.custom("Inter-Bold", size: 56))
                            .foregroundColor(themeService.textPrimaryColor)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        
                        if isOverBalance {
                            Text("Insufficient balance")
                                .font(.custom("Inter-Medium", size: 14))
                                .foregroundColor(Color(hex: "E30000"))
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: isOverBalance)
                }
                
                Spacer()
                
                // Payment source row
                PaymentInstrumentRow(
                    iconName: "SlingBalanceLogo",
                    title: "Sling balance",
                    subtitleParts: [formattedAvailableBalance],
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
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
            // Confirmation overlay
            if showConfirmation {
                SavingsDepositConfirmView(
                    isPresented: $showConfirmation,
                    amount: usdAmount,
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
    
    let amount: Double
    let usdyToReceive: Double
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    
    private var formattedAmount: String {
        String(format: "$%.2f", amount)
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
                    
                    // Savings icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "4CAF50"))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "dollarsign.arrow.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
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
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Amount display
                Text(formattedAmount)
                    .font(.custom("Inter-Bold", size: 56))
                    .foregroundColor(themeService.textPrimaryColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Spacer()
                
                // Details section
                VStack(spacing: 0) {
                    DetailRow(label: "From", value: "Sling Balance")
                    DetailRow(label: "To", value: "Savings")
                    
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    DetailRow(label: "Amount", value: formattedAmount)
                    DetailRow(label: "USDY price", value: savingsService.formatPrice(savingsService.currentUsdyPrice))
                    DetailRow(label: "You receive", value: "\(savingsService.formatTokens(usdyToReceive)) USDY")
                    DetailRow(label: "Current APY", value: "3.75%", isHighlighted: true)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Deposit button
                LoadingButton(
                    title: "Deposit \(formattedAmount)",
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
                        titleRight: "+\(formattedAmount)",
                        subtitleRight: ""
                    )
                    
                    // Navigate home and complete
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    onComplete()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
    }
}

#Preview {
    SavingsDepositSheet(isPresented: .constant(true))
}
