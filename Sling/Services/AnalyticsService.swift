import Foundation
import UIKit

/// Lightweight analytics service for tracking user events
/// Events are stored locally and can be batch-sent to an endpoint
final class AnalyticsService {
    static let shared = AnalyticsService()
    
    // MARK: - Configuration
    
    /// Analytics endpoint URL - set this after deploying your analytics dashboard to Vercel
    /// Example: URL(string: "https://sling-analytics.vercel.app/api/events")
    /// Events will only be logged locally if this is nil
    var endpointURL: URL? = nil
    
    // MARK: - Convenience: Set your deployed Vercel URL here
    // After deploying sling-analytics to Vercel, uncomment and update this line:
    // static let analyticsEndpoint = "https://YOUR-APP.vercel.app/api/events"
    
    /// Enable/disable analytics (useful for debug builds)
    var isEnabled: Bool = true
    
    /// Print events to console for debugging
    var debugLogging: Bool = true
    
    // MARK: - Private Properties
    
    private let queue = DispatchQueue(label: "com.sling.analytics", qos: .utility)
    private let storageKey = "sling_analytics_events"
    private let maxStoredEvents = 500
    private let batchSize = 50
    
    private var sessionId: String
    private var deviceInfo: [String: Any]
    
    // MARK: - Initialization
    
    private init() {
        self.sessionId = UUID().uuidString
        self.deviceInfo = AnalyticsService.collectDeviceInfo()
    }
    
    // MARK: - Public API
    
    /// Track a simple event
    func track(_ eventName: String) {
        track(eventName, properties: nil)
    }
    
    /// Track an event with properties
    func track(_ eventName: String, properties: [String: Any]?) {
        guard isEnabled else { return }
        
        let event = AnalyticsEvent(
            name: eventName,
            properties: properties,
            timestamp: Date(),
            sessionId: sessionId
        )
        
        queue.async { [weak self] in
            self?.storeEvent(event)
            
            if self?.debugLogging == true {
                self?.logEvent(event)
            }
        }
    }
    
    /// Track a screen view
    func trackScreen(_ screenName: String) {
        track("screen_view", properties: ["screen_name": screenName])
    }
    
    /// Track a button tap
    func trackTap(_ buttonName: String, screen: String? = nil) {
        var props: [String: Any] = ["button": buttonName]
        if let screen = screen {
            props["screen"] = screen
        }
        track("tap", properties: props)
    }
    
    /// Track sign-up flow progress
    func trackSignUpStep(_ step: String, completed: Bool = false) {
        track("signup_step", properties: [
            "step": step,
            "completed": completed
        ])
    }
    
    /// Track an error
    func trackError(_ error: String, context: String? = nil) {
        var props: [String: Any] = ["error": error]
        if let context = context {
            props["context"] = context
        }
        track("error", properties: props)
    }
    
    /// Flush events to the endpoint (call on app background/terminate)
    func flush() {
        guard let endpointURL = endpointURL else {
            if debugLogging {
                print("[Analytics] No endpoint configured, skipping flush")
            }
            return
        }
        
        queue.async { [weak self] in
            self?.sendEvents(to: endpointURL)
        }
    }
    
    /// Start a new session (call on app foreground)
    func startNewSession() {
        sessionId = UUID().uuidString
        track("session_start")
    }
    
    /// Get count of stored events (for debugging)
    var storedEventCount: Int {
        return loadStoredEvents().count
    }
    
    // MARK: - Private Methods
    
    private func storeEvent(_ event: AnalyticsEvent) {
        var events = loadStoredEvents()
        events.append(event.toDictionary(with: deviceInfo))
        
        // Trim if over max
        if events.count > maxStoredEvents {
            events = Array(events.suffix(maxStoredEvents))
        }
        
        saveEvents(events)
    }
    
    private func loadStoredEvents() -> [[String: Any]] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let events = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return events
    }
    
    private func saveEvents(_ events: [[String: Any]]) {
        guard let data = try? JSONSerialization.data(withJSONObject: events) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    private func clearEvents() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    private func sendEvents(to url: URL) {
        let events = loadStoredEvents()
        guard !events.isEmpty else { return }
        
        // Take a batch
        let batch = Array(events.prefix(batchSize))
        
        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "events": batch,
            "sent_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Success - remove sent events
                self?.queue.async {
                    var remaining = self?.loadStoredEvents() ?? []
                    remaining = Array(remaining.dropFirst(batch.count))
                    self?.saveEvents(remaining)
                    
                    if self?.debugLogging == true {
                        print("[Analytics] Sent \(batch.count) events, \(remaining.count) remaining")
                    }
                }
            } else if let error = error {
                if self?.debugLogging == true {
                    print("[Analytics] Failed to send events: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    private func logEvent(_ event: AnalyticsEvent) {
        var log = "[Analytics] \(event.name)"
        if let props = event.properties, !props.isEmpty {
            let propsString = props.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            log += " (\(propsString))"
        }
        print(log)
    }
    
    private static func collectDeviceInfo() -> [String: Any] {
        let device = UIDevice.current
        let bundle = Bundle.main
        
        return [
            "device_model": getDeviceModel(),
            "os_version": device.systemVersion,
            "app_version": bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build_number": bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            "locale": Locale.current.identifier,
            "timezone": TimeZone.current.identifier
        ]
    }
    
    private static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

// MARK: - Analytics Event

private struct AnalyticsEvent {
    let name: String
    let properties: [String: Any]?
    let timestamp: Date
    let sessionId: String
    
    func toDictionary(with deviceInfo: [String: Any]) -> [String: Any] {
        var dict: [String: Any] = [
            "event": name,
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "session_id": sessionId
        ]
        
        if let properties = properties {
            dict["properties"] = properties
        }
        
        dict["device"] = deviceInfo
        
        return dict
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Track when this view appears
    func trackScreen(_ name: String) -> some View {
        self.onAppear {
            AnalyticsService.shared.trackScreen(name)
        }
    }
}
