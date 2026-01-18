import SwiftUI

struct Stock: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let price: String
    let change: String
    let isPositive: Bool
    let iconName: String
}

struct InvestView: View {
    @StateObject private var stockService = StockService.shared
    @StateObject private var portfolioService = PortfolioService.shared
    @State private var selectedPeriod = "1D"
    @State private var isDragging = false
    @State private var dragProgress: CGFloat = 1.0
    @State private var selectedStock: Stock? = nil
    
    // Stock definitions - available stocks to buy/sell
    let stockDefinitions: [(name: String, iconName: String)] = [
        ("Amazon", "StockAmazon"),
        ("Apple Inc", "StockApple"),
        ("Bank of America", "StockBankOfAmerica"),
        ("Circle", "StockCircle"),
        ("Coinbase", "StockCoinbase"),
        ("Google Inc", "StockGoogle"),
        ("McDonalds", "StockMcDonalds"),
        ("Meta", "StockMeta"),
        ("Microsoft", "StockMicrosoft"),
        ("Tesla Inc", "StockTesla"),
        ("Visa", "StockVisa")
    ]
    
    // Build stocks from service data
    var allStocks: [Stock] {
        stockDefinitions.map { definition in
            if let data = stockService.stockData[definition.iconName] {
                return Stock(
                    name: definition.name,
                    symbol: data.symbol,
                    price: data.formattedPrice,
                    change: data.formattedChange,
                    isPositive: data.isPositive,
                    iconName: definition.iconName
                )
            } else {
                return Stock(
                    name: definition.name,
                    symbol: "---",
                    price: "Loading...",
                    change: "--",
                    isPositive: true,
                    iconName: definition.iconName
                )
            }
        }
    }
    
    // Stocks the user owns
    var ownedStocks: [Stock] {
        allStocks.filter { portfolioService.ownsStock($0.iconName) }
    }
    
    // Stocks available to browse (excludes owned stocks)
    var stocksToBrowse: [Stock] {
        allStocks.filter { !portfolioService.ownsStock($0.iconName) }
    }
    
    // Check if portfolio is empty
    var isPortfolioEmpty: Bool {
        portfolioService.holdings.isEmpty
    }
    
    // Calculate portfolio value at current prices
    var portfolioCurrentTotal: Double {
        portfolioService.portfolioValue()
    }
    
    // Calculate portfolio value at start of period
    var portfolioStartTotal: Double {
        portfolioService.portfolioValueAtPeriodStart(period: selectedPeriod)
    }
    
    // Calculate portfolio value at a specific progress point
    func portfolioValueAt(progress: Double) -> Double {
        stockService.stockData.reduce(0) { total, pair in
            let shares = portfolioService.sharesOwned(for: pair.key)
            let price = pair.value.priceAt(progress: progress)
            return total + price * shares
        }
    }
    
    // Display portfolio value based on drag position
    var displayPortfolioTotal: Double {
        if isDragging {
            return portfolioValueAt(progress: Double(dragProgress))
        } else {
            return portfolioCurrentTotal
        }
    }
    
    // Display change from start to current drag position
    var displayPortfolioChange: Double {
        let currentValue = isDragging ? portfolioValueAt(progress: Double(dragProgress)) : portfolioCurrentTotal
        return currentValue - portfolioStartTotal
    }
    
    var isPositiveChange: Bool {
        displayPortfolioChange >= 0
    }
    
    var changeColor: Color {
        isPositiveChange ? Color(hex: "57CE43") : Color(hex: "E30000")
    }
    
    var changeText: String {
        return String(format: "$%.2f", abs(displayPortfolioChange))
    }
    
    var portfolioTotalText: String {
        return String(format: "$%.2f", displayPortfolioTotal)
    }
    
    // Disabled periods for demo mode (only 1H and 1D are valid)
    let disabledPeriods = ["1W", "1M", "1Y", "All"]
    
    // Combined portfolio chart data (normalized 0-1) - uses history-based generation
    var portfolioChartData: [CGFloat] {
        guard !isPortfolioEmpty else { return [] }
        return portfolioService.generateChartData(period: selectedPeriod, sampleCount: 50)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Portfolio Header
                VStack(alignment: .leading, spacing: 4) {
                    if isPortfolioEmpty {
                        Text("Your portfolio")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Text("$0.00")
                            .font(.custom("Inter-Bold", size: 33))
                            .foregroundColor(Color(hex: "080808"))
                    } else {
                        HStack(spacing: 6) {
                            Text("Your portfolio")
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(Color(hex: "7B7B7B"))
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(changeColor)
                                .rotationEffect(.degrees(isPositiveChange ? 0 : 180))
                            
                            SlidingNumberText(
                                text: changeText,
                                font: .custom("Inter-Medium", size: 16),
                                color: changeColor
                            )
                        }
                        
                        SlidingNumberText(
                            text: displayPortfolioTotal > 0 ? portfolioTotalText : "$0.00",
                            font: .custom("Inter-Bold", size: 33),
                            color: Color(hex: "080808")
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .animation(.easeInOut(duration: 0.1), value: dragProgress)
                
                // Promotional card for empty portfolio
                if isPortfolioEmpty {
                    StartInvestingCard()
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                
                // Chart Area with Time Period Selector (only show if has holdings)
                if !isPortfolioEmpty {
                    ChartView(
                        selectedPeriod: $selectedPeriod,
                        isDragging: $isDragging,
                        dragProgress: $dragProgress,
                        externalChartData: portfolioChartData.isEmpty ? nil : portfolioChartData,
                        disabledPeriods: disabledPeriods
                    )
                }
                
                // Your Stocks Section (owned stocks)
                if !ownedStocks.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Your stocks")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .accessibilityAddTraits(.isHeader)
                        
                        ForEach(ownedStocks) { stock in
                            let shares = portfolioService.sharesOwned(for: stock.iconName)
                            ListRow(
                                iconName: stock.iconName,
                                title: stock.name,
                                subtitle: String(format: "%.2f shares", shares),
                                iconStyle: .rounded,
                                isButton: true,
                                onTap: {
                                    selectedStock = stock
                                }
                            ) {
                                // Value and Change
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(String(format: "$%.2f", portfolioService.holdingValue(for: stock.iconName)))
                                        .font(.custom("Inter-Bold", size: 16))
                                        .foregroundColor(Color(hex: "080808"))
                                    
                                    let pnl = portfolioService.holdingProfitLoss(for: stock.iconName)
                                    HStack(spacing: 4) {
                                        Image(systemName: pnl.isPositive ? "arrow.up" : "arrow.down")
                                            .font(.system(size: 10, weight: .bold))
                                        Text(String(format: "%.2f%%", abs(pnl.percent)))
                                            .font(.custom("Inter-Regular", size: 14))
                                    }
                                    .foregroundColor(pnl.isPositive ? Color(hex: "57CE43") : Color(hex: "E30000"))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 16)
                }
                
                // Available Stocks Section (stocks not yet owned)
                if !stocksToBrowse.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(isPortfolioEmpty ? "Stocks" : "Browse stocks")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .accessibilityAddTraits(.isHeader)
                        
                        ForEach(stocksToBrowse) { stock in
                        ListRow(
                            iconName: stock.iconName,
                            title: stock.name,
                            subtitle: stock.symbol,
                            iconStyle: .rounded,
                            isButton: true,
                            onTap: {
                                selectedStock = stock
                            }
                        ) {
                            // Price and Change
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(stock.price)
                                    .font(.custom("Inter-Bold", size: 16))
                                    .foregroundColor(Color(hex: "080808"))
                                
                                HStack(spacing: 4) {
                                    Image(systemName: stock.isPositive ? "arrow.up" : "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(stock.change)
                                        .font(.custom("Inter-Regular", size: 14))
                                }
                                .foregroundColor(stock.isPositive ? Color(hex: "57CE43") : Color(hex: "E30000"))
                            }
                        }
                    }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 16)
                }
                
                Spacer()
            }
        }
        .fullScreenCover(item: $selectedStock) { stock in
            StockDetailView(stock: stock)
        }
        .onAppear {
            Task {
                await fetchAllStocksForPeriod()
            }
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await fetchAllStocksForPeriod()
            }
        }
    }
    
    private func fetchAllStocksForPeriod() async {
        await stockService.fetchAllStocksForPeriodInParallel(period: selectedPeriod)
    }
}

// MARK: - Start Investing Promotional Card

struct StartInvestingCard: View {
    // Stock icons with their rotation angles
    private let stockIcons: [(name: String, rotation: Double)] = [
        ("StockTesla", -8),
        ("StockApple", 0),
        ("StockGoogle", 8)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Overlapping stock avatars with rotation
            HStack(spacing: -26) {
                ForEach(stockIcons, id: \.name) { icon in
                    Image(icon.name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 65, height: 65)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                        .rotationEffect(.degrees(icon.rotation))
                }
            }
            
            // Text content
            VStack(spacing: 4) {
                Text("Start building your wealth with investing from just $1")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                    .multilineTextAlignment(.center)
                
                Text("Buy stocks in your favorite companies to give your money a chance to grow.")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color(hex: "7B7B7B"))
                    .multilineTextAlignment(.center)
            }
            
            // Start investing button
            Button(action: {
                // Scroll to stocks section or show tutorial
            }) {
                Text("Start investing")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "080808"))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "F7F7F7"))
        )
    }
}

#Preview {
    InvestView()
}