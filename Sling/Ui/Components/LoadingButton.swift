import SwiftUI
import UIKit
import Lottie

/// A unified loading button that shrinks to a circle when tapped
/// Optionally shows a Lottie loader animation
struct LoadingButton: View {
    let title: String
    
    /// Binding to track loading state externally
    var isLoadingBinding: Binding<Bool>? = nil
    
    /// Whether to show the Lottie loader animation (default true)
    var showLoader: Bool = true
    
    /// Called immediately when tapped (for fading out other content)
    var onTap: (() -> Void)? = nil
    
    /// Called after shrink animation finishes (for transitioning to next screen)
    var onShrinkComplete: (() -> Void)? = nil
    
    /// Called for business logic or after loader animation completes
    let onComplete: () -> Void
    
    @State private var isLoading = false
    @State private var showLoaderAnimation = false
    @GestureState private var isPressed = false
    
    private let buttonHeight = DesignSystem.Button.height
    private let circleSize = DesignSystem.Button.loadingCircleSize
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Button background
                RoundedRectangle(cornerRadius: isLoading ? circleSize / 2 : DesignSystem.CornerRadius.large)
                    .fill(Color(hex: DesignSystem.Colors.primary))
                    .frame(
                        width: isLoading ? circleSize : geometry.size.width,
                        height: isLoading ? circleSize : buttonHeight
                    )
                
                // Button text (fades out when loading)
                Text(title)
                    .font(DesignSystem.Typography.buttonTitle)
                    .foregroundColor(.white)
                    .opacity(isLoading ? 0 : 1)
                
                // Lottie loader (appears after shrink if showLoader is true)
                if showLoaderAnimation {
                    LottieView(animation: .named("loader-complete"))
                        .playing(loopMode: .playOnce)
                        .frame(width: circleSize, height: circleSize)
                        .transition(.opacity)
                }
            }
            .frame(width: geometry.size.width, height: isLoading ? circleSize : buttonHeight)
            .scaleEffect(isPressed && !isLoading ? DesignSystem.Animation.pressedScale : 1.0)
            .animation(.easeInOut(duration: DesignSystem.Animation.pressDuration), value: isPressed)
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
                        
                        // Call onTap immediately (for fading content)
                        onTap?()
                        
                        // Start shrink animation
                        withAnimation(.easeInOut(duration: DesignSystem.Animation.shrinkDuration)) {
                            isLoading = true
                            isLoadingBinding?.wrappedValue = true
                        }
                        
                        if showLoader {
                            // Show loader after shrink completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.shrinkDuration) {
                                withAnimation(.easeIn(duration: 0.15)) {
                                    showLoaderAnimation = true
                                }
                                
                                // Success haptic when checkmark appears
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    let successGenerator = UINotificationFeedbackGenerator()
                                    successGenerator.notificationOccurred(.success)
                                }
                                
                                // Call onComplete after checkmark shows
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                    onComplete()
                                }
                            }
                        } else {
                            // Execute business logic immediately
                            onComplete()
                            
                            // Call onShrinkComplete after shrink animation finishes
                            DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.shrinkDuration + 0.05) {
                                onShrinkComplete?()
                            }
                        }
                    }
            )
        }
        .frame(height: isLoading ? circleSize : buttonHeight)
        .animation(.easeInOut(duration: DesignSystem.Animation.shrinkDuration), value: isLoading)
    }
}

// MARK: - Convenience Initializers

extension LoadingButton {
    /// Create a button with Lottie loader (for Send, Split Bill, etc.)
    static func withLoader(
        title: String,
        isLoadingBinding: Binding<Bool>? = nil,
        onComplete: @escaping () -> Void
    ) -> LoadingButton {
        LoadingButton(
            title: title,
            isLoadingBinding: isLoadingBinding,
            showLoader: true,
            onComplete: onComplete
        )
    }
    
    /// Create a button that just shrinks (for transitions to pending screens)
    static func shrinkOnly(
        title: String,
        isLoadingBinding: Binding<Bool>? = nil,
        onTap: (() -> Void)? = nil,
        onShrinkComplete: (() -> Void)? = nil,
        onComplete: @escaping () -> Void
    ) -> LoadingButton {
        LoadingButton(
            title: title,
            isLoadingBinding: isLoadingBinding,
            showLoader: false,
            onTap: onTap,
            onShrinkComplete: onShrinkComplete,
            onComplete: onComplete
        )
    }
}

// MARK: - Backward Compatibility

/// Backward compatible alias for AnimatedLoadingButton
typealias AnimatedLoadingButton = LoadingButton

/// Backward compatible wrapper for ShrinkingButton behavior
struct ShrinkingButton: View {
    let title: String
    var isLoadingBinding: Binding<Bool>? = nil
    var onTap: (() -> Void)? = nil
    var onShrinkComplete: (() -> Void)? = nil
    let onComplete: () -> Void
    
    var body: some View {
        LoadingButton.shrinkOnly(
            title: title,
            isLoadingBinding: isLoadingBinding,
            onTap: onTap,
            onShrinkComplete: onShrinkComplete,
            onComplete: onComplete
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        LoadingButton.withLoader(title: "Send £50.00") {
            print("Complete with loader!")
        }
        .padding(.horizontal, 24)
        
        LoadingButton.shrinkOnly(title: "Buy 0.56 AAPL") {
            print("Complete without loader!")
        }
        .padding(.horizontal, 24)
    }
}
