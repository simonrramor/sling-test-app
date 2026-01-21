import Foundation
import Combine

// MARK: - Financial Modeling Prep API Configuration

/// Get your free API key at https://financialmodelingprep.com (250 calls/day free tier)
private let fmpAPIKey = "Ng1HqWPxPHz3ScqxhLKOb77HO4Q8zdvX" // TODO: Replace with your API key

// MARK: - Debug Logging

// #region agent log
private let debugLogPath = "/Users/simonamor/Desktop/sling-test-app-2/.cursor/debug.log"
private func debugLog(_ location: String, _ message: String, _ data: [String: Any] = [:], hypothesisId: String = "") {
    var safeData: [String: Any] = [:]
    for (key, value) in data {
        if let v = value as? String { safeData[key] = v }
        else if let v = value as? Int { safeData[key] = v }
        else if let v = value as? Double { safeData[key] = v }
        else if let v = value as? Bool { safeData[key] = v }
        else { safeData[key] = String(describing: value) }
    }
    let entry: [String: Any] = [
        "timestamp": Date().timeIntervalSince1970 * 1000,
        "location": location,
        "message": message,
        "data": safeData,
        "sessionId": "debug-session",
        "hypothesisId": hypothesisId
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

// MARK: - FMP Response Models

struct FMPQuote: Codable {
    let symbol: String
    let price: Double
    let changePercentage: Double  // Note: stable API uses "changePercentage" not "changesPercentage"
    let change: Double
    let previousClose: Double
    let name: String?
}

struct FMPHistoricalPrice: Codable {
    let date: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
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
    
    func priceAt(progress: Double) -> Double {
        guard !rawPrices.isEmpty else { return currentPrice }
        let exactIndex = progress * Double(rawPrices.count - 1)
        let lowerIndex = Int(exactIndex)
        let upperIndex = min(lowerIndex + 1, rawPrices.count - 1)
        let fraction = exactIndex - Double(lowerIndex)
        return rawPrices[lowerIndex] + (rawPrices[upperIndex] - rawPrices[lowerIndex]) * fraction
    }
    
    func changeAt(progress: Double) -> (value: Double, percent: Double, isPositive: Bool) {
        if progress >= 1.0 {
            return (priceChange, percentChange, isPositive)
        }
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
    
    private let baseURL = "https://financialmodelingprep.com/stable"
    
    private init() {
        Task {
            await fetchAllStocksInParallel()
        }
    }
    
    // Map icon names to stock symbols
    let symbolMapping: [String: String] = [
        "StockAmazon": "AMZN",
        "StockApple": "AAPL",
        "StockBankOfAmerica": "BAC",
        "StockCircle": "COIN",  // Circle is private, use Coinbase
        "StockCoinbase": "COIN",
        "StockGoogle": "GOOGL",
        "StockMcDonalds": "MCD",
        "StockMeta": "META",
        "StockMicrosoft": "MSFT",
        "StockTesla": "TSLA",
        "StockVisa": "V"
    ]
    
    private let displaySymbols: [String: String] = [
        "StockCircle": "CRCLx"
    ]
    
    // MARK: - Public API
    
    func fetchStockData(for iconName: String, range: String = "1d", interval: String = "5m") async {
        guard let symbol = symbolMapping[iconName] else { return }
        let displaySymbol = displaySymbols[iconName] ?? (symbol + "x")
        
        // Check cache
        let cacheKey = "\(iconName)-\(range)"
        if let cached = cache[cacheKey],
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
        
        do {
            // Fetch quote and historical data
            async let quoteData = fetchQuote(symbol: symbol)
            async let historyData = fetchHistory(symbol: symbol, range: range)
            
            let (quote, history) = try await (quoteData, historyData)
            
            let priceData = processData(quote: quote, history: history, displaySymbol: displaySymbol)
            
            cache[cacheKey] = (priceData, Date())
            
            await MainActor.run {
                self.stockData[iconName] = priceData
                self.isLoading = false
            }
        } catch {
            // #region agent log
            debugLog("StockService:fetchStockData", "Error", ["symbol": symbol, "error": error.localizedDescription], hypothesisId: "H5")
            // #endregion
            
            let fallbackData = createFallbackData(for: displaySymbol)
            await MainActor.run {
                self.stockData[iconName] = fallbackData
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func fetchAllStocks() async {
        await fetchAllStocksInParallel()
    }
    
    func fetchAllStocksInParallel(range: String = "1d", interval: String = "5m") async {
        await MainActor.run {
            self.isLoading = true
        }
        
        // #region agent log
        debugLog("StockService:fetchAllStocksInParallel", "Starting fetch with historical data", ["range": range], hypothesisId: "H1")
        // #endregion
        
        // Fetch each stock with quote + historical data
        // Use TaskGroup for parallel fetching (faster)
        await withTaskGroup(of: Void.self) { group in
            for (iconName, symbol) in symbolMapping {
                group.addTask {
                    await self.fetchSingleStock(iconName: iconName, symbol: symbol, range: range)
                }
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    private func fetchSingleStock(iconName: String, symbol: String, range: String) async {
        let displaySymbol = displaySymbols[iconName] ?? (symbol + "x")
        
        do {
            // Fetch quote and history in parallel
            async let quoteTask = fetchQuote(symbol: symbol)
            async let historyTask = fetchHistory(symbol: symbol, range: range)
            
            let (quote, history) = try await (quoteTask, historyTask)
            
            let priceData = processData(quote: quote, history: history, displaySymbol: displaySymbol)
            cache["\(iconName)-\(range)"] = (priceData, Date())
            
            await MainActor.run {
                self.stockData[iconName] = priceData
            }
            
            // #region agent log
            debugLog("StockService:fetchSingleStock", "Success", ["symbol": symbol, "price": quote.price, "historyCount": history.count], hypothesisId: "H1")
            // #endregion
            
        } catch {
            // #region agent log
            debugLog("StockService:fetchSingleStock", "Failed", ["symbol": symbol, "error": error.localizedDescription], hypothesisId: "H5")
            // #endregion
            
            // Set fallback data
            let fallback = createFallbackData(for: displaySymbol)
            await MainActor.run {
                self.stockData[iconName] = fallback
            }
        }
    }
    
    func fetchAllStocksForPeriodInParallel(period: String) async {
        await fetchAllStocksInParallel(range: period)
    }
    
    func fetchStockForPeriod(iconName: String, period: String) async {
        await fetchStockData(for: iconName, range: period)
    }
    
    // MARK: - Private API Methods
    
    private func fetchQuote(symbol: String) async throws -> FMPQuote {
        // Use stable endpoint format: /stable/quote?symbol=AAPL
        let urlString = "\(baseURL)/quote?symbol=\(symbol)&apikey=\(fmpAPIKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        // Check for error message in response
        if let errorString = String(data: data, encoding: .utf8),
           errorString.contains("Restricted") || errorString.contains("Premium") {
            throw URLError(.resourceUnavailable)
        }
        
        let quotes = try JSONDecoder().decode([FMPQuote].self, from: data)
        guard let quote = quotes.first else { throw URLError(.cannotParseResponse) }
        return quote
    }
    
    private func fetchBatchQuotes(symbols: [String]) async throws -> [FMPQuote] {
        let symbolsParam = symbols.joined(separator: ",")
        let urlString = "\(baseURL)/quote/\(symbolsParam)?apikey=\(fmpAPIKey)"
        
        // #region agent log
        debugLog("StockService:fetchBatchQuotes", "Fetching", ["url": urlString.replacingOccurrences(of: fmpAPIKey, with: "***")], hypothesisId: "H1")
        // #endregion
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            // #region agent log
            debugLog("StockService:fetchBatchQuotes", "Response", ["statusCode": httpResponse.statusCode], hypothesisId: "H1")
            // #endregion
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
        }
        
        let quotes = try JSONDecoder().decode([FMPQuote].self, from: data)
        
        // #region agent log
        debugLog("StockService:fetchBatchQuotes", "Parsed", ["quoteCount": quotes.count], hypothesisId: "H1")
        // #endregion
        
        return quotes
    }
    
    private func fetchHistory(symbol: String, range: String) async throws -> [FMPHistoricalPrice] {
        let interval = getInterval(for: range)
        // Stable endpoint format: /stable/historical-chart/5min?symbol=AAPL
        let urlString = "\(baseURL)/historical-chart/\(interval)?symbol=\(symbol)&apikey=\(fmpAPIKey)"
        
        // #region agent log
        debugLog("StockService:fetchHistory", "Fetching", ["symbol": symbol, "interval": interval], hypothesisId: "H1")
        // #endregion
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        // Check for error message
        if let errorString = String(data: data, encoding: .utf8),
           errorString.contains("Restricted") || errorString.contains("Premium") {
            throw URLError(.resourceUnavailable)
        }
        
        let history = try JSONDecoder().decode([FMPHistoricalPrice].self, from: data)
        
        // #region agent log
        debugLog("StockService:fetchHistory", "Received", ["symbol": symbol, "count": history.count], hypothesisId: "H1")
        // #endregion
        
        return history
    }
    
    // MARK: - Data Processing
    
    private func processData(quote: FMPQuote, history: [FMPHistoricalPrice], displaySymbol: String) -> StockPriceData {
        let currentPrice = quote.price
        let previousClose = quote.previousClose
        let priceChange = quote.change
        let percentChange = quote.changePercentage
        
        // Historical prices (newest first in FMP, so reverse)
        var closePrices = history.map { $0.close }
        if !closePrices.isEmpty {
            closePrices = closePrices.reversed()
        }
        
        // Parse timestamps
        var timestamps: [Date] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        for item in history.reversed() {
            if let date = formatter.date(from: item.date) {
                timestamps.append(date)
            }
        }
        
        // Use quote price if no history
        if closePrices.isEmpty {
            closePrices = [previousClose, currentPrice]
        }
        
        let trimmedPrices = trimTrailingFlatPrices(closePrices)
        let normalizedPrices = normalizePrices(trimmedPrices)
        
        return StockPriceData(
            symbol: displaySymbol,
            currentPrice: currentPrice,
            previousClose: previousClose,
            priceChange: priceChange,
            percentChange: percentChange,
            isPositive: priceChange >= 0,
            historicalPrices: normalizedPrices,
            rawPrices: trimmedPrices,
            timestamps: timestamps
        )
    }
    
    private func processQuoteOnly(quote: FMPQuote, displaySymbol: String) -> StockPriceData {
        // Generate synthetic chart data based on previous close and current price
        let prices = generateSyntheticPrices(from: quote.previousClose, to: quote.price, points: 50)
        let normalized = normalizePrices(prices)
        
        return StockPriceData(
            symbol: displaySymbol,
            currentPrice: quote.price,
            previousClose: quote.previousClose,
            priceChange: quote.change,
            percentChange: quote.changePercentage,
            isPositive: quote.change >= 0,
            historicalPrices: normalized,
            rawPrices: prices,
            timestamps: []
        )
    }
    
    /// Generate synthetic price movement for chart visualization
    private func generateSyntheticPrices(from start: Double, to end: Double, points: Int) -> [Double] {
        guard points > 1 else { return [end] }
        var prices: [Double] = []
        let change = end - start
        
        for i in 0..<points {
            let progress = Double(i) / Double(points - 1)
            // Add some natural-looking variation
            let noise = sin(Double(i) * 0.5) * abs(change) * 0.1
            let price = start + (change * progress) + noise
            prices.append(price)
        }
        // Ensure last price matches current
        prices[prices.count - 1] = end
        return prices
    }
    
    private func createFallbackData(for displaySymbol: String) -> StockPriceData {
        return StockPriceData(
            symbol: displaySymbol,
            currentPrice: 0,
            previousClose: 0,
            priceChange: 0,
            percentChange: 0,
            isPositive: true,
            historicalPrices: [0.5, 0.5, 0.5, 0.5, 0.5],
            rawPrices: [0, 0, 0, 0, 0],
            timestamps: []
        )
    }
    
    // MARK: - Helpers
    
    private func getInterval(for range: String) -> String {
        switch range {
        case "1H": return "1min"
        case "1D": return "5min"
        case "1W": return "15min"
        case "1M": return "1hour"
        case "1Y": return "4hour"
        case "All": return "4hour"
        default: return "5min"
        }
    }
    
    private func trimTrailingFlatPrices(_ prices: [Double]) -> [Double] {
        guard prices.count > 20 else { return prices }
        guard let overallMin = prices.min(),
              let overallMax = prices.max(),
              overallMax > overallMin else { return prices }
        
        let overallRange = overallMax - overallMin
        let checkStartIndex = Int(Double(prices.count) * 0.6)
        let tailPrices = Array(prices.suffix(from: checkStartIndex))
        
        guard let tailMin = tailPrices.min(),
              let tailMax = tailPrices.max() else { return prices }
        
        let tailRange = tailMax - tailMin
        
        if tailRange < overallRange * 0.05 {
            let flatPrice = tailPrices.last!
            let tolerance = overallRange * 0.02
            var cutIndex = prices.count
            for i in stride(from: prices.count - 1, through: 0, by: -1) {
                if abs(prices[i] - flatPrice) > tolerance {
                    cutIndex = i + 2
                    break
                }
            }
            return Array(prices.prefix(min(cutIndex, prices.count)))
        }
        return prices
    }
    
    private func normalizePrices(_ prices: [Double]) -> [Double] {
        guard !prices.isEmpty else { return [] }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 1
        let range = maxPrice - minPrice
        if range == 0 { return prices.map { _ in 0.5 } }
        return prices.map { ($0 - minPrice) / range }
    }
    
    func samplePrices(_ prices: [Double], to count: Int = 10) -> [CGFloat] {
        guard prices.count >= count else {
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
