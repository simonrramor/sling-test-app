import SwiftUI

struct SellPendingView: View {
    @ObservedObject private var themeService = ThemeService.shared
    let stock: Stock
    let amount: Double
    let numberOfShares: Double
    var onComplete: () -> Void = {}
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    // Stock avatar
                    Image(stock.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    
                    // Stock name
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            Text("Sell")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                            Text("·")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                            Text(stock.symbol)
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                        }
                        Text(stock.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                
                Spacer()
                
                // Amount display
                Text(String(format: "£%.0f", amount))
                    .font(.custom("Inter-Bold", size: 62))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                // Orange circle with loader that transitions to checkmark
                ZStack {
                    // Orange background circle
                    Circle()
                        .fill(Color(hex: "FF5113"))
                        .frame(width: 56, height: 56)
                    
                    // Loader animation (spinner → checkmark)
                    LoaderWithCheckmark(onComplete: onComplete)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    SellPendingView(
        stock: Stock(
            name: "Apple Inc",
            symbol: "AAPL",
            price: "$178.50",
            change: "1.23%",
            isPositive: true,
            iconName: "StockApple"
        ),
        amount: 100,
        numberOfShares: 0.56,
        onComplete: {}
    )
}
