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
            return themeService.textPrimaryColor.opacity(0.4)
        }
        switch themeService.currentTheme {
        case .white:
            return .white  // White text on black button
        case .grey, .dark:
            return themeService.textPrimaryColor
        }
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
                .background(isEnabled ? themeService.buttonSecondaryColor : Color("ButtonDisabled"))
                .cornerRadius(DesignSystem.CornerRadius.large)
        }
        .buttonStyle(PressedButtonStyle())
        .disabled(!isEnabled)
    }
}

// MARK: - Tertiary Button (Grey)
struct TertiaryButton<Icon: View>: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    @ViewBuilder var icon: () -> Icon
    
    init(title: String, isEnabled: Bool = true, action: @escaping () -> Void, @ViewBuilder icon: @escaping () -> Icon) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
        self.icon = icon
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
            .foregroundColor(Color("TextPrimary"))
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Button.height)
            .background(Color("BackgroundTertiary"))
            .cornerRadius(DesignSystem.CornerRadius.large)
        }
        .buttonStyle(PressedButtonStyle())
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
    }
}

// Convenience initializer for TertiaryButton without icon
extension TertiaryButton where Icon == EmptyView {
    init(title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
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
