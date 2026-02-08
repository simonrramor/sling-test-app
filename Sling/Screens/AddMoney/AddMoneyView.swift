import SwiftUI
import UIKit

struct AddMoneyView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @State private var amountString: String = ""
    @State private var showConfirmation = false
    @State private var showAccountSelector = false
    @State private var selectedAccount: PaymentAccount = .ukBank
    @State private var showingSourceCurrency = true // true = source account currency is primary, false = USD is primary
    @State private var sourceAmount: Double = 0 // Amount in source account currency (GBP, EUR, etc.)
    @State private var usdAmount: Double = 0 // Amount in USD (what gets added to Sling balance)
    @State private var currentExchangeRate: Double = 1.0 // Rate from source currency to USD
    @State private var shakeOffset: CGFloat = 0
    @State private var isOverLimit: Bool = false
    
    private let exchangeService = ExchangeRateService.shared
    private let depositLimitGBP: Double = 7000 // Deposit limit in GBP
    
    var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    /// The linked account currency (what the user is paying from)
    var linkedAccountCurrency: String {
        selectedAccount.currency.isEmpty ? "GBP" : selectedAccount.currency
    }
    
    /// The display currency (what the user wants to see their balance in) - shown as large/primary
    var displayCurrency: String {
        displayCurrencyService.displayCurrency
    }
    
    /// The storage currency (what the Sling balance is stored in)
    var storageCurrency: String {
        displayCurrencyService.storageCurrency
    }
    
    /// For backwards compatibility
    var sourceCurrency: String {
        linkedAccountCurrency
    }
    
    /// Whether we need to show currency conversion (when display and linked account currencies differ)
    var needsCurrencyConversion: Bool {
        displayCurrency != linkedAccountCurrency
    }
    
    /// Formatted display currency amount (large/primary - what user sees)
    var formattedDisplayAmount: String {
        let symbol = ExchangeRateService.symbol(for: displayCurrency)
        if sourceAmount == 0 && amountString.isEmpty {
            return "\(symbol)0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: sourceAmount)) ?? NumberFormatService.shared.formatNumber(sourceAmount)
        return "\(symbol)\(formattedNumber)"
    }
    
    /// Fee in linked account currency
    private var feeInLinkedCurrency: Double {
        let fee = FeeService.shared.calculateFee(for: .deposit, paymentInstrumentCurrency: linkedAccountCurrency)
        if fee.isFree { return 0 }
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: linkedAccountCurrency) {
            return 0.50 * rate
        }
        let fallback: [String: Double] = ["GBP": 0.79, "EUR": 0.92]
        return 0.50 * (fallback[linkedAccountCurrency] ?? 1.0)
    }
    
    /// Whether a fee applies to this deposit
    private var hasFee: Bool {
        !FeeService.shared.calculateFee(for: .deposit, paymentInstrumentCurrency: linkedAccountCurrency).isFree
    }
    
    /// Formatted linked account amount (small/secondary - what will be charged to bank, including fee)
    var formattedLinkedAccountAmount: String {
        let symbol = ExchangeRateService.symbol(for: linkedAccountCurrency)
        let totalAmount = usdAmount + feeInLinkedCurrency
        if totalAmount == 0 && amountString.isEmpty {
            return "\(symbol)0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: totalAmount)) ?? NumberFormatService.shared.formatNumber(totalAmount)
        let base = "\(symbol)\(formattedNumber)"
        return hasFee && totalAmount > 0 ? "\(base) inc. fee" : base
    }
    
    /// Legacy property names for compatibility
    var formattedSourceAmount: String { formattedDisplayAmount }
    var formattedSecondaryAmount: String { formattedLinkedAccountAmount }
    
    var selectedAccountIconName: String {
        switch selectedAccount.iconType {
        case .asset(let assetName):
            return assetName
        }
    }
    
    /// Check if the current amount exceeds the deposit limit
    var exceedsDepositLimit: Bool {
        // Convert limit to source currency if needed
        if sourceCurrency == "GBP" {
            return sourceAmount > depositLimitGBP
        } else {
            // For other currencies, we'd need to convert the limit
            // For now, assume 1:1 or use the exchange rate
            return sourceAmount > depositLimitGBP * currentExchangeRate
        }
    }
    
    /// Trigger shake animation
    private func triggerShake() {
        withAnimation(.linear(duration: 0.05)) {
            shakeOffset = 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = -8
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = 6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = -4
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = 0
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    // Close button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeService.textSecondaryColor)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Close")
                    
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
                    
                    // Currency tag (shows display currency)
                    Text(displayCurrencyService.displayCurrency)
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
                
                // Amount display with swap animation - always show USD equivalent
                if needsCurrencyConversion {
                    AnimatedCurrencySwapView(
                        primaryDisplay: formattedSourceAmount,  // Source currency - what user pays
                        secondaryDisplay: formattedSecondaryAmount,   // Secondary currency (USD or display)
                        showingPrimaryOnTop: showingSourceCurrency,
                        onSwap: {
                            // Don't allow swap when over limit
                            if isOverLimit {
                                triggerShake()
                                return
                            }
                            showingSourceCurrency.toggle()
                            // Update amountString to match the new primary currency
                            if showingSourceCurrency {
                                // Now showing source currency, set amountString to source amount
                                amountString = sourceAmount > 0 ? formatForInput(sourceAmount) : ""
                            } else {
                                // Now showing USD, set amountString to USD amount
                                amountString = usdAmount > 0 ? formatForInput(usdAmount) : ""
                            }
                        },
                        errorMessage: isOverLimit ? "Deposit limit reached" : nil
                    )
                    .offset(x: shakeOffset)
                } else {
                    Text(formattedSourceAmount)
                        .font(.custom("Inter-Bold", size: 56))
                        .foregroundColor(themeService.textPrimaryColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .offset(x: shakeOffset)
                }
                
                Spacer()
                
                // Payment source (tappable)
                TappablePaymentInstrumentRow(
                    iconName: selectedAccountIconName,
                    title: selectedAccount.name,
                    subtitleParts: selectedAccount.accountNumber.isEmpty ? [] : [selectedAccount.accountNumber],
                    trailingText: selectedAccount.currency,
                    onTap: {
                        showAccountSelector = true
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
                    isEnabled: amountValue > 0 && !isOverLimit
                ) {
                    showConfirmation = true
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
            // Confirmation overlay
            if showConfirmation {
                AddMoneyConfirmView(
                    isPresented: $showConfirmation,
                    sourceAccount: selectedAccount,
                    sourceAmount: sourceAmount,  // Display currency amount (what user typed)
                    sourceCurrency: sourceCurrency,  // Linked account currency code
                    linkedAccountAmount: usdAmount,  // Amount in linked account currency
                    destinationAmount: usdAmount,  // Amount for storage (same as linked for now)
                    exchangeRate: currentExchangeRate,
                    onComplete: {
                        isPresented = false
                    }
                )
                .transition(.fluidConfirm)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showConfirmation)
        .onChange(of: amountString) { oldValue, newValue in
            // If already over limit, prevent adding more characters (allow backspace)
            if isOverLimit && newValue.count > oldValue.count {
                // Revert the change
                amountString = oldValue
                triggerShake()
                return
            }
            
            updateAmounts()
            
            // Check deposit limit after amounts are updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let wasOverLimit = isOverLimit
                isOverLimit = exceedsDepositLimit
                
                // Trigger shake when first exceeding limit
                if isOverLimit && !wasOverLimit {
                    triggerShake()
                }
            }
        }
        .onChange(of: selectedAccount.id) { _, _ in
            // Reset to source currency when account changes
            showingSourceCurrency = true
            sourceAmount = amountValue
            usdAmount = 0
            updateAmounts()
        }
        .onAppear {
            updateAmounts()
        }
        .accountSelectorOverlay(
            isPresented: $showAccountSelector,
            selectedAccount: $selectedAccount
        )
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
            // No conversion needed (display and linked account are same currency)
            sourceAmount = amountValue
            usdAmount = amountValue
            currentExchangeRate = 1.0
            return
        }
        
        let inputAmount = amountValue
        
        if showingSourceCurrency {
            // User is entering display currency (primary/large), convert to linked account currency (secondary/small)
            sourceAmount = inputAmount
            Task {
                // Get the rate from display currency to linked account currency
                if let rate = await exchangeService.getRate(from: displayCurrency, to: linkedAccountCurrency) {
                    await MainActor.run {
                        currentExchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: displayCurrency,
                    to: linkedAccountCurrency
                ) {
                    await MainActor.run {
                        usdAmount = converted
                    }
                }
            }
        } else {
            // User is entering linked account currency, convert to display currency
            usdAmount = inputAmount
            Task {
                // Get the rate from display to linked account (for display)
                if let rate = await exchangeService.getRate(from: displayCurrency, to: linkedAccountCurrency) {
                    await MainActor.run {
                        currentExchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: linkedAccountCurrency,
                    to: displayCurrency
                ) {
                    await MainActor.run {
                        sourceAmount = converted
                    }
                }
            }
        }
    }
}

#Preview {
    AddMoneyView(isPresented: .constant(true))
}



