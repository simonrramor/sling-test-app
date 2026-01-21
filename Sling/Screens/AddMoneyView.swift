import SwiftUI
import UIKit

struct AddMoneyView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @State private var amountString: String = ""
    @State private var showConfirmation = false
    @State private var showAccountSelector = false
    @State private var selectedAccount: PaymentAccount = .monzoBankLimited
    @State private var showingSourceCurrency = true // true = source account currency is primary, false = USD is primary
    @State private var sourceAmount: Double = 0 // Amount in source account currency (GBP, EUR, etc.)
    @State private var usdAmount: Double = 0 // Amount in USD (what gets added to Sling balance)
    @State private var currentExchangeRate: Double = 1.0 // Rate from source currency to USD
    
    private let exchangeService = ExchangeRateService.shared
    private let slingCurrency = "USD" // Sling balance is always stored in USD
    
    var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    /// The source account currency (what the user is paying from)
    var sourceCurrency: String {
        selectedAccount.currency.isEmpty ? "GBP" : selectedAccount.currency
    }
    
    /// Whether the source account has a different currency than USD
    var hasCurrencyDifference: Bool {
        sourceCurrency != slingCurrency
    }
    
    /// Formatted source amount (GBP, EUR, etc. - what user is paying)
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
    
    /// Formatted USD amount (what gets added to Sling balance)
    var formattedUSDAmount: String {
        let symbol = ExchangeRateService.symbol(for: slingCurrency)
        if usdAmount == 0 && amountString.isEmpty {
            return "\(symbol)0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: usdAmount)) ?? String(format: "%.2f", usdAmount)
        return "\(symbol)\(formattedNumber)"
    }
    
    /// Formatted amount for non-currency-difference case (when source is USD)
    var formattedAmount: String {
        let symbol = ExchangeRateService.symbol(for: sourceCurrency)
        if amountString.isEmpty {
            return "\(symbol)0"
        }
        let number = Double(amountString) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = amountString.contains(".") ? 2 : 0
        let formattedNumber = formatter.string(from: NSNumber(value: number)) ?? amountString
        return "\(symbol)\(formattedNumber)"
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
                    
                    // Currency tag (shows source account currency)
                    Text(sourceCurrency)
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "F7F7F7"))
                        )
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                
                Spacer()
                
                // Amount display with swap animation
                if hasCurrencyDifference {
                    CurrencySwapView(
                        primaryDisplay: formattedSourceAmount,  // Source currency (GBP) - what user types
                        secondaryDisplay: formattedUSDAmount,   // USD - what gets added to Sling
                        showingPrimaryOnTop: showingSourceCurrency,
                        onSwap: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSourceCurrency.toggle()
                            }
                            // Update amountString to match the new primary currency
                            if showingSourceCurrency {
                                // Now showing source currency, set amountString to source amount
                                amountString = sourceAmount > 0 ? formatForInput(sourceAmount) : ""
                            } else {
                                // Now showing USD, set amountString to USD amount
                                amountString = usdAmount > 0 ? formatForInput(usdAmount) : ""
                            }
                        }
                    )
                } else {
                    Text(formattedAmount)
                        .font(.custom("Inter-Bold", size: 56))
                        .foregroundColor(themeService.textPrimaryColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
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
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .sheet(isPresented: $showAccountSelector) {
                    AccountSelectorView(
                        selectedAccount: $selectedAccount,
                        isPresented: $showAccountSelector
                    )
                }
                
                // Number pad
                NumberPadView(amountString: $amountString)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Next button
                SecondaryButton(
                    title: "Next",
                    isEnabled: amountValue > 0
                ) {
                    showConfirmation = true
                }
                .padding(.horizontal, 24)
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
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showConfirmation)
        .onChange(of: amountString) { _, newValue in
            updateAmounts()
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
    }
    
    private func formatForInput(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    private func updateAmounts() {
        guard hasCurrencyDifference else {
            // Source is USD, no conversion needed
            sourceAmount = amountValue
            usdAmount = amountValue
            currentExchangeRate = 1.0
            return
        }
        
        let inputAmount = amountValue
        
        if showingSourceCurrency {
            // User is entering source currency (e.g., GBP), convert to USD
            sourceAmount = inputAmount
            Task {
                // Get the rate from source currency to USD
                if let rate = await exchangeService.getRate(from: sourceCurrency, to: slingCurrency) {
                    await MainActor.run {
                        currentExchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: sourceCurrency,
                    to: slingCurrency
                ) {
                    await MainActor.run {
                        usdAmount = converted
                    }
                }
            }
        } else {
            // User is entering USD, convert to source currency
            usdAmount = inputAmount
            Task {
                // Get the rate from source currency to USD (for display)
                if let rate = await exchangeService.getRate(from: sourceCurrency, to: slingCurrency) {
                    await MainActor.run {
                        currentExchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: slingCurrency,
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

// MARK: - Currency Swap View

struct CurrencySwapView: View {
    @ObservedObject private var themeService = ThemeService.shared
    let primaryDisplay: String // The primary currency amount (what user is typing)
    let secondaryDisplay: String // The secondary currency amount (converted)
    let showingPrimaryOnTop: Bool // true = primary is on top (large), false = secondary is on top
    let onSwap: () -> Void
    
    private let topOffset: CGFloat = 0
    private let bottomOffset: CGFloat = 45
    
    var body: some View {
        Button(action: onSwap) {
            ZStack {
                // Primary currency amount (e.g., GBP - source)
                HStack(spacing: 4) {
                    // Swap icon (visible when primary is secondary/bottom)
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeService.textSecondaryColor)
                        .opacity(showingPrimaryOnTop ? 0 : 1)
                    
                    Text(primaryDisplay)
                        .font(.custom(showingPrimaryOnTop ? "Inter-Bold" : "Inter-Medium", size: showingPrimaryOnTop ? 56 : 18))
                        .foregroundColor(showingPrimaryOnTop ? Color(hex: "080808") : Color(hex: "7B7B7B"))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .offset(y: showingPrimaryOnTop ? topOffset : bottomOffset)
                
                // Secondary currency amount (e.g., USD - Sling balance)
                HStack(spacing: 4) {
                    // Swap icon (visible when secondary is on bottom)
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeService.textSecondaryColor)
                        .opacity(showingPrimaryOnTop ? 1 : 0)
                    
                    Text(secondaryDisplay)
                        .font(.custom(showingPrimaryOnTop ? "Inter-Medium" : "Inter-Bold", size: showingPrimaryOnTop ? 18 : 56))
                        .foregroundColor(showingPrimaryOnTop ? Color(hex: "7B7B7B") : Color(hex: "080808"))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .offset(y: showingPrimaryOnTop ? bottomOffset : topOffset)
            }
            .frame(height: 100)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddMoneyView(isPresented: .constant(true))
}
