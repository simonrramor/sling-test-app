//
//  sling_test_app_2App.swift
//  sling-test-app-2
//
//  Created by Simon Amor on 14/01/2026.
//

import SwiftUI
import UIKit
import CoreMotion

// MARK: - Flip Gesture Detection

extension Notification.Name {
    static let deviceDidFlip = Notification.Name("deviceDidFlip")
}

/// Detects when the user flips the phone face-down and back up
class FlipGestureDetector {
    static let shared = FlipGestureDetector()
    
    private let motionManager = CMMotionManager()
    private var wasFlippedDown = false
    private var lastTriggerTime: Date = .distantPast
    private let cooldownInterval: TimeInterval = 0.1 // Minimal cooldown
    private var debugCounter = 0
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            print("[FlipDetector] Device motion not available")
            return
        }
        
        print("[FlipDetector] Starting motion monitoring...")
        
        motionManager.deviceMotionUpdateInterval = 0.02 // 50Hz for faster response
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let error = error {
                print("[FlipDetector] Error: \(error.localizedDescription)")
                return
            }
            guard let self = self, let motion = motion else { return }
            self.processMotion(motion)
        }
    }
    
    private func processMotion(_ motion: CMDeviceMotion) {
        let roll = motion.attitude.roll
        let absRoll = abs(roll)
        
        // Log every 10 updates for better visibility
        debugCounter += 1
        if debugCounter % 10 == 0 {
            print("[Flip] Roll: \(String(format: "%+.2f", roll)) | Flipped: \(wasFlippedDown ? "YES" : "no")")
        }
        
        // Horizontal flip detection using roll:
        // - Normal (screen facing user): roll ≈ 0
        // - Flipped 180° horizontally: roll ≈ ±π (±3.14)
        let flippedThreshold: Double = 2.3 // Slightly earlier detection
        let normalThreshold: Double = 1.5 // Trigger earlier when coming back
        
        if absRoll > flippedThreshold && !wasFlippedDown {
            wasFlippedDown = true
            print("[Flip] 🔄 FLIPPED detected (roll: \(String(format: "%.2f", roll)))")
        } else if wasFlippedDown && absRoll < normalThreshold {
            wasFlippedDown = false
            print("[Flip] ✅ BACK TO NORMAL (roll: \(String(format: "%.2f", roll)))")
            
            let now = Date()
            if now.timeIntervalSince(lastTriggerTime) > cooldownInterval {
                lastTriggerTime = now
                print("[Flip] 🎉 TRIGGERED!")
                triggerFlip()
            }
        }
    }
    
    private func triggerFlip() {
        print("[FlipDetector] Flip gesture detected!")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .deviceDidFlip, object: nil)
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Flip Gesture View Modifier

struct FlipGestureViewModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidFlip)) { _ in
                action()
            }
    }
}

extension View {
    func onFlip(perform action: @escaping () -> Void) -> some View {
        self.modifier(FlipGestureViewModifier(action: action))
    }
}

// MARK: - App Delegate for Analytics

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure analytics - after deploying sling-analytics/ to Vercel, set your URL:
        // AnalyticsService.shared.endpointURL = URL(string: "https://YOUR-APP.vercel.app/api/events")
        AnalyticsService.shared.debugLogging = true
        AnalyticsService.shared.startNewSession()
        AnalyticsService.shared.track("app_launch")
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        AnalyticsService.shared.track("app_background")
        AnalyticsService.shared.flush()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        AnalyticsService.shared.startNewSession()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        AnalyticsService.shared.track("app_terminate")
        AnalyticsService.shared.flush()
    }
}

// MARK: - App

@main
struct sling_test_app_2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var showScreenshotMode = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    // Initialize flip detector on app launch
    private let flipDetector = FlipGestureDetector.shared
    
    // Check if launched with screenshot mode argument
    private var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshot-mode")
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView()
                    .fullScreenCover(isPresented: $showScreenshotMode) {
                        ScreenshotModeView()
                    }
                    .onAppear {
                        // Auto-open screenshot mode if launched with argument
                        if isScreenshotMode {
                            showScreenshotMode = true
                        }
                        
                        // Initialize recurring purchases demo data
                        RecurringPurchaseInitializer.shared.initializeForDemo()
                    }
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
