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
    
    @State private var isButtonLoading = false
    @State private var quoteTimeRemaining: Int = 30
    @State private var currentStockPrice: Double? = nil
    @State private var showSharesInfo = false
    
    // Timer for quote countdown
    let quoteTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Get current stock price from service (or use cached quote price)
    var stockPrice: Double {
        currentStockPrice ?? OndoService.shared.tokenData[stock.iconName]?.currentPrice ?? 100
    }
    
    // Platform fee is 50 basis points (0.50%) of the purchase amount
    var platformFee: Double {
        amount * 0.005
    }
    
    // Amount that actually goes to buying stocks (after fee)
    var totalStockPurchase: Double {
        amount - platformFee
    }
    
    var numberOfShares: Double {
        totalStockPurchase / stockPrice
    }
    
    var formattedShares: String {
        String(format: "%.2f", numberOfShares)
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
                .padding(.horizontal, 16)
                .frame(height: 64)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Amount display - centered between header and details
                Text("$\(NumberFormatService.shared.formatWholeNumber(amount))")
                    .font(.custom("Inter-Bold", size: 62))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                // Details section
                VStack(spacing: 4) {
                    // From
                    DetailRow(
                        label: "From",
                        value: "Sling balance",
                        showSlingIcon: true
                    )
                    
                    // Quote validity countdown
                    QuoteValidityRow(secondsRemaining: quoteTimeRemaining)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    // Amount
                    DetailRow(
                        label: "Amount",
                        value: amount.asUSD
                    )
                    
                    // Platform fee
                    DetailRow(
                        label: "Platform fee",
                        value: "-" + platformFee.asUSD,
                        isHighlighted: true
                    )
                    
                    // Price
                    DetailRow(
                        label: "Price",
                        value: "1 \(stock.symbol) = \(stockPrice.asUSD)",
                        isHighlighted: true
                    )
                    
                    // Estimated shares (tappable)
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showSharesInfo = true
                    }) {
                        DetailRow(
                            label: "Estimated shares",
                            value: String(format: "%.2f", numberOfShares),
                            isHighlighted: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
                .padding(.horizontal, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Confirm button with smooth loading animation
                LoadingButton(
                    title: "Confirm",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
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
                        
                        // Dismiss buy flow and stay on invest page
                        isBuyFlowPresented = false
                        onComplete()
                    } else {
                        // Reset loading state if purchase failed
                        isButtonLoading = false
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
        .onAppear {
            // Initialize with current price
            currentStockPrice = OndoService.shared.tokenData[stock.iconName]?.currentPrice ?? 100
        }
        .overlay {
            if showSharesInfo {
                EstimatedSharesInfoSheet(isPresented: $showSharesInfo)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSharesInfo)
        .onReceive(quoteTimer) { _ in
            // Don't count down if loading
            guard !isButtonLoading else { return }
            
            if quoteTimeRemaining > 0 {
                quoteTimeRemaining -= 1
            } else {
                // Refresh the quote
                refreshQuote()
            }
        }
    }
    
    private func refreshQuote() {
        // Fetch fresh price data from API
        Task {
            await OndoService.shared.fetchToken(iconName: stock.iconName)
            
            await MainActor.run {
                // Get updated price from service
                let newPrice = OndoService.shared.tokenData[stock.iconName]?.currentPrice ?? currentStockPrice ?? 100
                
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
            Text("Quote valid")
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

// MARK: - Estimated Shares Info Sheet

struct EstimatedSharesInfoSheet: View {
    @Binding var isPresented: Bool
    @State private var showCard = false
    @State private var dragOffset: CGFloat = 0
    
    private var deviceCornerRadius: CGFloat {
        UIScreen.displayCornerRadius
    }
    
    private var stretchScale: CGFloat {
        guard dragOffset > 0 else { return 1.0 }
        let stretchAmount = dragOffset / 150.0 * 0.08
        return 1.0 + min(stretchAmount, 0.08)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            Color.black.opacity(showCard ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissSheet()
                }
                .animation(.easeOut(duration: 0.25), value: showCard)
            
            // Sheet content
            if showCard {
                VStack(spacing: 0) {
                    // Drawer handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What are estimated shares?")
                            .font(.custom("Inter-Bold", size: 24))
                            .tracking(-0.48)
                            .foregroundColor(Color(hex: "080808"))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("When you buy a stock, the number of shares you receive is estimated based on the current market price at the time of your order.")
                                .font(.custom("Inter-Regular", size: 16))
                                .tracking(-0.32)
                                .foregroundColor(Color(hex: "7B7B7B"))
                            
                            Text("The final number of shares may vary slightly due to price movements between when you place your order and when it's executed. The actual shares will be confirmed once the order is complete.")
                                .font(.custom("Inter-Regular", size: 16))
                                .tracking(-0.32)
                                .foregroundColor(Color(hex: "7B7B7B"))
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        // Done button
                        Button(action: {
                            dismissSheet()
                        }) {
                            Text("Done")
                                .font(.custom("Inter-Bold", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: DesignSystem.Button.height)
                                .background(Color(hex: "080808"))
                                .cornerRadius(DesignSystem.CornerRadius.large)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
                .background(Color(hex: "F2F2F2"))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 40,
                        bottomLeadingRadius: deviceCornerRadius,
                        bottomTrailingRadius: deviceCornerRadius,
                        topTrailingRadius: 40,
                        style: .continuous
                    )
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .scaleEffect(x: 1.0, y: stretchScale, anchor: .bottom)
                .offset(y: min(0, -dragOffset))
                .transition(.move(edge: .bottom))
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            let translation = value.translation.height
                            if translation > 0 {
                                dragOffset = -translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                dismissSheet()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showCard = true
            }
        }
    }
    
    private func dismissSheet() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            showCard = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}
