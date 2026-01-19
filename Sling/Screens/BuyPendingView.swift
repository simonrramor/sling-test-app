import SwiftUI

struct BuyPendingView: View {
    let stock: Stock
    let amount: Double
    let numberOfShares: Double
    var onComplete: () -> Void = {}
    
    @State private var showHeader = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - starts hidden, fades in when animation completes
                HStack(spacing: 16) {
                    Image(stock.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            Text("Buy")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(Color(hex: "7B7B7B"))
                            Text("·")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(Color(hex: "7B7B7B"))
                            Text(stock.symbol)
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(Color(hex: "7B7B7B"))
                        }
                        Text(stock.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                .opacity(showHeader ? 1 : 0)
                
                Spacer()
                
                // Amount display
                Text(String(format: "£%.0f", amount))
                    .font(.custom("Inter-Bold", size: 62))
                    .foregroundColor(Color(hex: "080808"))
                
                Spacer()
                
                // Lottie animation
                ZStack {
                    Circle()
                        .fill(Color(hex: "FF5113"))
                        .frame(width: 56, height: 56)
                    
                    LoaderWithCheckmark {
                        // Animation complete - fade in header
                        withAnimation(.easeOut(duration: 0.4)) {
                            showHeader = true
                        }
                        
                        // Call onComplete after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onComplete()
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    BuyPendingView(
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
