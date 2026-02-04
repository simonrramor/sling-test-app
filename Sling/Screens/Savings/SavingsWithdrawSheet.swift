import SwiftUI
import UIKit

struct SavingsWithdrawSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var savingsService = SavingsService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    
    @State private var amountString = ""
    @State private var showConfirmation = false
    @State private var showingDisplayCurrencyOnTop = true // true = display currency primary, false = USDY primary
    @State private var displayCurrencyAmount: Double = 0
    @State private var exchangeRate: Double = 1.0
    
    private let exchangeService = ExchangeRateService.shared
    
    private var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    /// User's display currency (e.g., EUR)
    private var displayCurrency: String {
        displayCurrencyService.displayCurrency
    }
    
    /// Symbol for display currency
    private var displayCurrencySymbol: String {
        ExchangeRateService.symbol(for: displayCurrency)
    }
    
    // USD amount based on input
    private var usdAmount: Double {
        if showingDisplayCurrencyOnTop {
            // User entered display currency, convert to USD
            if displayCurrency == "USD" {
                return amountValue
            }
            return exchangeRate > 0 ? amountValue * exchangeRate : amountValue
        } else {
            // User entered USDY, convert to USD
            return amountValue * savingsService.currentUsdyPrice
        }
    }
    
    // USDY amount (what user is withdrawing)
    private var usdyAmount: Double {
        // Convert USD to USDY
        return usdAmount / savingsService.currentUsdyPrice
    }
    
    private var availableUSDY: Double {
        savingsService.usdyBalance
    }
    
    private var availableUSD: Double {
        savingsService.totalValueUSD
    }
    
    /// Available balance formatted in display currency
    private var formattedAvailableBalance: String {
        if displayCurrency == "USD" {
            return availableUSD.asUSD
        }
        let convertedBalance = exchangeRate > 0 ? availableUSD / exchangeRate : availableUSD
        return convertedBalance.asCurrency(displayCurrencySymbol)
    }
    
    private var isOverBalance: Bool {
        usdyAmount > availableUSDY && usdyAmount > 0
    }
    
    private var canWithdraw: Bool {
        usdyAmount > 0 && usdyAmount <= availableUSDY
    }
    
    // Formatted display currency amount (primary)
    private var formattedDisplayCurrency: String {
        if amountString.isEmpty {
            return "\(displayCurrencySymbol)0"
        }
        
        // Show exactly what the user typed, with currency symbol
        // This preserves decimal behavior - only shows decimals after user presses "."
        return "\(displayCurrencySymbol)\(amountString)"
    }
    
    // Formatted USDY amount (secondary)
    private var formattedUSDY: String {
        let value = showingDisplayCurrencyOnTop ? usdyAmount : amountValue
        if amountString.isEmpty || value == 0 {
            return "0 USDY"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? NumberFormatService.shared.formatNumber(value)
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
                    
                    // Sling balance icon (destination - where money goes TO)
                    Image("SlingBalanceLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // Title - destination (To)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Withdraw to")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text("Sling balance")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                Spacer()
                
                // Amount display with currency swap (display currency primary, USDY secondary)
                AnimatedCurrencySwapView(
                    primaryDisplay: formattedDisplayCurrency,
                    secondaryDisplay: formattedUSDY,
                    showingPrimaryOnTop: showingDisplayCurrencyOnTop,
                    onSwap: {
                        // Convert current amount to the other currency before swapping
                        if showingDisplayCurrencyOnTop {
                            // Switching to USDY input
                            let newAmount = usdyAmount
                            amountString = newAmount > 0 ? formatForInput(newAmount) : ""
                        } else {
                            // Switching to display currency input
                            let newAmount = displayCurrencyAmount
                            amountString = newAmount > 0 ? formatForInput(newAmount) : ""
                        }
                        showingDisplayCurrencyOnTop.toggle()
                    },
                    errorMessage: isOverBalance ? "Insufficient balance" : nil
                )
                
                Spacer()
                
                // Payment source row (Savings - where money comes FROM)
                HStack(spacing: 12) {
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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Savings")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        Text(formattedAvailableBalance)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "F7F7F7"))
                .cornerRadius(24)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Number pad
                NumberPadView(amountString: $amountString)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Next button
                SecondaryButton(
                    title: "Next",
                    isEnabled: canWithdraw
                ) {
                    showConfirmation = true
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
            // Confirmation overlay
            if showConfirmation {
                SavingsWithdrawConfirmView(
                    isPresented: $showConfirmation,
                    usdyAmount: usdyAmount,
                    usdcToReceive: usdAmount,
                    onComplete: {
                        isPresented = false
                    }
                )
                .transition(.fluidConfirm)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showConfirmation)
        .onAppear {
            fetchExchangeRate()
        }
        .onChange(of: amountString) {
            updateAmounts()
        }
    }
    
    private func formatForInput(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    private func fetchExchangeRate() {
        guard displayCurrency != "USD" else {
            exchangeRate = 1.0
            return
        }
        
        Task {
            if let rate = await exchangeService.getRate(from: displayCurrency, to: "USD") {
                await MainActor.run {
                    exchangeRate = rate
                    updateAmounts()
                }
            }
        }
    }
    
    private func updateAmounts() {
        if showingDisplayCurrencyOnTop {
            // Calculate display currency amount from input
            displayCurrencyAmount = amountValue
        } else {
            // Calculate display currency amount from USDY input
            let usdValue = amountValue * savingsService.currentUsdyPrice
            if displayCurrency == "USD" {
                displayCurrencyAmount = usdValue
            } else {
                displayCurrencyAmount = exchangeRate > 0 ? usdValue / exchangeRate : usdValue
            }
        }
    }
}

// MARK: - Withdraw Confirm View

struct SavingsWithdrawConfirmView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var savingsService = SavingsService.shared
    @ObservedObject private var portfolioService = PortfolioService.shared
    
    let usdyAmount: Double
    let usdcToReceive: Double
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    
    private var formattedUSDY: String {
        "\(savingsService.formatTokens(usdyAmount)) USDY"
    }
    
    private var formattedUSDC: String {
        savingsService.formatUSD(usdcToReceive)
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
                    
                    // Savings icon with withdrawal badge
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
                        
                        // Purple badge with arrow down icon
                        ZStack {
                            Circle()
                                .fill(Color(hex: "9874FF"))
                                .frame(width: 14, height: 14)
                            
                            Image(systemName: "arrow.down")
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
                        Text("Withdraw from")
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
                Text(formattedUSDY)
                    .font(.custom("Inter-Bold", size: 48))
                    .foregroundColor(themeService.textPrimaryColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Spacer()
                
                // Details section
                VStack(spacing: 0) {
                    DetailRow(label: "From", value: "Savings")
                    DetailRow(label: "To", value: "Sling Balance")
                    
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    DetailRow(label: "Amount", value: formattedUSDY)
                    DetailRow(label: "USDY price", value: savingsService.formatPrice(savingsService.currentUsdyPrice))
                    DetailRow(label: "You receive", value: formattedUSDC)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Withdraw button
                LoadingButton(
                    title: "Withdraw \(formattedUSDC)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    // Withdraw from savings
                    savingsService.withdraw(usdyAmount: usdyAmount)
                    
                    // Add to Sling balance
                    portfolioService.addCash(usdcToReceive)
                    
                    // Record activity
                    ActivityService.shared.addActivity(
                        avatar: "IconSavings",
                        titleLeft: "Savings",
                        subtitleLeft: "Withdrawal",
                        titleRight: "-\(formattedUSDC)",
                        subtitleRight: ""
                    )
                    
                    // Navigate back to savings and complete
                    NotificationCenter.default.post(name: .navigateToSavings, object: nil)
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
    SavingsWithdrawSheet(isPresented: .constant(true))
}
