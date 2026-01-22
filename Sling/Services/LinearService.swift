import Foundation
import UIKit

// MARK: - Linear API Response Types

struct LinearGraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [LinearGraphQLError]?
}

struct LinearGraphQLError: Decodable {
    let message: String
    let locations: [LinearErrorLocation]?
    let path: [String]?
}

struct LinearErrorLocation: Decodable {
    let line: Int
    let column: Int
}

struct IssueCreateResponse: Decodable {
    let issueCreate: IssueCreatePayload
}

struct IssueCreatePayload: Decodable {
    let success: Bool
    let issue: LinearIssue?
}

struct LinearIssue: Decodable {
    let id: String
    let identifier: String
    let title: String
    let url: String
}

struct AttachmentCreateResponse: Decodable {
    let attachmentLinkURL: AttachmentLinkPayload
}

struct AttachmentLinkPayload: Decodable {
    let success: Bool
    let attachment: LinearAttachment?
}

struct LinearAttachment: Decodable {
    let id: String
    let url: String
}

// MARK: - Linear Service Errors

enum LinearServiceError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case graphQLError([LinearGraphQLError])
    case invalidResponse
    case imageUploadFailed
    case issueCreationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid Linear API key. Please check your configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .graphQLError(let errors):
            let messages = errors.map { $0.message }.joined(separator: ", ")
            return "Linear API error: \(messages)"
        case .invalidResponse:
            return "Invalid response from Linear API"
        case .imageUploadFailed:
            return "Failed to upload screenshot"
        case .issueCreationFailed(let message):
            return "Failed to create issue: \(message)"
        }
    }
}

// MARK: - Linear Service

class LinearService {
    static let shared = LinearService()
    
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Create a feedback issue in Linear with optional screenshot
    func createFeedbackIssue(
        title: String,
        description: String,
        team: FeedbackTeam,
        screenshot: UIImage?
    ) async throws -> LinearIssue {
        print("[LinearService] Creating feedback issue...")
        print("[LinearService] Title: \(title)")
        print("[LinearService] Team: \(team.displayName) -> \(team.assigneeName)")
        
        // Validate API key
        let apiKey = Config.linearAPIKey
        print("[LinearService] API Key present: \(!apiKey.isEmpty), length: \(apiKey.count)")
        guard !apiKey.isEmpty && apiKey != "YOUR_LINEAR_API_KEY_HERE" else {
            print("[LinearService] ERROR: Invalid API key")
            throw LinearServiceError.invalidAPIKey
        }
        
        // Get assignee ID
        let assigneeId = LinearConfig.userId(for: team.configKey)
        
        // Build the description with metadata
        var fullDescription = description
        fullDescription += "\n\n---\n"
        fullDescription += "**Submitted via:** In-app Feedback\n"
        fullDescription += "**Assigned to:** \(team.assigneeName) (\(team.displayName))\n"
        fullDescription += "**Date:** \(formattedDate())\n"
        
        // Create the issue first
        let issue = try await createIssue(
            title: title,
            description: fullDescription,
            teamId: LinearConfig.teamId,
            assigneeId: assigneeId
        )
        
        // If we have a screenshot, upload it as an attachment
        if let screenshot = screenshot {
            do {
                try await attachScreenshot(screenshot, to: issue.id)
            } catch {
                // Log but don't fail - the issue was created successfully
                print("Failed to attach screenshot: \(error.localizedDescription)")
            }
        }
        
        return issue
    }
    
    // MARK: - Private Methods
    
    private func createIssue(
        title: String,
        description: String,
        teamId: String,
        assigneeId: String?
    ) async throws -> LinearIssue {
        let mutation = """
        mutation IssueCreate($input: IssueCreateInput!) {
            issueCreate(input: $input) {
                success
                issue {
                    id
                    identifier
                    title
                    url
                }
            }
        }
        """
        
        var input: [String: Any] = [
            "title": title,
            "description": description,
            "teamId": teamId
        ]
        
        if let assigneeId = assigneeId, !assigneeId.hasPrefix("YOUR_") {
            input["assigneeId"] = assigneeId
        }
        
        let variables: [String: Any] = ["input": input]
        
        let response: LinearGraphQLResponse<IssueCreateResponse> = try await executeGraphQL(
            query: mutation,
            variables: variables
        )
        
        if let errors = response.errors, !errors.isEmpty {
            throw LinearServiceError.graphQLError(errors)
        }
        
        guard let payload = response.data?.issueCreate,
              payload.success,
              let issue = payload.issue else {
            throw LinearServiceError.issueCreationFailed("Issue creation returned unsuccessful")
        }
        
        return issue
    }
    
    private func attachScreenshot(_ image: UIImage, to issueId: String) async throws {
        // First, upload the image to get a URL
        // Linear doesn't have direct image upload in GraphQL, so we need to use
        // their attachment URL linking feature with an external image host
        // For now, we'll encode the image as base64 and include it in the description
        // or use Linear's file upload endpoint if available
        
        // Alternative approach: Upload to a temporary file hosting service
        // and then link it to the issue
        
        // For this implementation, we'll use Linear's attachmentLinkURL mutation
        // which allows linking external URLs. In production, you'd upload to 
        // your own storage (S3, CloudFlare, etc.) first.
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw LinearServiceError.imageUploadFailed
        }
        
        // For now, we'll add a note that screenshot was captured
        // In production, implement proper image hosting
        let base64String = imageData.base64EncodedString()
        let dataUrl = "data:image/jpeg;base64,\(base64String.prefix(100))..." // Truncated for logging
        
        print("Screenshot captured (\(imageData.count) bytes). Base64 preview: \(dataUrl)")
        
        // Note: Full implementation would require:
        // 1. Upload image to your own hosting (S3, CloudFlare R2, etc.)
        // 2. Get the public URL
        // 3. Use attachmentLinkURL mutation to link it to the issue
        
        // Placeholder for the attachment mutation:
        /*
        let mutation = """
        mutation AttachmentLinkURL($issueId: String!, $url: String!, $title: String) {
            attachmentLinkURL(issueId: $issueId, url: $url, title: $title) {
                success
                attachment {
                    id
                    url
                }
            }
        }
        """
        */
    }
    
    private func executeGraphQL<T: Decodable>(
        query: String,
        variables: [String: Any]
    ) async throws -> LinearGraphQLResponse<T> {
        guard let url = URL(string: LinearConfig.apiEndpoint) else {
            throw LinearServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.linearAPIKey, forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("[LinearService] Sending request to: \(LinearConfig.apiEndpoint)")
        
        do {
            let (data, response) = try await session.data(for: request)
            print("[LinearService] Received response")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LinearServiceError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw LinearServiceError.invalidAPIKey
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw LinearServiceError.issueCreationFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            return try decoder.decode(LinearGraphQLResponse<T>.self, from: data)
        } catch let error as LinearServiceError {
            throw error
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw LinearServiceError.invalidResponse
        } catch {
            throw LinearServiceError.networkError(error)
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}
