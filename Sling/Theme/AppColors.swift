import SwiftUI
import UIKit

// MARK: - Color Extension for Hex Values

/// Helper extension for hex colors - uses Display P3 for wider color gamut
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        // Use Display P3 color space for wider gamut on modern displays
        self.init(
            UIColor(
                displayP3Red: Double(r) / 255,
                green: Double(g) / 255,
                blue: Double(b) / 255,
                alpha: Double(a) / 255
            )
        )
    }
}

// MARK: - App Colors

/// Pre-defined app colors using DesignSystem hex values
extension Color {
    /// Primary action color (orange) - #FF5113
    static let appPrimary = Color(hex: DesignSystem.Colors.primary)
    
    /// Dark background/text - #080808
    static let appDark = Color(hex: DesignSystem.Colors.dark)
    
    /// Light gray background - #F5F5F5
    static let appBackgroundLight = Color(hex: DesignSystem.Colors.backgroundLight)
    
    /// Dark card background - #1B1B1B
    static let appCardDark = Color(hex: DesignSystem.Colors.cardDark)
    
    /// Secondary text color - #8E8E93
    static let appTextSecondary = Color(hex: DesignSystem.Colors.textSecondary)
    
    /// Divider color - #2A2A2A
    static let appDivider = Color(hex: DesignSystem.Colors.divider)
    
    /// Positive/increase state (inbound payments, gains, APY) - #57CE43
    static let appPositiveGreen = Color(hex: DesignSystem.Colors.positiveGreen)
    
    /// Negative/decrease state (outbound, losses) - #E30000
    static let appNegativeRed = Color(hex: DesignSystem.Colors.negativeRed)
}
