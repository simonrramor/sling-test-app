import Foundation

struct Config {
    // API key is loaded from Secrets.swift (gitignored) or environment variable
    // Get your key from: https://console.anthropic.com/
    static let anthropicAPIKey: String = {
        // First try environment variable (for Xcode debugging)
        if let envKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // Fall back to Secrets.swift (for TestFlight/production)
        return Secrets.anthropicAPIKey
    }()
}
