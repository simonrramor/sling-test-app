import SwiftUI

// MARK: - Face Rig State

struct FaceRigState {
    var headX: CGFloat = 0      // -1 (left) to 1 (right)
    var headY: CGFloat = 0      // -1 (up) to 1 (down)
    var blink: CGFloat = 0      // 0 (open) to 1 (closed)
    var eyebrows: CGFloat = 0   // -1 (angry/down) to 1 (surprised/up)
    var mouth: CGFloat = 0      // -1 (frown) to 1 (smile)
}

// MARK: - Pose Configurations for Interpolation

struct FacePoseConfig {
    var leftEyeX: CGFloat
    var leftEyeY: CGFloat
    var rightEyeX: CGFloat
    var rightEyeY: CGFloat
    var mouthX: CGFloat
    var mouthY: CGFloat
    
    // Base poses for joystick interpolation
    // Default neutral: eyes and mouth horizontally aligned at center
    // Eye width=16 (radius 8), mouth stroke width=16 with round caps (+8 each side)
    // For 2px gap: left eye at 37, right eye at 163
    static let center = FacePoseConfig(
        leftEyeX: 37, leftEyeY: 100,
        rightEyeX: 163, rightEyeY: 100,
        mouthX: 100, mouthY: 100
    )
    
    static let left = FacePoseConfig(
        leftEyeX: 26, leftEyeY: 100,
        rightEyeX: 149, rightEyeY: 100,
        mouthX: 85, mouthY: 100
    )
    
    static let right = FacePoseConfig(
        leftEyeX: 51, leftEyeY: 100,
        rightEyeX: 174, rightEyeY: 100,
        mouthX: 115, mouthY: 100
    )
    
    static let up = FacePoseConfig(
        leftEyeX: 37, leftEyeY: 85,
        rightEyeX: 163, rightEyeY: 85,
        mouthX: 100, mouthY: 85
    )
    
    static let down = FacePoseConfig(
        leftEyeX: 37, leftEyeY: 115,
        rightEyeX: 163, rightEyeY: 115,
        mouthX: 100, mouthY: 115
    )
    
    // Linear interpolation between two poses
    static func lerp(_ a: FacePoseConfig, _ b: FacePoseConfig, t: CGFloat) -> FacePoseConfig {
        FacePoseConfig(
            leftEyeX: a.leftEyeX + (b.leftEyeX - a.leftEyeX) * t,
            leftEyeY: a.leftEyeY + (b.leftEyeY - a.leftEyeY) * t,
            rightEyeX: a.rightEyeX + (b.rightEyeX - a.rightEyeX) * t,
            rightEyeY: a.rightEyeY + (b.rightEyeY - a.rightEyeY) * t,
            mouthX: a.mouthX + (b.mouthX - a.mouthX) * t,
            mouthY: a.mouthY + (b.mouthY - a.mouthY) * t
        )
    }
    
    // Interpolate based on joystick position
    static func interpolate(headX: CGFloat, headY: CGFloat) -> FacePoseConfig {
        // Horizontal interpolation
        let horizontal: FacePoseConfig
        if headX < 0 {
            horizontal = lerp(center, left, t: -headX)
        } else {
            horizontal = lerp(center, right, t: headX)
        }
        
        // Vertical interpolation
        let vertical: FacePoseConfig
        if headY < 0 {
            vertical = lerp(center, up, t: -headY)
        } else {
            vertical = lerp(center, down, t: headY)
        }
        
        // Combine horizontal and vertical (additive blend)
        return FacePoseConfig(
            leftEyeX: center.leftEyeX + (horizontal.leftEyeX - center.leftEyeX) + (vertical.leftEyeX - center.leftEyeX),
            leftEyeY: center.leftEyeY + (horizontal.leftEyeY - center.leftEyeY) + (vertical.leftEyeY - center.leftEyeY),
            rightEyeX: center.rightEyeX + (horizontal.rightEyeX - center.rightEyeX) + (vertical.rightEyeX - center.rightEyeX),
            rightEyeY: center.rightEyeY + (horizontal.rightEyeY - center.rightEyeY) + (vertical.rightEyeY - center.rightEyeY),
            mouthX: center.mouthX + (horizontal.mouthX - center.mouthX) + (vertical.mouthX - center.mouthX),
            mouthY: center.mouthY + (horizontal.mouthY - center.mouthY) + (vertical.mouthY - center.mouthY)
        )
    }
}

// MARK: - Main View

struct MorseBotView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    
    // Face rig state
    @State private var rigState = FaceRigState()
    @State private var blinkFrequency: CGFloat = 0.5 // 0 = never, 1 = frequent
    @State private var blinkTimer: Timer?
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            themeService.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                headerView
                
                Spacer()
                
                // Main content: Controls | Face | Controls
                rigControlsAndFace
                
                Spacer()
            }
        }
        .onAppear {
            startBlinkTimer()
        }
        .onDisappear {
            blinkTimer?.invalidate()
        }
        .onChange(of: blinkFrequency) { _, _ in
            // Restart blink timer when frequency changes
            blinkTimer?.invalidate()
            scheduleBlink()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeService.textPrimaryColor)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("Morse Bot Rig")
                .font(.custom("Inter-Bold", size: 18))
                .foregroundColor(themeService.textPrimaryColor)
            
            Spacer()
            
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
    
    // MARK: - Rig Controls and Face Layout
    
    private var rigControlsAndFace: some View {
        VStack(spacing: 24) {
            // Top: Head joystick
            VStack(spacing: 8) {
                Text("Head")
                    .font(.custom("Inter-SemiBold", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
                
                JoystickControlView(
                    positionX: $rigState.headX,
                    positionY: $rigState.headY
                )
            }
            
            // Center: Face
            MorseBotRiggedFaceView(rigState: rigState)
                .frame(width: 200, height: 200)
            
            // Bottom: Sliders
            VStack(spacing: 16) {
                // Blink slider (manual override)
                LabeledSlider(
                    label: "Blink",
                    value: $rigState.blink,
                    range: 0...1
                )
                
                // Blink frequency slider
                LabeledSlider(
                    label: "Blink Frequency",
                    value: $blinkFrequency,
                    range: 0...1
                )
                
                // Eyebrows slider
                LabeledSlider(
                    label: "Eyebrows",
                    value: $rigState.eyebrows,
                    range: -1...1
                )
                
                // Mouth slider
                LabeledSlider(
                    label: "Mouth",
                    value: $rigState.mouth,
                    range: -1...1
                )
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Blink Timer
    
    private func startBlinkTimer() {
        scheduleBlink()
    }
    
    private func scheduleBlink() {
        // blinkFrequency: 0 = never, 1 = every ~1 second
        // At 0: interval is infinite (don't schedule)
        // At 1: interval is ~1-2 seconds
        // At 0.5: interval is ~3-5 seconds
        guard blinkFrequency > 0.01 else {
            // No auto-blink when frequency is 0
            return
        }
        
        let minInterval = 1.0 + (1.0 - blinkFrequency) * 5.0 // 1s at freq=1, 6s at freq=0
        let maxInterval = minInterval + 2.0
        let interval = Double.random(in: minInterval...maxInterval)
        
        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            performBlink()
        }
    }
    
    private func performBlink() {
        // Only auto-blink if manual slider is at 0
        guard rigState.blink < 0.1 else {
            scheduleBlink()
            return
        }
        
        withAnimation(.easeInOut(duration: 0.08)) {
            rigState.blink = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.08)) {
                rigState.blink = 0
            }
            scheduleBlink()
        }
    }
}

// MARK: - Joystick Control View

struct JoystickControlView: View {
    @Binding var positionX: CGFloat
    @Binding var positionY: CGFloat
    
    let size: CGFloat = 100
    let dotSize: CGFloat = 24
    
    @State private var isDragging = false
    
    private var dotOffset: CGSize {
        CGSize(
            width: positionX * (size - dotSize) / 2,
            height: positionY * (size - dotSize) / 2
        )
    }
    
    var body: some View {
        ZStack {
            // Boundary rectangle
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .frame(width: size, height: size)
            
            // Center crosshairs
            Path { path in
                path.move(to: CGPoint(x: size/2, y: 10))
                path.addLine(to: CGPoint(x: size/2, y: size - 10))
                path.move(to: CGPoint(x: 10, y: size/2))
                path.addLine(to: CGPoint(x: size - 10, y: size/2))
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            .frame(width: size, height: size)
            
            // Draggable dot
            Circle()
                .fill(Color(hex: "FF5500"))
                .frame(width: dotSize, height: dotSize)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .offset(dotOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let maxOffset = (size - dotSize) / 2
                            
                            // Calculate position from drag
                            let newX = value.location.x - size/2
                            let newY = value.location.y - size/2
                            
                            // Clamp to bounds
                            positionX = max(-1, min(1, newX / maxOffset))
                            positionY = max(-1, min(1, newY / maxOffset))
                        }
                        .onEnded { _ in
                            isDragging = false
                            // Spring back to center
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                positionX = 0
                                positionY = 0
                            }
                        }
                )
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Labeled Slider

struct LabeledSlider: View {
    let label: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("Inter-SemiBold", size: 12))
                .foregroundColor(themeService.textSecondaryColor)
            
            Slider(value: $value, in: range)
                .tint(Color(hex: "FF5500"))
        }
    }
}

// MARK: - Rigged Face View

struct MorseBotRiggedFaceView: View {
    let rigState: FaceRigState
    
    // Computed face configuration from rig state
    private var faceConfig: ComputedFaceConfig {
        computeFaceConfig(from: rigState)
    }
    
    var body: some View {
        ZStack {
            // Background - black rounded super-ellipse
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.black)
            
            // Left eye
            RoundedRectangle(cornerRadius: faceConfig.leftEyeCornerRadius)
                .fill(Color(hex: "FCFCFC"))
                .frame(width: faceConfig.leftEyeWidth, height: faceConfig.leftEyeHeight)
                .rotationEffect(.degrees(faceConfig.leftEyeRotation))
                .position(x: faceConfig.leftEyeX, y: faceConfig.leftEyeY)
            
            // Right eye
            RoundedRectangle(cornerRadius: faceConfig.rightEyeCornerRadius)
                .fill(Color(hex: "FF5500"))
                .frame(width: faceConfig.rightEyeWidth, height: faceConfig.rightEyeHeight)
                .rotationEffect(.degrees(faceConfig.rightEyeRotation))
                .position(x: faceConfig.rightEyeX, y: faceConfig.rightEyeY)
            
            // Mouth - stroke path with consistent thickness
            MorseBotMouthShape(
                width: faceConfig.mouthWidth,
                curve: faceConfig.mouthCurve
            )
            .stroke(Color(hex: "FCFCFC"), style: StrokeStyle(lineWidth: 16, lineCap: .round))
            .frame(width: faceConfig.mouthWidth, height: 50)
            .position(x: faceConfig.mouthX, y: faceConfig.mouthY)
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.headX)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.headY)
        .animation(.spring(response: 0.15, dampingFraction: 0.9), value: rigState.blink)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.eyebrows)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.mouth)
    }
    
    // MARK: - Compute Face Config
    
    private func computeFaceConfig(from state: FaceRigState) -> ComputedFaceConfig {
        // 1. Get base pose from joystick interpolation
        let basePose = FacePoseConfig.interpolate(headX: state.headX, headY: state.headY)
        
        // 2. Base eye properties
        let baseEyeWidth: CGFloat = 16
        let baseEyeHeight: CGFloat = 16
        let baseEyeCornerRadius: CGFloat = 8
        
        // 3. Apply blink modifier (0 = open, 1 = closed)
        let blinkScale = 1 - state.blink * 0.9 // At blink=1, height is 10% of original
        let eyeHeight = max(2, baseEyeHeight * blinkScale)
        
        // 4. Apply eyebrow modifier
        // Positive = surprised (eyes up, wider)
        // Negative = angry (eyes angled inward)
        let eyebrowYOffset = -state.eyebrows * 8 // Move up when positive
        let eyebrowRotation = -state.eyebrows * 15 // Angle when negative (angry)
        let eyebrowHeightMod = 1 + state.eyebrows * 0.3 // Taller when surprised
        
        // 5. Apply mouth modifier
        let baseMouthWidth: CGFloat = 58
        let mouthCurve = state.mouth // Direct mapping
        let mouthWidthMod = 1 + abs(state.mouth) * 0.3 // Wider when expressing
        // Move mouth down when smiling so curve doesn't go above eyes
        let mouthYOffset = max(0, state.mouth) * 20 // Only move down for smile, not frown
        
        return ComputedFaceConfig(
            leftEyeX: basePose.leftEyeX,
            leftEyeY: basePose.leftEyeY + eyebrowYOffset,
            leftEyeWidth: baseEyeWidth,
            leftEyeHeight: eyeHeight * eyebrowHeightMod,
            leftEyeCornerRadius: baseEyeCornerRadius,
            leftEyeRotation: eyebrowRotation, // Left eye rotates opposite for angry
            rightEyeX: basePose.rightEyeX,
            rightEyeY: basePose.rightEyeY + eyebrowYOffset,
            rightEyeWidth: baseEyeWidth,
            rightEyeHeight: eyeHeight * eyebrowHeightMod,
            rightEyeCornerRadius: baseEyeCornerRadius,
            rightEyeRotation: -eyebrowRotation, // Right eye rotates opposite
            mouthX: basePose.mouthX,
            mouthY: basePose.mouthY + mouthYOffset,
            mouthWidth: baseMouthWidth * mouthWidthMod,
            mouthCurve: mouthCurve
        )
    }
}

// MARK: - Computed Face Config

struct ComputedFaceConfig {
    var leftEyeX: CGFloat
    var leftEyeY: CGFloat
    var leftEyeWidth: CGFloat
    var leftEyeHeight: CGFloat
    var leftEyeCornerRadius: CGFloat
    var leftEyeRotation: CGFloat
    
    var rightEyeX: CGFloat
    var rightEyeY: CGFloat
    var rightEyeWidth: CGFloat
    var rightEyeHeight: CGFloat
    var rightEyeCornerRadius: CGFloat
    var rightEyeRotation: CGFloat
    
    var mouthX: CGFloat
    var mouthY: CGFloat
    var mouthWidth: CGFloat
    var mouthCurve: CGFloat
}

// MARK: - Mouth Shape

struct MorseBotMouthShape: Shape {
    var width: CGFloat
    var curve: CGFloat // -1 = frown, 0 = straight, 1 = smile
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(width, curve) }
        set {
            width = newValue.first
            curve = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let curveAmount = curve * 20 // How much the curve bends
        
        // Single curved line from left to right
        path.move(to: CGPoint(x: (rect.width - width) / 2, y: rect.midY - curveAmount / 2))
        path.addQuadCurve(
            to: CGPoint(x: (rect.width + width) / 2, y: rect.midY - curveAmount / 2),
            control: CGPoint(x: rect.midX, y: rect.midY + curveAmount / 2)
        )
        
        return path
    }
}

#Preview {
    MorseBotView(isPresented: .constant(true))
}
