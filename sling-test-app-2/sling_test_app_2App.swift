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
            ZStack {
                ContentView()
                
                // Screenshot mode button (debug builds only)
                #if DEBUG
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showScreenshotMode = true }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
                #endif
            }
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
