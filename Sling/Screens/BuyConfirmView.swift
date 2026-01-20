import SwiftUI
import UIKit
import Combine

struct BuyConfirmView: View {
    let stock: Stock
    let amount: Double
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @Binding var isBuyFlowPresented: Bool
    var onComplete: () -> Void = {}
    
    @State private var showPendingScreen = false
    @State private var isButtonLoading = false
    @State private var quoteTimeRemaining: Int = 30
    @State private var currentStockPrice: Double? = nil
    
    // Timer for quote countdown
    let quoteTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Get current stock price from service (or use cached quote price)
    var stockPrice: Double {
        currentStockPrice ?? StockService.shared.stockData[stock.iconName]?.currentPrice ?? 100
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
                            .foregroundColor(themeService.textSecondaryColor)
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
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Amount display - centered between header and details
                Text(String(format: "£%.0f", amount))
                    .font(.custom("Inter-Bold", size: 62))
                    .foregroundColor(themeService.textPrimaryColor)
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
                    
                    // Quote validity countdown
                    QuoteValidityRow(secondsRemaining: quoteTimeRemaining)
                    
                    // Aprox share price
                    DetailRow(
                        label: "Aprox share price",
                        value: String(format: "~$%.2f", stockPrice),
                        isHighlighted: true
                    )
                    
                    // Aprox shares
                    DetailRow(
                        label: "Aprox shares",
                        value: String(format: "~%.2f", numberOfShares)
                    )
                    
                    // Platform fee
                    DetailRow(
                        label: "Platform fee",
                        value: String(format: "$%.2f", platformFee),
                        isHighlighted: true
                    )
                    
                    // Total cost
                    DetailRow(
                        label: "Total cost",
                        value: String(format: "$%.2f", totalCost)
                    )
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Buy button - shrinks then transitions to pending screen
                ShrinkingButton(
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
                        
                        // Show pending screen immediately after shrink
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
                    .foregroundColor(themeService.textPrimaryColor)
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
        .onAppear {
            // Initialize with current price
            currentStockPrice = StockService.shared.stockData[stock.iconName]?.currentPrice ?? 100
        }
        .onReceive(quoteTimer) { _ in
            // Don't count down if loading or showing pending screen
            guard !isButtonLoading && !showPendingScreen else { return }
            
            if quoteTimeRemaining > 0 {
                quoteTimeRemaining -= 1
            } else {
                // Refresh the quote
                refreshQuote()
            }
        }
    }
    
    private func refreshQuote() {
        // Get fresh price from service
        let newPrice = StockService.shared.stockData[stock.iconName]?.currentPrice ?? 100
        
        // Add small random variation to simulate real market movement (±0.5%)
        let variation = Double.random(in: -0.005...0.005)
        currentStockPrice = newPrice * (1 + variation)
        
        // Reset timer
        quoteTimeRemaining = 30
        
        // Haptic feedback to indicate refresh
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Quote Validity Row

struct QuoteValidityRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let secondsRemaining: Int
    let totalSeconds: Int = 30
    
    private var progress: Double {
        Double(secondsRemaining) / Double(totalSeconds)
    }
    
    var body: some View {
        HStack {
            Text("Quote valid for")
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(themeService.textSecondaryColor)
            
            Spacer()
            
            HStack(spacing: 6) {
                // Animated countdown clock
                CountdownClockIcon(progress: progress)
                    .frame(width: 14, height: 14)
                
                Text("\(secondsRemaining)s")
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Countdown Clock Icon

struct CountdownClockIcon: View {
    let progress: Double // 1.0 = full, 0.0 = empty
    
    private let iconColor = Color(hex: "7B7B7B")
    private let fillColor = Color(hex: "E8E8E8")
    
    var body: some View {
        ZStack {
            // Background circle (full)
            Circle()
                .fill(fillColor)
            
            // Progress fill (pie slice that depletes)
            PieSlice(progress: progress)
                .fill(iconColor.opacity(0.3))
            
            // Clock hands
            ClockHands(progress: progress, color: iconColor)
        }
    }
}

// Pie slice shape for the countdown fill (depletes clockwise)
struct PieSlice: Shape {
    var progress: Double
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Start at 12 o'clock, draw clockwise based on remaining progress
        // When progress = 1.0, full circle; when progress = 0.0, empty
        let startAngle = Angle(degrees: -90)
        let endAngle = Angle(degrees: -90 + (360 * (1 - progress)))
        
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

struct ClockHands: View {
    let progress: Double
    let color: Color
    
    // The minute hand rotates clockwise as time decreases
    // At progress = 1.0 (30s), hand at 12 o'clock (0°)
    // At progress = 0.0 (0s), hand completes full rotation (360°)
    private var minuteHandRotation: Double {
        360 * (1 - progress)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let handLength = geometry.size.width * 0.3
            
            Path { path in
                // Hour hand (static, pointing to 12)
                path.move(to: center)
                path.addLine(to: CGPoint(x: center.x, y: center.y - handLength * 0.6))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            
            Path { path in
                // Minute hand (rotates with countdown)
                path.move(to: center)
                path.addLine(to: CGPoint(x: center.x, y: center.y - handLength))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .rotationEffect(.degrees(minuteHandRotation), anchor: .center)
            
            // Center dot
            Circle()
                .fill(color)
                .frame(width: 3, height: 3)
                .position(center)
        }
    }
}

struct DetailRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let label: String
    let value: String
    var showSlingIcon: Bool = false
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(themeService.textSecondaryColor)
            
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
                    .foregroundColor(isHighlighted ? Color(hex: "FF5113") : themeService.textPrimaryColor)
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
