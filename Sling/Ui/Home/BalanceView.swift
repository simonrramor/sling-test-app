import SwiftUI
import UIKit

struct BalanceView: View {
    @StateObject private var portfolioService = PortfolioService.shared
    @StateObject private var exchangeRateService = ExchangeRateService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @State private var displayBalance: Double?
    
    var onAddMoney: (() -> Void)? = nil
    
    // USD balance (stored value)
    var usdBalance: Double {
        portfolioService.cashBalance
    }
    
    // Formatted USD balance for subtitle
    var formattedUSDBalance: String {
        ExchangeRateService.format(amount: usdBalance, currency: "USD")
    }
    
    // Formatted display currency balance
    var formattedDisplayBalance: String {
        if let displayAmount = displayBalance {
            return ExchangeRateService.format(amount: displayAmount, currency: portfolioService.displayCurrency)
        }
        // Fallback while loading - show USD with display currency symbol
        return ExchangeRateService.format(amount: usdBalance, currency: portfolioService.displayCurrency)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            // Left side: Balance info
            VStack(alignment: .leading, spacing: 4) {
                // Subtitle: "Cash balance ・ $X,XXX.XX"
                HStack(spacing: 0) {
                    Text("Cash balance")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    Text("・")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    Text(formattedUSDBalance)
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
        .padding(.vertical, 16)
        .task {
            await updateDisplayBalance()
        }
        .onChange(of: portfolioService.cashBalance) { _, _ in
            Task { await updateDisplayBalance() }
        }
        .onChange(of: portfolioService.displayCurrency) { _, _ in
            Task { await updateDisplayBalance() }
        }
    }
    
    private func updateDisplayBalance() async {
        let converted = await exchangeRateService.convert(
            amount: usdBalance,
            from: "USD",
            to: portfolioService.displayCurrency
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
