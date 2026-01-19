import SwiftUI
import UIKit

struct BalanceView: View {
    @StateObject private var portfolioService = PortfolioService.shared
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: portfolioService.cashBalance)) ?? "£0.00"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Balance")
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(Color(hex: "7B7B7B"))
                .accessibilityAddTraits(.isHeader)
            
            Text(formattedBalance)
                .font(.custom("Inter-Bold", size: 33))
                .foregroundColor(Color(hex: "080808"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }
}

#Preview {
    BalanceView()
        .padding()
}
