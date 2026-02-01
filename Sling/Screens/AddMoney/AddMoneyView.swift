import SwiftUI
import UIKit

struct AddMoneyView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @State private var amountString: String = ""
    @State private var showConfirmation = false
    @State private var showAccountSelector = false
    @State private var selectedAccount: PaymentAccount = .monzoBankLimited
    @State private var showingSourceCurrency = true // true = source account currency is primary, false = USD is primary
    @State private var sourceAmount: Double = 0 // Amount in source account currency (GBP, EUR, etc.)
    @State private var usdAmount: Double = 0 // Amount in USD (what gets added to Sling balance)
    @State private var currentExchangeRate: Double = 1.0 // Rate from source currency to USD
    @State private var shakeOffset: CGFloat = 0
    @State private var isOverLimit: Bool = false
    
    private let exchangeService = ExchangeRateService.shared
    private let slingBaseCurrency = "USD" // Sling balance is always stored in USD
    private let depositLimitGBP: Double = 7000 // Deposit limit in GBP
    
    var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    /// The source account currency (what the user is paying from)
    var sourceCurrency: String {
        selectedAccount.currency.isEmpty ? "GBP" : selectedAccount.currency
    }
    
    /// The display currency (what the user wants to see their balance in)
    var displayCurrency: String {
        displayCurrencyService.displayCurrency
    }
    
    /// The secondary currency to show (USD if source matches display, otherwise display currency)
    var secondaryCurrency: String {
        if sourceCurrency == displayCurrency {
            // GBP-GBP: show USD as secondary (since Sling stores in USD)
            return slingBaseCurrency
        } else {
            // USD-GBP: show display currency as secondary
            return displayCurrency
        }
    }
    
    /// Whether we need to show currency conversion (always true unless source is USD and display is USD)
    var needsCurrencyConversion: Bool {
        sourceCurrency != secondaryCurrency
    }
    
    /// Formatted source amount (what user is paying from their account)
    var formattedSourceAmount: String {
        let symbol = ExchangeRateService.symbol(for: sourceCurrency)
        if sourceAmount == 0 && amountString.isEmpty {
            return "\(symbol)0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: sourceAmount)) ?? String(format: "%.2f", sourceAmount)
        return "\(symbol)\(formattedNumber)"
    }
    
    /// Formatted secondary currency amount
    var formattedSecondaryAmount: String {
        let symbol = ExchangeRateService.symbol(for: secondaryCurrency)
        if usdAmount == 0 && amountString.isEmpty {
            return "\(symbol)0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2  // Always show 2 decimals for USD
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: usdAmount)) ?? String(format: "%.2f", usdAmount)
        return "\(symbol)\(formattedNumber)"
    }
    
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
                    
                    // Currency tag (shows wallet display currency)
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
                    sourceAmount: sourceAmount,
                    sourceCurrency: sourceCurrency,
                    destinationAmount: usdAmount,
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
            // No conversion needed (source is USD and display is USD)
            sourceAmount = amountValue
            usdAmount = amountValue
            currentExchangeRate = 1.0
            return
        }
        
        let inputAmount = amountValue
        
        if showingSourceCurrency {
            // User is entering source currency, convert to secondary currency
            sourceAmount = inputAmount
            Task {
                // Get the rate from source currency to secondary currency
                if let rate = await exchangeService.getRate(from: sourceCurrency, to: secondaryCurrency) {
                    await MainActor.run {
                        currentExchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: sourceCurrency,
                    to: secondaryCurrency
                ) {
                    await MainActor.run {
                        usdAmount = converted
                    }
                }
            }
        } else {
            // User is entering secondary currency, convert to source currency
            usdAmount = inputAmount
            Task {
                // Get the rate from source currency to secondary currency (for display)
                if let rate = await exchangeService.getRate(from: sourceCurrency, to: secondaryCurrency) {
                    await MainActor.run {
                        currentExchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: secondaryCurrency,
                    to: sourceCurrency
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



