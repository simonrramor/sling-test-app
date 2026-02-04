import Foundation
import Combine

// MARK: - Ondo Tokenized Stock Configuration

/// Ondo Global Markets - Tokenized US Stocks
/// Since Ondo tokens track 1:1 with underlying stocks, we use real stock prices
/// and display them as tokenized versions (AAPLon, TSLAon, etc.)

// MARK: - FMP Response Models (for real stock prices)

private struct OndoFMPQuote: Codable {
    let symbol: String
    let price: Double
    let changePercentage: Double
    let change: Double
    let previousClose: Double
    let name: String?
}

private struct OndoFMPHistoricalPrice: Codable {
    let date: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
}

// MARK: - Ondo Token Price Data

struct OndoTokenPriceData {
    let tokenId: String           // Ondo token identifier
    let symbol: String            // Display symbol (e.g., "AAPLon")
    let underlyingSymbol: String  // Underlying stock symbol (e.g., "AAPL")
    let currentPrice: Double
    let previousClose: Double
    let priceChange: Double
    let percentChange: Double
    let isPositive: Bool
    let historicalPrices: [Double] // Normalized 0-1 for chart
    let rawPrices: [Double]        // Actual price values
    let timestamps: [Date]
    let isOndo: Bool = true        // Flag to identify Ondo tokens
    
    var formattedPrice: String {
        return currentPrice.asUSD
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

// MARK: - Ondo Token Definition

struct OndoTokenDefinition {
    let ondoSymbol: String        // Ondo token symbol (e.g., "AAPLon")
    let underlyingSymbol: String  // Underlying stock symbol (e.g., "AAPL")
    let name: String              // Display name
    let iconName: String          // Asset icon name in app
    let contractAddress: String?  // Ethereum contract address (if known)
}

// MARK: - Ondo Service

class OndoService: ObservableObject {
    static let shared = OndoService()
    
    @Published var tokenData: [String: OndoTokenPriceData] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    private var cache: [String: (data: OndoTokenPriceData, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minute cache
    
    // FMP API for real stock prices (Ondo tokens track 1:1 with underlying)
    private let fmpAPIKey = "Ng1HqWPxPHz3ScqxhLKOb77HO4Q8zdvX"
    private let baseURL = "https://financialmodelingprep.com/stable"
    
    // Map of available Ondo tokenized stocks
    let availableTokens: [OndoTokenDefinition] = [
        OndoTokenDefinition(
            ondoSymbol: "AAPLon",
            underlyingSymbol: "AAPL",
            name: "Apple (Ondo)",
            iconName: "StockApple",
            contractAddress: "0x14c3abf95cb9c93a8b82c1cdcb76d72cb87b2d4c"
        ),
        OndoTokenDefinition(
            ondoSymbol: "AMZNon",
            underlyingSymbol: "AMZN",
            name: "Amazon (Ondo)",
            iconName: "StockAmazon",
            contractAddress: "0xbb8774fb97436d23d74c1b882e8e9a69322cfd31"
        ),
        OndoTokenDefinition(
            ondoSymbol: "TSLAon",
            underlyingSymbol: "TSLA",
            name: "Tesla (Ondo)",
            iconName: "StockTesla",
            contractAddress: nil
        ),
        OndoTokenDefinition(
            ondoSymbol: "GOOGon",
            underlyingSymbol: "GOOGL",
            name: "Google (Ondo)",
            iconName: "StockGoogle",
            contractAddress: nil
        ),
        OndoTokenDefinition(
            ondoSymbol: "MSFTon",
            underlyingSymbol: "MSFT",
            name: "Microsoft (Ondo)",
            iconName: "StockMicrosoft",
            contractAddress: nil
        ),
        OndoTokenDefinition(
            ondoSymbol: "METAon",
            underlyingSymbol: "META",
            name: "Meta (Ondo)",
            iconName: "StockMeta",
            contractAddress: nil
        ),
        OndoTokenDefinition(
            ondoSymbol: "COINon",
            underlyingSymbol: "COIN",
            name: "Coinbase (Ondo)",
            iconName: "StockCoinbase",
            contractAddress: nil
        ),
        OndoTokenDefinition(
            ondoSymbol: "Von",
            underlyingSymbol: "V",
            name: "Visa (Ondo)",
            iconName: "StockVisa",
            contractAddress: nil
        ),
        OndoTokenDefinition(
            ondoSymbol: "MCDon",
            underlyingSymbol: "MCD",
            name: "McDonalds (Ondo)",
            iconName: "StockMcDonalds",
            contractAddress: nil
        )
    ]
    
    // Map icon names to token definitions
    var iconToToken: [String: OndoTokenDefinition] {
        Dictionary(uniqueKeysWithValues: availableTokens.map { ($0.iconName, $0) })
    }
    
    // Map underlying symbols to token definitions
    var symbolToToken: [String: OndoTokenDefinition] {
        Dictionary(uniqueKeysWithValues: availableTokens.map { ($0.underlyingSymbol, $0) })
    }
    
    private init() {
        // Start fetching on init
        Task {
            await fetchAllTokens()
        }
    }
    
    // MARK: - Public API
    
    /// Fetch all Ondo tokenized stock prices
    func fetchAllTokens() async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        // Use TaskGroup for parallel fetching
        await withTaskGroup(of: Void.self) { group in
            for token in availableTokens {
                group.addTask {
                    await self.fetchSingleToken(token: token, range: "1d")
                }
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    /// Fetch a single token's data
    private func fetchSingleToken(token: OndoTokenDefinition, range: String) async {
        // Check cache
        let cacheKey = "\(token.iconName)-\(range)"
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            await MainActor.run {
                self.tokenData[token.iconName] = cached.data
            }
            return
        }
        
        do {
            // Fetch quote and history in parallel
            async let quoteTask = fetchQuote(symbol: token.underlyingSymbol)
            async let historyTask = fetchHistory(symbol: token.underlyingSymbol, range: range)
            
            let (quote, history) = try await (quoteTask, historyTask)
            
            let priceData = processData(token: token, quote: quote, history: history)
            cache[cacheKey] = (priceData, Date())
            
            await MainActor.run {
                self.tokenData[token.iconName] = priceData
            }
            
            print("OndoService: Fetched \(token.ondoSymbol) - $\(quote.price)")
            
        } catch {
            print("OndoService: Error fetching \(token.ondoSymbol) - \(error.localizedDescription)")
            
            // Set fallback data
            let fallback = createFallbackData(for: token)
            await MainActor.run {
                self.tokenData[token.iconName] = fallback
            }
        }
    }
    
    /// Fetch token for a specific icon name
    func fetchToken(iconName: String) async {
        guard let token = iconToToken[iconName] else { return }
        await fetchSingleToken(token: token, range: "1d")
    }
    
    /// Fetch token data for a specific time period
    func fetchTokenForPeriod(iconName: String, period: String) async {
        guard let token = iconToToken[iconName] else { return }
        await fetchSingleToken(token: token, range: period)
    }
    
    // MARK: - Private API Methods
    
    private func fetchQuote(symbol: String) async throws -> OndoFMPQuote {
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
        
        let quotes = try JSONDecoder().decode([OndoFMPQuote].self, from: data)
        guard let quote = quotes.first else { throw URLError(.cannotParseResponse) }
        return quote
    }
    
    private func fetchHistory(symbol: String, range: String) async throws -> [OndoFMPHistoricalPrice] {
        let interval = getInterval(for: range)
        let urlString = "\(baseURL)/historical-chart/\(interval)?symbol=\(symbol)&apikey=\(fmpAPIKey)"
        
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
        
        let history = try JSONDecoder().decode([OndoFMPHistoricalPrice].self, from: data)
        return history
    }
    
    // MARK: - Data Processing
    
    private func processData(token: OndoTokenDefinition, quote: OndoFMPQuote, history: [OndoFMPHistoricalPrice]) -> OndoTokenPriceData {
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
        
        return OndoTokenPriceData(
            tokenId: token.ondoSymbol,
            symbol: token.ondoSymbol,
            underlyingSymbol: token.underlyingSymbol,
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
    
    private func createFallbackData(for token: OndoTokenDefinition) -> OndoTokenPriceData {
        return OndoTokenPriceData(
            tokenId: token.ondoSymbol,
            symbol: token.ondoSymbol,
            underlyingSymbol: token.underlyingSymbol,
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
    
    /// Check if an icon name has an Ondo tokenized version
    func hasOndoToken(for iconName: String) -> Bool {
        return iconToToken[iconName] != nil
    }
    
    /// Get the Ondo symbol for a stock icon
    func ondoSymbol(for iconName: String) -> String? {
        return iconToToken[iconName]?.ondoSymbol
    }
    
    /// Sample prices for mini chart display
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
