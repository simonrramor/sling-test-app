import SwiftUI

// #region agent log
private let debugLogPath = "/Users/simonamor/Desktop/sling-test-app-2/.cursor/debug.log"
private var investViewBodyCount = 0
private func debugLog(_ location: String, _ message: String, _ data: [String: Any] = [:]) {
    let entry: [String: Any] = [
        "timestamp": Date().timeIntervalSince1970 * 1000,
        "location": location,
        "message": message,
        "data": data,
        "sessionId": "debug-session"
    ]
    if let jsonData = try? JSONSerialization.data(withJSONObject: entry),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        if let handle = FileHandle(forWritingAtPath: debugLogPath) {
            handle.seekToEndOfFile()
            handle.write((jsonString + "\n").data(using: .utf8)!)
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: debugLogPath, contents: (jsonString + "\n").data(using: .utf8))
        }
    }
}
// #endregion

struct Stock: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let price: String
    let change: String
    let isPositive: Bool
    let iconName: String
    var description: String = ""
    var isOndo: Bool = false  // True if this is an Ondo tokenized stock
    var ondoSymbol: String? = nil  // The Ondo token symbol (e.g., "AAPLon")
}

struct InvestView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var ondoService = OndoService.shared
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @State private var selectedPeriod = "1D"
    @State private var isDragging = false
    @State private var dragProgress: CGFloat = 1.0
    @State private var selectedStock: Stock? = nil
    @State private var exchangeRate: Double = 1.0
    
    private let exchangeRateService = ExchangeRateService.shared
    
    // Stock definitions - available Ondo tokenized stocks to buy/sell
    let stockDefinitions: [(name: String, iconName: String, description: String)] = [
        ("Amazon", "StockAmazon", "Amazon is a global technology company and one of the world's largest e-commerce and cloud computing platforms. Founded by Jeff Bezos in 1994, it has grown from an online bookstore to a leader in retail, AWS cloud services, streaming, and AI."),
        ("Apple Inc", "StockApple", "Apple Inc. designs, manufactures, and markets consumer electronics, software, and services. Known for iconic products like iPhone, Mac, and iPad, Apple has built one of the world's most valuable brands through innovation and ecosystem integration."),
        ("Coinbase", "StockCoinbase", "Coinbase is the largest cryptocurrency exchange in the United States, providing a platform for buying, selling, and storing digital assets. Founded in 2012, it serves as a gateway for millions of users entering the crypto economy."),
        ("Google Inc", "StockGoogle", "Alphabet Inc., Google's parent company, is a multinational technology conglomerate known for its dominant search engine, advertising platform, Android OS, YouTube, and cloud services. It's a leader in AI and machine learning innovation."),
        ("McDonalds", "StockMcDonalds", "McDonald's Corporation is the world's largest restaurant chain by revenue, serving millions of customers daily across more than 100 countries. Known for its iconic Big Mac and golden arches, it's a global leader in quick-service dining."),
        ("Meta", "StockMeta", "Meta Platforms, formerly Facebook, is a social technology company building products that help people connect. Its family of apps includes Facebook, Instagram, WhatsApp, and Messenger, while investing heavily in the metaverse."),
        ("Microsoft", "StockMicrosoft", "Microsoft Corporation is a global technology leader known for Windows, Office 365, Azure cloud platform, and Xbox gaming. Under Satya Nadella's leadership, it has become a dominant force in cloud computing and enterprise software."),
        ("Tesla Inc", "StockTesla", "Tesla, Inc. is an electric vehicle and clean energy company founded by Elon Musk. It designs and manufactures electric cars, battery storage systems, and solar products, pioneering the transition to sustainable energy."),
        ("Visa", "StockVisa", "Visa Inc. is a global payments technology company that facilitates electronic funds transfers worldwide through its branded credit, debit, and prepaid cards. It operates one of the world's largest retail electronic payments networks.")
    ]
    
    // Build stocks from Ondo service data
    var allStocks: [Stock] {
        stockDefinitions.compactMap { definition in
            // Only include stocks that have Ondo tokens available
            guard ondoService.hasOndoToken(for: definition.iconName) else { return nil }
            
            if let data = ondoService.tokenData[definition.iconName] {
                return Stock(
                    name: definition.name,
                    symbol: data.symbol,
                    price: data.formattedPrice,
                    change: data.formattedChange,
                    isPositive: data.isPositive,
                    iconName: definition.iconName,
                    description: definition.description,
                    isOndo: true,
                    ondoSymbol: data.symbol
                )
            } else {
                let ondoSymbol = ondoService.ondoSymbol(for: definition.iconName) ?? "---"
                return Stock(
                    name: definition.name,
                    symbol: ondoSymbol,
                    price: "Loading...",
                    change: "--",
                    isPositive: true,
                    iconName: definition.iconName,
                    description: definition.description,
                    isOndo: true,
                    ondoSymbol: ondoSymbol
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
    
    // Get total cost basis (what you paid for all holdings)
    var totalCostBasis: Double {
        portfolioService.holdings.values.reduce(0) { $0 + $1.totalCost }
    }
    
    // Calculate portfolio value at a specific progress point
    func portfolioValueAt(progress: Double) -> Double {
        ondoService.tokenData.reduce(0) { total, pair in
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
    
    // Calculate gain/loss at a specific progress point (value - cost basis)
    func gainLossAt(progress: Double) -> Double {
        let valueAtProgress = portfolioValueAt(progress: progress)
        return valueAtProgress - totalCostBasis
    }
    
    // Display profit/loss from price changes only (not money added)
    // This compares current value to cost basis (what you paid)
    var displayPortfolioChange: Double {
        if isDragging {
            return gainLossAt(progress: Double(dragProgress))
        } else {
            return portfolioCurrentTotal - totalCostBasis
        }
    }
    
    var isPositiveChange: Bool {
        displayPortfolioChange > 0.001 // Small threshold to avoid floating point issues
    }
    
    var isNegativeChange: Bool {
        displayPortfolioChange < -0.001
    }
    
    var isNoChange: Bool {
        !isPositiveChange && !isNegativeChange
    }
    
    var changeColor: Color {
        if isNoChange {
            return themeService.textSecondaryColor // Grey for no change
        }
        return isPositiveChange ? Color.appPositiveGreen : Color.appNegativeRed
    }
    
    var currencySymbol: String {
        ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
    }
    
    var displayPortfolioChangeConverted: Double {
        displayCurrencyService.displayCurrency == "USD" ? displayPortfolioChange : displayPortfolioChange * exchangeRate
    }
    
    var displayPortfolioTotalConverted: Double {
        displayCurrencyService.displayCurrency == "USD" ? displayPortfolioTotal : displayPortfolioTotal * exchangeRate
    }
    
    var changeText: String {
        return abs(displayPortfolioChangeConverted).asCurrency(currencySymbol)
    }
    
    var portfolioTotalText: String {
        return displayPortfolioTotalConverted.asCurrency(currencySymbol)
    }
    
    var zeroBalanceText: String {
        return "\(currencySymbol)0.00"
    }
    
    // Disabled periods for demo mode (only 1H and 1D are valid)
    let disabledPeriods = ["1W", "1M", "1Y", "All"]
    
    // Combined portfolio chart data (normalized 0-1) - uses history-based generation
    var portfolioChartData: [CGFloat] {
        // #region agent log
        debugLog("InvestView.swift:portfolioChartData", "H3: Chart data requested", ["period": selectedPeriod, "isEmpty": isPortfolioEmpty])
        // #endregion
        guard !isPortfolioEmpty else { return [] }
        return portfolioService.generateChartData(period: selectedPeriod, sampleCount: 50)
    }
    
    var body: some View {
        // #region agent log
        let _ = {
            investViewBodyCount += 1
            debugLog("InvestView.swift:body", "H1: View body computed", ["count": investViewBodyCount, "holdingsCount": portfolioService.holdings.count])
        }()
        // #endregion
        VStack(spacing: 0) {
        ScrollView {
            VStack(spacing: 0) {
                // Portfolio Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if isPortfolioEmpty {
                            Text("Portfolio")
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(themeService.textSecondaryColor)
                        } else {
                            HStack(spacing: 6) {
                                Text("Portfolio")
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(themeService.textSecondaryColor)
                                
                                Image(systemName: isNoChange ? "arrow.right" : "arrow.up")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(changeColor)
                                    .rotationEffect(.degrees(isNoChange ? 0 : (isPositiveChange ? 0 : 180)))
                                
                                SlidingNumberText(
                                    text: changeText,
                                    font: .custom("Inter-Medium", size: 16),
                                    color: changeColor
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    
                    if isPortfolioEmpty {
                        Text(zeroBalanceText)
                            .font(.custom("Inter-Bold", size: 48))
                            .tracking(-0.96)
                            .foregroundColor(themeService.textPrimaryColor)
                    } else {
                        SlidingNumberText(
                            text: displayPortfolioTotal > 0 ? portfolioTotalText : zeroBalanceText,
                            font: .custom("Inter-Bold", size: 48),
                            color: themeService.textPrimaryColor
                        )
                        .tracking(-0.96)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .animation(.easeInOut(duration: 0.1), value: dragProgress)
                
                // Promotional card for empty portfolio (hidden for now)
                // if isPortfolioEmpty {
                //     StartInvestingCard()
                //         .padding(.horizontal, 16)
                //         .padding(.top, 8)
                // }
                
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
                            .foregroundColor(themeService.textPrimaryColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .accessibilityAddTraits(.isHeader)
                        
                        ForEach(ownedStocks) { stock in
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
                                // Value and Change
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(portfolioService.holdingValue(for: stock.iconName).asUSD)
                                        .font(.custom("Inter-Bold", size: 16))
                                        .foregroundColor(themeService.textPrimaryColor)
                                    
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
                            .foregroundColor(themeService.textPrimaryColor)
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
                                    .foregroundColor(themeService.textPrimaryColor)
                                
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
                
                // Bottom padding for scroll content to clear nav bar
                Spacer()
                    .frame(height: 120)
            }
        }
        .fullScreenCover(item: $selectedStock) { stock in
            StockDetailView(stock: stock)
        }
        .onAppear {
            Task {
                await fetchAllStocksForPeriod()
            }
            fetchExchangeRate()
        }
        .onChange(of: displayCurrencyService.displayCurrency) { _, _ in
            fetchExchangeRate()
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await fetchAllStocksForPeriod()
            }
        }
        } // Close outer VStack
        .background(themeService.backgroundColor)
    }
    
    private func fetchAllStocksForPeriod() async {
        await ondoService.fetchAllTokens()
    }
    
    private func fetchExchangeRate() {
        let currency = displayCurrencyService.displayCurrency
        guard currency != "USD" else {
            exchangeRate = 1.0
            return
        }
        
        Task {
            if let rate = await exchangeRateService.getRate(from: "USD", to: currency) {
                await MainActor.run {
                    exchangeRate = rate
                }
            }
        }
    }
}

// MARK: - Start Investing Promotional Card

struct StartInvestingCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    @State private var showStockList = false
    // Stock icons with their rotation angles
    private let stockIcons: [(name: String, rotation: Double)] = [
        ("StockTesla", -13),
        ("StockApple", 0),
        ("StockGoogle", 13)
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
                    .foregroundColor(themeService.textPrimaryColor)
                    .multilineTextAlignment(.center)
                
                Text("Buy stocks in your favorite companies to give your money a chance to grow.")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }
            
            // Start investing button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showStockList = true
            }) {
                Text("Start investing")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(themeService.currentTheme == .dark ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(themeService.textPrimaryColor)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeService.currentTheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F7F7F7"))
        )
        .fullScreenCover(isPresented: $showStockList) {
            BrowseStocksView(isPresented: $showStockList)
        }
    }
}

#Preview {
    InvestView(isPresented: .constant(true))
}