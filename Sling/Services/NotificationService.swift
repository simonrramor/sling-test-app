import Foundation
import SwiftUI
import Combine

struct InAppNotification: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let type: NotificationType
    let createdAt: Date
    
    init(title: String, message: String, type: NotificationType = .info) {
        self.title = title
        self.message = message
        self.type = type
        self.createdAt = Date()
    }
}

enum NotificationType {
    case success
    case info
    case warning
    case request
    
    var color: String {
        switch self {
        case .success: return "57CE43"
        case .info: return "3167FC"
        case .warning: return "FF9500"
        case .request: return "FF5113"
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .request: return "bell.fill"
        }
    }
}

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var currentNotification: InAppNotification?
    @Published var notificationHistory: [InAppNotification] = []
    
    private var dismissTask: Task<Void, Never>?
    
    private init() {}
    
    func show(_ notification: InAppNotification, duration: TimeInterval = 3.0) {
        dismissTask?.cancel()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentNotification = notification
        }
        
        notificationHistory.insert(notification, at: 0)
        
        // Keep only last 50 notifications
        if notificationHistory.count > 50 {
            notificationHistory = Array(notificationHistory.prefix(50))
        }
        
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                self.dismiss()
            }
        }
    }
    
    func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            currentNotification = nil
        }
    }
    
    // Convenience methods
    func showSuccess(_ title: String, message: String = "") {
        show(InAppNotification(title: title, message: message, type: .success))
    }
    
    func showInfo(_ title: String, message: String = "") {
        show(InAppNotification(title: title, message: message, type: .info))
    }
    
    func showWarning(_ title: String, message: String = "") {
        show(InAppNotification(title: title, message: message, type: .warning))
    }
    
    func showRequest(_ title: String, message: String = "") {
        show(InAppNotification(title: title, message: message, type: .request), duration: 5.0)
    }
}
