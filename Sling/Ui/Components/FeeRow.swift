import SwiftUI

/// Reusable component for displaying fee information in transaction confirmations
struct FeeRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let fee: FeeResult
    
    var body: some View {
        HStack {
            Text("Fees")
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(themeService.textSecondaryColor)
            
            Spacer()
            
            if fee.isFree {
                // Free or waived fee
                VStack(alignment: .trailing, spacing: 2) {
                    Text("No fee")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(Color(hex: "57CE43"))
                    
                    if let reason = fee.waiverReason, fee.isWaived {
                        Text(reason)
                            .font(.custom("Inter-Regular", size: 12))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                }
            } else {
                // Fee applies
                Text(fee.formattedCombined)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

/// Compact fee display for inline use
struct FeeLabel: View {
    let fee: FeeResult
    let showWaiverReason: Bool
    
    init(fee: FeeResult, showWaiverReason: Bool = false) {
        self.fee = fee
        self.showWaiverReason = showWaiverReason
    }
    
    var body: some View {
        if fee.isFree {
            HStack(spacing: 4) {
                Text("No fee")
                    .foregroundColor(Color(hex: "57CE43"))
                
                if showWaiverReason, let reason = fee.waiverReason, fee.isWaived {
                    Text("•")
                        .foregroundColor(Color(hex: "7B7B7B"))
                    Text(reason)
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
            }
            .font(.custom("Inter-Medium", size: 14))
        } else {
            Text(fee.formattedCombined)
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(Color(hex: "080808"))
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
                    .foregroundColor(Color(hex: "57CE43"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "57CE43").opacity(0.1))
                    .cornerRadius(8)
            } else {
                let symbol = feeService.accountStablecoin == "EURC" ? "€" : "$"
                Text("\(symbol)\(String(format: "%.2f", feeService.baseFee))")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(themeService.textPrimaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "F7F7F7"))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "EDEDED"), lineWidth: 1)
        )
    }
}

/// Fee waiver banner for promotions
struct FeeWaiverBanner: View {
    @ObservedObject private var feeService = FeeService.shared
    
    var body: some View {
        if feeService.freeTransfersRemaining > 0 || feeService.isEarlyAdopter {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "FF5113"))
                
                VStack(alignment: .leading, spacing: 2) {
                    if feeService.isEarlyAdopter {
                        Text("Early Adopter Bonus")
                            .font(.custom("Inter-Bold", size: 14))
                            .foregroundColor(Color(hex: "080808"))
                        Text("All fees waived")
                            .font(.custom("Inter-Regular", size: 13))
                            .foregroundColor(Color(hex: "7B7B7B"))
                    } else {
                        Text("\(feeService.freeTransfersRemaining) Free Transfer\(feeService.freeTransfersRemaining == 1 ? "" : "s")")
                            .font(.custom("Inter-Bold", size: 14))
                            .foregroundColor(Color(hex: "080808"))
                        Text("Foreign currency fees waived")
                            .font(.custom("Inter-Regular", size: 13))
                            .foregroundColor(Color(hex: "7B7B7B"))
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(hex: "FF5113").opacity(0.08))
            .cornerRadius(16)
        }
    }
}

#Preview("FeeRow - Free") {
    VStack(spacing: 16) {
        FeeRow(fee: .free)
        
        FeeRow(fee: FeeResult(
            amount: 0.50,
            stablecoin: "USDP",
            displayAmount: 0.40,
            displayCurrency: "GBP",
            isWaived: true,
            waiverReason: "2 free transfers remaining"
        ))
        
        FeeRow(fee: FeeResult(
            amount: 0.50,
            stablecoin: "USDP",
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
