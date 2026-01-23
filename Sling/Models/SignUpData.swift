import Foundation
import SwiftUI
import Combine

/// Shared data model for the signup flow
/// Passed between all signup screens to collect user information
class SignUpData: ObservableObject {
    // Step 1: About you
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var preferredName = ""
    
    // Step 2: Birthday
    @Published var birthDay = ""
    @Published var birthMonth = ""
    @Published var birthYear = ""
    
    // Step 3: Country
    @Published var country = ""
    @Published var countryCode = "+44"
    @Published var countryFlag = "FlagGB" // Circle Flag asset name
    
    // Step 4: Phone
    @Published var phoneNumber = ""
    
    // Step 5: Verification
    @Published var verificationCode = ""
    
    // Step 6: Terms & Conditions
    @Published var hasAcceptedTerms = false
    @Published var useESignature = false
    
    // Computed property for full legal name
    var fullLegalName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    // Computed property for display name (preferred or first name)
    var displayName: String {
        let trimmedPreferred = preferredName.trimmingCharacters(in: .whitespaces)
        return trimmedPreferred.isEmpty ? firstName : trimmedPreferred
    }
    
    // Computed property for formatted phone number
    var formattedPhoneNumber: String {
        "\(countryCode) \(phoneNumber)"
    }
    
    // Computed property for birthday as Date
    var birthday: Date? {
        guard !birthDay.isEmpty, !birthMonth.isEmpty, !birthYear.isEmpty else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MM yyyy"
        return dateFormatter.date(from: "\(birthDay) \(birthMonth) \(birthYear)")
    }
    
    // Validation for birthday (must be 18+ years old)
    var isBirthdayValid: Bool {
        guard let day = Int(birthDay),
              let month = Int(birthMonth),
              let year = Int(birthYear) else { return false }
        let currentYear = Calendar.current.component(.year, from: Date())
        return day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 1900 && year <= currentYear - 18
    }
}

// MARK: - Country Data

struct Country: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let dialCode: String
    let flag: String // Emoji fallback
    
    /// Asset name for Circle Flag image (e.g., "FlagGB")
    var flagAsset: String {
        "Flag\(code)"
    }
    
    static let all: [Country] = [
        Country(name: "Australia", code: "AU", dialCode: "+61", flag: "🇦🇺"),
        Country(name: "Brazil", code: "BR", dialCode: "+55", flag: "🇧🇷"),
        Country(name: "Canada", code: "CA", dialCode: "+1", flag: "🇨🇦"),
        Country(name: "China", code: "CN", dialCode: "+86", flag: "🇨🇳"),
        Country(name: "France", code: "FR", dialCode: "+33", flag: "🇫🇷"),
        Country(name: "Germany", code: "DE", dialCode: "+49", flag: "🇩🇪"),
        Country(name: "Hong Kong", code: "HK", dialCode: "+852", flag: "🇭🇰"),
        Country(name: "India", code: "IN", dialCode: "+91", flag: "🇮🇳"),
        Country(name: "Ireland", code: "IE", dialCode: "+353", flag: "🇮🇪"),
        Country(name: "Italy", code: "IT", dialCode: "+39", flag: "🇮🇹"),
        Country(name: "Japan", code: "JP", dialCode: "+81", flag: "🇯🇵"),
        Country(name: "Kenya", code: "KE", dialCode: "+254", flag: "🇰🇪"),
        Country(name: "Mexico", code: "MX", dialCode: "+52", flag: "🇲🇽"),
        Country(name: "Netherlands", code: "NL", dialCode: "+31", flag: "🇳🇱"),
        Country(name: "New Zealand", code: "NZ", dialCode: "+64", flag: "🇳🇿"),
        Country(name: "Nigeria", code: "NG", dialCode: "+234", flag: "🇳🇬"),
        Country(name: "Singapore", code: "SG", dialCode: "+65", flag: "🇸🇬"),
        Country(name: "South Africa", code: "ZA", dialCode: "+27", flag: "🇿🇦"),
        Country(name: "Spain", code: "ES", dialCode: "+34", flag: "🇪🇸"),
        Country(name: "Switzerland", code: "CH", dialCode: "+41", flag: "🇨🇭"),
        Country(name: "United Arab Emirates", code: "AE", dialCode: "+971", flag: "🇦🇪"),
        Country(name: "United Kingdom", code: "GB", dialCode: "+44", flag: "🇬🇧"),
        Country(name: "United States", code: "US", dialCode: "+1", flag: "🇺🇸")
    ]
    
    static func search(_ query: String) -> [Country] {
        if query.isEmpty {
            return all
        }
        return all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

// MARK: - Month Data

struct Month: Identifiable {
    let id: Int
    let name: String
    let shortName: String
    
    static let all: [Month] = [
        Month(id: 1, name: "January", shortName: "Jan"),
        Month(id: 2, name: "February", shortName: "Feb"),
        Month(id: 3, name: "March", shortName: "Mar"),
        Month(id: 4, name: "April", shortName: "Apr"),
        Month(id: 5, name: "May", shortName: "May"),
        Month(id: 6, name: "June", shortName: "Jun"),
        Month(id: 7, name: "July", shortName: "Jul"),
        Month(id: 8, name: "August", shortName: "Aug"),
        Month(id: 9, name: "September", shortName: "Sep"),
        Month(id: 10, name: "October", shortName: "Oct"),
        Month(id: 11, name: "November", shortName: "Nov"),
        Month(id: 12, name: "December", shortName: "Dec")
    ]
}
