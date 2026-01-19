import SwiftUI
import Lottie

/// A button that shrinks to a circle and shows a Lottie loader when tapped
struct AnimatedLoadingButton: View {
    let title: String
    var isLoadingBinding: Binding<Bool>? = nil
    let onComplete: () -> Void
    
    @State private var isLoading = false
    @State private var showLoader = false
    @GestureState private var isPressed = false
    
    private let buttonHeight: CGFloat = 56
    private let circleSize: CGFloat = 56
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Button background
                RoundedRectangle(cornerRadius: isLoading ? circleSize / 2 : 20)
                    .fill(Color(hex: "FF5113"))
                    .frame(
                        width: isLoading ? circleSize : geometry.size.width,
                        height: buttonHeight
                    )
                
                // Button text (fades out when loading)
                if !isLoading {
                    Text(title)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(.white)
                        .transition(.opacity)
                }
                
                // Lottie loader (appears after shrink)
                if showLoader {
                    LottieView(animation: .named("loader-complete"))
                        .playing(loopMode: .playOnce)
                        .frame(width: 48, height: 48)
                        .transition(.opacity)
                }
            }
            .frame(width: geometry.size.width, height: buttonHeight)
            .scaleEffect(isPressed && !isLoading ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
                    .onEnded { _ in
                        guard !isLoading else { return }
                        
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        // Start shrink animation
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoading = true
                            isLoadingBinding?.wrappedValue = true
                        }
                        
                        // Show loader after shrink completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeIn(duration: 0.15)) {
                                showLoader = true
                            }
                            
                            // Call onComplete after checkmark shows (faster than waiting for full animation)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                onComplete()
                            }
                        }
                    }
            )
        }
        .frame(height: buttonHeight)
    }
}

#Preview {
    VStack {
        AnimatedLoadingButton(title: "Add £5.00") {
            print("Complete!")
        }
        .padding(.horizontal, 24)
    }
}
