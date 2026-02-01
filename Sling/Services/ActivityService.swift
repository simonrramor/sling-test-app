import Foundation
import Combine

// MARK: - KMP Migration Guide
// ============================================================================
// This service is being migrated to Kotlin Multiplatform (KMP).
// The shared business logic is now in: shared/src/commonMain/kotlin/com/sling/shared/services/
//
// To complete the migration:
// 1. Build the shared KMP framework:
//    ./gradlew :shared:linkDebugFrameworkIosSimulatorArm64  (for simulator)
//    ./gradlew :shared:linkDebugFrameworkIosArm64          (for device)
//
// 2. Run pod install to integrate the framework
//
// 3. Replace usages of ActivityService.shared with SharedActivityService.shared
//    The SharedActivityService wrapper provides the same API while using KMP logic.
//
// 4. Once verified, this file can be removed in favor of SharedActivityService.swift
// ============================================================================

// MARK: - Activity Item Model

struct ActivityItem: Identifiable {
    let id = UUID()
    let avatar: String
    let titleLeft: String
    let subtitleLeft: String
    let titleRight: String
    let subtitleRight: String
    let date: Date?
    
    // Formatted date for display (short)
    var formattedDate: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    // Formatted date for detail view (long)
    var formattedDateLong: String {
        guard let date = date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
    
    // Section title based on date
    var sectionTitle: String {
        guard let date = date else { return "Recent" }
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Activity Service

class ActivityService: ObservableObject {
    static let shared = ActivityService()
    
    @Published var activities: [ActivityItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let sheetId = "1zEHThVwTJEoecibJhn5lq6ePY3YZ4v_1BnTpvYO_kis"
    
    // Track local activities separately so they persist across fetches
    private var localActivities: [ActivityItem] = []
    private var fetchedActivities: [ActivityItem] = []
    private var hasFetchedOnce = false
    
    private let persistence = PersistenceService.shared
    
    // Track if user is active (has made transactions) - new users start with empty feed
    private let isActiveUserKey = "isActiveUser"
    var isActiveUser: Bool {
        get { UserDefaults.standard.bool(forKey: isActiveUserKey) }
        set { UserDefaults.standard.set(newValue, forKey: isActiveUserKey) }
    }
    
    private init() {
        // Load persisted local activities from iCloud
        let persisted = persistence.loadActivities()
        for p in persisted {
            let item = ActivityItem(
                avatar: p.avatar,
                titleLeft: p.titleLeft,
                subtitleLeft: p.subtitleLeft,
                titleRight: p.titleRight,
                subtitleRight: p.subtitleRight,
                date: p.date
            )
            localActivities.append(item)
        }
        
        if !localActivities.isEmpty {
            print("ActivityService: Restored \(localActivities.count) activities from iCloud")
            isActiveUser = true  // User has existing activities, mark as active
            updateCombinedActivities()
        }
    }
    
    // MARK: - Persistence
    
    private func saveLocalActivitiesToCloud() {
        let persisted = localActivities.map { a in
            PersistedActivityItem(
                avatar: a.avatar,
                titleLeft: a.titleLeft,
                subtitleLeft: a.subtitleLeft,
                titleRight: a.titleRight,
                subtitleRight: a.subtitleRight,
                date: a.date
            )
        }
        persistence.saveActivities(persisted)
    }
    
    // MARK: - Add Local Activity
    
    /// Adds a new activity to the list (e.g., after add money, buy, sell)
    func addActivity(
        avatar: String,
        titleLeft: String,
        subtitleLeft: String,
        titleRight: String,
        subtitleRight: String = "",
        date: Date = Date()
    ) {
        let newItem = ActivityItem(
            avatar: avatar,
            titleLeft: titleLeft,
            subtitleLeft: subtitleLeft,
            titleRight: titleRight,
            subtitleRight: subtitleRight,
            date: date
        )
        
        // Add to local activities
        localActivities.insert(newItem, at: 0)
        
        // Mark user as active (has made transactions)
        isActiveUser = true
        
        // Update combined activities list
        updateCombinedActivities()
        
        // Save to iCloud
        saveLocalActivitiesToCloud()
    }
    
    /// Combines local and fetched activities, sorted by date
    private func updateCombinedActivities() {
        var combined = localActivities + fetchedActivities
        
        // Sort by date (most recent first)
        combined.sort { (a, b) in
            guard let dateA = a.date else { return true }
            guard let dateB = b.date else { return false }
            return dateA > dateB
        }
        
        activities = combined
    }
    
    /// Convenience method for add money transactions
    func recordAddMoney(
        fromAccountName: String,
        fromAccountAvatar: String,
        amount: Double,
        currency: String = "GBP"
    ) {
        let symbol = currency == "GBP" ? "£" : (currency == "USD" ? "$" : (currency == "EUR" ? "€" : currency))
        let formattedAmount = String(format: "+%@%.2f", symbol, amount)
        
        addActivity(
            avatar: fromAccountAvatar,
            titleLeft: fromAccountName,
            subtitleLeft: "",
            titleRight: formattedAmount,
            subtitleRight: ""
        )
    }
    
    /// Convenience method for stock buy transactions
    func recordBuyStock(
        stockName: String,
        stockIcon: String,
        amount: Double,
        shares: Double,
        symbol: String
    ) {
        let formattedAmount = String(format: "-£%.2f", amount)
        let formattedShares = String(format: "+%.2f %@", shares, symbol)
        
        addActivity(
            avatar: stockIcon,
            titleLeft: stockName,
            subtitleLeft: "",
            titleRight: formattedAmount,
            subtitleRight: formattedShares
        )
    }
    
    /// Convenience method for stock sell transactions
    func recordSellStock(
        stockName: String,
        stockIcon: String,
        amount: Double,
        shares: Double,
        symbol: String
    ) {
        let formattedAmount = String(format: "+£%.2f", amount)
        let formattedShares = String(format: "%.2f %@", shares, symbol)
        
        addActivity(
            avatar: stockIcon,
            titleLeft: stockName,
            subtitleLeft: "Sold \(formattedShares)",
            titleRight: formattedAmount,
            subtitleRight: ""
        )
    }
    
    /// Convenience method for send money transactions
    func recordSendMoney(
        toContactName: String,
        toContactAvatar: String,
        amount: Double
    ) {
        let formattedAmount = String(format: "-£%.2f", amount)
        
        addActivity(
            avatar: toContactAvatar,
            titleLeft: toContactName,
            subtitleLeft: "",
            titleRight: formattedAmount,
            subtitleRight: ""
        )
    }
    
    /// Convenience method for request money transactions
    func recordRequestMoney(
        fromContactName: String,
        fromContactAvatar: String,
        amount: Double
    ) {
        let formattedAmount = String(format: "£%.2f", amount)
        
        addActivity(
            avatar: fromContactAvatar,
            titleLeft: fromContactName,
            subtitleLeft: "Requested",
            titleRight: formattedAmount,
            subtitleRight: ""
        )
    }
    
    /// Convenience method for split bill transactions
    func recordSplitBill(
        merchantName: String,
        merchantAvatar: String,
        splitAmount: Double,
        withContactName: String
    ) {
        let formattedAmount = String(format: "£%.2f", splitAmount)
        
        addActivity(
            avatar: merchantAvatar,
            titleLeft: merchantName,
            subtitleLeft: "Split with \(withContactName)",
            titleRight: formattedAmount,
            subtitleRight: ""
        )
    }
    
    /// Convenience method for card payment at merchant
    func recordCardPayment(
        merchantName: String,
        merchantAvatar: String,
        amount: Double
    ) {
        let formattedAmount = String(format: "-£%.2f", amount)
        
        addActivity(
            avatar: merchantAvatar,
            titleLeft: merchantName,
            subtitleLeft: "Card payment",
            titleRight: formattedAmount,
            subtitleRight: ""
        )
    }
    
    /// Convenience method for receiving money (P2P inbound)
    func recordReceivedMoney(
        fromContactName: String,
        fromContactAvatar: String,
        amount: Double
    ) {
        let formattedAmount = String(format: "+£%.2f", amount)
        
        addActivity(
            avatar: fromContactAvatar,
            titleLeft: fromContactName,
            subtitleLeft: "Received",
            titleRight: formattedAmount,
            subtitleRight: ""
        )
    }
    
    /// Convenience method for top up transactions
    func recordTopUp(
        amount: Double,
        source: String = "Bank Transfer"
    ) {
        let formattedAmount = String(format: "+£%.2f", amount)
        
        addActivity(
            avatar: "🏦",
            titleLeft: "Top Up",
            subtitleLeft: source,
            titleRight: formattedAmount,
            subtitleRight: ""
        )
    }
    
    /// Convenience method for withdrawal transactions
    func recordWithdrawal(
        amount: Double,
        method: String = "ATM"
    ) {
        let formattedAmount = String(format: "-£%.2f", amount)
        
        addActivity(
            avatar: "💳",
            titleLeft: "Withdrawal",
            subtitleLeft: method,
            titleRight: formattedAmount,
            subtitleRight: ""
        )
    }
    
    // MARK: - Test Data Generation
    
    private let sampleMerchants: [(name: String, avatar: String)] = [
        ("Tesco", "tesco.com"),
        ("Amazon", "amazon.com"),
        ("Uber", "uber.com"),
        ("Deliveroo", "deliveroo.com"),
        ("Netflix", "netflix.com"),
        ("Spotify", "spotify.com"),
        ("Costa", "costa.co.uk"),
        ("Apple", "apple.com"),
        ("TfL", "tfl.gov.uk"),
        ("Sainsbury's", "sainsburys.co.uk")
    ]
    
    private let sampleContacts: [(name: String, avatar: String)] = [
        ("Emma", "E"),
        ("James", "J"),
        ("Sarah", "S"),
        ("Michael", "M"),
        ("Lucy", "L"),
        ("Tom", "T"),
        ("Sophie", "S"),
        ("Ben", "B")
    ]
    
    /// Generate a single random card payment
    func generateCardPayment() {
        let merchant = sampleMerchants.randomElement()!
        let amount = Double.random(in: 2.50...85.00)
        recordCardPayment(merchantName: merchant.name, merchantAvatar: merchant.avatar, amount: amount)
    }
    
    /// Generate a single random P2P outbound (send money)
    func generateP2POutbound() {
        let contact = sampleContacts.randomElement()!
        let amount = Double.random(in: 5.00...100.00)
        recordSendMoney(toContactName: contact.name, toContactAvatar: contact.avatar, amount: amount)
    }
    
    /// Generate a single random P2P inbound (receive money)
    func generateP2PInbound() {
        let contact = sampleContacts.randomElement()!
        let amount = Double.random(in: 5.00...150.00)
        recordReceivedMoney(fromContactName: contact.name, fromContactAvatar: contact.avatar, amount: amount)
    }
    
    /// Generate a single random top up
    func generateTopUp() {
        let sources = ["Bank Transfer", "Apple Pay", "Debit Card"]
        let amount = Double.random(in: 20.00...500.00)
        recordTopUp(amount: amount, source: sources.randomElement()!)
    }
    
    /// Generate a single random withdrawal
    func generateWithdrawal() {
        let methods = ["ATM", "Bank Transfer", "Cash Back"]
        let amount = Double.random(in: 10.00...200.00)
        recordWithdrawal(amount: amount, method: methods.randomElement()!)
    }
    
    /// Generate a random mix of transactions
    func generateRandomMix(count: Int = 8) {
        let generators: [() -> Void] = [
            generateCardPayment,
            generateP2POutbound,
            generateP2PInbound,
            generateTopUp,
            generateWithdrawal
        ]
        
        for _ in 0..<count {
            let generator = generators.randomElement()!
            generator()
        }
    }
    
    func fetchActivities(force: Bool = false) async {
        // Skip fetch for new users - they should only see their own local activities
        if !isActiveUser {
            print("ActivityService: New user, showing empty feed")
            await MainActor.run {
                self.isLoading = false
            }
            return
        }
        
        // Skip fetch if already fetched and not forced (e.g., pull-to-refresh)
        if hasFetchedOnce && !force {
            print("ActivityService: Already fetched, skipping...")
            return
        }
        
        print("ActivityService: Starting fetch for active user...")
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        // Google Sheets CSV export URL
        let urlString = "https://docs.google.com/spreadsheets/d/\(sheetId)/export?format=csv&gid=0"
        print("ActivityService: Fetching from \(urlString)")
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.error = "Invalid URL"
                self.isLoading = false
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let csvString = String(data: data, encoding: .utf8) else {
                print("ActivityService: Failed to decode data")
                await MainActor.run {
                    self.error = "Failed to decode data"
                    self.isLoading = false
                }
                return
            }
            
            print("ActivityService: Received CSV data:")
            print(csvString)
            
            let items = parseCSV(csvString)
            
            print("ActivityService: Parsed \(items.count) items")
            for item in items {
                print("  - \(item.titleLeft): \(item.titleRight)")
            }
            
            await MainActor.run {
                self.fetchedActivities = items
                self.hasFetchedOnce = true
                self.updateCombinedActivities()
                self.isLoading = false
            }
        } catch {
            print("ActivityService: Error fetching data: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func parseCSV(_ csv: String) -> [ActivityItem] {
        var items: [ActivityItem] = []
        
        // Date formatters for parsing DD/MM/YYYY or DD/MM/YY
        let dateFormatter4 = DateFormatter()
        dateFormatter4.dateFormat = "dd/MM/yyyy"
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "dd/MM/yy"
        // Set the two-digit year start date to 2000 so "20" becomes 2020, not 0020
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let startOf2000 = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        dateFormatter2.twoDigitStartDate = startOf2000
        
        // Normalize line endings and split into lines
        let normalizedCSV = csv.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let lines = normalizedCSV.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        print("ActivityService: Total lines: \(lines.count)")
        
        // Skip header row (first line)
        for (index, line) in lines.enumerated() {
            if index == 0 {
                continue
            }
            
            let columns = parseCSVLine(line)
            
            // New column order: Avatar, Title-left, Subtitle-left, Title-right, Subtitle-right, date
            if columns.count >= 5 {
                let dateString = columns.count >= 6 ? columns[5].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                // Try 4-digit year first, then 2-digit
                let date = dateFormatter4.date(from: dateString) ?? dateFormatter2.date(from: dateString)
                
                let item = ActivityItem(
                    avatar: columns[0].trimmingCharacters(in: .whitespacesAndNewlines),
                    titleLeft: columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
                    subtitleLeft: columns[2].trimmingCharacters(in: .whitespacesAndNewlines),
                    titleRight: columns[3].trimmingCharacters(in: .whitespacesAndNewlines),
                    subtitleRight: columns[4].trimmingCharacters(in: .whitespacesAndNewlines),
                    date: date
                )
                items.append(item)
                print("ActivityService: Created item: \(item.titleLeft) - \(item.titleRight) - date: \(dateString)")
            }
        }
        
        // Sort by date (most recent first)
        items.sort { (a, b) in
            guard let dateA = a.date else { return false }
            guard let dateB = b.date else { return true }
            return dateA > dateB
        }
        
        print("ActivityService: Parsed \(items.count) items")
        return items
    }
    
    // MARK: - Clear Local Activities
    
    /// Clears all activities (for reset functionality)
    func clearLocalActivities() {
        localActivities = []
        fetchedActivities = []
        hasFetchedOnce = false
        activities = []
        isActiveUser = false  // Reset to new user state
        saveLocalActivitiesToCloud()
        print("ActivityService: Cleared all activities, reset to new user state")
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // Add the last field
        result.append(currentField)
        
        return result
    }
}
