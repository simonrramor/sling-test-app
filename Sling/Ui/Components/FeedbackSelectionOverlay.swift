import SwiftUI
import UIKit

// MARK: - Device Corner Radius Helper

extension UIScreen {
    /// Returns the display corner radius for the current device
    static var displayCornerRadius: CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return 44 // Default fallback
        }
        
        // Access the private _displayCornerRadius property safely
        let cornerRadiusKey = ["Radius", "Corner", "display", "_"].reversed().joined()
        if let cornerRadius = window.screen.value(forKey: cornerRadiusKey) as? CGFloat, cornerRadius > 0 {
            return cornerRadius
        }
        
        return 44 // Fallback for older devices
    }
}

struct FeedbackSelectionOverlay: View {
    @ObservedObject private var feedbackManager = FeedbackModeManager.shared
    @State private var dragStarted = false
    @State private var showIntroSheet = true
    @State private var readyToCapture = false
    @State private var sheetOffset: CGFloat = 0
    
    // Long press indicator states
    @State private var longPressActive = false
    @State private var longPressLocation: CGPoint = .zero
    @State private var circleScale: CGFloat = 1.0
    @State private var circleOpacity: Double = 0.6
    
    private let initialCircleSize: CGFloat = 80
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed background when intro sheet is showing
                if showIntroSheet {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissAndExit()
                        }
                } else if readyToCapture {
                    // Transparent touch capture area for drawing
                    Color.black.opacity(0.01)
                        .ignoresSafeArea()
                }
                
                // Long press indicator circle
                if longPressActive && !dragStarted {
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: initialCircleSize * circleScale, height: initialCircleSize * circleScale)
                        .opacity(circleOpacity)
                        .position(longPressLocation)
                        .allowsHitTesting(false)
                    
                    // Inner pulsing circle
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: initialCircleSize * circleScale * 0.8, height: initialCircleSize * circleScale * 0.8)
                        .opacity(circleOpacity)
                        .position(longPressLocation)
                        .allowsHitTesting(false)
                }
                
                // Selection box (no dark overlay, just rounded blue border)
                if feedbackManager.isCapturing && feedbackManager.selectionRect != .zero {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 4)
                        .frame(
                            width: feedbackManager.selectionRect.width,
                            height: feedbackManager.selectionRect.height
                        )
                        .position(
                            x: feedbackManager.selectionRect.midX,
                            y: feedbackManager.selectionRect.midY
                        )
                        .allowsHitTesting(false)
                }
                
                // Custom bottom sheet (content-hugging)
                if showIntroSheet {
                    VStack {
                        Spacer()
                        
                        FeedbackIntroSheet(
                            onGiveFeedback: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showIntroSheet = false
                                    readyToCapture = true
                                }
                            },
                            onDismiss: {
                                dismissAndExit()
                            }
                        )
                        .offset(y: sheetOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.height > 0 {
                                        sheetOffset = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.height > 100 {
                                        dismissAndExit()
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            sheetOffset = 0
                                        }
                                    }
                                }
                        )
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .gesture(
                readyToCapture && !showIntroSheet ? DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !longPressActive && !dragStarted {
                            // First touch - start long press indicator
                            longPressLocation = drag.startLocation
                            longPressActive = true
                            circleScale = 1.0
                            circleOpacity = 0.6
                            
                            // Light haptic for touch
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            // Animate circle shrinking
                            withAnimation(.easeInOut(duration: 0.4)) {
                                circleScale = 0.3
                                circleOpacity = 1.0
                            }
                            
                            // After long press duration, enable drawing
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                if longPressActive && !dragStarted {
                                    // Long press complete - ready to draw
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                    dragStarted = true
                                    feedbackManager.startCapture(at: longPressLocation)
                                    
                                    // Hide the circle
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        circleOpacity = 0
                                    }
                                }
                            }
                        }
                        
                        // If drag has started, update the selection
                        if dragStarted {
                            feedbackManager.updateCapture(to: drag.location)
                        }
                    }
                    .onEnded { drag in
                        if dragStarted {
                            feedbackManager.endCapture()
                            
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                        
                        // Reset states
                        dragStarted = false
                        longPressActive = false
                        circleScale = 1.0
                        circleOpacity = 0.6
                    }
                : nil
            )
        }
    }
    
    private func dismissAndExit() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            sheetOffset = 500
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            feedbackManager.toggleFeedbackMode()
        }
    }
}

// MARK: - Feedback Intro Sheet

struct FeedbackIntroSheet: View {
    let onGiveFeedback: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Drag indicator
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 36, height: 5)
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(Color(red: 0.4, green: 0.7, blue: 1.0))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 20)
            
            // Title
            Text("Feedback mode")
                .font(.custom("Inter-Bold", size: 26))
                .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                .padding(.bottom, 12)
            
            // Description
            Text("To give feedback on the app, long-press and drag over the element to highlight. Comments will be submitted as Linear tickets.")
                .font(.custom("Inter-Regular", size: 17))
                .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 32)
            
            // Buttons row
            HStack(spacing: 12) {
                // Tertiary button (Cancel)
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onDismiss()
                }) {
                    Text("Cancel")
                        .font(DesignSystem.Typography.buttonTitle)
                        .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Button.height)
                        .background(Color(hex: DesignSystem.Colors.tertiary))
                        .cornerRadius(DesignSystem.CornerRadius.large)
                }
                .buttonStyle(PressedButtonStyle())
                
                // Secondary button (Give feedback)
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onGiveFeedback()
                }) {
                    Text("Give feedback")
                        .font(DesignSystem.Typography.buttonTitle)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Button.height)
                        .background(Color(hex: DesignSystem.Colors.dark))
                        .cornerRadius(DesignSystem.CornerRadius.large)
                }
                .buttonStyle(PressedButtonStyle())
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 32,
                bottomLeadingRadius: UIScreen.displayCornerRadius,
                bottomTrailingRadius: UIScreen.displayCornerRadius,
                topTrailingRadius: 32
            )
            .fill(Color.white)
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Selection Overlay Shape

struct SelectionOverlayShape: Shape {
    let selectionRect: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Full rectangle
        path.addRect(rect)
        
        // Cut out the selection area
        path.addRect(selectionRect)
        
        return path
    }
}

extension SelectionOverlayShape {
    // Use even-odd fill rule to create the cutout effect
    var fillStyle: FillStyle {
        FillStyle(eoFill: true)
    }
}

// Custom fill modifier that uses even-odd fill
extension Shape {
    func fill<S: ShapeStyle>(_ style: S, eoFill: Bool) -> some View {
        self.fill(style, style: FillStyle(eoFill: eoFill))
    }
}

#Preview {
    ZStack {
        Color.gray
        FeedbackSelectionOverlay()
    }
}
