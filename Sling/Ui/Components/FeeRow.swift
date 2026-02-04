import SwiftUI

/// Reusable component for displaying fee information in transaction confirmations
struct FeeRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    let fee: FeeResult
    var onTap: (() -> Void)? = nil
    
    /// Fixed fee based on storage currency (-$0.50 or -€0.50)
    private var fixedFeeDisplay: String {
        let symbol = displayCurrencyService.storageCurrency == "EUR" ? "€" : "$"
        return "-\(symbol)0.50"
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap?()
        }) {
            HStack {
                Text("Fees")
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(themeService.textSecondaryColor)
                
                Spacer()
                
                if fee.isFree {
                    // Free fee
                    Text("No fee")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                } else {
                    // Fee applies - always show fixed $0.50 or €0.50 in orange
                    Text(fixedFeeDisplay)
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(Color(hex: "FF5113"))
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Compact fee display for inline use
struct FeeLabel: View {
    @ObservedObject private var themeService = ThemeService.shared
    let fee: FeeResult
    
    init(fee: FeeResult) {
        self.fee = fee
    }
    
    var body: some View {
        if fee.isFree {
            Text("No fee")
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(themeService.textPrimaryColor)
        } else {
            Text(fee.formattedCombined)
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(themeService.textPrimaryColor)
        }
    }
}

/// Fee card for settings/info pages showing fee schedule
struct FeeInfoCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var feeService = FeeService.shared
    
    let transactionType: String
    let description: String
    let isFree: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(transactionType)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Text(description)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
            }
            
            Spacer()
            
            if isFree {
                Text("Free")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(Color.appPositiveGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appPositiveGreen.opacity(0.1))
                    .cornerRadius(8)
            } else {
                let symbol = feeService.accountStablecoin == "EURC" ? "€" : "$"
                Text(feeService.baseFee.asCurrency(symbol))
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(themeService.textPrimaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeService.currentTheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F7F7F7"))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(themeService.cardBackgroundColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "EDEDED"), lineWidth: 1)
        )
    }
}


#Preview("FeeRow - Free") {
    VStack(spacing: 16) {
        FeeRow(fee: .free)
        
        FeeRow(fee: FeeResult(
            amount: 0.40,
            stablecoin: "GBP",
            displayAmount: 0.40,
            displayCurrency: "GBP",
            isWaived: false,
            waiverReason: nil
        ))
    }
    .padding()
    .background(Color.white)
}

#Preview("FeeInfoCard") {
    VStack(spacing: 16) {
        FeeInfoCard(
            transactionType: "Send to Sling users",
            description: "P2P payments are always free",
            isFree: true
        )
        
        FeeInfoCard(
            transactionType: "Foreign currency deposit",
            description: "Depositing non-local currency",
            isFree: false
        )
    }
    .padding()
    .background(Color(hex: "F7F7F7"))
}
