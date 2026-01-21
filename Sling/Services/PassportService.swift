import SwiftUI
import Combine

// MARK: - Passport Model

struct PassportInfo: Codable, Identifiable {
    let code: String
    let country: String
    let color: String
    let colorName: String
    let emblem: String
    let emblemIcon: String
    let emblemDescription: String
    
    var id: String { code }
    
    var swiftUIColor: Color {
        Color(hex: color.replacingOccurrences(of: "#", with: ""))
    }
}

struct PassportData: Codable {
    let passports: [PassportInfo]
}

// MARK: - Passport Service

class PassportService: ObservableObject {
    static let shared = PassportService()
    
    @Published private(set) var passports: [PassportInfo] = []
    
    private init() {
        loadPassports()
    }
    
    private func loadPassports() {
        guard let url = Bundle.main.url(forResource: "PassportColors", withExtension: "json") else {
            print("PassportColors.json not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(PassportData.self, from: data)
            passports = decoded.passports.sorted { $0.country < $1.country }
        } catch {
            print("Error loading passport data: \(error)")
        }
    }
    
    // Get passport info by country code
    func passport(forCode code: String) -> PassportInfo? {
        passports.first { $0.code.uppercased() == code.uppercased() }
    }
    
    // Get passport info by country name
    func passport(forCountry country: String) -> PassportInfo? {
        passports.first { $0.country.lowercased() == country.lowercased() }
    }
    
    // Get all passports of a specific color
    func passports(withColorName colorName: String) -> [PassportInfo] {
        passports.filter { $0.colorName.lowercased() == colorName.lowercased() }
    }
    
    // Get unique color categories
    var colorCategories: [String] {
        Array(Set(passports.map { $0.colorName })).sorted()
    }
    
    // Group passports by color
    var passportsByColor: [String: [PassportInfo]] {
        Dictionary(grouping: passports) { $0.colorName }
    }
}
