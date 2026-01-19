import SwiftUI
import UIKit

// MARK: - Pressed Button Style (shrinks by ~2px on all sides)
struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

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
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "FF5113"))
                .cornerRadius(20)
        }
        .buttonStyle(PressedButtonStyle())
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
    }
}

// MARK: - Secondary Button (Black)
struct SecondaryButton: View {
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
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "080808"))
                .cornerRadius(20)
        }
        .buttonStyle(PressedButtonStyle())
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
    }
}

// MARK: - Tertiary Button (Grey)
struct TertiaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(Color(hex: "080808"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "EDEDED"))
                .cornerRadius(20)
        }
        .buttonStyle(PressedButtonStyle())
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
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
