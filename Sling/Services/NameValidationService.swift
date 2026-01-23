import Foundation
import Combine

// MARK: - Validation Result

/// Result of preferred name validation
struct NameValidationResult: Decodable {
    let approved: Bool
    let reason: String
}

// MARK: - Name Validation Service

/// Service that validates whether a preferred name is an acceptable variation of a legal name
/// Uses Claude AI to evaluate nickname patterns, cultural naming conventions, and common alternatives
class NameValidationService: ObservableObject {
    @Published var isValidating = false
    @Published var error: String?
    
    private let apiKey = Config.anthropicAPIKey
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-20250514"
    
    /// System prompt for name validation
    private let systemPrompt = """
    You work in Customer Operations at Sling Money, a global Venmo / WhatsApp for Money. Your job is to determine whether a user signing up with a manually entered name which is different from the name on their ID is legitimate or not. You want to accept / pass through users who use a common nickname or recognizable alternative name.
    
    Examples:
    - "Mike Hudack" is OK if the legal name is "Michael Nicholas Hudack", but NOT if the legal name is "Nicholas Hudack"
    - "Sheena Shiravi" is OK if the legal name is "Golnaz Sheena Shiravi" but NOT if the legal name is only "Golnaz Shiravi"
    - "Jack Brown" is OK if the legal name is "John Brown" because "Jack" is a common nickname for John
    
    You are specially trained to apply these rules across all countries and cultures in the world, drawing on extensive experience in language and naming and alternative spellings. Your job is to minimize friction for incoming new users while protecting the community from bad actors who might try to scam or impersonate other people on the Sling Money platform.
    
    IMPORTANT: You must respond with ONLY a valid JSON object in this exact format, with no additional text:
    {"approved": true, "reason": "Brief explanation"}
    or
    {"approved": false, "reason": "Brief explanation"}
    
    The "reason" should be a concise, user-friendly explanation (1-2 sentences max).
    """
    
    /// Validates whether the preferred name is an acceptable variation of the legal name
    /// - Parameters:
    ///   - legalFirstName: User's legal first name(s) from ID
    ///   - legalLastName: User's legal last name(s) from ID
    ///   - preferredName: The preferred name the user wants to use
    /// - Returns: ValidationResult with approval status and reason
    func validatePreferredName(
        legalFirstName: String,
        legalLastName: String,
        preferredName: String
    ) async -> Result<NameValidationResult, Error> {
        let trimmedPreferred = preferredName.trimmingCharacters(in: .whitespaces)
        let fullLegalName = "\(legalFirstName) \(legalLastName)".trimmingCharacters(in: .whitespaces)
        
        // Skip validation if preferred name is empty
        if trimmedPreferred.isEmpty {
            return .success(NameValidationResult(approved: true, reason: "No preferred name specified"))
        }
        
        // Skip validation if preferred name matches legal name
        if trimmedPreferred.lowercased() == fullLegalName.lowercased() {
            return .success(NameValidationResult(approved: true, reason: "Preferred name matches legal name"))
        }
        
        await MainActor.run {
            isValidating = true
            error = nil
        }
        
        // Build the user message
        let userMessage = """
        Legal name on ID: \(fullLegalName)
        Preferred name entered by user: \(trimmedPreferred)
        
        Is this preferred name acceptable? Respond with JSON only.
        """
        
        // Create request using the same structures as ChatService
        let request = AnthropicRequest(
            model: model,
            max_tokens: 256,
            system: systemPrompt,
            messages: [AnthropicMessage(role: "user", content: userMessage)]
        )
        
        do {
            var urlRequest = URLRequest(url: apiURL)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let apiError = try? JSONDecoder().decode(AnthropicError.self, from: data) {
                    throw NSError(
                        domain: "NameValidation",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: apiError.error.message]
                    )
                }
                throw NSError(
                    domain: "NameValidation",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Validation request failed with status \(httpResponse.statusCode)"]
                )
            }
            
            // Decode Anthropic response
            let apiResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            
            // Extract text from response
            let responseText = apiResponse.content
                .compactMap { $0.text }
                .joined(separator: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse the JSON response
            guard let jsonData = responseText.data(using: .utf8) else {
                throw NSError(
                    domain: "NameValidation",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to parse validation response"]
                )
            }
            
            let validationResult = try JSONDecoder().decode(NameValidationResult.self, from: jsonData)
            
            await MainActor.run {
                isValidating = false
            }
            
            return .success(validationResult)
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isValidating = false
            }
            return .failure(error)
        }
    }
}
