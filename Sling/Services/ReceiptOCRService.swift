import UIKit

// MARK: - Receipt OCR Service (TabScanner)

/// A service for processing receipt images using TabScanner API.
/// Get your API key from https://tabscanner.com
class ReceiptOCRService {
    
    static let shared = ReceiptOCRService()
    
    // TODO: Replace with your TabScanner API key
    // Get one free at https://tabscanner.com (200 scans/month on free tier)
    // Steps: 1) Sign up  2) Get API key from dashboard  3) Paste below
    private let apiKey = "YOUR_TABSCANNER_API_KEY"
    
    private let processURL = "https://api.tabscanner.com/api/2/process"
    private let resultURL = "https://api.tabscanner.com/api/result"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Process a receipt image using TabScanner API
    /// - Parameter image: The captured receipt image
    /// - Parameter completion: Callback with the scanned receipt
    func processImage(_ image: UIImage, completion: @escaping (ScannedReceipt) -> Void) {
        // Check if API key is set
        guard apiKey != "YOUR_TABSCANNER_API_KEY" else {
            print("⚠️ TabScanner API key not set. Using mock data.")
            print("Get your free API key at https://tabscanner.com")
            DispatchQueue.main.async {
                completion(self.generateMockReceipt())
            }
            return
        }
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG")
            DispatchQueue.main.async {
                completion(self.generateMockReceipt())
            }
            return
        }
        
        // Upload to TabScanner
        uploadReceipt(imageData: imageData) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let token):
                print("📤 Receipt uploaded, token: \(token)")
                // Poll for results
                self.pollForResult(token: token, completion: completion)
                
            case .failure(let error):
                print("❌ Upload failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(self.generateMockReceipt())
                }
            }
        }
    }
    
    /// Synchronous version that returns mock data (for backwards compatibility)
    func processImage(_ image: UIImage) -> ScannedReceipt {
        return generateMockReceipt()
    }
    
    // MARK: - TabScanner API
    
    /// Upload receipt image to TabScanner
    private func uploadReceipt(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: processURL) else {
            completion(.failure(TabScannerError.invalidURL))
            return
        }
        
        // Create multipart form request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        var body = Data()
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"receipt.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add document type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"documentType\"\r\n\r\n".data(using: .utf8)!)
        body.append("receipt\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Make request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(TabScannerError.noData))
                return
            }
            
            // Debug: print response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Upload response: \(responseString)")
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    completion(.success(token))
                } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let message = json["message"] as? String {
                    completion(.failure(TabScannerError.apiError(message)))
                } else {
                    completion(.failure(TabScannerError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Poll TabScanner for results
    private func pollForResult(token: String, attempt: Int = 0, completion: @escaping (ScannedReceipt) -> Void) {
        // Max 30 attempts (30 seconds)
        guard attempt < 30 else {
            print("❌ Polling timeout")
            DispatchQueue.main.async {
                completion(self.generateMockReceipt())
            }
            return
        }
        
        guard var urlComponents = URLComponents(string: resultURL) else {
            DispatchQueue.main.async {
                completion(self.generateMockReceipt())
            }
            return
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "token", value: token)]
        
        guard let url = urlComponents.url else {
            DispatchQueue.main.async {
                completion(self.generateMockReceipt())
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Poll error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(self.generateMockReceipt())
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(self.generateMockReceipt())
                }
                return
            }
            
            // Debug: print response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Poll response (\(attempt)): \(responseString.prefix(500))...")
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let status = json["status"] as? String ?? ""
                    
                    if status == "done" {
                        // Parse the result
                        let receipt = self.parseTabScannerResult(json)
                        DispatchQueue.main.async {
                            completion(receipt)
                        }
                    } else if status == "pending" || status == "processing" {
                        // Wait and poll again
                        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                            self.pollForResult(token: token, attempt: attempt + 1, completion: completion)
                        }
                    } else {
                        // Error or unknown status
                        print("❌ Unexpected status: \(status)")
                        DispatchQueue.main.async {
                            completion(self.generateMockReceipt())
                        }
                    }
                }
            } catch {
                print("❌ Parse error: \(error)")
                DispatchQueue.main.async {
                    completion(self.generateMockReceipt())
                }
            }
        }.resume()
    }
    
    /// Parse TabScanner result JSON into ScannedReceipt
    private func parseTabScannerResult(_ json: [String: Any]) -> ScannedReceipt {
        var items: [ReceiptItem] = []
        var tax: Double?
        var total: Double?
        
        // Get result object
        guard let result = json["result"] as? [String: Any] else {
            print("❌ No result object in response")
            return generateMockReceipt()
        }
        
        // Extract line items
        if let lineItems = result["lineItems"] as? [[String: Any]] {
            print("📋 Found \(lineItems.count) line items")
            
            for item in lineItems {
                let description = item["descClean"] as? String
                    ?? item["desc"] as? String
                    ?? item["description"] as? String
                    ?? "Unknown Item"
                
                // Get price - try lineTotal first, then price
                let price = item["lineTotal"] as? Double
                    ?? item["price"] as? Double
                    ?? (item["lineTotal"] as? Int).map { Double($0) }
                    ?? (item["price"] as? Int).map { Double($0) }
                    ?? 0.0
                
                if !description.isEmpty && price > 0 {
                    items.append(ReceiptItem(name: description, price: price, assignedTo: []))
                    print("  ✓ \(description): £\(String(format: "%.2f", price))")
                }
            }
        }
        
        // Extract total
        if let totalValue = result["total"] as? Double {
            total = totalValue
        } else if let totalValue = result["total"] as? Int {
            total = Double(totalValue)
        }
        
        // Extract tax
        if let taxValue = result["tax"] as? Double {
            tax = taxValue
        } else if let taxValue = result["tax"] as? Int {
            tax = Double(taxValue)
        }
        
        print("📊 Total: £\(String(format: "%.2f", total ?? 0)), Tax: £\(String(format: "%.2f", tax ?? 0))")
        print("✅ Parsed \(items.count) items from TabScanner")
        
        // If no items found, use mock data
        if items.isEmpty {
            print("⚠️ No items parsed, using mock data")
            return generateMockReceipt()
        }
        
        return ScannedReceipt(
            items: items,
            tax: tax,
            tip: nil,
            total: total ?? items.reduce(0) { $0 + $1.price }
        )
    }
    
    // MARK: - Mock Data
    
    /// Generate a mock receipt for testing
    func generateMockReceipt() -> ScannedReceipt {
        let items = [
            ReceiptItem(name: "Margherita Pizza", price: 14.99, assignedTo: []),
            ReceiptItem(name: "Pepperoni Pizza", price: 16.99, assignedTo: []),
            ReceiptItem(name: "Caesar Salad", price: 8.99, assignedTo: []),
            ReceiptItem(name: "Garlic Bread", price: 5.99, assignedTo: []),
            ReceiptItem(name: "Coke", price: 2.99, assignedTo: []),
            ReceiptItem(name: "Sprite", price: 2.99, assignedTo: []),
            ReceiptItem(name: "Water", price: 1.99, assignedTo: []),
            ReceiptItem(name: "Tiramisu", price: 7.99, assignedTo: [])
        ]
        
        let subtotal = items.reduce(0) { $0 + $1.price }
        let tax = subtotal * 0.08
        let total = subtotal + tax
        
        return ScannedReceipt(
            items: items,
            tax: tax,
            tip: nil,
            total: total
        )
    }
}

// MARK: - Errors

enum TabScannerError: LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response format"
        case .apiError(let message):
            return message
        }
    }
}
