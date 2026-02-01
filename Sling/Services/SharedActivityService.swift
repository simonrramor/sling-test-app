//
//  SharedActivityService.swift
//  sling-test-app-2
//
//  Swift wrapper for KMP ActivityService
//  Bridges Kotlin StateFlow to SwiftUI's ObservableObject pattern
//

import Foundation
import Combine
// Note: Import Shared framework when KMP build is available
// import Shared

/**
 * Swift wrapper for the KMP ActivityService
 * 
 * This provides a SwiftUI-compatible interface to the shared Kotlin business logic.
 * The wrapper collects Kotlin StateFlow values and publishes them as @Published properties.
 * 
 * Usage:
 * 1. Build the shared KMP framework: ./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
 * 2. Run pod install
 * 3. Uncomment the 'import Shared' line above
 * 4. Replace ActivityService.shared with SharedActivityService.shared in your views
 */
class SharedActivityService: ObservableObject {
    static let shared = SharedActivityService()
    
    // Published properties that mirror the KMP service's StateFlow
    @Published var activities: [ActivityItem] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // Persistence for backward compatibility during migration
    private let persistence = PersistenceService.shared
    private let isActiveUserKey = "isActiveUser"
    
    var isActiveUser: Bool {
        get { UserDefaults.standard.bool(forKey: isActiveUserKey) }
        set { UserDefaults.standard.set(newValue, forKey: isActiveUserKey) }
    }
    
    private init() {
        // Load persisted activities on init
        loadFromPersistence()
        
        // TODO: When KMP is integrated, initialize the KMP service and collect its StateFlow
        // Example:
        // let kmpService = ServiceLocator.shared.activityService
        // collectFlow(kmpService.activities) { [weak self] items in
        //     self?.activities = items.map { ActivityItem(from: $0) }
        // }
    }
    
    // MARK: - Persistence (mirrors KMP implementation)
    
    private func loadFromPersistence() {
        let persisted = persistence.loadActivities()
        activities = persisted.map { p in
            ActivityItem(
                avatar: p.avatar,
                titleLeft: p.titleLeft,
                subtitleLeft: p.subtitleLeft,
                titleRight: p.titleRight,
                subtitleRight: p.subtitleRight,
                date: p.date
            )
        }
        if !activities.isEmpty {
            isActiveUser = true
        }
    }
    
    private func saveToPersistence() {
        let persisted = activities.map { a in
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
    
    // MARK: - Public API (mirrors KMP ActivityService)
    
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
        
        activities.insert(newItem, at: 0)
        activities.sort { (a, b) in
            guard let dateA = a.date else { return true }
            guard let dateB = b.date else { return false }
            return dateA > dateB
        }
        
        isActiveUser = true
        saveToPersistence()
    }
    
    func recordSendMoney(
        contactName: String,
        contactAvatar: String,
        amount: Double
    ) {
        let formattedAmount = String(format: "-£%.2f", amount)
        addActivity(
            avatar: contactAvatar,
            titleLeft: contactName,
            subtitleLeft: "",
            titleRight: formattedAmount
        )
    }
    
    func recordReceivedMoney(
        contactName: String,
        contactAvatar: String,
        amount: Double
    ) {
        let formattedAmount = String(format: "+£%.2f", amount)
        addActivity(
            avatar: contactAvatar,
            titleLeft: contactName,
            subtitleLeft: "Received",
            titleRight: formattedAmount
        )
    }
    
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
            titleRight: formattedAmount
        )
    }
    
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
            titleRight: formattedAmount
        )
    }
    
    func recordWithdrawal(
        amount: Double,
        method: String = "ATM"
    ) {
        let formattedAmount = String(format: "-£%.2f", amount)
        addActivity(
            avatar: "💳",
            titleLeft: "Withdrawal",
            subtitleLeft: method,
            titleRight: formattedAmount
        )
    }
    
    func clearActivities() {
        activities = []
        isActiveUser = false
        persistence.saveActivities([])
    }
    
    // MARK: - Demo Data Generation
    
    private let sampleMerchants: [(name: String, avatar: String)] = [
        ("Tesco", "🛒"),
        ("Amazon", "📦"),
        ("Uber", "🚗"),
        ("Deliveroo", "🍔"),
        ("Netflix", "🎬")
    ]
    
    private let sampleContacts: [(name: String, avatar: String)] = [
        ("Emma", "E"),
        ("James", "J"),
        ("Sarah", "S"),
        ("Michael", "M")
    ]
    
    func generateRandomMix(count: Int = 8) {
        for _ in 0..<count {
            switch Int.random(in: 0...4) {
            case 0:
                let merchant = sampleMerchants.randomElement()!
                recordCardPayment(merchantName: merchant.name, merchantAvatar: merchant.avatar, amount: Double.random(in: 2.50...85.00))
            case 1:
                let contact = sampleContacts.randomElement()!
                recordSendMoney(contactName: contact.name, contactAvatar: contact.avatar, amount: Double.random(in: 5.00...100.00))
            case 2:
                let contact = sampleContacts.randomElement()!
                recordReceivedMoney(contactName: contact.name, contactAvatar: contact.avatar, amount: Double.random(in: 5.00...150.00))
            case 3:
                recordAddMoney(fromAccountName: "Bank Transfer", fromAccountAvatar: "🏦", amount: Double.random(in: 20.00...500.00))
            default:
                recordWithdrawal(amount: Double.random(in: 10.00...200.00))
            }
        }
    }
}

// MARK: - Helper to bridge Kotlin Flow to Swift (for future KMP integration)

/*
 * When KMP is fully integrated, use this pattern to collect StateFlow:
 *
 * private func collectFlow<T>(_ flow: Kotlinx_coroutines_coreStateFlow, onEach: @escaping (T) -> Void) {
 *     Task {
 *         for await value in flow {
 *             await MainActor.run {
 *                 onEach(value as! T)
 *             }
 *         }
 *     }
 * }
 */
