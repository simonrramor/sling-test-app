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
    
    /// Destination account currency
    var destinationCurrency: String {
        selectedAccount.currency.isEmpty ? "GBP" : selectedAccount.currency
    }
    
    /// Symbol for destination currency
    var destinationSymbol: String {
        ExchangeRateService.symbol(for: destinationCurrency)
    }
    
    /// Whether we need to show currency conversion (destination differs from USD)
    var needsCurrencyConversion: Bool {
        destinationCurrency != "USD"
    }
    
    /// Formatted destination currency amount
    var formattedDestinationAmount: String {
        let value = showingDestinationCurrency ? amountValue : destinationAmount
        if amountString.isEmpty || value == 0 {
            return "\(destinationSymbol)0"
        }
        return value.asCurrency(destinationSymbol)
    }
    
    /// Formatted USD amount (storage currency)
    var formattedUSDAmount: String {
        let value = showingDestinationCurrency ? usdAmount : amountValue
        if amountString.isEmpty || value == 0 {
            return "$0"
        }
        return value.asUSD
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
                        .buttonStyle(PlainButtonStyle())
                    }
                    
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
                    .buttonStyle(PlainButtonStyle())
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
                if needsCurrencyConversion {
                    AnimatedCurrencySwapView(
                        primaryDisplay: formattedDestinationAmount,
                        secondaryDisplay: formattedUSDAmount,
                        showingPrimaryOnTop: showingDestinationCurrency,
                        onSwap: {
                            // Convert current amount to the other currency before swapping
                            if showingDestinationCurrency {
                                // Switching to USD input
                                amountString = usdAmount > 0 ? formatForInput(usdAmount) : ""
                            } else {
                                // Switching to destination currency input
                                amountString = destinationAmount > 0 ? formatForInput(destinationAmount) : ""
                            }
                            showingDestinationCurrency.toggle()
                        },
                        errorMessage: isOverBalance ? "Insufficient balance" : nil
                    )
                } else {
                    // No conversion needed - destination is USD
                    VStack(spacing: 4) {
                        Text(formattedUSDAmount)
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
    
    /// Available balance formatted in destination currency
    private var formattedAvailableBalance: String {
        if destinationCurrency == "USD" {
            return portfolioService.cashBalance.asUSD
        }
        // Convert USD balance to destination currency
        let convertedBalance = exchangeRate > 0 ? portfolioService.cashBalance / exchangeRate : portfolioService.cashBalance
        return convertedBalance.asCurrency(destinationSymbol)
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
    
    /// Formatted destination currency amount (what user receives)
    var formattedDestinationAmount: String {
        destinationAmount.asCurrency(destinationSymbol)
    }
    
    /// Formatted USD amount (storage currency)
    var formattedUSDAmount: String {
        usdAmount.asUSD
    }
    
    /// Formatted total deducted in USD
    var formattedTotalDeducted: String {
        totalDeductedUSD.asUSD
    }
    
    var destinationAccountIcon: String {
        switch destinationAccount.iconType {
        case .asset(let assetName):
            return assetName
        }
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
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
                    
                    AccountIconView(iconType: destinationAccount.iconType)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Withdraw to")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text(destinationAccount.name)
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
                
                // Amount display - show destination currency as primary
                VStack(spacing: 4) {
                    Text(formattedDestinationAmount)
                        .font(.custom("Inter-Bold", size: 56))
                        .foregroundColor(themeService.textPrimaryColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    // Show USD equivalent if different currency
                    if destinationCurrency != "USD" {
                        Text(formattedUSDAmount)
                            .font(.custom("Inter-Medium", size: 18))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                }
                
                Spacer()
                
                // Details section
                VStack(spacing: 0) {
                    DetailRow(label: "To", value: destinationAccount.name)
                    DetailRow(label: "Speed", value: "1-2 business days")
                    
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    DetailRow(label: "You receive", value: formattedDestinationAmount)
                    
                    if destinationCurrency != "USD" {
                        DetailRow(label: "From balance", value: formattedUSDAmount)
                    }
                    
                    // Fee row
                    FeeRow(fee: withdrawalFee, paymentInstrumentCurrency: destinationCurrency, onTap: { showFeesSheet = true })
                    
                    // Total deducted (if fee applies)
                    if !withdrawalFee.isFree {
                        DetailRow(label: "Total from balance", value: formattedTotalDeducted)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Withdraw button with smooth loading animation
                LoadingButton(
                    title: "Withdraw \(formattedDestinationAmount)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    // Perform withdrawal (deduct total USD including fee)
                    portfolioService.deductCash(totalDeductedUSD)
                    
                    // Record activity
                    ActivityService.shared.addActivity(
                        avatar: destinationAccountIcon,
                        titleLeft: destinationAccount.name,
                        subtitleLeft: "Withdrawal",
                        titleRight: "-\(formattedDestinationAmount)",
                        subtitleRight: formattedUSDAmount
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
