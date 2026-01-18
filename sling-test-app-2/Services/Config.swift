import Foundation

struct Config {
    // Add your Anthropic API key here or use environment variable
    // Get your key from: https://console.anthropic.com/
    static let anthropicAPIKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
}
