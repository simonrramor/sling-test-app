import SwiftUI
import UIKit

struct AddMoneyView: View {
    @Binding var isPresented: Bool
    @State private var amountString: String = ""
    @State private var showConfirmation = false
    @State private var showAccountSelector = false
    @State private var selectedAccount: PaymentAccount = .monzoBankLimited
    @State private var showingWalletCurrency = true // true = wallet currency (GBP) is primary, false = account currency is primary
    @State private var walletAmount: Double = 0 // Amount in wallet currency (GBP)
    @State private var accountAmount: Double = 0 // Amount in account currency (USD, EUR, etc.)
    @State private var currentExchangeRate: Double = 1.0 // Rate from account currency to wallet currency
    
    private let exchangeService = ExchangeRateService.shared
    private let walletCurrency = "GBP"
    
    var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    /// Whether the selected account has a different currency than the wallet
    var hasCurrencyDifference: Bool {
        selectedAccount.currency != walletCurrency && !selectedAccount.currency.isEmpty
    }
    
    /// Formatted wallet amount (always GBP)
    var formattedWalletAmount: String {
        let symbol = ExchangeRateService.symbol(for: walletCurrency)
        if walletAmount == 0 && amountString.isEmpty {
            return "\(symbol)0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: walletAmount)) ?? String(format: "%.2f", walletAmount)
        return "\(symbol)\(formattedNumber)"
    }
    
    /// Formatted account amount (USD, EUR, etc.)
    var formattedAccountAmount: String {
        let symbol = ExchangeRateService.symbol(for: selectedAccount.currency)
        if accountAmount == 0 && amountString.isEmpty {
            return "\(symbol)0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: accountAmount)) ?? String(format: "%.2f", accountAmount)
        return "\(symbol)\(formattedNumber)"
    }
    
    /// Formatted amount for non-currency-difference case
    var formattedAmount: String {
        if amountString.isEmpty {
            return "£0"
        }
        let number = Double(amountString) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = amountString.contains(".") ? 2 : 0
        let formattedNumber = formatter.string(from: NSNumber(value: number)) ?? amountString
        return "£\(formattedNumber)"
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
                            .foregroundColor(Color(hex: "7B7B7B"))
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
                            .foregroundColor(Color(hex: "7B7B7B"))
                        Text("Sling Balance")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                    }
                    
                    Spacer()
                    
                    // Currency tag
                    Text("GBP")
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(Color(hex: "7B7B7B"))
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
                        walletDisplay: formattedWalletAmount,
                        accountDisplay: formattedAccountAmount,
                        showingWalletCurrency: showingWalletCurrency,
                        onSwap: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingWalletCurrency.toggle()
                            }
                            // Update amountString to match the new primary currency
                            if showingWalletCurrency {
                                // Now showing wallet currency, set amountString to wallet amount
                                amountString = walletAmount > 0 ? formatForInput(walletAmount) : ""
                            } else {
                                // Now showing account currency, set amountString to account amount
                                amountString = accountAmount > 0 ? formatForInput(accountAmount) : ""
                            }
                        }
                    )
                } else {
                    Text(formattedAmount)
                        .font(.custom("Inter-Bold", size: 56))
                        .foregroundColor(Color(hex: "080808"))
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
                    sourceAmount: accountAmount,
                    sourceCurrency: selectedAccount.currency.isEmpty ? walletCurrency : selectedAccount.currency,
                    destinationAmount: walletAmount,
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
            // Reset to wallet currency when account changes
            showingWalletCurrency = true
            walletAmount = amountValue
            accountAmount = 0
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
            walletAmount = amountValue
            accountAmount = amountValue
            currentExchangeRate = 1.0
            return
        }
        
        let inputAmount = amountValue
        
        if showingWalletCurrency {
            // User is entering wallet currency (GBP), convert to account currency
            walletAmount = inputAmount
            Task {
                // Get the rate from account currency to wallet currency
                if let rate = await exchangeService.getRate(from: selectedAccount.currency, to: walletCurrency) {
                    await MainActor.run {
                        currentExchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: walletCurrency,
                    to: selectedAccount.currency
                ) {
                    await MainActor.run {
                        accountAmount = converted
                    }
                }
            }
        } else {
            // User is entering account currency, convert to wallet currency (GBP)
            accountAmount = inputAmount
            Task {
                // Get the rate from account currency to wallet currency
                if let rate = await exchangeService.getRate(from: selectedAccount.currency, to: walletCurrency) {
                    await MainActor.run {
                        currentExchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: selectedAccount.currency,
                    to: walletCurrency
                ) {
                    await MainActor.run {
                        walletAmount = converted
                    }
                }
            }
        }
    }
}

// MARK: - Currency Swap View

struct CurrencySwapView: View {
    let walletDisplay: String // Always the wallet currency (GBP) amount
    let accountDisplay: String // Always the account currency (USD, EUR, etc.) amount
    let showingWalletCurrency: Bool // true = wallet is primary (top), false = account is primary (top)
    let onSwap: () -> Void
    
    private let topOffset: CGFloat = 0
    private let bottomOffset: CGFloat = 45
    
    var body: some View {
        Button(action: onSwap) {
            ZStack {
                // Wallet currency amount (GBP)
                HStack(spacing: 4) {
                    // Swap icon (visible when wallet is secondary/bottom)
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "7B7B7B"))
                        .opacity(showingWalletCurrency ? 0 : 1)
                    
                    Text(walletDisplay)
                        .font(.custom(showingWalletCurrency ? "Inter-Bold" : "Inter-Medium", size: showingWalletCurrency ? 56 : 18))
                        .foregroundColor(showingWalletCurrency ? Color(hex: "080808") : Color(hex: "7B7B7B"))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .offset(y: showingWalletCurrency ? topOffset : bottomOffset)
                
                // Account currency amount (USD, EUR, etc.)
                HStack(spacing: 4) {
                    // Swap icon (visible when account is secondary/bottom)
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "7B7B7B"))
                        .opacity(showingWalletCurrency ? 1 : 0)
                    
                    Text(accountDisplay)
                        .font(.custom(showingWalletCurrency ? "Inter-Medium" : "Inter-Bold", size: showingWalletCurrency ? 18 : 56))
                        .foregroundColor(showingWalletCurrency ? Color(hex: "7B7B7B") : Color(hex: "080808"))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .offset(y: showingWalletCurrency ? bottomOffset : topOffset)
            }
            .frame(height: 100)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddMoneyView(isPresented: .constant(true))
}
