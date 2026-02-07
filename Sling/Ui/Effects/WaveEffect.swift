import SwiftUI

// MARK: - Shader Effect Type

enum ShaderEffectType: String, CaseIterable {
    case shimmer = "Shimmer"
    case wave = "Wave"
    case ripple = "Ripple"
}

// MARK: - Wave Effect View Modifier

struct WaveEffectModifier: ViewModifier {
    let isActive: Bool
    let amplitude: CGFloat
    let frequency: CGFloat
    
    @State private var time: Double = 0
    
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            content
                .distortionEffect(
                    ShaderLibrary.wave(
                        .float(timeline.date.timeIntervalSinceReferenceDate),
                        .float(isActive ? amplitude : 0),
                        .float(frequency)
                    ),
                    maxSampleOffset: CGSize(width: amplitude * 2, height: amplitude * 2)
                )
        }
    }
}

// MARK: - Ripple Effect View Modifier

struct RippleEffectModifier: ViewModifier {
    let isActive: Bool
    let amplitude: CGFloat
    
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            content
                .visualEffect { content, proxy in
                    content
                        .distortionEffect(
                            ShaderLibrary.ripple(
                                .float2(proxy.size),
                                .float(isActive ? timeline.date.timeIntervalSinceReferenceDate : 0),
                                .float(isActive ? amplitude : 0)
                            ),
                            maxSampleOffset: CGSize(width: amplitude * 2, height: amplitude * 2)
                        )
                }
        }
    }
}

// MARK: - Shimmer Effect View Modifier

struct ShimmerEffectModifier: ViewModifier {
    let isActive: Bool
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            content
                .colorEffect(
                    ShaderLibrary.shimmer(
                        .float(timeline.date.timeIntervalSinceReferenceDate),
                        .float(isActive ? intensity : 0)
                    )
                )
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a smooth wave distortion effect
    func waveEffect(isActive: Bool = true, amplitude: CGFloat = 8, frequency: CGFloat = 1.0) -> some View {
        modifier(WaveEffectModifier(isActive: isActive, amplitude: amplitude, frequency: frequency))
    }
    
    /// Applies a ripple effect emanating from the center
    func rippleEffect(isActive: Bool = true, amplitude: CGFloat = 12) -> some View {
        modifier(RippleEffectModifier(isActive: isActive, amplitude: amplitude))
    }
    
    /// Applies a shimmering color effect
    func shimmerEffect(isActive: Bool = true, intensity: CGFloat = 1.0) -> some View {
        modifier(ShimmerEffectModifier(isActive: isActive, intensity: intensity))
    }
    
    /// Applies the specified shader effect type
    @ViewBuilder
    func applyShaderEffect(isActive: Bool, effectType: ShaderEffectType) -> some View {
        switch effectType {
        case .shimmer:
            self.shimmerEffect(isActive: isActive, intensity: 2.5)
        case .wave:
            self.waveEffect(isActive: isActive, amplitude: 12, frequency: 1.5)
        case .ripple:
            self.rippleEffect(isActive: isActive, amplitude: 20)
        }
    }
}
