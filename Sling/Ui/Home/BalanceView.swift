import SwiftUI
import UIKit

struct BalanceView: View {
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @ObservedObject private var exchangeRateService = ExchangeRateService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @State private var displayBalance: Double?
    
    var onAddMoney: (() -> Void)? = nil
    var onBalanceTap: (() -> Void)? = nil
    
    // Storage currency balance (stored value)
    var storageBalance: Double {
        portfolioService.cashBalance
    }
    
    // Formatted storage currency balance for subtitle
    var formattedStorageBalance: String {
        ExchangeRateService.format(amount: storageBalance, currency: displayCurrencyService.storageCurrency)
    }
    
    // Formatted display currency balance
    var formattedDisplayBalance: String {
        if let displayAmount = displayBalance {
            return ExchangeRateService.format(amount: displayAmount, currency: displayCurrencyService.displayCurrency)
        }
        // Fallback while loading - show storage balance with display currency symbol
        return ExchangeRateService.format(amount: storageBalance, currency: displayCurrencyService.displayCurrency)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            // Left side: Balance info - tappable to show currency sheet
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onBalanceTap?()
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    // Subtitle: "Cash balance ・ $X,XXX.XX"
                    HStack(spacing: 0) {
                        Text("Cash balance")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Text("・")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Text(formattedStorageBalance)
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                    
                    // Main balance in display currency (animated) - H1 style from Figma
                    SlidingNumberText(
                        text: formattedDisplayBalance,
                        font: .custom("Inter-Bold", size: 48),
                        color: themeService.textPrimaryColor
                    )
                    .tracking(-0.96) // -2% letter spacing at 48pt
                }
            }
            .buttonStyle(PressedButtonStyle())
            
            Spacer()
            
            // Right side: Add money button (secondary small)
            if let onAddMoney = onAddMoney {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onAddMoney()
                }) {
                    Text("Add money")
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(height: 36)
                        .background(Color(hex: "080808"))
                        .cornerRadius(12)
                }
                .buttonStyle(PressedButtonStyle())
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .task {
            await updateDisplayBalance()
        }
        .onChange(of: portfolioService.cashBalance) { _, _ in
            Task { await updateDisplayBalance() }
        }
        .onChange(of: displayCurrencyService.displayCurrency) { _, _ in
            Task { await updateDisplayBalance() }
        }
        .onChange(of: displayCurrencyService.storageCurrency) { _, _ in
            Task { await updateDisplayBalance() }
        }
    }
    
    private func updateDisplayBalance() async {
        let converted = await exchangeRateService.convert(
            amount: storageBalance,
            from: displayCurrencyService.storageCurrency,
            to: displayCurrencyService.displayCurrency
        )
        await MainActor.run {
            displayBalance = converted
        }
    }
}

#Preview {
    BalanceView(onAddMoney: {})
        .padding()
}
