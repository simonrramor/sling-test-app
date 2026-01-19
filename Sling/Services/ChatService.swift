import Foundation
import Combine

// MARK: - Message Model

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    enum MessageRole: String {
        case user
        case assistant
    }
}

// MARK: - Anthropic API Models

struct AnthropicRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [AnthropicMessage]
}

struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

struct AnthropicResponse: Decodable {
    let content: [ContentBlock]
    let stop_reason: String?
    
    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }
}

struct AnthropicError: Decodable {
    let error: ErrorDetail
    
    struct ErrorDetail: Decodable {
        let type: String
        let message: String
    }
}

// MARK: - Chat Service

class ChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var isStreaming = false
    @Published var streamingContent = ""
    @Published var error: String?
    
    private let apiKey = Config.anthropicAPIKey
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-20250514"
    
    // Speed of word-by-word animation (seconds per word)
    private let wordDelay: Double = 0.03
    
    init() {
        // Start with empty messages to show the empty state
    }
    
    /// Send a message and get a response from Claude
    func sendMessage(_ content: String) async {
        // #region agent log
        print("🔍 [A] ChatService:sendMessage - API key empty: \(apiKey.isEmpty), key length: \(apiKey.count)")
        // #endregion
        
        // Add user message
        let userMessage = ChatMessage(
            role: .user,
            content: content,
            timestamp: Date()
        )
        
        await MainActor.run {
            messages.append(userMessage)
            isLoading = true
            streamingContent = ""
            error = nil
        }
        
        // Build conversation history for API
        let apiMessages = messages
            .map { AnthropicMessage(role: $0.role.rawValue, content: $0.content) }
        
        // Create request
        let request = AnthropicRequest(
            model: model,
            max_tokens: 1024,
            system: SlingKnowledge.systemPrompt,
            messages: apiMessages
        )
        
        do {
            var urlRequest = URLRequest(url: apiURL)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            // #region agent log
            print("🔍 [B] ChatService:sendMessage - Making API request")
            // #endregion
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // #region agent log
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("🔍 [C] ChatService:response - HTTP status: \(httpStatus)")
            // #endregion
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                // Try to decode error
                // #region agent log
                if let errorStr = String(data: data, encoding: .utf8) {
                    print("🔍 [C] ChatService:error - Response body: \(errorStr.prefix(500))")
                }
                // #endregion
                if let apiError = try? JSONDecoder().decode(AnthropicError.self, from: data) {
                    throw NSError(domain: "Anthropic", code: httpResponse.statusCode, 
                                  userInfo: [NSLocalizedDescriptionKey: apiError.error.message])
                }
                throw NSError(domain: "Anthropic", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode)"])
            }
            
            // Decode response
            let apiResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            // #region agent log
            print("🔍 [D] ChatService:success - Response received, content blocks: \(apiResponse.content.count)")
            // #endregion
            
            // Extract text from response
            let responseText = apiResponse.content
                .compactMap { $0.text }
                .joined(separator: "\n")
            
            // Stream the response word by word
            await streamResponse(responseText)
            
        } catch {
            // #region agent log
            print("🔍 [E] ChatService:catch - Error: \(error.localizedDescription)")
            // #endregion
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
                self.isStreaming = false
                
                // Add error message to chat
                let errorMessage = ChatMessage(
                    role: .assistant,
                    content: "Sorry, I'm having trouble connecting right now. Please try again in a moment.",
                    timestamp: Date()
                )
                messages.append(errorMessage)
            }
        }
    }
    
    /// Stream the response word by word
    private func streamResponse(_ text: String) async {
        await MainActor.run {
            isLoading = false
            isStreaming = true
            streamingContent = ""
        }
        
        let words = text.components(separatedBy: " ")
        
        for (index, word) in words.enumerated() {
            await MainActor.run {
                if index == 0 {
                    streamingContent = word
                } else {
                    streamingContent += " " + word
                }
            }
            
            // Small delay between words
            try? await Task.sleep(nanoseconds: UInt64(wordDelay * 1_000_000_000))
        }
        
        // Add the complete message
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: text,
            timestamp: Date()
        )
        
        await MainActor.run {
            messages.append(assistantMessage)
            isStreaming = false
            streamingContent = ""
        }
    }
    
    /// Clear conversation history
    func clearChat() {
        messages = []
        streamingContent = ""
        isStreaming = false
    }
}
