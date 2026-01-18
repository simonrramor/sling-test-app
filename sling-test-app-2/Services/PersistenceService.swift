import Foundation

// MARK: - Codable Models for Persistence

struct PersistedHolding: Codable {
    let symbol: String
    let iconName: String
    var shares: Double
    var averageCost: Double
}

struct PersistedPortfolioEvent: Codable {
    let timestamp: Date
    let type: String // "buy" or "sell"
    let portfolioValueAfter: Double
    let iconName: String
    let shares: Double
    let pricePerShare: Double
}

struct PersistedActivityItem: Codable {
    let avatar: String
    let titleLeft: String
    let subtitleLeft: String
    let titleRight: String
    let subtitleRight: String
    let date: Date?
}

struct PersistedPortfolio: Codable {
    var holdings: [String: PersistedHolding]
    var cashBalance: Double
    var history: [PersistedPortfolioEvent]
}

struct PersistedActivities: Codable {
    var activities: [PersistedActivityItem]
}

// MARK: - Persistence Service

class PersistenceService {
    static let shared = PersistenceService()
    
    private let iCloud = NSUbiquitousKeyValueStore.default
    
    private let portfolioKey = "sling_portfolio_v1"
    private let activitiesKey = "sling_activities_v1"
    
    private init() {
        // Listen for external changes (from other devices or iCloud sync)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloud
        )
        
        // Synchronize to get latest data
        iCloud.synchronize()
    }
    
    @objc private func iCloudDidChange(_ notification: Notification) {
        print("PersistenceService: iCloud data changed externally")
        // Post notification for services to reload if needed
        NotificationCenter.default.post(name: .persistenceDidChange, object: nil)
    }
    
    // MARK: - Portfolio Persistence
    
    func savePortfolio(holdings: [String: PersistedHolding], cashBalance: Double, history: [PersistedPortfolioEvent]) {
        let portfolio = PersistedPortfolio(
            holdings: holdings,
            cashBalance: cashBalance,
            history: history
        )
        
        do {
            let data = try JSONEncoder().encode(portfolio)
            iCloud.set(data, forKey: portfolioKey)
            iCloud.synchronize()
            print("PersistenceService: Saved portfolio to iCloud")
        } catch {
            print("PersistenceService: Failed to save portfolio: \(error)")
        }
    }
    
    func loadPortfolio() -> PersistedPortfolio? {
        guard let data = iCloud.data(forKey: portfolioKey) else {
            print("PersistenceService: No portfolio data in iCloud")
            return nil
        }
        
        do {
            let portfolio = try JSONDecoder().decode(PersistedPortfolio.self, from: data)
            print("PersistenceService: Loaded portfolio from iCloud")
            return portfolio
        } catch {
            print("PersistenceService: Failed to load portfolio: \(error)")
            return nil
        }
    }
    
    // MARK: - Activities Persistence
    
    func saveActivities(_ activities: [PersistedActivityItem]) {
        let persisted = PersistedActivities(activities: activities)
        
        do {
            let data = try JSONEncoder().encode(persisted)
            iCloud.set(data, forKey: activitiesKey)
            iCloud.synchronize()
            print("PersistenceService: Saved \(activities.count) activities to iCloud")
        } catch {
            print("PersistenceService: Failed to save activities: \(error)")
        }
    }
    
    func loadActivities() -> [PersistedActivityItem] {
        guard let data = iCloud.data(forKey: activitiesKey) else {
            print("PersistenceService: No activities data in iCloud")
            return []
        }
        
        do {
            let persisted = try JSONDecoder().decode(PersistedActivities.self, from: data)
            print("PersistenceService: Loaded \(persisted.activities.count) activities from iCloud")
            return persisted.activities
        } catch {
            print("PersistenceService: Failed to load activities: \(error)")
            return []
        }
    }
    
    // MARK: - Clear All Data (for testing)
    
    func clearAllData() {
        iCloud.removeObject(forKey: portfolioKey)
        iCloud.removeObject(forKey: activitiesKey)
        iCloud.synchronize()
        print("PersistenceService: Cleared all persisted data")
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let persistenceDidChange = Notification.Name("persistenceDidChange")
}
