import Foundation

// MARK: - Recurring Purchase Frequency

enum RecurringFrequency: String, CaseIterable, Identifiable, Codable {
    case daily = "daily"
    case weekly = "weekly" 
    case biweekly = "biweekly"
    case monthly = "monthly"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .biweekly:
            return "Every 2 weeks"
        case .monthly:
            return "Monthly"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .biweekly:
            return "Biweekly"
        case .monthly:
            return "Monthly"
        }
    }
    
    // Calculate next purchase date from a given date
    func nextDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}

// MARK: - Recurring Purchase Status

enum RecurringPurchaseStatus: String, CaseIterable, Codable {
    case active = "active"
    case paused = "paused"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .paused:
            return "Paused"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .active:
            return "57CE43" // positive green
        case .paused:
            return "FF8C00" // orange
        case .cancelled:
            return "8E8E93" // secondary text
        }
    }
}

// MARK: - Recurring Purchase Model

struct RecurringPurchase: Identifiable, Codable {
    let id: UUID
    let stockIconName: String // e.g., "StockApple"
    let stockSymbol: String   // e.g., "AAPL"
    let stockName: String     // e.g., "Apple Inc"
    let amount: Double        // USD amount to purchase each time
    let frequency: RecurringFrequency
    var status: RecurringPurchaseStatus
    let createdAt: Date
    var nextPurchaseDate: Date
    var lastPurchaseDate: Date?
    var totalInvested: Double // Running total of all purchases made
    var purchaseCount: Int    // Number of purchases completed
    
    init(stockIconName: String, stockSymbol: String, stockName: String, amount: Double, frequency: RecurringFrequency) {
        self.id = UUID()
        self.stockIconName = stockIconName
        self.stockSymbol = stockSymbol
        self.stockName = stockName
        self.amount = amount
        self.frequency = frequency
        self.status = .active
        self.createdAt = Date()
        self.nextPurchaseDate = frequency.nextDate(from: Date())
        self.lastPurchaseDate = nil
        self.totalInvested = 0
        self.purchaseCount = 0
    }
    
    // MARK: - Computed Properties
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "£\(Int(amount))"
    }
    
    var formattedTotalInvested: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: totalInvested)) ?? "£\(totalInvested)"
    }
    
    var formattedNextPurchase: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: nextPurchaseDate)
    }
    
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
    
    var daysUntilNextPurchase: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextPurchaseDate).day ?? 0
    }
    
    var nextPurchaseDescription: String {
        let days = daysUntilNextPurchase
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 0 {
            return "Overdue"
        } else {
            return "In \(days) days"
        }
    }
    
    // MARK: - Purchase Execution
    
    mutating func recordPurchase(purchaseDate: Date = Date()) {
        self.lastPurchaseDate = purchaseDate
        self.totalInvested += amount
        self.purchaseCount += 1
        self.nextPurchaseDate = frequency.nextDate(from: purchaseDate)
    }
    
    mutating func pause() {
        self.status = .paused
    }
    
    mutating func resume() {
        self.status = .active
        // Update next purchase date if it's in the past
        if nextPurchaseDate < Date() {
            self.nextPurchaseDate = frequency.nextDate(from: Date())
        }
    }
    
    mutating func cancel() {
        self.status = .cancelled
    }
    
    // Check if this purchase is due to execute
    var isDue: Bool {
        guard status == .active else { return false }
        return Date() >= nextPurchaseDate
    }
}

// MARK: - Recurring Purchase History

struct RecurringPurchaseExecution: Identifiable, Codable {
    let id: UUID
    let recurringPurchaseId: UUID
    let executionDate: Date
    let amount: Double
    let pricePerShare: Double
    let shares: Double
    let stockIconName: String
    let stockSymbol: String
    let success: Bool
    let errorMessage: String?
    
    init(recurringPurchaseId: UUID, amount: Double, pricePerShare: Double, shares: Double, 
         stockIconName: String, stockSymbol: String, success: Bool = true, errorMessage: String? = nil) {
        self.id = UUID()
        self.recurringPurchaseId = recurringPurchaseId
        self.executionDate = Date()
        self.amount = amount
        self.pricePerShare = pricePerShare
        self.shares = shares
        self.stockIconName = stockIconName
        self.stockSymbol = stockSymbol
        self.success = success
        self.errorMessage = errorMessage
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "£\(amount)"
    }
    
    var formattedShares: String {
        String(format: "%.4f", shares)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: executionDate)
    }
}
