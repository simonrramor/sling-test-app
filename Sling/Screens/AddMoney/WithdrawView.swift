import SwiftUI
import UIKit

struct WithdrawView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @State private var amountString = ""
    @State private var selectedAccount: PaymentAccount = .ukBank
    @State private var showAccountPicker = false
    @State private var showAccountSelection = true
    @State private var showConfirmation = false
    @State private var showingDestinationCurrency = true // true = destination currency primary, false = USD primary
    @State private var destinationAmount: Double = 0 // Amount in destination account currency
    @State private var usdAmount: Double = 0 // Amount in USD (storage currency)
    @State private var exchangeRate: Double = 1.0 // Rate from destination currency to USD
    
    private let exchangeService = ExchangeRateService.shared
    
    var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    /// Destination account currency (where money goes TO)
    var destinationCurrency: String {
        selectedAccount.currency.isEmpty ? "GBP" : selectedAccount.currency
    }
    
    /// Symbol for destination currency
    var destinationSymbol: String {
        ExchangeRateService.symbol(for: destinationCurrency)
    }
    
    /// Display currency (user's preferred currency - source)
    var sourceCurrency: String {
        displayCurrencyService.displayCurrency
    }
    
    /// Symbol for source/display currency
    var sourceSymbol: String {
        ExchangeRateService.symbol(for: sourceCurrency)
    }
    
    /// Whether we need to show currency conversion (source differs from destination)
    var needsCurrencyConversion: Bool {
        sourceCurrency != destinationCurrency
    }
    
    /// Whether a fee applies to this withdrawal
    private var hasWithdrawFee: Bool {
        !FeeService.shared.calculateFee(for: .withdrawal, paymentInstrumentCurrency: destinationCurrency).isFree
    }
    
    /// Fee in display currency
    private var withdrawFeeInDisplayCurrency: Double {
        if !hasWithdrawFee { return 0 }
        let feeUSD = 0.50
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: sourceCurrency) {
            return feeUSD * rate
        }
        let fallback: [String: Double] = ["EUR": 0.92, "GBP": 0.79]
        return feeUSD * (fallback[sourceCurrency] ?? 1.0)
    }
    
    /// Formatted source/display currency amount (EUR - what user is withdrawing FROM, includes fee)
    var formattedSourceAmount: String {
        let value = showingDestinationCurrency ? usdAmount : amountValue
        if amountString.isEmpty || value == 0 {
            return "\(sourceSymbol)0"
        }
        // Convert from USD storage to display currency
        var displayAmount: Double
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: sourceCurrency) {
            displayAmount = showingDestinationCurrency ? (usdAmount * rate) : amountValue
        } else {
            displayAmount = value
        }
        // Add fee to the display amount
        let totalWithFee = displayAmount + withdrawFeeInDisplayCurrency
        let base = totalWithFee.asCurrency(sourceSymbol)
        return base
    }
    
    /// Formatted destination currency amount (GBP - where money goes TO)
    var formattedDestinationAmount: String {
        let value = showingDestinationCurrency ? amountValue : destinationAmount
        if amountString.isEmpty || value == 0 {
            return "\(destinationSymbol)0"
        }
        return value.asCurrency(destinationSymbol)
    }
    
    var canWithdraw: Bool {
        usdAmount > 0 && usdAmount <= portfolioService.cashBalance
    }
    
    var isOverBalance: Bool {
        usdAmount > portfolioService.cashBalance && usdAmount > 0
    }
    
    var selectedAccountIconName: String {
        switch selectedAccount.iconType {
        case .asset(let assetName):
            return assetName
        }
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            if showAccountSelection {
                // Account Selection Screen
                accountSelectionView
            } else {
                // Amount Input Screen
                amountInputView
            }
        }
        .accountSelectorOverlay(isPresented: $showAccountPicker, selectedAccount: $selectedAccount)
        .fullScreenCover(isPresented: $showConfirmation) {
            WithdrawConfirmView(
                usdAmount: showingDestinationCurrency ? usdAmount : amountValue,
                destinationAmount: showingDestinationCurrency ? amountValue : destinationAmount,
                destinationCurrency: destinationCurrency,
                destinationAccount: selectedAccount,
                isPresented: $showConfirmation,
                onComplete: {
                    isPresented = false
                }
            )
        }
        .onAppear {
            updateAmounts()
        }
        .onChange(of: selectedAccount) { _, _ in
            showingDestinationCurrency = true
            destinationAmount = amountValue
            usdAmount = 0
            updateAmounts()
        }
        .onChange(of: amountString) { _, _ in
            updateAmounts()
        }
    }
    
    // MARK: - Account Selection View
    
    private var accountSelectionView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeService.textPrimaryColor)
                        .frame(width: 32, height: 32)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Title
            Text("Withdraw to")
                .font(.custom("Inter-Bold", size: 28))
                .foregroundColor(themeService.textPrimaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            Text("Select an account to withdraw funds to")
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(themeService.textSecondaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            
            // Account list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(PaymentAccount.allAccounts.filter { !$0.isAddNew }) { account in
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            selectedAccount = account
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showAccountSelection = false
                            }
                        }) {
                            HStack(spacing: 16) {
                                // Account icon
                                AccountIconView(iconType: account.iconType)
                                
                                // Account details
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name)
                                        .font(.custom("Inter-Bold", size: 16))
                                        .foregroundColor(themeService.textPrimaryColor)
                                    
                                    Text(account.subtitle)
                                        .font(.custom("Inter-Regular", size: 14))
                                        .foregroundColor(themeService.textSecondaryColor)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeService.textSecondaryColor)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(AccountRowButtonStyle())
                    }
                    
                    // Divider before Add new account
                    Rectangle()
                        .fill(Color(hex: "F0F0F0"))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                    
                    // Add a new account row
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        // TODO: Handle add new account action
                    }) {
                        HStack(spacing: 16) {
                            // Icon
                            Image("AccountAddNew")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            // Details
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add a new account")
                                    .font(.custom("Inter-Bold", size: 16))
                                    .foregroundColor(themeService.textPrimaryColor)
                                
                                Text("Bank · Card · Mobile wallet")
                                    .font(.custom("Inter-Regular", size: 14))
                                    .foregroundColor(themeService.textSecondaryColor)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeService.textSecondaryColor)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(AccountRowButtonStyle())
                }
            }
            
            Spacer()
        }
        .background(Color.white)
    }
    
    // MARK: - Amount Input View
    
    private var amountInputView: some View {
        VStack(spacing: 0) {
            // Header - shows DESTINATION (where money goes TO)
            HStack(spacing: 16) {
                // Back button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAccountSelection = true
                    }
                }) {
                    Image("ArrowLeft")
                        .renderingMode(.template)
                        .foregroundColor(themeService.textSecondaryColor)
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("Go back")
                    
                    // Destination account icon
                    AccountIconView(iconType: selectedAccount.iconType)
                    
                    // Title
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Withdraw to")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text(selectedAccount.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                    
                    // Currency tag
                    Text(selectedAccount.currency.isEmpty ? "GBP" : selectedAccount.currency)
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
                
                // Amount display with currency swap
                // Shows: Source currency (EUR - display currency) and Destination currency (GBP - linked account)
                if needsCurrencyConversion {
                    AnimatedCurrencySwapView(
                        primaryDisplay: formattedSourceAmount,
                        secondaryDisplay: formattedDestinationAmount,
                        showingPrimaryOnTop: !showingDestinationCurrency,
                        onSwap: {
                            // Convert current amount to the other currency before swapping
                            if showingDestinationCurrency {
                                // Currently showing destination (GBP), switch to source (EUR) input
                                let sourceAmount = usdAmount > 0 ? usdAmount * (ExchangeRateService.shared.getCachedRate(from: "USD", to: sourceCurrency) ?? 1.0) : 0
                                amountString = sourceAmount > 0 ? formatForInput(sourceAmount) : ""
                            } else {
                                // Currently showing source (EUR), switch to destination (GBP) input
                                amountString = destinationAmount > 0 ? formatForInput(destinationAmount) : ""
                            }
                            showingDestinationCurrency.toggle()
                        },
                        errorMessage: isOverBalance ? "Insufficient balance" : nil
                    )
                } else {
                    // No conversion needed - same currency
                    VStack(spacing: 4) {
                        Text(formattedSourceAmount)
                            .font(.custom("Inter-Bold", size: 56))
                            .foregroundColor(isOverBalance ? .red : themeService.textPrimaryColor)
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
                
                // Source account (Sling Balance) - show in destination currency
                PaymentInstrumentRow(
                    iconName: "SlingBalanceLogo",
                    title: "Sling Balance",
                    subtitleParts: [formattedAvailableBalance],
                    actionButtonTitle: "Max",
                    onActionTap: {
                        // Set max in the current input currency
                        if showingDestinationCurrency && needsCurrencyConversion {
                            // Convert USD balance to destination currency
                            let maxInDestination = exchangeRate > 0 ? portfolioService.cashBalance / exchangeRate : portfolioService.cashBalance
                            amountString = formatForInput(floor(maxInDestination))
                        } else {
                            amountString = formatForInput(floor(portfolioService.cashBalance))
                        }
                        updateAmounts()
                    },
                    showMenu: true,
                    onMenuTap: {
                        // TODO: Show source selector if needed
                    }
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
                    isEnabled: canWithdraw
                ) {
                    showConfirmation = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
    }
    
    /// Available balance formatted in display currency
    private var formattedAvailableBalance: String {
        let displayCurrency = displayCurrencyService.displayCurrency
        let symbol = ExchangeRateService.symbol(for: displayCurrency)
        
        if displayCurrency == "USD" {
            return portfolioService.cashBalance.asUSD
        }
        
        // Convert USD balance to display currency
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: displayCurrency) {
            let convertedBalance = portfolioService.cashBalance * rate
            return convertedBalance.asCurrency(symbol)
        }
        
        // Fallback - just show USD
        return portfolioService.cashBalance.asUSD
    }
    
    private func formatForInput(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    private func updateAmounts() {
        guard needsCurrencyConversion else {
            // No conversion needed (destination is USD)
            destinationAmount = amountValue
            usdAmount = amountValue
            exchangeRate = 1.0
            return
        }
        
        let inputAmount = amountValue
        
        if showingDestinationCurrency {
            // User is entering destination currency, convert to USD
            destinationAmount = inputAmount
            Task {
                // Get rate from destination currency to USD
                if let rate = await exchangeService.getRate(from: destinationCurrency, to: "USD") {
                    await MainActor.run {
                        exchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: destinationCurrency,
                    to: "USD"
                ) {
                    await MainActor.run {
                        usdAmount = converted
                    }
                }
            }
        } else {
            // User is entering USD, convert to destination currency
            usdAmount = inputAmount
            Task {
                // Get rate from destination currency to USD (for display)
                if let rate = await exchangeService.getRate(from: destinationCurrency, to: "USD") {
                    await MainActor.run {
                        exchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: "USD",
                    to: destinationCurrency
                ) {
                    await MainActor.run {
                        destinationAmount = converted
                    }
                }
            }
        }
    }
}

// MARK: - Withdraw Confirm View

struct WithdrawConfirmView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var feeService = FeeService.shared
    
    let usdAmount: Double // Amount in USD (storage currency) - what gets deducted
    let destinationAmount: Double // Amount in destination currency
    let destinationCurrency: String // e.g., "GBP", "EUR"
    let destinationAccount: PaymentAccount
    @Binding var isPresented: Bool
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    @State private var showFeesSheet = false
    
    private let portfolioService = PortfolioService.shared
    
    /// Symbol for destination currency
    private var destinationSymbol: String {
        ExchangeRateService.symbol(for: destinationCurrency)
    }
    
    private var displayCurrency: String {
        DisplayCurrencyService.shared.displayCurrency
    }
    
    private var displaySymbol: String {
        ExchangeRateService.symbol(for: displayCurrency)
    }
    
    /// Calculate fee for this withdrawal
    private var withdrawalFee: FeeResult {
        feeService.calculateFee(
            for: .withdrawal,
            paymentInstrumentCurrency: destinationCurrency
        )
    }
    
    /// Total USD amount deducted from balance (amount + fee)
    private var totalDeductedUSD: Double {
        if withdrawalFee.isFree {
            return usdAmount
        }
        return usdAmount + withdrawalFee.amount
    }
    
    /// Convert USD to display currency
    private func usdToDisplay(_ usd: Double) -> Double {
        if displayCurrency == "USD" { return usd }
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: displayCurrency) {
            return usd * rate
        }
        let fallback: [String: Double] = ["EUR": 0.92, "GBP": 0.79]
        return usd * (fallback[displayCurrency] ?? 1.0)
    }
    
    /// Formatted destination currency amount (what recipient receives)
    var formattedDestinationAmount: String {
        destinationAmount.asCurrency(destinationSymbol)
    }
    
    /// Exchange rate from display currency to destination currency
    private var displayToDestRate: Double {
        let baseInDisplay = usdToDisplay(usdAmount)
        guard baseInDisplay > 0 else { return 1.0 }
        return destinationAmount / baseInDisplay
    }
    
    /// Amount exchanged in display currency (derived from destination / rate so math is exact)
    private var amountExchangedDisplay: Double {
        guard displayToDestRate > 0 else { return usdToDisplay(usdAmount) }
        return destinationAmount / displayToDestRate
    }
    
    /// Fee in display currency
    private var feeDisplay: Double {
        usdToDisplay(withdrawalFee.isFree ? 0 : withdrawalFee.amount)
    }
    
    /// Total withdrawn = amount exchanged + fee (computed from chain so it adds up)
    private var totalWithdrawnDisplay: Double {
        amountExchangedDisplay + feeDisplay
    }
    
    /// Formatted total withdrawn in display currency
    var formattedTotalWithdrawnDisplay: String {
        totalWithdrawnDisplay.asCurrency(displaySymbol)
    }
    
    /// Formatted base/exchanged amount in display currency
    var formattedBaseAmountDisplay: String {
        amountExchangedDisplay.asCurrency(displaySymbol)
    }
    
    /// Formatted fee in display currency
    var formattedFeeDisplay: String {
        feeDisplay.asCurrency(displaySymbol)
    }
    
    var destinationAccountIcon: String {
        switch destinationAccount.iconType {
        case .asset(let assetName):
            return assetName
        }
    }
    
    /// Attributed title with green amount
    private var withdrawTitle: AttributedString {
        var result = AttributedString("Withdraw ")
        result.foregroundColor = UIColor(Color(hex: "080808"))
        var amount = AttributedString(shortDestinationAmount)
        amount.foregroundColor = UIColor(Color(hex: "57CE43"))
        var suffix = AttributedString(" to \(destinationAccount.name)")
        suffix.foregroundColor = UIColor(Color(hex: "080808"))
        return result + amount + suffix
    }
    
    /// Short formatted amount for title
    private var shortDestinationAmount: String {
        if destinationAmount.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(destinationSymbol)\(Int(destinationAmount))"
        }
        return formattedDestinationAmount
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
                    // Destination account icon
                    AccountIconView(iconType: destinationAccount.iconType)
                    
                    // Title: "Withdraw €100 to Monzo bank Limited"
                    Text(withdrawTitle)
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
                        
                        // Total withdrawn (in display currency, includes fee)
                        InfoListItem(label: "Total withdrawn", detail: formattedTotalWithdrawnDisplay)
                        
                        // Fees (red, in display currency)
                        if !withdrawalFee.isFree {
                            HStack {
                                Text("Fees")
                                    .font(.custom("Inter-Regular", size: 16))
                                    .foregroundColor(themeService.textSecondaryColor)
                                
                                Spacer()
                                
                                Text("-\(formattedFeeDisplay)")
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(Color(hex: "E30000"))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 16)
                        } else {
                            InfoListItem(label: "Fees", detail: "No fee")
                        }
                        
                        // Amount exchanged (in display currency, after fee)
                        if !withdrawalFee.isFree {
                            InfoListItem(label: "Amount exchanged", detail: formattedBaseAmountDisplay)
                        }
                        
                        // Exchange rate (source/display currency on left - money flows from balance)
                        if displayCurrency != destinationCurrency {
                            HStack {
                                Text("Exchange rate")
                                    .font(.custom("Inter-Regular", size: 16))
                                    .foregroundColor(themeService.textSecondaryColor)
                                
                                Spacer()
                                
                                Text("\(displaySymbol)1 = \(destinationSymbol)\(String(format: "%.2f", displayToDestRate))")
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(Color(hex: "FF5113"))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 16)
                        }
                        
                        // Recipient gets (in destination currency)
                        InfoListItem(label: "Recipient gets", detail: formattedDestinationAmount)
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
                    title: "Withdraw \(shortDestinationAmount)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    portfolioService.deductCash(totalDeductedUSD)
                    ActivityService.shared.addActivity(
                        avatar: destinationAccountIcon,
                        titleLeft: destinationAccount.name,
                        subtitleLeft: "Withdrawal",
                        titleRight: "-\(formattedDestinationAmount)",
                        subtitleRight: formattedBaseAmountDisplay
                    )
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

// MARK: - Quick Amount Button

struct QuickAmountButton: View {
    @ObservedObject private var themeService = ThemeService.shared
    let amount: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            Text(amount == "All" ? "All" : "£\(amount)")
                .font(.custom("Inter-Bold", size: 14))
                .foregroundColor(themeService.textPrimaryColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "F7F7F7"))
                .cornerRadius(12)
        }
    }
}

#Preview {
    WithdrawView(isPresented: .constant(true))
}
