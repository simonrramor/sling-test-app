import Foundation
import Combine

// MARK: - Yahoo Finance Response Models

struct YahooFinanceResponse: Codable {
    let chart: ChartResult
}

struct ChartResult: Codable {
    let result: [ChartData]?
    let error: YahooError?
}

struct YahooError: Codable {
    let code: String
    let description: String
}

struct ChartData: Codable {
    let meta: MetaData
    let timestamp: [Int]?
    let indicators: Indicators
}

struct MetaData: Codable {
    let symbol: String
    let regularMarketPrice: Double?
    let previousClose: Double?
    let currency: String?
}

struct Indicators: Codable {
    let quote: [QuoteData]?
}

struct QuoteData: Codable {
    let close: [Double?]?
    let high: [Double?]?
    let low: [Double?]?
    let open: [Double?]?
    let volume: [Int?]?
}

// MARK: - Stock Price Data

struct StockPriceData {
    let symbol: String
    let currentPrice: Double
    let previousClose: Double
    let priceChange: Double
    let percentChange: Double
    let isPositive: Bool
    let historicalPrices: [Double] // Normalized 0-1 for chart
    let rawPrices: [Double] // Actual price values
    let timestamps: [Date]
    
    var formattedPrice: String {
        return String(format: "$%.2f", currentPrice)
    }
    
    var formattedChange: String {
        return String(format: "%.2f%%", abs(percentChange))
    }
    
    // Get price at a specific progress point (0-1)
    func priceAt(progress: Double) -> Double {
        guard !rawPrices.isEmpty else { return currentPrice }
        
        let exactIndex = progress * Double(rawPrices.count - 1)
        let lowerIndex = Int(exactIndex)
        let upperIndex = min(lowerIndex + 1, rawPrices.count - 1)
        let fraction = exactIndex - Double(lowerIndex)
        
        return rawPrices[lowerIndex] + (rawPrices[upperIndex] - rawPrices[lowerIndex]) * fraction
    }
    
    // Get change from start to a specific progress point
    func changeAt(progress: Double) -> (value: Double, percent: Double, isPositive: Bool) {
        guard !rawPrices.isEmpty, let startPrice = rawPrices.first else {
            return (priceChange, percentChange, isPositive)
        }
        
        let currentPriceAtProgress = priceAt(progress: progress)
        let change = currentPriceAtProgress - startPrice
        let percent = startPrice > 0 ? (change / startPrice) * 100 : 0
        
        return (change, percent, change >= 0)
    }
}

// MARK: - Stock Service

class StockService: ObservableObject {
    static let shared = StockService()
    
    @Published var stockData: [String: StockPriceData] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    private var cache: [String: (data: StockPriceData, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minute cache
    
    private init() {
        // Prefetch stock data on initialization
        Task {
            await fetchAllStocksInParallel()
        }
    }
    
    // Map our icon names to Yahoo Finance symbols
    let symbolMapping: [String: String] = [
        "StockAmazon": "AMZN",
        "StockApple": "AAPL",
        "StockBankOfAmerica": "BAC",
        "StockCircle": "USDC-USD", // Circle's USDC
        "StockCoinbase": "COIN",
        "StockGoogle": "GOOGL",
        "StockMcDonalds": "MCD",
        "StockMeta": "META",
        "StockMicrosoft": "MSFT",
        "StockTesla": "TSLA",
        "StockVisa": "V"
    ]
    
    func fetchStockData(for iconName: String, range: String = "1d", interval: String = "5m") async {
        guard let symbol = symbolMapping[iconName] else { return }
        
        // Check cache
        if let cached = cache["\(symbol)-\(range)"],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            await MainActor.run {
                self.stockData[iconName] = cached.data
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=\(interval)&range=\(range)"
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.error = "Invalid URL"
                self.isLoading = false
            }
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(YahooFinanceResponse.self, from: data)
            
            if let chartData = response.chart.result?.first {
                let priceData = processChartData(chartData, iconName: iconName)
                
                // Cache the result
                cache["\(symbol)-\(range)"] = (priceData, Date())
                
                await MainActor.run {
                    self.stockData[iconName] = priceData
                    self.isLoading = false
                }
            } else if let error = response.chart.error {
                await MainActor.run {
                    self.error = error.description
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func fetchAllStocks() async {
        await fetchAllStocksInParallel()
    }
    
    // Fetch all stocks in parallel for much faster loading
    func fetchAllStocksInParallel(range: String = "1d", interval: String = "5m") async {
        await MainActor.run {
            self.isLoading = true
        }
        
        await withTaskGroup(of: Void.self) { group in
            for iconName in symbolMapping.keys {
                group.addTask {
                    await self.fetchStockData(for: iconName, range: range, interval: interval)
                }
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    // Fetch all stocks for a specific period in parallel
    func fetchAllStocksForPeriodInParallel(period: String) async {
        let (range, interval) = getRangeAndInterval(for: period)
        await fetchAllStocksInParallel(range: range, interval: interval)
    }
    
    func fetchStockForPeriod(iconName: String, period: String) async {
        let (range, interval) = getRangeAndInterval(for: period)
        await fetchStockData(for: iconName, range: range, interval: interval)
    }
    
    private func getRangeAndInterval(for period: String) -> (range: String, interval: String) {
        switch period {
        case "1H":
            return ("1d", "1m")
        case "1D":
            return ("1d", "5m")
        case "1W":
            return ("5d", "15m")
        case "1M":
            return ("1mo", "1h")
        case "1Y":
            return ("1y", "1d")
        case "All":
            return ("5y", "1wk")
        default:
            return ("1d", "5m")
        }
    }
    
    private func processChartData(_ chartData: ChartData, iconName: String) -> StockPriceData {
        let meta = chartData.meta
        let currentPrice = meta.regularMarketPrice ?? 0
        let previousClose = meta.previousClose ?? currentPrice
        let priceChange = currentPrice - previousClose
        let percentChange = previousClose > 0 ? (priceChange / previousClose) * 100 : 0
        
        // Get closing prices
        var closePrices: [Double] = []
        var timestamps: [Date] = []
        
        if let quotes = chartData.indicators.quote?.first,
           let closes = quotes.close,
           let times = chartData.timestamp {
            
            for (index, close) in closes.enumerated() {
                if let price = close {
                    closePrices.append(price)
                    if index < times.count {
                        timestamps.append(Date(timeIntervalSince1970: TimeInterval(times[index])))
                    }
                }
            }
        }
        
        // Normalize prices to 0-1 range for chart
        let normalizedPrices = normalizePrices(closePrices)

        return StockPriceData(
            symbol: meta.symbol,
            currentPrice: currentPrice,
            previousClose: previousClose,
            priceChange: priceChange,
            percentChange: percentChange,
            isPositive: priceChange >= 0,
            historicalPrices: normalizedPrices,
            rawPrices: closePrices,
            timestamps: timestamps
        )
    }
    
    private func normalizePrices(_ prices: [Double]) -> [Double] {
        guard !prices.isEmpty else { return [] }
        
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 1
        let range = maxPrice - minPrice
        
        if range == 0 {
            return prices.map { _ in 0.5 }
        }
        
        return prices.map { ($0 - minPrice) / range }
    }
    
    // Sample to exactly 10 points for chart compatibility
    func samplePrices(_ prices: [Double], to count: Int = 10) -> [CGFloat] {
        guard prices.count >= count else {
            // Pad with last value if not enough data
            let padding = Array(repeating: prices.last ?? 0.5, count: count - prices.count)
            return (prices + padding).map { CGFloat($0) }
        }
        
        var sampled: [Double] = []
        let step = Double(prices.count - 1) / Double(count - 1)
        
        for i in 0..<count {
            let index = Int(Double(i) * step)
            sampled.append(prices[min(index, prices.count - 1)])
        }
        
        return sampled.map { CGFloat($0) }
    }
}
