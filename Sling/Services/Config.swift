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
    
    // Linear API key for feedback ticket creation
    static let linearAPIKey: String = {
        if let envKey = ProcessInfo.processInfo.environment["LINEAR_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        return Secrets.linearAPIKey
    }()
}

// MARK: - Linear Configuration

struct LinearConfig {
    // Linear API endpoint
    static let apiEndpoint = "https://api.linear.app/graphql"
    
    // Team ID for the project (get from Linear settings or API)
    // Options: "7d80d1fb-8eff-4ff3-9a02-263fb5ab3e52" (Product Engineering)
    //          "0e341c70-fe6b-4139-8ae4-f974e32aefcb" (Core Product)
    static let teamId = "7d80d1fb-8eff-4ff3-9a02-263fb5ab3e52"  // Product Engineering
    
    // User IDs for ticket assignment
    static let userIds: [String: String] = [
        "greg": "8e450331-5ae0-48e6-bd6e-d4f787028027",      // Product
        "simon": "8cc72d87-ceeb-43da-a6b2-5c93b8e7a9cb",     // Design
        "marius": "7380714f-1879-4c01-b9e4-91c8d7ae2d6d",    // Front End Dev
        "dom": "faadf14e-b5d3-4ff0-888b-a91c75858960"        // Back End Dev
    ]
    
    // Get user ID by key (greg, simon, marius, dom)
    static func userId(for key: String) -> String? {
        return userIds[key.lowercased()]
    }
    
    // Labels for different feedback types (optional - create in Linear first)
    static let labels: [String: String] = [
        "feedback": "YOUR_FEEDBACK_LABEL_ID",  // Optional: Label for all feedback tickets
        "bug": "YOUR_BUG_LABEL_ID"             // Optional: Label for bug reports
    ]
}
