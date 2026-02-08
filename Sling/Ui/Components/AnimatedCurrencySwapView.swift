import SwiftUI

/// A currency swap view. Primary always on top, secondary always below.
/// Tapping crossfades between large (prominent) and small (subdued) rendering.
/// Uses two overlapping Text views per slot for pixel-perfect rendering at both sizes.
struct AnimatedCurrencySwapView: View {
    @ObservedObject private var themeService = ThemeService.shared
    
    let primaryDisplay: String
    let secondaryDisplay: String
    let showingPrimaryOnTop: Bool   // true = primary is prominent (large)
    let onSwap: () -> Void
    var errorMessage: String? = nil
    
    private let prominentColor = Color(hex: "080808")
    private let subduedColor = Color(hex: "7B7B7B")
    
    private var swapAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.85)
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onSwap()
        }) {
            VStack(spacing: 4) {
                // Primary amount slot - always on top
                CurrencyAmountSlot(
                    amount: primaryDisplay,
                    isProminent: showingPrimaryOnTop,
                    prominentColor: prominentColor,
                    subduedColor: subduedColor
                )
                
                // Secondary amount slot - always below
                if let error = errorMessage {
                    Text(error)
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(Color(hex: "FF3B30"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                } else {
                    CurrencyAmountSlot(
                        amount: secondaryDisplay,
                        isProminent: !showingPrimaryOnTop,
                        prominentColor: prominentColor,
                        subduedColor: subduedColor
                    )
                }
            }
            .padding(.horizontal, 24)
            .animation(swapAnimation, value: showingPrimaryOnTop)
        }
        .buttonStyle(PressedButtonStyle())
    }
}

// MARK: - Currency Amount Slot

/// A single amount slot. Renders at 18pt and scales UP when prominent.
/// Small state is pixel-perfect 18pt. Large state is scaled up (looks great for large text).
private struct CurrencyAmountSlot: View {
    let amount: String
    let isProminent: Bool
    let prominentColor: Color
    let subduedColor: Color
    
    // 48 / 18 = 2.667
    private let largeScale: CGFloat = 48.0 / 18.0
    
    var body: some View {
        Text(amount)
            .font(.custom("Inter-Bold", size: 18))
            .foregroundColor(isProminent ? prominentColor : subduedColor)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .center)
            .scaleEffect(isProminent ? largeScale : 1.0)
            .frame(height: isProminent ? 56 : 24)
            .clipped()
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
