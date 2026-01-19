import SwiftUI
import UIKit

struct AddMoneyPendingView: View {
    let amount: Double
    var onComplete: () -> Void = {}
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "£\(amount)"
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    // Empty space for back button
                    Color.clear
                        .frame(width: 24, height: 24)
                    
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
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                
                Spacer()
                
                // Amount display
                Text(formattedAmount)
                    .font(.custom("Inter-Bold", size: 56))
                    .foregroundColor(Color(hex: "080808"))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Spacer()
                
                // Orange circle with loader that transitions to checkmark
                ZStack {
                    // Orange background circle
                    Circle()
                        .fill(Color(hex: "FF5113"))
                        .frame(width: 64, height: 64)
                    
                    // Loader animation (spinner → checkmark)
                    LoaderWithCheckmark(onComplete: onComplete)
                }
                .frame(height: 80)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    AddMoneyPendingView(amount: 100)
}
