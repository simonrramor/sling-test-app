import SwiftUI
import UIKit

struct BuyConfirmView: View {
    let stock: Stock
    let amount: Double
    @Binding var isPresented: Bool
    @Binding var isBuyFlowPresented: Bool
    var onComplete: () -> Void = {}
    
    @State private var showPendingScreen = false
    @State private var isButtonLoading = false
    
    // Get current stock price from service
    var stockPrice: Double {
        StockService.shared.stockData[stock.iconName]?.currentPrice ?? 100
    }
    
    var numberOfShares: Double {
        amount / stockPrice
    }
    
    var formattedShares: String {
        String(format: "%.2f", numberOfShares)
    }
    
    var platformFee: Double {
        3.00
    }
    
    var totalCost: Double {
        amount
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
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Amount display - centered between header and details
                Text(String(format: "£%.0f", amount))
                    .font(.custom("Inter-Bold", size: 62))
                    .foregroundColor(Color(hex: "080808"))
                    .opacity(isButtonLoading ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Details section
                VStack(spacing: 0) {
                    // From
                    DetailRow(
                        label: "From",
                        value: "Sling balance",
                        showSlingIcon: true
                    )
                    
                    // Speed
                    DetailRow(
                        label: "Speed",
                        value: "Instant"
                    )
                    
                    // Divider
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    // Price
                    DetailRow(
                        label: "Price",
                        value: String(format: "1 %@ = $%.2f", stock.symbol, stockPrice),
                        isHighlighted: true
                    )
                    
                    // Number of shares
                    DetailRow(
                        label: "No. of shares (estimated)",
                        value: formattedShares
                    )
                    
                    // Platform fee
                    DetailRow(
                        label: "Platform fee",
                        value: String(format: "£%.2f", platformFee),
                        isHighlighted: true
                    )
                    
                    // Total cost
                    DetailRow(
                        label: "Total cost",
                        value: String(format: "£%.2f", totalCost)
                    )
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Buy button with animation
                AnimatedLoadingButton(
                    title: "Buy \(formattedShares) \(stock.symbol)",
                    isLoadingBinding: $isButtonLoading
                ) {
                    // Execute the purchase through PortfolioService
                    let success = PortfolioService.shared.buy(
                        iconName: stock.iconName,
                        symbol: stock.symbol,
                        shares: numberOfShares,
                        pricePerShare: stockPrice
                    )
                    
                    // Only record activity and show success if purchase succeeded
                    if success {
                        // Record the transaction in activity feed
                        ActivityService.shared.recordBuyStock(
                            stockName: stock.name,
                            stockIcon: stock.iconName,
                            amount: amount,
                            shares: numberOfShares,
                            symbol: stock.symbol
                        )
                        
                        // Show pending screen
                        showPendingScreen = true
                    } else {
                        // Reset loading state if purchase failed
                        isButtonLoading = false
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            // Centered amount overlay (appears when loading)
            if isButtonLoading {
                Text(String(format: "£%.0f", amount))
                    .font(.custom("Inter-Bold", size: 62))
                    .foregroundColor(Color(hex: "080808"))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
        .overlay {
            if showPendingScreen {
                BuyPendingView(
                    stock: stock,
                    amount: amount,
                    numberOfShares: numberOfShares,
                    onComplete: onComplete
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showPendingScreen)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var showSlingIcon: Bool = false
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(Color(hex: "7B7B7B"))
            
            Spacer()
            
            HStack(spacing: 6) {
                if showSlingIcon {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "FF5113"))
                            .frame(width: 18, height: 18)
                        
                        Image("SlingLogo")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                }
                
                Text(value)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(isHighlighted ? Color(hex: "FF5113") : Color(hex: "080808"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

#Preview {
    BuyConfirmView(
        stock: Stock(
            name: "Meta",
            symbol: "META",
            price: "$620.80",
            change: "0.43%",
            isPositive: true,
            iconName: "StockMeta"
        ),
        amount: 1000,
        isPresented: .constant(true),
        isBuyFlowPresented: .constant(true)
    )
}
