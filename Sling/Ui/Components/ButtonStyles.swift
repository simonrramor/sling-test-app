import SwiftUI

// MARK: - Fluid Transitions

/// A fluid transition for confirmation screens - scales and fades instead of sliding
extension AnyTransition {
    /// Fluid scale + fade transition for confirm screens
    static var fluidConfirm: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.96).combined(with: .opacity),
            removal: .scale(scale: 0.96).combined(with: .opacity)
        )
    }
    
    /// Fluid transition from trailing edge with scale
    static var fluidTrailing: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.98, anchor: .trailing).combined(with: .opacity),
            removal: .scale(scale: 0.98, anchor: .leading).combined(with: .opacity)
        )
    }
}

// MARK: - Pressed Button Style

/// Standard pressed button style that shrinks by ~2px on all sides (0.97 scale)
struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DesignSystem.Animation.pressedScale : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - No Feedback Button Style

/// Button style with no visual feedback (for custom implementations)
struct NoFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

// MARK: - Opacity Pressed Button Style

/// Button style that reduces opacity when pressed
struct OpacityPressedButtonStyle: ButtonStyle {
    var pressedOpacity: Double = 0.7
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Combined Pressed Button Style

/// Button style that combines scale and opacity effects
struct CombinedPressedButtonStyle: ButtonStyle {
    var scale: CGFloat = DesignSystem.Animation.pressedScale
    var pressedOpacity: Double = 0.9
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
