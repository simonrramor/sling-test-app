import Foundation
import Combine

// MARK: - Recurring Purchase Service

class RecurringPurchaseService: ObservableObject {
    static let shared = RecurringPurchaseService()
    
    @Published var recurringPurchases: [RecurringPurchase] = []
    @Published var executionHistory: [RecurringPurchaseExecution] = []
    
    private let portfolioService = PortfolioService.shared
    private let ondoService = OndoService.shared
    private let persistence = PersistenceService.shared
    
    // Timer for checking and executing purchases
    private var executionTimer: Timer?
    
    private init() {
        loadPersistedData()
        startExecutionTimer()
    }
    
    deinit {
        executionTimer?.invalidate()
    }
    
    // MARK: - Persistence
    
    private func loadPersistedData() {
        if let data = UserDefaults.standard.data(forKey: "recurringPurchases"),
           let decoded = try? JSONDecoder().decode([RecurringPurchase].self, from: data) {
            recurringPurchases = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "recurringPurchaseExecutions"),
           let decoded = try? JSONDecoder().decode([RecurringPurchaseExecution].self, from: data) {
            executionHistory = decoded
        }
    }
    
    private func saveRecurringPurchases() {
        if let encoded = try? JSONEncoder().encode(recurringPurchases) {
            UserDefaults.standard.set(encoded, forKey: "recurringPurchases")
        }
    }
    
    private func saveExecutionHistory() {
        if let encoded = try? JSONEncoder().encode(executionHistory) {
            UserDefaults.standard.set(encoded, forKey: "recurringPurchaseExecutions")
        }
    }
    
    // MARK: - Timer Management
    
    private func startExecutionTimer() {
        // Check every hour for purchases due
        executionTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.checkAndExecutePurchases()
        }
    }
    
    // MARK: - Purchase Management
    
    func addRecurringPurchase(_ purchase: RecurringPurchase) {
        recurringPurchases.append(purchase)
        saveRecurringPurchases()
        debugLog("RecurringPurchaseService.addRecurringPurchase", 
                 "Added recurring purchase", 
                 ["stock": purchase.stockSymbol, "amount": purchase.amount, "frequency": purchase.frequency.rawValue])
    }
    
    func updateRecurringPurchase(_ purchase: RecurringPurchase) {
        if let index = recurringPurchases.firstIndex(where: { $0.id == purchase.id }) {
            recurringPurchases[index] = purchase
            saveRecurringPurchases()
            debugLog("RecurringPurchaseService.updateRecurringPurchase", 
                     "Updated recurring purchase", 
                     ["id": purchase.id.uuidString, "status": purchase.status.rawValue])
        }
    }
    
    func removeRecurringPurchase(_ purchase: RecurringPurchase) {
        recurringPurchases.removeAll { $0.id == purchase.id }
        saveRecurringPurchases()
        debugLog("RecurringPurchaseService.removeRecurringPurchase", 
                 "Removed recurring purchase", 
                 ["id": purchase.id.uuidString, "stock": purchase.stockSymbol])
    }
    
    func pauseRecurringPurchase(_ purchaseId: UUID) {
        if let index = recurringPurchases.firstIndex(where: { $0.id == purchaseId }) {
            recurringPurchases[index].pause()
            saveRecurringPurchases()
        }
    }
    
    func resumeRecurringPurchase(_ purchaseId: UUID) {
        if let index = recurringPurchases.firstIndex(where: { $0.id == purchaseId }) {
            recurringPurchases[index].resume()
            saveRecurringPurchases()
        }
    }
    
    func cancelRecurringPurchase(_ purchaseId: UUID) {
        if let index = recurringPurchases.firstIndex(where: { $0.id == purchaseId }) {
            recurringPurchases[index].cancel()
            saveRecurringPurchases()
        }
    }
    
    // MARK: - Purchase Execution
    
    func checkAndExecutePurchases() {
        let duePurchases = recurringPurchases.filter { $0.isDue }
        
        for purchase in duePurchases {
            executePurchase(purchase)
        }
    }
    
    private func executePurchase(_ purchase: RecurringPurchase) {
        // Check if user has sufficient funds
        guard portfolioService.cashBalance >= purchase.amount else {
            recordFailedExecution(purchase, error: "Insufficient funds")
            return
        }
        
        // Get current stock price
        guard let stockPrice = ondoService.tokenData[purchase.stockIconName]?.currentPrice else {
            recordFailedExecution(purchase, error: "Could not get stock price")
            return
        }
        
        // Calculate shares to purchase
        let sharesToBuy = purchase.amount / stockPrice
        
        // Execute the purchase through portfolio service
        let success = portfolioService.buyStock(
            iconName: purchase.stockIconName,
            symbol: purchase.stockSymbol,
            shares: sharesToBuy,
            pricePerShare: stockPrice
        )
        
        if success {
            // Record successful execution
            let execution = RecurringPurchaseExecution(
                recurringPurchaseId: purchase.id,
                amount: purchase.amount,
                pricePerShare: stockPrice,
                shares: sharesToBuy,
                stockIconName: purchase.stockIconName,
                stockSymbol: purchase.stockSymbol,
                success: true
            )
            
            executionHistory.insert(execution, at: 0) // Most recent first
            saveExecutionHistory()
            
            // Update the recurring purchase
            if let index = recurringPurchases.firstIndex(where: { $0.id == purchase.id }) {
                recurringPurchases[index].recordPurchase()
                saveRecurringPurchases()
            }
            
            debugLog("RecurringPurchaseService.executePurchase", 
                     "Successfully executed recurring purchase", 
                     ["stock": purchase.stockSymbol, "amount": purchase.amount, "shares": sharesToBuy])
            
        } else {
            recordFailedExecution(purchase, error: "Purchase failed")
        }
    }
    
    private func recordFailedExecution(_ purchase: RecurringPurchase, error: String) {
        let execution = RecurringPurchaseExecution(
            recurringPurchaseId: purchase.id,
            amount: purchase.amount,
            pricePerShare: 0,
            shares: 0,
            stockIconName: purchase.stockIconName,
            stockSymbol: purchase.stockSymbol,
            success: false,
            errorMessage: error
        )
        
        executionHistory.insert(execution, at: 0)
        saveExecutionHistory()
        
        debugLog("RecurringPurchaseService.recordFailedExecution", 
                 "Failed to execute recurring purchase", 
                 ["stock": purchase.stockSymbol, "error": error])
    }
    
    // MARK: - Data Access
    
    var activePurchases: [RecurringPurchase] {
        recurringPurchases.filter { $0.status == .active }
    }
    
    var pausedPurchases: [RecurringPurchase] {
        recurringPurchases.filter { $0.status == .paused }
    }
    
    var cancelledPurchases: [RecurringPurchase] {
        recurringPurchases.filter { $0.status == .cancelled }
    }
    
    func getRecurringPurchase(for stockIconName: String) -> RecurringPurchase? {
        return recurringPurchases.first { $0.stockIconName == stockIconName && $0.status == .active }
    }
    
    func hasRecurringPurchase(for stockIconName: String) -> Bool {
        return getRecurringPurchase(for: stockIconName) != nil
    }
    
    func getExecutionHistory(for purchaseId: UUID) -> [RecurringPurchaseExecution] {
        return executionHistory.filter { $0.recurringPurchaseId == purchaseId }
    }
    
    // MARK: - Statistics
    
    var totalMonthlyInvestment: Double {
        return activePurchases.reduce(0) { total, purchase in
            switch purchase.frequency {
            case .daily:
                return total + (purchase.amount * 30) // Approximate
            case .weekly:
                return total + (purchase.amount * 4.33) // Approximate
            case .biweekly:
                return total + (purchase.amount * 2.17) // Approximate
            case .monthly:
                return total + purchase.amount
            }
        }
    }
    
    var totalInvested: Double {
        return recurringPurchases.reduce(0) { $0 + $1.totalInvested }
    }
    
    var totalExecutions: Int {
        return recurringPurchases.reduce(0) { $0 + $1.purchaseCount }
    }
}

// MARK: - Debug Logging

private func debugLog(_ location: String, _ message: String, _ data: [String: Any] = [:]) {
    let debugLogPath = "/Users/simonamor/Desktop/sling-test-app-2/.cursor/debug.log"
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