//
//  sling_test_app_2App.swift
//  sling-test-app-2
//
//  Created by Simon Amor on 14/01/2026.
//

import SwiftUI

@main
struct sling_test_app_2App: App {
    @State private var showScreenshotMode = false
    
    // Check if launched with screenshot mode argument
    private var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshot-mode")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .fullScreenCover(isPresented: $showScreenshotMode) {
                    ScreenshotModeView()
                }
                .onAppear {
                    // Auto-open screenshot mode if launched with argument
                    if isScreenshotMode {
                        showScreenshotMode = true
                    }
                }
        }
    }
}
