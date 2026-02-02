import SwiftUI

// MARK: - Face Rig State

struct FaceRigState {
    var headX: CGFloat = 0      // -1 (left) to 1 (right)
    var headY: CGFloat = 0      // -1 (up) to 1 (down)
    var blink: CGFloat = 0      // 0 (open) to 1 (closed)
    var eyebrows: CGFloat = 0   // -1 (angry/down) to 1 (surprised/up)
    var mouth: CGFloat = 0      // -1 (frown) to 1 (smile)
    var mouthIsCircle: Bool = false // True for "O" shape (sleeping/surprised)
    
    // Advanced eye controls (inspired by esp32-eyes)
    var eyelidTop: CGFloat = 0  // 0 (open) to 1 (closed from top) - for sleepy/skeptical
    var pupilX: CGFloat = 0     // -1 (left) to 1 (right) - pupil offset within eye
    var pupilY: CGFloat = 0     // -1 (up) to 1 (down) - pupil offset within eye
    var eyeHeight: CGFloat = 1  // 0.3 (squint) to 1.5 (wide) - eye openness
    
    // Asymmetric eye controls (inspired by Procedural-Expression-Library)
    var leftEyeScale: CGFloat = 1.0   // Scale multiplier for left eye (0.5 to 1.5)
    var rightEyeScale: CGFloat = 1.0  // Scale multiplier for right eye (0.5 to 1.5)
}

// MARK: - Expression Presets

enum ExpressionPreset: String, CaseIterable {
    case wink = "Wink"
    case thinking = "Thinking"
    case sleeping = "Sleeping"
    case excited = "Excited"
    case confused = "Confused"
    case angry = "Angry"
    case shy = "Shy"
    case skeptical = "Skeptical"
    case glee = "Glee"
    case pleading = "Pleading"
    case scared = "Scared"
    case sad = "Sad"
    case awe = "Awe"
    case focused = "Focused"
    case suspicious = "Suspicious"
    case frustrated = "Frustrated"
    
    var icon: String {
        switch self {
        case .wink: return "😉"
        case .thinking: return "🤔"
        case .sleeping: return "😴"
        case .excited: return "🤩"
        case .confused: return "😕"
        case .angry: return "😠"
        case .shy: return "🥺"
        case .skeptical: return "🤨"
        case .glee: return "😄"
        case .pleading: return "🥹"
        case .scared: return "😨"
        case .sad: return "😢"
        case .awe: return "😲"
        case .focused: return "🧐"
        case .suspicious: return "🤔"
        case .frustrated: return "😤"
        }
    }
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
    
    // Asymmetric eye blink (for wink)
    @State private var leftEyeBlink: CGFloat = 0
    @State private var rightEyeBlink: CGFloat = 0
    
    // Breathing animation
    @State private var breathingScale: CGFloat = 1.0
    
    // Squash and stretch
    @State private var squashStretch: CGFloat = 1.0
    
    // Idle eye drifts
    @State private var idleEyeOffsetX: CGFloat = 0
    @State private var idleEyeOffsetY: CGFloat = 0
    @State private var idleTimer: Timer?
    
    // Swirl/dizzy animation
    @State private var swirlAngle: CGFloat = 0
    
    // Track if user is interacting
    @State private var isUserInteracting: Bool = false
    
    // Currently playing preset (to prevent overlap)
    @State private var isPlayingPreset: Bool = false
    
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
            startBreathingAnimation()
            scheduleIdleEyeDrift()
        }
        .onDisappear {
            blinkTimer?.invalidate()
            idleTimer?.invalidate()
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
        VStack(spacing: 20) {
            // Top: Head and Look At joysticks
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Head")
                        .font(.custom("Inter-SemiBold", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    JoystickControlView(
                        positionX: $rigState.headX,
                        positionY: $rigState.headY,
                        onInteractionChanged: { interacting in
                            isUserInteracting = interacting
                        }
                    )
                }
                
                VStack(spacing: 8) {
                    Text("Look At")
                        .font(.custom("Inter-SemiBold", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    JoystickControlView(
                        positionX: $rigState.pupilX,
                        positionY: $rigState.pupilY,
                        onInteractionChanged: { interacting in
                            isUserInteracting = interacting
                        }
                    )
                }
            }
            
            // Center: Two faces side by side
            HStack(spacing: 16) {
                // Eyes only version (no mouth)
                VStack(spacing: 4) {
                    ZStack {
                        MorseBotEyesOnlyView(
                            rigState: rigState,
                            leftEyeBlink: leftEyeBlink,
                            rightEyeBlink: rightEyeBlink,
                            idleEyeOffsetX: idleEyeOffsetX,
                            idleEyeOffsetY: idleEyeOffsetY,
                            swirlAngle: swirlAngle
                        )
                        .frame(width: 140, height: 140)
                    }
                    .scaleEffect(x: squashStretch, y: 2.0 - squashStretch)
                    .scaleEffect(breathingScale)
                    .onTapGesture {
                        triggerTouchReaction()
                    }
                    
                    Text("Eyes Only")
                        .font(.custom("Inter-Medium", size: 11))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                // Full face with mouth
                VStack(spacing: 4) {
                    ZStack {
                        MorseBotRiggedFaceView(
                            rigState: rigState,
                            leftEyeBlink: leftEyeBlink,
                            rightEyeBlink: rightEyeBlink,
                            idleEyeOffsetX: idleEyeOffsetX,
                            idleEyeOffsetY: idleEyeOffsetY,
                            swirlAngle: swirlAngle
                        )
                        .frame(width: 140, height: 140)
                        
                        // Vintage TV overlay
                        VintageTVOverlay()
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .allowsHitTesting(false)
                    }
                    .scaleEffect(x: squashStretch, y: 2.0 - squashStretch)
                    .scaleEffect(breathingScale)
                    .onTapGesture {
                        triggerTouchReaction()
                    }
                    
                    Text("With Mouth")
                        .font(.custom("Inter-Medium", size: 11))
                        .foregroundColor(themeService.textSecondaryColor)
                }
            }
            
            // Expression preset buttons
            expressionPresetsView
            
            // Bottom: Sliders in scrollable area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // Basic controls
                    Text("Basic")
                        .font(.custom("Inter-Bold", size: 12))
                        .foregroundColor(themeService.textSecondaryColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LabeledSlider(
                        label: "Blink",
                        value: $rigState.blink,
                        range: 0...1
                    )
                    
                    LabeledSlider(
                        label: "Blink Frequency",
                        value: $blinkFrequency,
                        range: 0...1
                    )
                    
                    LabeledSlider(
                        label: "Eyebrows",
                        value: $rigState.eyebrows,
                        range: -1...1
                    )
                    
                    LabeledSlider(
                        label: "Mouth",
                        value: $rigState.mouth,
                        range: -1...1
                    )
                    
                    // Advanced eye controls
                    Text("Eye Size")
                        .font(.custom("Inter-Bold", size: 12))
                        .foregroundColor(themeService.textSecondaryColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    
                    LabeledSlider(
                        label: "Eye Height",
                        value: $rigState.eyeHeight,
                        range: 0.3...1.5
                    )
                    
                    LabeledSlider(
                        label: "Left Eye Scale",
                        value: $rigState.leftEyeScale,
                        range: 0.5...1.5
                    )
                    
                    LabeledSlider(
                        label: "Right Eye Scale",
                        value: $rigState.rightEyeScale,
                        range: 0.5...1.5
                    )
                }
                .padding(.horizontal, 40)
            }
            .frame(maxHeight: 250)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Expression Presets View
    
    private var expressionPresetsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ExpressionPreset.allCases, id: \.self) { preset in
                    Button(action: {
                        triggerPreset(preset)
                    }) {
                        Text(preset.icon)
                            .font(.system(size: 28))
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    .disabled(isPlayingPreset)
                    .opacity(isPlayingPreset ? 0.5 : 1.0)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Breathing Animation
    
    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            breathingScale = 1.015 // Very subtle 1.5% pulse
        }
    }
    
    // MARK: - Idle Eye Drift
    
    private func scheduleIdleEyeDrift() {
        let interval = Double.random(in: 3...8)
        idleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            // Only drift if user isn't interacting
            guard !isUserInteracting && !isPlayingPreset else {
                scheduleIdleEyeDrift()
                return
            }
            
            withAnimation(.easeInOut(duration: 0.8)) {
                idleEyeOffsetX = CGFloat.random(in: -0.15...0.15)
                idleEyeOffsetY = CGFloat.random(in: -0.1...0.1)
            }
            
            // Return to center after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    idleEyeOffsetX = 0
                    idleEyeOffsetY = 0
                }
                scheduleIdleEyeDrift()
            }
        }
    }
    
    // MARK: - Blink Timer
    
    private func startBlinkTimer() {
        scheduleBlink()
    }
    
    private func scheduleBlink() {
        guard blinkFrequency > 0.01 else {
            return
        }
        
        let minInterval = 1.0 + (1.0 - blinkFrequency) * 5.0
        let maxInterval = minInterval + 2.0
        let interval = Double.random(in: minInterval...maxInterval)
        
        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            performBlink()
        }
    }
    
    private func performBlink() {
        // Only auto-blink if manual slider is at 0 and not playing preset
        guard rigState.blink < 0.1 && !isPlayingPreset else {
            scheduleBlink()
            return
        }
        
        // 20% chance of double-blink
        let isDoubleBlink = Double.random(in: 0...1) < 0.2
        
        performSingleBlink {
            if isDoubleBlink {
                // Short pause then second blink
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    performSingleBlink {
                        scheduleBlink()
                    }
                }
            } else {
                scheduleBlink()
            }
        }
    }
    
    private func performSingleBlink(completion: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.08)) {
            rigState.blink = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.08)) {
                rigState.blink = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion()
            }
        }
    }
    
    // MARK: - Touch Reactions
    
    private func triggerTouchReaction() {
        guard !isPlayingPreset else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Trigger dizzy swirl reaction
        dizzyReaction()
    }
    
    private func dizzyReaction() {
        isPlayingPreset = true
        
        // Spin the entire face like a loading spinner
        // Fast spin for 2 full rotations, then settle back
        withAnimation(.easeIn(duration: 0.15)) {
            swirlAngle = .pi / 4 // Start with a quick quarter turn
        }
        
        // Continue spinning
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.25)) {
                swirlAngle = .pi // Half rotation
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.25)) {
                swirlAngle = .pi * 1.5 // Three quarters
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeInOut(duration: 0.25)) {
                swirlAngle = .pi * 2 // Full rotation
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.3)) {
                swirlAngle = .pi * 2.5 // One and a quarter
            }
        }
        
        // Slow down and settle back to 0 (or nearest full rotation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                swirlAngle = 0 // Settle back to normal
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isPlayingPreset = false
            }
        }
    }
    
    private func surprisedReaction() {
        isPlayingPreset = true
        
        // Anticipation: quick squash
        withAnimation(.easeIn(duration: 0.08)) {
            squashStretch = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                rigState.eyebrows = 1.0
                rigState.mouth = 0.3
                squashStretch = 1.12
            }
            
            // Settle back
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    rigState.eyebrows = 0
                    rigState.mouth = 0
                    squashStretch = 1.0
                }
                isPlayingPreset = false
            }
        }
    }
    
    private func annoyedReaction() {
        isPlayingPreset = true
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            rigState.eyebrows = -0.8
            rigState.mouth = -0.4
            squashStretch = 0.97
        }
        
        // Settle back
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.eyebrows = 0
                rigState.mouth = 0
                squashStretch = 1.0
            }
            isPlayingPreset = false
        }
    }
    
    private func happyReaction() {
        isPlayingPreset = true
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            rigState.eyebrows = 0.5
            rigState.mouth = 1.0
            squashStretch = 1.08
        }
        
        // Settle back
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.eyebrows = 0
                rigState.mouth = 0
                squashStretch = 1.0
            }
            isPlayingPreset = false
        }
    }
    
    private func curiousReaction() {
        isPlayingPreset = true
        
        // Look to the side
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            rigState.headX = 0.5
            rigState.headY = -0.3
            rigState.eyebrows = 0.3
        }
        
        // Settle back
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.headX = 0
                rigState.headY = 0
                rigState.eyebrows = 0
            }
            isPlayingPreset = false
        }
    }
    
    // MARK: - Expression Presets
    
    private func triggerPreset(_ preset: ExpressionPreset) {
        guard !isPlayingPreset else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        switch preset {
        case .wink:
            triggerWink()
        case .thinking:
            triggerThinking()
        case .sleeping:
            triggerSleeping()
        case .excited:
            triggerExcited()
        case .confused:
            triggerConfused()
        case .angry:
            triggerAngry()
        case .shy:
            triggerShy()
        case .skeptical:
            triggerSkeptical()
        case .glee:
            triggerGlee()
        case .pleading:
            triggerPleading()
        case .scared:
            triggerScared()
        case .sad:
            triggerSad()
        case .awe:
            triggerAwe()
        case .focused:
            triggerFocused()
        case .suspicious:
            triggerSuspicious()
        case .frustrated:
            triggerFrustrated()
        }
    }
    
    private func triggerWink() {
        isPlayingPreset = true
        
        // Only close right eye (the orange one)
        withAnimation(.easeInOut(duration: 0.1)) {
            rightEyeBlink = 1.0
            rigState.mouth = 0.5 // Slight smirk
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.1)) {
                rightEyeBlink = 0
                rigState.mouth = 0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerThinking() {
        isPlayingPreset = true
        
        // Look up and to the side
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            rigState.headX = 0.4
            rigState.headY = -0.5
            rigState.eyebrows = 0.2
            rigState.mouth = -0.2
        }
        
        // Hold for a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.headX = 0
                rigState.headY = 0
                rigState.eyebrows = 0
                rigState.mouth = 0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerSleeping() {
        isPlayingPreset = true
        
        // Close eyes, droop head, "O" mouth for breathing
        withAnimation(.easeInOut(duration: 0.5)) {
            rigState.blink = 1.0
            rigState.eyebrows = -0.3
            rigState.mouthIsCircle = true // Circle "O" mouth
            rigState.headY = 0.2
        }
        
        // Breathing cycle - slow rise and fall
        var breathCount = 0
        let totalBreaths = 3
        
        func doBreathCycle() {
            // Inhale - rise up slightly
            withAnimation(.easeInOut(duration: 1.2)) {
                rigState.headY = 0.05
                squashStretch = 1.04
            }
            
            // Exhale - sink down
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeInOut(duration: 1.4)) {
                    rigState.headY = 0.25
                    squashStretch = 0.97
                }
                
                breathCount += 1
                
                if breathCount < totalBreaths {
                    // Continue breathing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        doBreathCycle()
                    }
                } else {
                    // Wake up
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            rigState.blink = 0
                            rigState.eyebrows = 0
                            rigState.mouth = 0
                            rigState.mouthIsCircle = false
                            rigState.headY = 0
                            squashStretch = 1.0
                        }
                        isPlayingPreset = false
                    }
                }
            }
        }
        
        // Start breathing after initial settling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            doBreathCycle()
        }
    }
    
    private func triggerExcited() {
        isPlayingPreset = true
        
        // Anticipation: slight crouch
        withAnimation(.easeIn(duration: 0.1)) {
            squashStretch = 0.92
            rigState.eyebrows = -0.2
        }
        
        // Then spring up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                squashStretch = 1.2
                rigState.eyebrows = 1.0
                rigState.mouth = 1.0
            }
        }
        
        // Bounce back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                squashStretch = 0.95
            }
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                squashStretch = 1.0
                rigState.eyebrows = 0
                rigState.mouth = 0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerConfused() {
        isPlayingPreset = true
        
        // Tilt head and raise one eyebrow (asymmetric via head tilt)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            rigState.headX = -0.3
            rigState.eyebrows = 0.4
            rigState.mouth = -0.3
        }
        
        // Look other way
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                rigState.headX = 0.3
            }
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.headX = 0
                rigState.eyebrows = 0
                rigState.mouth = 0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerAngry() {
        isPlayingPreset = true
        
        // Angry: squinted eyes, furrowed brows, frown
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            rigState.eyebrows = -1.0
            rigState.eyelidTop = 0.4 // Half-closed angry eyes
            rigState.eyeHeight = 0.6 // Squint
            rigState.mouth = -0.6
            rigState.headY = 0.1
        }
        
        // Shake head slightly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                rigState.headX = -0.2
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                rigState.headX = 0.2
            }
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.eyebrows = 0
                rigState.eyelidTop = 0
                rigState.eyeHeight = 1.0
                rigState.mouth = 0
                rigState.headX = 0
                rigState.headY = 0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerShy() {
        isPlayingPreset = true
        
        // Shy: look away, half-close eyes, slight smile
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            rigState.headX = -0.5
            rigState.headY = 0.3
            rigState.eyelidTop = 0.3
            rigState.eyebrows = 0.2
            rigState.mouth = 0.3
            rigState.pupilX = 0.8 // Look away
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.headX = 0
                rigState.headY = 0
                rigState.eyelidTop = 0
                rigState.eyebrows = 0
                rigState.mouth = 0
                rigState.pupilX = 0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerSkeptical() {
        isPlayingPreset = true
        
        // Skeptical: one raised eyebrow effect via eyelid and head tilt
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            rigState.headX = 0.15
            rigState.eyebrows = 0.5
            rigState.eyelidTop = 0.25 // Slightly lowered
            rigState.mouth = -0.2
            rigState.pupilX = -0.5 // Side-eye
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.headX = 0
                rigState.eyebrows = 0
                rigState.eyelidTop = 0
                rigState.mouth = 0
                rigState.pupilX = 0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerGlee() {
        isPlayingPreset = true
        
        // Glee: super happy, wide eyes, big smile
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            rigState.eyebrows = 0.8
            rigState.eyeHeight = 1.4 // Wide eyes
            rigState.mouth = 1.0 // Big smile
            squashStretch = 1.1
        }
        
        // Bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                rigState.headY = -0.2
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                rigState.headY = 0.1
            }
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.eyebrows = 0
                rigState.eyeHeight = 1.0
                rigState.mouth = 0
                rigState.headY = 0
                squashStretch = 1.0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerPleading() {
        isPlayingPreset = true
        
        // Pleading: puppy dog eyes - big, wide, looking up
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            rigState.eyebrows = 0.7
            rigState.eyeHeight = 1.3 // Wide eyes
            rigState.pupilY = -0.7 // Looking up
            rigState.headY = 0.2 // Head tilted down
            rigState.mouth = -0.2 // Slight pout
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.eyebrows = 0
                rigState.eyeHeight = 1.0
                rigState.pupilY = 0
                rigState.headY = 0
                rigState.mouth = 0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerScared() {
        isPlayingPreset = true
        
        // Scared: wide eyes, trembling, looking around nervously
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            rigState.eyeHeight = 1.5 // Very wide eyes
            rigState.eyebrows = 0.8
            rigState.mouth = -0.4
            rigState.pupilY = -0.3
        }
        
        // Trembling effect - rapid small shakes
        var shakeCount = 0
        func doShake() {
            guard shakeCount < 8 else {
                // Settle after shaking
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        rigState.eyeHeight = 1.0
                        rigState.eyebrows = 0
                        rigState.mouth = 0
                        rigState.headX = 0
                        rigState.pupilY = 0
                    }
                    isPlayingPreset = false
                }
                return
            }
            
            let direction: CGFloat = shakeCount % 2 == 0 ? 0.08 : -0.08
            withAnimation(.linear(duration: 0.05)) {
                rigState.headX = direction
            }
            shakeCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                doShake()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            doShake()
        }
    }
    
    private func triggerSad() {
        isPlayingPreset = true
        
        // Sad: droopy eyes, downward gaze, frown
        withAnimation(.easeInOut(duration: 0.5)) {
            rigState.eyebrows = -0.6
            rigState.eyelidTop = 0.3 // Heavy eyelids
            rigState.eyeHeight = 0.8
            rigState.mouth = -0.7
            rigState.headY = 0.3 // Head down
            rigState.pupilY = 0.5 // Looking down
        }
        
        // Slow sigh effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.6)) {
                squashStretch = 0.95
            }
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                rigState.eyebrows = 0
                rigState.eyelidTop = 0
                rigState.eyeHeight = 1.0
                rigState.mouth = 0
                rigState.headY = 0
                rigState.pupilY = 0
                squashStretch = 1.0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerAwe() {
        isPlayingPreset = true
        
        // Awe: extremely wide eyes, mouth open, amazed
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            rigState.eyeHeight = 1.5 // Maximum wide
            rigState.eyebrows = 1.0 // Raised high
            rigState.mouthIsCircle = true // O mouth
            rigState.headY = -0.1 // Slight head up
        }
        
        // Slight expansion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                squashStretch = 1.08
            }
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.eyeHeight = 1.0
                rigState.eyebrows = 0
                rigState.mouthIsCircle = false
                rigState.headY = 0
                squashStretch = 1.0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerFocused() {
        isPlayingPreset = true
        
        // Focused: squinted eyes, intense concentration
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            rigState.eyeHeight = 0.5 // Squinted
            rigState.eyelidTop = 0.2
            rigState.eyebrows = -0.3 // Slight furrow
            rigState.mouth = 0 // Neutral mouth
            rigState.pupilX = 0 // Looking straight
        }
        
        // Slight lean forward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                squashStretch = 1.03
            }
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.eyeHeight = 1.0
                rigState.eyelidTop = 0
                rigState.eyebrows = 0
                squashStretch = 1.0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerSuspicious() {
        isPlayingPreset = true
        
        // Suspicious: asymmetric eyes, one bigger than other, side-eye
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            rigState.leftEyeScale = 0.7 // Smaller/squinted
            rigState.rightEyeScale = 1.1 // Normal/slightly bigger
            rigState.eyelidTop = 0.2
            rigState.eyebrows = 0.3
            rigState.pupilX = -0.6 // Side-eye
            rigState.mouth = -0.15
            rigState.headX = 0.2
        }
        
        // Slow look to other side
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                rigState.pupilX = 0.5
            }
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.leftEyeScale = 1.0
                rigState.rightEyeScale = 1.0
                rigState.eyelidTop = 0
                rigState.eyebrows = 0
                rigState.pupilX = 0
                rigState.mouth = 0
                rigState.headX = 0
            }
            isPlayingPreset = false
        }
    }
    
    private func triggerFrustrated() {
        isPlayingPreset = true
        
        // Frustrated: squinted, tight mouth, head shake
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            rigState.eyeHeight = 0.6
            rigState.eyebrows = -0.5
            rigState.eyelidTop = 0.3
            rigState.mouth = -0.4
        }
        
        // Frustrated head shake/twitch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.4)) {
                rigState.headX = -0.15
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.4)) {
                rigState.headX = 0.15
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.4)) {
                rigState.headX = -0.1
            }
        }
        
        // Exhale (squash)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                squashStretch = 0.94
            }
        }
        
        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                rigState.eyeHeight = 1.0
                rigState.eyebrows = 0
                rigState.eyelidTop = 0
                rigState.mouth = 0
                rigState.headX = 0
                squashStretch = 1.0
            }
            isPlayingPreset = false
        }
    }
    
    private func resetAdvancedEyeControls() {
        rigState.eyelidTop = 0
        rigState.pupilX = 0
        rigState.pupilY = 0
        rigState.eyeHeight = 1.0
        rigState.leftEyeScale = 1.0
        rigState.rightEyeScale = 1.0
    }
}

// MARK: - Joystick Control View

struct JoystickControlView: View {
    @Binding var positionX: CGFloat
    @Binding var positionY: CGFloat
    var onInteractionChanged: ((Bool) -> Void)?
    
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
                            if !isDragging {
                                isDragging = true
                                onInteractionChanged?(true)
                            }
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
                            onInteractionChanged?(false)
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
    var leftEyeBlink: CGFloat = 0
    var rightEyeBlink: CGFloat = 0
    var idleEyeOffsetX: CGFloat = 0
    var idleEyeOffsetY: CGFloat = 0
    var swirlAngle: CGFloat = 0 // Rotation angle in radians for entire face
    
    // Computed face configuration from rig state
    private var faceConfig: ComputedFaceConfig {
        computeFaceConfig(from: rigState)
    }
    
    var body: some View {
        ZStack {
            // Background - black rounded super-ellipse
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.black)
            
            // Face elements group (rotates together during swirl)
            // Using Mini Robot Face style - clean rectangular eyes like Cozmo
            Group {
                // Left eye - simple rounded rectangle (white)
                RoundedRectangle(cornerRadius: faceConfig.leftEyeCornerRadius)
                    .fill(Color(hex: "FCFCFC"))
                    .frame(
                        width: faceConfig.leftEyeWidth * rigState.leftEyeScale,
                        height: computeEyeHeight(base: faceConfig.leftEyeHeight * rigState.eyeHeight * rigState.leftEyeScale, blink: leftEyeBlink)
                    )
                    .rotationEffect(.degrees(faceConfig.leftEyeRotation))
                    .position(
                        x: faceConfig.leftEyeX + idleEyeOffsetX * 15 + rigState.pupilX * 8,
                        y: faceConfig.leftEyeY + idleEyeOffsetY * 10 + rigState.pupilY * 6
                    )
                
                // Right eye - simple rounded rectangle (orange)
                RoundedRectangle(cornerRadius: faceConfig.rightEyeCornerRadius)
                    .fill(Color(hex: "FF5500"))
                    .frame(
                        width: faceConfig.rightEyeWidth * rigState.rightEyeScale,
                        height: computeEyeHeight(base: faceConfig.rightEyeHeight * rigState.eyeHeight * rigState.rightEyeScale, blink: rightEyeBlink)
                    )
                    .rotationEffect(.degrees(faceConfig.rightEyeRotation))
                    .position(
                        x: faceConfig.rightEyeX + idleEyeOffsetX * 15 + rigState.pupilX * 8,
                        y: faceConfig.rightEyeY + idleEyeOffsetY * 10 + rigState.pupilY * 6
                    )
                
                // Mouth - either solid circle or curved line
                if rigState.mouthIsCircle {
                    // Solid circle mouth for sleeping
                    Circle()
                        .fill(Color(hex: "FCFCFC"))
                        .frame(width: 20, height: 20)
                        .position(x: faceConfig.mouthX, y: faceConfig.mouthY)
                } else {
                    // Normal curved line mouth
                    MorseBotMouthShape(
                        width: faceConfig.mouthWidth,
                        curve: faceConfig.mouthCurve
                    )
                    .stroke(Color(hex: "FCFCFC"), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: faceConfig.mouthWidth, height: 50)
                    .position(x: faceConfig.mouthX, y: faceConfig.mouthY)
                }
            }
            .rotationEffect(.radians(swirlAngle))
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.headX)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.headY)
        .animation(.spring(response: 0.15, dampingFraction: 0.9), value: rigState.blink)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.eyebrows)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.mouth)
        .animation(.easeInOut(duration: 0.1), value: leftEyeBlink)
        .animation(.easeInOut(duration: 0.1), value: rightEyeBlink)
        .animation(.easeInOut(duration: 0.6), value: idleEyeOffsetX)
        .animation(.easeInOut(duration: 0.6), value: idleEyeOffsetY)
        .animation(.easeInOut(duration: 0.2), value: swirlAngle)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.eyelidTop)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.eyeHeight)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: rigState.pupilX)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: rigState.pupilY)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: rigState.leftEyeScale)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: rigState.rightEyeScale)
    }
    
    private func computeEyeHeight(base: CGFloat, blink: CGFloat) -> CGFloat {
        let blinkScale = 1 - blink * 0.9
        return max(2, base * blinkScale)
    }
    
    // MARK: - Compute Face Config
    
    private func computeFaceConfig(from state: FaceRigState) -> ComputedFaceConfig {
        // 1. Get base pose from joystick interpolation
        let basePose = FacePoseConfig.interpolate(headX: state.headX, headY: state.headY)
        
        // 2. Base eye properties - Mini Robot style (more rectangular)
        let baseEyeWidth: CGFloat = 24
        let baseEyeHeight: CGFloat = 24
        let baseEyeCornerRadius: CGFloat = 4  // Small radius for rectangular look
        
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

// MARK: - Eyes Only View (No Mouth)

struct MorseBotEyesOnlyView: View {
    let rigState: FaceRigState
    var leftEyeBlink: CGFloat = 0
    var rightEyeBlink: CGFloat = 0
    var idleEyeOffsetX: CGFloat = 0
    var idleEyeOffsetY: CGFloat = 0
    var swirlAngle: CGFloat = 0
    
    private var faceConfig: ComputedFaceConfig {
        computeFaceConfig(from: rigState)
    }
    
    var body: some View {
        ZStack {
            // Background - black rounded rectangle
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black)
            
            // Eyes only (no mouth) - centered vertically
            Group {
                // Left eye
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "FCFCFC"))
                    .frame(
                        width: 24 * rigState.leftEyeScale,
                        height: computeEyeHeight(base: 24 * rigState.eyeHeight * rigState.leftEyeScale, blink: leftEyeBlink)
                    )
                    .rotationEffect(.degrees(rigState.eyebrows * -15))
                    .position(
                        x: 50 + idleEyeOffsetX * 10 + rigState.pupilX * 6,
                        y: 70 + idleEyeOffsetY * 8 + rigState.pupilY * 5 - rigState.eyebrows * 6
                    )
                
                // Right eye
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "FF5500"))
                    .frame(
                        width: 24 * rigState.rightEyeScale,
                        height: computeEyeHeight(base: 24 * rigState.eyeHeight * rigState.rightEyeScale, blink: rightEyeBlink)
                    )
                    .rotationEffect(.degrees(rigState.eyebrows * 15))
                    .position(
                        x: 90 + idleEyeOffsetX * 10 + rigState.pupilX * 6,
                        y: 70 + idleEyeOffsetY * 8 + rigState.pupilY * 5 - rigState.eyebrows * 6
                    )
            }
            .rotationEffect(.radians(swirlAngle))
        }
        .frame(width: 140, height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.headX)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.headY)
        .animation(.spring(response: 0.15, dampingFraction: 0.9), value: rigState.blink)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: rigState.eyebrows)
        .animation(.easeInOut(duration: 0.1), value: leftEyeBlink)
        .animation(.easeInOut(duration: 0.1), value: rightEyeBlink)
    }
    
    private func computeEyeHeight(base: CGFloat, blink: CGFloat) -> CGFloat {
        let blinkScale = 1 - blink * 0.9
        return max(2, base * blinkScale)
    }
    
    private func computeFaceConfig(from state: FaceRigState) -> ComputedFaceConfig {
        let basePose = FacePoseConfig.interpolate(headX: state.headX, headY: state.headY)
        return ComputedFaceConfig(
            leftEyeX: basePose.leftEyeX,
            leftEyeY: basePose.leftEyeY,
            leftEyeWidth: 24,
            leftEyeHeight: 24,
            leftEyeCornerRadius: 4,
            leftEyeRotation: 0,
            rightEyeX: basePose.rightEyeX,
            rightEyeY: basePose.rightEyeY,
            rightEyeWidth: 24,
            rightEyeHeight: 24,
            rightEyeCornerRadius: 4,
            rightEyeRotation: 0,
            mouthX: 0,
            mouthY: 0,
            mouthWidth: 0,
            mouthCurve: 0
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

// MARK: - Vintage TV Overlay

struct VintageTVOverlay: View {
    @State private var flickerOpacity: Double = 0.03
    
    var body: some View {
        ZStack {
            // Scanlines
            ScanlinesView()
                .opacity(0.15)
            
            // Vignette (dark edges)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 140
            )
            
            // CRT screen glow (subtle green/blue tint)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "00FF88").opacity(0.05),
                    Color.clear
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
            
            // Flicker effect
            Color.white
                .opacity(flickerOpacity)
                .onAppear {
                    startFlicker()
                }
            
            // Screen reflection (subtle highlight)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.08),
                    Color.clear,
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .center
            )
        }
    }
    
    private func startFlicker() {
        // Random flicker every so often
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if Double.random(in: 0...1) < 0.1 {
                // Occasional flicker
                flickerOpacity = Double.random(in: 0.02...0.08)
            } else {
                flickerOpacity = 0.02
            }
        }
    }
}

// MARK: - Scanlines View

struct ScanlinesView: View {
    var body: some View {
        Canvas { context, size in
            let lineSpacing: CGFloat = 3
            var x: CGFloat = 0
            
            while x < size.width {
                let rect = CGRect(x: x, y: 0, width: 1, height: size.height)
                context.fill(Path(rect), with: .color(.black))
                x += lineSpacing
            }
        }
    }
}

#Preview {
    MorseBotView(isPresented: .constant(true))
}
