import Foundation
import Combine

struct PaymentRequest: Identifiable, Codable {
    let id: UUID
    let fromName: String
    let fromUsername: String
    let fromAvatar: String
    let amount: Double
    let note: String
    let createdAt: Date
    var status: RequestStatus
    
    init(
        id: UUID = UUID(),
        fromName: String,
        fromUsername: String,
        fromAvatar: String,
        amount: Double,
        note: String = "",
        createdAt: Date = Date(),
        status: RequestStatus = .pending
    ) {
        self.id = id
        self.fromName = fromName
        self.fromUsername = fromUsername
        self.fromAvatar = fromAvatar
        self.amount = amount
        self.note = note
        self.createdAt = createdAt
        self.status = status
    }
    
    var formattedAmount: String {
        amount.asGBP
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: createdAt)
    }
}

enum RequestStatus: String, Codable {
    case pending
    case paid
    case declined
}

class RequestService: ObservableObject {
    static let shared = RequestService()
    
    @Published var pendingRequests: [PaymentRequest] = []
    @Published var sentRequests: [PaymentRequest] = []
    
    private let pendingKey = "pendingRequests"
    private let sentKey = "sentRequests"
    private let defaults = UserDefaults.standard
    
    private init() {
        loadRequests()
        
        // Add some demo requests if empty
        if pendingRequests.isEmpty {
            addDemoRequests()
        }
    }
    
    private func addDemoRequests() {
        pendingRequests = [
            PaymentRequest(
                fromName: "Ben Johnson",
                fromUsername: "@ben_j",
                fromAvatar: "AvatarBenJohnson",
                amount: 25.00,
                note: "Dinner last night",
                createdAt: Date().addingTimeInterval(-3600)
            ),
            PaymentRequest(
                fromName: "Eileen Farrell",
                fromUsername: "@eileen_f",
                fromAvatar: "AvatarEileenFarrell",
                amount: 12.50,
                note: "Coffee",
                createdAt: Date().addingTimeInterval(-86400)
            )
        ]
        saveRequests()
    }
    
    // MARK: - Persistence
    
    private func loadRequests() {
        if let data = defaults.data(forKey: pendingKey),
           let requests = try? JSONDecoder().decode([PaymentRequest].self, from: data) {
            pendingRequests = requests
        }
        
        if let data = defaults.data(forKey: sentKey),
           let requests = try? JSONDecoder().decode([PaymentRequest].self, from: data) {
            sentRequests = requests
        }
    }
    
    private func saveRequests() {
        if let data = try? JSONEncoder().encode(pendingRequests) {
            defaults.set(data, forKey: pendingKey)
        }
        
        if let data = try? JSONEncoder().encode(sentRequests) {
            defaults.set(data, forKey: sentKey)
        }
    }
    
    // MARK: - Actions
    
    func createRequest(
        toName: String,
        toUsername: String,
        toAvatar: String,
        amount: Double,
        note: String = ""
    ) {
        let request = PaymentRequest(
            fromName: "Brendon Arnold",
            fromUsername: "@brendon",
            fromAvatar: "AvatarProfile",
            amount: amount,
            note: note
        )
        
        sentRequests.insert(request, at: 0)
        saveRequests()
    }
    
    func payRequest(_ request: PaymentRequest) {
        guard let index = pendingRequests.firstIndex(where: { $0.id == request.id }) else { return }
        
        // Deduct from balance
        PortfolioService.shared.deductCash(request.amount)
        
        // Record activity
        ActivityService.shared.addActivity(
            avatar: request.fromAvatar,
            titleLeft: request.fromName,
            subtitleLeft: request.note.isEmpty ? "Payment" : request.note,
            titleRight: "-\(request.formattedAmount)",
            subtitleRight: ""
        )
        
        // Update status and remove from pending
        pendingRequests.remove(at: index)
        saveRequests()
    }
    
    func declineRequest(_ request: PaymentRequest) {
        guard let index = pendingRequests.firstIndex(where: { $0.id == request.id }) else { return }
        pendingRequests.remove(at: index)
        saveRequests()
    }
    
    func clearAllRequests() {
        pendingRequests = []
        sentRequests = []
        saveRequests()
    }
}
