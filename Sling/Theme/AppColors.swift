import SwiftUI

/// Centralized color palette with automatic light/dark mode support
struct AppColors {
    
    // MARK: - Primary Brand Colors
    
    /// Sling primary orange - #FF5113
    static let primary = Color(hex: "FF5113")
    
    // MARK: - Text Colors
    
    /// Primary text color - black in light mode, white in dark mode
    static let textPrimary = Color("TextPrimary")
    
    /// Secondary text color - grey
    static let textSecondary = Color("TextSecondary")
    
    /// Tertiary/muted text color
    static let textTertiary = Color("TextTertiary")
    
    // MARK: - Background Colors
    
    /// Main app background
    static let background = Color("Background")
    
    /// Secondary/elevated background (cards, etc)
    static let backgroundSecondary = Color("BackgroundSecondary")
    
    /// Tertiary background (inputs, subtle elements)
    static let backgroundTertiary = Color("BackgroundTertiary")
    
    // MARK: - UI Element Colors
    
    /// Divider/separator color
    static let divider = Color("Divider")
    
    /// Border/stroke color
    static let border = Color("Border")
    
    /// Success/positive color (green)
    static let success = Color(hex: "57CE43")
    
    /// Error/negative color (red)
    static let error = Color(hex: "E30000")
    
    // MARK: - Button Colors
    
    /// Primary button background
    static let buttonPrimary = primary
    
    /// Secondary button background (dark in light mode, light in dark mode)
    static let buttonSecondary = Color("ButtonSecondary")
    
    /// Secondary button text
    static let buttonSecondaryText = Color("ButtonSecondaryText")
    
    /// Disabled button background
    static let buttonDisabled = Color("ButtonDisabled")
    
    // MARK: - Adaptive hex color helper
    
    /// Create an adaptive color with different values for light and dark mode
    static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(displayP3Red: Double(Int(dark.suffix(6).prefix(2), radix: 16) ?? 0) / 255,
                         green: Double(Int(dark.suffix(4).prefix(2), radix: 16) ?? 0) / 255,
                         blue: Double(Int(dark.suffix(2), radix: 16) ?? 0) / 255,
                         alpha: 1)
                : UIColor(displayP3Red: Double(Int(light.suffix(6).prefix(2), radix: 16) ?? 0) / 255,
                         green: Double(Int(light.suffix(4).prefix(2), radix: 16) ?? 0) / 255,
                         blue: Double(Int(light.suffix(2), radix: 16) ?? 0) / 255,
                         alpha: 1)
        })
    }
}

// Note: Color assets automatically generate Color extensions via Xcode's asset symbols
// Use Color("TextPrimary"), Color("Background"), etc. directly
// Or use AppColors.textPrimary, AppColors.background, etc.
