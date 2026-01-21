import SwiftUI

/// Shared design system constants for consistent styling across the app
struct DesignSystem {
    
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
    }
    
    // MARK: - Icon Sizes
    
    struct IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 24
        static let large: CGFloat = 48
    }
}
