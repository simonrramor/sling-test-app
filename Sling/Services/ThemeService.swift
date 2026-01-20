import SwiftUI
import Combine

// MARK: - App Theme

enum AppTheme: String, CaseIterable {
    case grey = "grey"
    case white = "white"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .grey: return "Grey"
        case .white: return "White"
        case .dark: return "Dark"
        }
    }
    
    var iconName: String {
        switch self {
        case .grey: return "circle.lefthalf.filled"
        case .white: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var nextTheme: AppTheme {
        switch self {
        case .grey: return .white
        case .white: return .dark
        case .dark: return .grey
        }
    }
}

// MARK: - Theme Service

class ThemeService: ObservableObject {
    static let shared = ThemeService()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.grey.rawValue
        self.currentTheme = AppTheme(rawValue: saved) ?? .grey
    }
    
    func toggleTheme() {
        currentTheme = currentTheme.nextTheme
    }
    
    // MARK: - Theme Colors
    
    var backgroundColor: Color {
        switch currentTheme {
        case .grey:
            return Color(hex: "F2F2F2")  // Light grey
        case .white:
            return Color.white
        case .dark:
            return Color(hex: "000000")  // Pure black
        }
    }
    
    var backgroundSecondaryColor: Color {
        switch currentTheme {
        case .grey:
            return Color.white
        case .white:
            return Color(hex: "F7F7F7")  // Very light grey for cards on white
        case .dark:
            return Color(hex: "1C1C1E")  // Dark grey for cards
        }
    }
    
    var cardBackgroundColor: Color {
        switch currentTheme {
        case .grey:
            return Color(hex: "FCFCFC")
        case .white:
            return Color(hex: "F7F7F7")
        case .dark:
            return Color(hex: "1C1C1E")
        }
    }
    
    var buttonSecondaryColor: Color {
        switch currentTheme {
        case .grey:
            return Color.white
        case .white:
            return Color(hex: "EDEDED")  // Grey buttons on white background
        case .dark:
            return Color(hex: "2C2C2E")  // Dark grey buttons
        }
    }
    
    var textPrimaryColor: Color {
        switch currentTheme {
        case .grey, .white:
            return Color(hex: "080808")
        case .dark:
            return Color.white
        }
    }
    
    var textSecondaryColor: Color {
        switch currentTheme {
        case .grey, .white:
            return Color(hex: "7B7B7B")
        case .dark:
            return Color(hex: "999999")
        }
    }
    
    var textTertiaryColor: Color {
        switch currentTheme {
        case .grey, .white:
            return Color(hex: "999999")
        case .dark:
            return Color(hex: "676767")
        }
    }
    
    // Returns the appropriate color scheme for the theme
    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .grey, .white:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Environment Key

struct ThemeServiceKey: EnvironmentKey {
    static let defaultValue = ThemeService.shared
}

extension EnvironmentValues {
    var themeService: ThemeService {
        get { self[ThemeServiceKey.self] }
        set { self[ThemeServiceKey.self] = newValue }
    }
}
