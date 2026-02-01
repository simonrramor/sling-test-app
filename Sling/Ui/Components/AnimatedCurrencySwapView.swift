import SwiftUI

/// A smooth, animated currency swap view with scale and position animations.
/// Figma specs: Large = 80px Bold, Small = 18px Medium, Icon = 18x18
struct AnimatedCurrencySwapView: View {
    @ObservedObject private var themeService = ThemeService.shared
    
    let primaryDisplay: String      // The primary currency amount
    let secondaryDisplay: String    // The secondary currency amount (converted)
    let showingPrimaryOnTop: Bool   // true = primary is large, false = primary is small
    let onSwap: () -> Void
    var errorMessage: String? = nil // Optional error to show instead of secondary
    
    // Colors (from Figma)
    private var primaryColor: Color { Color(hex: "080808") }
    private var secondaryColor: Color { Color(hex: "7B7B7B") }
    
    // Animation - quick and smooth
    private var swapAnimation: Animation {
        .easeOut(duration: 0.2)
    }
    
    // Scale: 1.0 = 64px, 0.28125 = 18px (18/64)
    // When primary is on top: primary = large (1.0), secondary = small (0.28125)
    // When primary is NOT on top: primary = small (0.28125), secondary = large (1.0)
    private var primaryScale: CGFloat {
        showingPrimaryOnTop ? 1.0 : 0.28125
    }
    
    private var secondaryScale: CGFloat {
        showingPrimaryOnTop ? 0.28125 : 1.0
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onSwap()
            }) {
                ZStack {
                    // Primary amount - swaps position and scale (text always centered)
                    Text(primaryDisplay)
                        .font(.custom("Inter-Bold", size: 64))
                        .foregroundColor(showingPrimaryOnTop ? primaryColor : secondaryColor)
                        .tracking(-1.6)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0), location: 0),
                                    .init(color: .white, location: 0.3),
                                    .init(color: .white, location: 0.7),
                                    .init(color: .white.opacity(0), location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(primaryScale, anchor: .center)
                        .frame(width: geometry.size.width, height: 80, alignment: .center)
                        .offset(y: showingPrimaryOnTop ? -5 : 45)
                    
                    // Secondary amount or error message
                    if let error = errorMessage {
                        // Show error message instead of secondary amount
                        Text(error)
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(Color(hex: "FF3B30"))
                            .frame(width: geometry.size.width, height: 80, alignment: .center)
                            .offset(y: 45)
                    } else {
                        // Secondary amount - swaps position and scale (text always centered)
                        Text(secondaryDisplay)
                            .font(.custom("Inter-Bold", size: 64))
                            .foregroundColor(showingPrimaryOnTop ? secondaryColor : primaryColor)
                            .tracking(-1.6)
                            .lineLimit(1)   
                            .fixedSize()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    stops: [
                                        .init(color: .white.opacity(0), location: 0),
                                        .init(color: .white, location: 0.3),
                                        .init(color: .white, location: 0.7),
                                        .init(color: .white.opacity(0), location: 1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(secondaryScale, anchor: .center)
                            .frame(width: geometry.size.width, height: 80, alignment: .center)
                            .offset(y: showingPrimaryOnTop ? 45 : -5)
                    }
                    
                }
                .frame(width: geometry.size.width, height: 120)
                .animation(swapAnimation, value: showingPrimaryOnTop)
            }
            .buttonStyle(PressedButtonStyle())
        }
        .frame(height: 120)
    }
}


// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var showingPrimaryOnTop = true
        
        var body: some View {
            VStack(spacing: 40) {
                AnimatedCurrencySwapView(
                    primaryDisplay: "£221.37",
                    secondaryDisplay: "€255",
                    showingPrimaryOnTop: showingPrimaryOnTop,
                    onSwap: {
                        withAnimation {
                            showingPrimaryOnTop.toggle()
                        }
                    }
                )
                
                Button("Toggle") {
                    showingPrimaryOnTop.toggle()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
