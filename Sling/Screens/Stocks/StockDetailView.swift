import SwiftUI
import UIKit

// #region agent log
@discardableResult
func debugLog(location: String, message: String, data: [String: Any], hypothesisId: String) -> Bool {
    let dataStr = data.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    print("🔍 [\(hypothesisId)] \(location): \(message) | \(dataStr)")
    return true
}
// #endregion

struct StockDetailView: View {
    let stock: Stock
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var ondoService = OndoService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var portfolioService = PortfolioService.shared
    @State private var selectedPeriod = "1D"
    @State private var isDragging = false
    @State private var dragProgress: CGFloat = 1.0
    @State private var chartData: [CGFloat] = []
    @State private var showBuyScreen = false
    @State private var showSellScreen = false
    
    // Check if user owns this stock
    var ownsStock: Bool {
        portfolioService.ownsStock(stock.iconName)
    }
    
    var sharesOwned: Double {
        portfolioService.sharesOwned(for: stock.iconName)
    }
    
    // Primary colors for each stock (brand colors from logos)
    var primaryColor: Color {
        switch stock.iconName {
        case "StockAmazon":
            return Color(hex: "FF9900")  // Amazon orange
        case "StockApple":
            return Color(hex: "000000")  // Apple black
        case "StockBankOfAmerica":
            return Color(hex: "012169")  // Bank of America blue
        case "StockCircle":
            return Color(hex: "00D4AA")  // Circle teal
        case "StockCoinbase":
            return Color(hex: "0052FF")  // Coinbase blue
        case "StockGoogle":
            return Color(hex: "4285F4")  // Google blue
        case "StockMcDonalds":
            return Color(hex: "FFC72C")  // McDonald's yellow/gold
        case "StockMeta":
            return Color(hex: "0668E1")  // Meta blue
        case "StockMicrosoft":
            return Color(hex: "00A4EF")  // Microsoft blue
        case "StockTesla":
            return Color(hex: "E82127")  // Tesla red
        case "StockVisa":
            return Color(hex: "1A1F71")  // Visa blue
        default:
            return Color(hex: "080808")
        }
    }
    
    // Get real price data from Ondo service
    var stockData: OndoTokenPriceData? {
        ondoService.tokenData[stock.iconName]
    }
    
    // Display price based on drag position
    var displayPrice: String {
        guard let data = stockData else { return stock.price }
        
        if isDragging {
            let price = data.priceAt(progress: Double(dragProgress))
            return String(format: "$%.2f", price)
        } else {
            return data.formattedPrice
        }
    }
    
    // Display change based on drag position
    var displayChange: String {
        guard let data = stockData else { return stock.change }
        
        let progress = isDragging ? Double(dragProgress) : 1.0
        let change = data.changeAt(progress: progress)
        return String(format: "%.2f%%", abs(change.percent))
    }
    
    var displayIsPositive: Bool {
        guard let data = stockData else { return stock.isPositive }
        
        let progress = isDragging ? Double(dragProgress) : 1.0
        let change = data.changeAt(progress: progress)
        return change.isPositive
    }
    
    var body: some View {
        // #region agent log
        let _ = debugLog(location: "StockDetailView:body", message: "View rendered", data: ["stock": stock.name], hypothesisId: "A")
        // #endregion
        GeometryReader { rootGeo in
            // #region agent log
            let _ = debugLog(location: "StockDetailView:rootGeo", message: "Root geometry", data: ["width": rootGeo.size.width, "height": rootGeo.size.height, "safeTop": rootGeo.safeAreaInsets.top, "safeBottom": rootGeo.safeAreaInsets.bottom, "safeLeading": rootGeo.safeAreaInsets.leading, "safeTrailing": rootGeo.safeAreaInsets.trailing], hypothesisId: "A,B")
            // #endregion
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeService.textSecondaryColor)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Close")
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // #region agent log
                        GeometryReader { scrollGeo in
                            Color.clear.onAppear {
                                debugLog(location: "StockDetailView:scrollContent", message: "ScrollView content size", data: ["contentWidth": scrollGeo.size.width, "contentHeight": scrollGeo.size.height, "frameWidth": scrollGeo.frame(in: .global).width], hypothesisId: "C,E")
                            }
                        }.frame(height: 0)
                        // #endregion
                        // Stock info card
                        VStack(alignment: .leading, spacing: 24) {
                            // Stock avatar
                            Image(stock.iconName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 1.8)
                                )
                            
                            // Name/Symbol row with Price/Change
                            HStack(alignment: .top) {
                                // Stock name and symbol
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stock.name)
                                        .font(.custom("Inter-Bold", size: 24))
                                        .foregroundColor(themeService.textPrimaryColor)
                                    
                                    Text(stock.symbol)
                                        .font(.custom("Inter-Regular", size: 14))
                                        .foregroundColor(themeService.textSecondaryColor)
                                }
                                
                                Spacer()
                                
                                // Price and change
                                VStack(alignment: .trailing, spacing: 2) {
                                    SlidingNumberText(
                                        text: displayPrice,
                                        font: .custom("Inter-Bold", size: 24),
                                        color: themeService.textPrimaryColor
                                    )
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: displayIsPositive ? "arrow.up" : "arrow.down")
                                            .font(.system(size: 10, weight: .bold))
                                        SlidingNumberText(
                                            text: displayChange,
                                            font: .custom("Inter-Regular", size: 14),
                                            color: displayIsPositive ? Color(hex: "57CE43") : Color(hex: "E30000")
                                        )
                                    }
                                    .foregroundColor(displayIsPositive ? Color(hex: "57CE43") : Color(hex: "E30000"))
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(themeService.cardBackgroundColor)
                        )
                        .padding(.horizontal, 8)
                        .animation(.easeInOut(duration: 0.1), value: dragProgress)
                        
                        // Chart
                        StockChartView(
                            selectedPeriod: $selectedPeriod,
                            isDragging: $isDragging,
                            dragProgress: $dragProgress,
                            chartColor: primaryColor,
                            chartData: chartData
                        )
                        
                        // Your investment section (only if user owns shares)
                        if ownsStock {
                            YourInvestmentSection(
                                stock: stock,
                                sharesOwned: sharesOwned,
                                currentPrice: stockData?.currentPrice ?? 0,
                                portfolioService: portfolioService
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 24)
                        }
                        
                        // About section
                        if !stock.description.isEmpty {
                            AboutSection(description: stock.description)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        }
                        
                        // Info section (at bottom)
                        InfoSection(stock: stock)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Bottom buttons
                HStack(spacing: 8) {
                    // Sell button - active only when user owns shares
                    Button(action: {
                        if ownsStock {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showSellScreen = true
                        }
                    }) {
                        Text("Sell")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(ownsStock ? themeService.textPrimaryColor : themeService.textTertiaryColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(ownsStock ? (themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "EDEDED")) : (themeService.currentTheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F7F7F7")))
                            .cornerRadius(20)
                    }
                    .disabled(!ownsStock)
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showBuyScreen = true
                    }) {
                        Text("Buy")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.currentTheme == .dark ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(themeService.textPrimaryColor)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0), Color.white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .allowsHitTesting(false),
                    alignment: .top
                )
            }
        }
        .onAppear {
            fetchChartData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            fetchChartData()
        }
        .overlay {
            if showBuyScreen {
                BuyStockView(stock: stock, isPresented: $showBuyScreen, onComplete: {
                    dismiss()
                })
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .overlay {
            if showSellScreen {
                SellStockView(stock: stock, isPresented: $showSellScreen, onComplete: {
                    dismiss()
                })
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showBuyScreen)
        .animation(.easeInOut(duration: 0.3), value: showSellScreen)
        } // Close GeometryReader
    }

    private func fetchChartData() {
        Task {
            await ondoService.fetchTokenForPeriod(iconName: stock.iconName, period: selectedPeriod)
            if let data = ondoService.tokenData[stock.iconName] {
                await MainActor.run {
                    // Use more points for detailed chart (50 points gives good detail)
                    chartData = ondoService.samplePrices(data.historicalPrices, to: 50)
                }
            }
        }
    }
}

struct YourInvestmentSection: View {
    @ObservedObject private var themeService = ThemeService.shared
    let stock: Stock
    let sharesOwned: Double
    let currentPrice: Double
    let portfolioService: PortfolioService
    
    var holdingValue: Double {
        sharesOwned * currentPrice
    }
    
    var profitLoss: (amount: Double, percent: Double, isPositive: Bool) {
        let pl = portfolioService.holdingProfitLoss(for: stock.iconName)
        return (pl.value, pl.percent, pl.isPositive)
    }
    
    var portfolioPercent: Double {
        let totalValue = portfolioService.portfolioValue()
        guard totalValue > 0 else { return 0 }
        return (holdingValue / totalValue) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Your investment")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(themeService.textPrimaryColor)
                .padding(.bottom, 16)
                .accessibilityAddTraits(.isHeader)
            
            // Value and Shares row
            HStack(alignment: .top, spacing: 48) {
                // Value
                VStack(alignment: .leading, spacing: 4) {
                    Text("Value")
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                    Text(String(format: "$%.2f", holdingValue))
                        .font(.custom("Inter-Bold", size: 24))
                        .foregroundColor(themeService.textPrimaryColor)
                }
                
                // Number of shares
                VStack(alignment: .leading, spacing: 4) {
                    Text("No. of shares")
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                    Text(String(format: "%.2f", sharesOwned))
                        .font(.custom("Inter-Bold", size: 24))
                        .foregroundColor(themeService.textPrimaryColor)
                }
                
                Spacer()
            }
            .padding(.bottom, 24)
            
            // Details
            VStack(spacing: 8) {
                // Today's returns (simulated as small daily change)
                InvestmentDetailRow(
                    label: "Today's returns",
                    value: String(format: "%@$%.2f (%.2f%%)",
                                  profitLoss.isPositive ? "+" : "",
                                  profitLoss.amount * 0.05,
                                  profitLoss.percent * 0.05),
                    isPositive: profitLoss.isPositive
                )
                
                // Total return (total profit/loss)
                InvestmentDetailRow(
                    label: "Total return",
                    value: String(format: "%@$%.2f (%.2f%%)",
                                  profitLoss.isPositive ? "+" : "",
                                  profitLoss.amount,
                                  profitLoss.percent),
                    isPositive: profitLoss.isPositive
                )
                
                // Average purchase price
                InvestmentDetailRow(
                    label: "Average purchase price",
                    value: String(format: "$%.2f", portfolioService.holdings[stock.iconName]?.averageCost ?? 0),
                    isPositive: nil
                )
                
                // % of Portfolio
                InvestmentDetailRow(
                    label: "% of Portfolio",
                    value: String(format: "%.1f%%", portfolioPercent),
                    isPositive: nil
                )
            }
        }
        .background(Color.white)
    }
}

struct InvestmentDetailRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let label: String
    let value: String
    var isPositive: Bool?
    
    var valueColor: Color {
        if let isPositive = isPositive {
            return isPositive ? Color(hex: "57CE43") : Color(hex: "E30000")
        }
        return themeService.textPrimaryColor
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(themeService.textSecondaryColor)
            
            Spacer()
            
            Text(value)
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 4)
    }
}

struct InfoCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(themeService.textSecondaryColor)
            
            Spacer()
            
            Text(value)
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(themeService.textPrimaryColor)
        }
        .padding(.vertical, 4)
    }
}

// About section with company description
struct AboutSection: View {
    @ObservedObject private var themeService = ThemeService.shared
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("About")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(themeService.textPrimaryColor)
            
            // Description text
            Text(description)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(themeService.textSecondaryColor)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        // #region agent log
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    debugLog(location: "AboutSection", message: "About section size", data: ["width": geo.size.width, "descLength": description.count], hypothesisId: "D")
                }
            }
        )
        // #endregion
    }
}

// Info section with stock details
struct InfoSection: View {
    @ObservedObject private var themeService = ThemeService.shared
    let stock: Stock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Info")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(themeService.textPrimaryColor)
                .padding(.bottom, 16)
            
            // Info items
            VStack(spacing: 8) {
                InfoCard(title: "Market Cap", value: "$2.89T")
                InfoCard(title: "P/E Ratio", value: "28.5")
                InfoCard(title: "52 Week High", value: "$310.00")
                InfoCard(title: "52 Week Low", value: "$164.08")
                InfoCard(title: "Volume", value: "52.3M")
                InfoCard(title: "Avg Volume", value: "48.1M")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        // #region agent log
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    debugLog(location: "InfoSection", message: "Info section size", data: ["width": geo.size.width], hypothesisId: "D")
                }
            }
        )
        // #endregion
    }
}

// Stock-specific chart view with customizable color
struct StockChartView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Binding var selectedPeriod: String
    @Binding var isDragging: Bool
    @Binding var dragProgress: CGFloat
    var chartColor: Color
    var chartData: [CGFloat]
    @State private var lastHapticInterval: Int = -1
    @State private var animatedPoints: [CGFloat] = []

    let periods = ["1H", "1D", "1W", "1M", "1Y", "All"]
    
    // Source chart points - use chartData or fallback
    var sourceChartPoints: [CGFloat] {
        chartData.isEmpty ? [0.5, 0.5] : chartData
    }
    
    // Use animated points for display
    var chartPoints: [CGFloat] {
        animatedPoints.isEmpty ? normalizePoints(sourceChartPoints) : animatedPoints
    }
    
    // Normalize points to a standard count for smooth animation between different data sizes
    private func normalizePoints(_ points: [CGFloat], to count: Int = 20) -> [CGFloat] {
        guard points.count > 1 else { return Array(repeating: points.first ?? 0.5, count: count) }
        var result = [CGFloat]()
        for i in 0..<count {
            let progress = CGFloat(i) / CGFloat(count - 1)
            let exactIndex = progress * CGFloat(points.count - 1)
            let lowerIndex = Int(exactIndex)
            let upperIndex = min(lowerIndex + 1, points.count - 1)
            let fraction = exactIndex - CGFloat(lowerIndex)
            let interpolated = points[lowerIndex] + (points[upperIndex] - points[lowerIndex]) * fraction
            result.append(interpolated)
        }
        return result
    }
    
    func getYValue(at progress: CGFloat, height: CGFloat) -> CGFloat {
        guard !chartPoints.isEmpty else { return height / 2 }
        let count = chartPoints.count
        let exactIndex = progress * CGFloat(count - 1)
        let lowerIndex = Int(exactIndex)
        let upperIndex = min(lowerIndex + 1, count - 1)
        let fraction = exactIndex - CGFloat(lowerIndex)

        let lowerValue = chartPoints[lowerIndex]
        let upperValue = chartPoints[upperIndex]
        let interpolatedValue = lowerValue + (upperValue - lowerValue) * fraction

        return height * (1 - interpolatedValue)
    }
    
    // Get time label based on period and progress
    func getTimeLabel(at progress: CGFloat) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case "1H":
            let minutesAgo = Int((1.0 - progress) * 60)
            let time = calendar.date(byAdding: .minute, value: -minutesAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma"
            return formatter.string(from: time).lowercased()
        case "1D":
            let hoursAgo = Int((1.0 - progress) * 24)
            let time = calendar.date(byAdding: .hour, value: -hoursAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma"
            return formatter.string(from: time).lowercased()
        case "1W":
            let daysAgo = Int((1.0 - progress) * 7)
            let time = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: time)
        case "1M":
            let daysAgo = Int((1.0 - progress) * 30)
            let time = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: time)
        case "1Y":
            let monthsAgo = Int((1.0 - progress) * 12)
            let time = calendar.date(byAdding: .month, value: -monthsAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: time)
        case "All":
            let yearsAgo = Int((1.0 - progress) * 5)
            let time = calendar.date(byAdding: .year, value: -yearsAgo, to: now) ?? now
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: time)
        default:
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let dotX = width * dragProgress
                let dotY = getYValue(at: dragProgress, height: height)
                // #region agent log
                let _ = debugLog(location: "StockChartView:geo", message: "Chart geometry", data: ["chartWidth": width, "chartHeight": height, "frameMinX": geometry.frame(in: .global).minX, "frameMaxX": geometry.frame(in: .global).maxX], hypothesisId: "C")
                // #endregion
                
                ZStack {
                    if isDragging {
                        StockAnimatedChartLine(points: chartPoints, width: width, height: height, chartColor: chartColor)
                            .stroke(Color(hex: "EDEDED"), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: animatedPoints)
                    }

                    StockAnimatedChartLine(points: chartPoints, width: width, height: height, trimEnd: dragProgress, chartColor: chartColor)
                        .stroke(chartColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: animatedPoints)
                    
                    if isDragging {
                        // Vertical line
                        Rectangle()
                            .fill(Color(hex: "EDEDED"))
                            .frame(width: 1)
                            .position(x: dotX, y: height / 2)
                        
                        // Time label at top of line
                        Text(getTimeLabel(at: dragProgress))
                            .font(.custom("Inter-Medium", size: 10))
                            .foregroundColor(themeService.textSecondaryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "EDEDED"))
                            )
                            .position(x: dotX, y: -12)
                        
                        // Dot when dragging
                        Circle()
                            .fill(chartColor)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .position(x: dotX, y: dotY)
                    } else {
                        let lastY = height * (1 - (chartPoints.last ?? 0.5))
                        StockPulsingDot(color: chartColor)
                            .position(x: width, y: lastY)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            if !isDragging {
                                generator.impactOccurred()
                                lastHapticInterval = -1
                            }
                            isDragging = true
                            let newProgress = min(max(value.location.x / width, 0), 1)
                            
                            let intervals: Int
                            switch selectedPeriod {
                            case "1H": intervals = 12
                            case "1D": intervals = 48
                            case "1W": intervals = 7
                            case "1M": intervals = 30
                            case "1Y": intervals = 12
                            case "All": intervals = 5
                            default: intervals = 10
                            }
                            
                            let currentInterval = Int(newProgress * CGFloat(intervals))
                            if currentInterval != lastHapticInterval {
                                generator.impactOccurred()
                                lastHapticInterval = currentInterval
                            }
                            
                            dragProgress = newProgress
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isDragging = false
                                dragProgress = 1.0
                            }
                            lastHapticInterval = -1
                        }
                )
            }
            .padding(.leading, -20)
            .padding(.trailing, 40)
            .frame(height: 140)
            
            // Time Period Selector
            HStack {
                ForEach(periods, id: \.self) { period in
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        selectedPeriod = period
                    } label: {
                        Text(period)
                            .font(.custom(selectedPeriod == period ? "Inter-Medium" : "Inter-Regular", size: 14))
                            .foregroundColor(selectedPeriod == period ? themeService.textPrimaryColor : themeService.textSecondaryColor)
                            .frame(height: 20) // Line height 20
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedPeriod == period ? Color(hex: "E8E8E8") : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    if period != periods.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 16)
        .onAppear {
            // Initialize with normalized points
            animatedPoints = normalizePoints(sourceChartPoints)
        }
        .onChange(of: selectedPeriod) { _, _ in
            // Animate to new chart data when period changes
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                animatedPoints = normalizePoints(sourceChartPoints)
            }
        }
        .onChange(of: chartData) { _, newValue in
            // Animate when chart data changes
            if !newValue.isEmpty {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    animatedPoints = normalizePoints(newValue)
                }
            }
        }
    }
}

struct StockAnimatedChartLine: Shape {
    var points: [CGFloat]
    var width: CGFloat
    var height: CGFloat
    var trimEnd: CGFloat = 1.0
    var chartColor: Color

    // Animate both points and trimEnd
    var animatableData: AnimatablePair<AnimatableVector, CGFloat> {
        get { AnimatablePair(AnimatableVector(values: points), trimEnd) }
        set {
            points = newValue.first.values
            trimEnd = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        guard !points.isEmpty else { return Path() }
        
        let cgPoints: [CGPoint] = points.enumerated().map { index, point in
            let x = width * CGFloat(index) / CGFloat(points.count - 1)
            let y = height * (1 - point)
            return CGPoint(x: x, y: y)
        }
        
        let endX = width * trimEnd
        
        var path = Path()
        guard cgPoints.count > 1 else { return path }
        
        let cornerRadius: CGFloat = 6
        
        path.move(to: cgPoints[0])
        
        for i in 1..<cgPoints.count - 1 {
            let prev = cgPoints[i - 1]
            let curr = cgPoints[i]
            let next = cgPoints[i + 1]
            
            if curr.x > endX {
                let t = (endX - prev.x) / (curr.x - prev.x)
                let endY = prev.y + (curr.y - prev.y) * t
                path.addLine(to: CGPoint(x: endX, y: endY))
                return path
            }
            
            let v1 = CGPoint(x: curr.x - prev.x, y: curr.y - prev.y)
            let v2 = CGPoint(x: next.x - curr.x, y: next.y - curr.y)
            
            let len1 = sqrt(v1.x * v1.x + v1.y * v1.y)
            let len2 = sqrt(v2.x * v2.x + v2.y * v2.y)
            
            let radius = min(cornerRadius, len1 / 2, len2 / 2)
            
            let n1 = CGPoint(x: v1.x / len1 * radius, y: v1.y / len1 * radius)
            let n2 = CGPoint(x: v2.x / len2 * radius, y: v2.y / len2 * radius)
            
            let p1 = CGPoint(x: curr.x - n1.x, y: curr.y - n1.y)
            let p2 = CGPoint(x: curr.x + n2.x, y: curr.y + n2.y)
            
            path.addLine(to: p1)
            path.addQuadCurve(to: p2, control: curr)
        }
        
        let lastPoint = cgPoints.last!
        let secondLast = cgPoints[cgPoints.count - 2]
        
        if lastPoint.x > endX && secondLast.x < endX {
            let t = (endX - secondLast.x) / (lastPoint.x - secondLast.x)
            let endY = secondLast.y + (lastPoint.y - secondLast.y) * t
            path.addLine(to: CGPoint(x: endX, y: endY))
        } else if trimEnd >= 1.0 {
            path.addLine(to: lastPoint)
        }
        
        return path
    }
}

struct StockPulsingDot: View {
    let color: Color
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
                .scaleEffect(isPulsing ? 1.0 : 0.5)
                .opacity(isPulsing ? 0 : 1)
            
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .onAppear {
            withAnimation(
                .easeOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    StockDetailView(stock: Stock(
        name: "Apple Inc",
        symbol: "AAPL",
        price: "$277.59",
        change: "0.42%",
        isPositive: true,
        iconName: "StockApple"
    ))
}
