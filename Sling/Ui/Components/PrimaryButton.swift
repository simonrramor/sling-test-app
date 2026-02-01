import SwiftUI
import UIKit

// MARK: - Primary Button (Orange)
struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .font(DesignSystem.Typography.buttonTitle)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Button.height)
                .background(Color(hex: DesignSystem.Colors.primary))
                .cornerRadius(DesignSystem.CornerRadius.large)
        }
        .buttonStyle(PressedButtonStyle())
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    @ObservedObject private var themeService = ThemeService.shared
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    
    // Text color depends on theme - white text on black button (white theme), dark text otherwise
    private var textColor: Color {
        if !isEnabled {
            return .white.opacity(0.5)  // White text at 50% opacity when disabled
        }
        switch themeService.currentTheme {
        case .grey, .white:
            return .white  // White text on black button
        case .dark:
            return themeService.textPrimaryColor
        }
    }
    
    // Background color - uses theme color when enabled, grey when disabled
    private var backgroundColor: Color {
        if !isEnabled {
            return Color(hex: "CCCCCC")  // Grey when disabled
        }
        return themeService.buttonSecondaryColor
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .font(DesignSystem.Typography.buttonTitle)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Button.height)
                .background(backgroundColor)
                .cornerRadius(DesignSystem.CornerRadius.large)
        }
        .buttonStyle(PressedButtonStyle())
        .disabled(!isEnabled)
    }
}

// MARK: - Tertiary Button (Grey)
struct TertiaryButton<Icon: View>: View {
    @ObservedObject private var themeService = ThemeService.shared
    let title: String
    var isEnabled: Bool = true
    var onCard: Bool = false // true = on card (grey), false = on surface (white on grey theme)
    let action: () -> Void
    @ViewBuilder var icon: () -> Icon
    
    init(title: String, isEnabled: Bool = true, onCard: Bool = false, action: @escaping () -> Void, @ViewBuilder icon: @escaping () -> Icon) {
        self.title = title
        self.isEnabled = isEnabled
        self.onCard = onCard
        self.action = action
        self.icon = icon
    }
    
    // Background color depends on theme and context (on card vs on surface)
    private var backgroundColor: Color {
        if onCard {
            // On card - use grey background
            switch themeService.currentTheme {
            case .grey, .white:
                return Color(hex: DesignSystem.Colors.tertiary) // Grey
            case .dark:
                return Color(hex: "3A3A3C") // Slightly lighter for cards in dark mode
            }
        } else {
            // On surface/background - use contrasting color
            switch themeService.currentTheme {
            case .grey:
                return .white
            case .white:
                return Color(hex: DesignSystem.Colors.tertiary)
            case .dark:
                return Color(hex: "2C2C2E")
            }
        }
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                icon()
                Text(title)
                    .font(DesignSystem.Typography.buttonTitle)
            }
            .foregroundColor(themeService.textPrimaryColor)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Button.height)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.large)
        }
        .buttonStyle(PressedButtonStyle())
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
    }
}

// Convenience initializer for TertiaryButton without icon
extension TertiaryButton where Icon == EmptyView {
    init(title: String, isEnabled: Bool = true, onCard: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.onCard = onCard
        self.action = action
        self.icon = { EmptyView() }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Primary (Orange)") {}
        PrimaryButton(title: "Primary Disabled", isEnabled: false) {}
        SecondaryButton(title: "Secondary (Black)") {}
        SecondaryButton(title: "Secondary Disabled", isEnabled: false) {}
        TertiaryButton(title: "Tertiary (Grey)") {}
        TertiaryButton(title: "Tertiary Disabled", isEnabled: false) {}
    }
    .padding()
}
