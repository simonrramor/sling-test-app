import SwiftUI

/// Shared design system constants for consistent styling across the app
struct DesignSystem {
    
    // MARK: - View Extensions for Text Styles
    
    /// Apply body text style (16px, regular, #7B7B7B, -2% tracking, 1.5 line height)
    static func bodyStyle(_ color: Color = Color(hex: "7B7B7B")) -> some ViewModifier {
        BodyStyle(color: color)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        /// Small elements like tags, badges (12px)
        static let small: CGFloat = 12
        /// Cards, rows, containers (16px)
        static let medium: CGFloat = 16
        /// Buttons, large cards (20px)
        static let large: CGFloat = 20
        /// Pills, circular elements (28px - half of standard 56px button)
        static let pill: CGFloat = 28
        /// Large cards like transfer menu (32px)
        static let extraLarge: CGFloat = 32
    }
    
    // MARK: - Button Dimensions
    
    struct Button {
        /// Standard button height (56px)
        static let height: CGFloat = 56
        /// Loading circle size (64px)
        static let loadingCircleSize: CGFloat = 64
    }
    
    // MARK: - Animation
    
    struct Animation {
        /// Scale factor for pressed state (0.97 = 2px shrink on 56px button)
        static let pressedScale: CGFloat = 0.97
        /// Duration for press animations
        static let pressDuration: Double = 0.1
        /// Duration for loading/shrink animations
        static let shrinkDuration: Double = 0.3
        /// Standard spring response
        static let springResponse: Double = 0.25
        /// Standard spring damping
        static let springDamping: Double = 0.8
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Page headings (H2)
        static let heading = Font.custom("Inter-Bold", size: 32)
        
        // Body text - default regular (16px, 400 weight, -2% tracking)
        static let bodyRegular = Font.custom("Inter-Regular", size: 16)
        
        // Body text - medium weight
        static let bodyMedium = Font.custom("Inter-Medium", size: 16)
        
        // Body text - bold weight
        static let bodyBold = Font.custom("Inter-Bold", size: 16)
        
        // Button text
        static let buttonTitle = Font.custom("Inter-Bold", size: 16)
        
        // Row text
        static let rowTitle = Font.custom("Inter-Bold", size: 16)
        static let rowSubtitle = Font.custom("Inter-Regular", size: 14)
        
        // Large display text
        static let amountLarge = Font.custom("Inter-Bold", size: 56)
        static let amountExtraLarge = Font.custom("Inter-Bold", size: 62)
        
        // Header text
        static let headerTitle = Font.custom("Inter-Bold", size: 17)
        
        // Small text
        static let caption = Font.custom("Inter-Regular", size: 13)
        
        // Label text (form inputs)
        static let label = Font.custom("Inter-Medium", size: 13)
    }
    
    // MARK: - Text Styles with Line Height
    
    /// H1 header style - largest heading
    /// Font: Inter 700, Size: 40px, Letter Spacing: -2%
    struct H1Style: ViewModifier {
        var color: Color = Color(hex: "080808")
        
        func body(content: Content) -> some View {
            content
                .font(.custom("Inter-Bold", size: 40))
                .foregroundColor(color)
                .tracking(-0.80) // -2% of 40px
        }
    }
    
    /// H2 header style matching Figma header/H2
    /// Font: Inter 700, Size: 32px, Letter Spacing: -2%
    struct H2Style: ViewModifier {
        var color: Color = Color(hex: "080808")
        
        func body(content: Content) -> some View {
            content
                .font(.custom("Inter-Bold", size: 32))
                .foregroundColor(color)
                .tracking(-0.64) // -2% of 32px
        }
    }
    
    /// Body text style matching Figma body/default/regular
    /// Font: Inter 400, Size: 16px, Line Height: 1.5 (24px), Letter Spacing: -2%
    struct BodyStyle: ViewModifier {
        var color: Color = Color(hex: "7B7B7B")
        
        func body(content: Content) -> some View {
            content
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(color)
                .tracking(-0.32) // -2% of 16px
                .lineSpacing(4) // 24px line height - 16px font ≈ 4px extra
        }
    }
    
    // MARK: - Colors (Common hex values)
    
    struct Colors {
        /// Primary action color (orange)
        static let primary = "FF5113"
        /// Dark background/text
        static let dark = "080808"
        /// Light gray background
        static let backgroundLight = "F5F5F5"
        /// Tertiary button background
        static let tertiary = "EDEDED"
        /// Dark card background
        static let cardDark = "1B1B1B"
        /// Secondary text color
        static let textSecondary = "8E8E93"
        /// Divider color
        static let divider = "2A2A2A"
        /// Positive/increase state (inbound payments, gains, APY)
        static let positiveGreen = "57CE43"
        /// Negative/decrease state (outbound, losses)
        static let negativeRed = "E30000"
    }
    
    // MARK: - Icon Sizes
    
    struct IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 24
        static let large: CGFloat = 48
    }
}

// MARK: - H1 Text View
/// Figma header/H1: Inter 700, 40px, letter-spacing -2%
struct H1Text: View {
    let text: String
    var color: Color = Color(hex: "080808")
    
    var body: some View {
        Text(text)
            .font(.custom("Inter-Bold", size: 40))
            .foregroundColor(color)
            .tracking(-0.80)
    }
}

// MARK: - H2 Text View
/// Figma header/H2: Inter 700, 32px, line-height 40px, letter-spacing -2%
struct H2Text: View {
    let text: String
    var color: Color = Color(hex: "080808")
    
    var body: some View {
        Text(text)
            .font(.custom("Inter-Bold", size: 32))
            .foregroundColor(color)
            .tracking(-0.64)
    }
}

// MARK: - View Extensions for Text Styles

extension View {
    /// Apply H1 header style - largest heading
    /// Font: Inter Bold 40px, Letter Spacing: -2%
    func h1Style(color: Color = Color(hex: "080808")) -> some View {
        self.modifier(DesignSystem.H1Style(color: color))
    }
    
    /// Apply H2 header style matching Figma header/H2
    /// Font: Inter Bold 32px, Line Height: 1.25 (40px), Letter Spacing: -2%
    func h2Style(color: Color = Color(hex: "080808")) -> some View {
        self.modifier(DesignSystem.H2Style(color: color))
    }
    
    /// Apply body text style matching Figma body/default/regular
    /// Font: Inter 400, Size: 16px, Line Height: 1.5 (24px), Letter Spacing: -2%
    func bodyTextStyle(color: Color = Color(hex: "7B7B7B")) -> some View {
        self.modifier(DesignSystem.BodyStyle(color: color))
    }
}
