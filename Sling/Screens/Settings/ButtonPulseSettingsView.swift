import SwiftUI

// MARK: - FAB Pulse Effect Enum (30 pure SwiftUI animations)

enum FABPulseEffect: String, CaseIterable, Identifiable {
    // Original 10
    case rippleRing
    case doubleRipple
    case glowBreathe
    case bounce
    case wiggle
    case scalePulse
    case orbitingDot
    case arrowPeek
    case ringFill
    case spotlightSweep
    
    // 20 new animations
    case tripleRipple
    case heartbeat
    case pendulum
    case jelly
    case spin
    case shadowOrbit
    case colorCycle
    case trailingDots
    case pulsingBorder
    case tilt3D
    case floatDrift
    case dashRing
    case springPop
    case twinkle
    case breatheFade
    case shake
    case magnify
    case doubleBounce
    case wavyRing
    case beacon
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .rippleRing: return "Ripple Ring"
        case .doubleRipple: return "Double Ripple"
        case .glowBreathe: return "Glow Breathe"
        case .bounce: return "Bounce"
        case .wiggle: return "Wiggle"
        case .scalePulse: return "Scale Pulse"
        case .orbitingDot: return "Orbiting Dot"
        case .arrowPeek: return "Arrow Peek"
        case .ringFill: return "Ring Fill"
        case .spotlightSweep: return "Spotlight Sweep"
        case .tripleRipple: return "Triple Ripple"
        case .heartbeat: return "Heartbeat"
        case .pendulum: return "Pendulum"
        case .jelly: return "Jelly"
        case .spin: return "Spin"
        case .shadowOrbit: return "Shadow Orbit"
        case .colorCycle: return "Color Cycle"
        case .trailingDots: return "Trailing Dots"
        case .pulsingBorder: return "Pulsing Border"
        case .tilt3D: return "3D Tilt"
        case .floatDrift: return "Float Drift"
        case .dashRing: return "Dash Ring"
        case .springPop: return "Spring Pop"
        case .twinkle: return "Twinkle"
        case .breatheFade: return "Breathe Fade"
        case .shake: return "Shake"
        case .magnify: return "Magnify"
        case .doubleBounce: return "Double Bounce"
        case .wavyRing: return "Wavy Ring"
        case .beacon: return "Beacon"
        }
    }
    
    var description: String {
        switch self {
        case .rippleRing: return "Expanding ring fades outward"
        case .doubleRipple: return "Two staggered sonar rings"
        case .glowBreathe: return "Shadow breathes in and out"
        case .bounce: return "Gentle up-and-down bounce"
        case .wiggle: return "Bell-shake rotation wiggle"
        case .scalePulse: return "Heartbeat-like scale throb"
        case .orbitingDot: return "Dot orbits the button"
        case .arrowPeek: return "Arrow nudges upward"
        case .ringFill: return "Progress ring loops around"
        case .spotlightSweep: return "Highlight sweeps across"
        case .tripleRipple: return "Three staggered sonar rings"
        case .heartbeat: return "Quick double-beat then pause"
        case .pendulum: return "Swings side to side"
        case .jelly: return "Squish and stretch squash"
        case .spin: return "Slow continuous rotation"
        case .shadowOrbit: return "Shadow circles underneath"
        case .colorCycle: return "Hue shifts through the rainbow"
        case .trailingDots: return "Dots orbit with a fading trail"
        case .pulsingBorder: return "Border ring pulses in thickness"
        case .tilt3D: return "Tilts forward and back in 3D"
        case .floatDrift: return "Floats gently with subtle tilt"
        case .dashRing: return "Dashed ring rotates around"
        case .springPop: return "Pops up with overshoot spring"
        case .twinkle: return "Sparkles appear around the edge"
        case .breatheFade: return "Fades in and out gently"
        case .shake: return "Quick horizontal shake burst"
        case .magnify: return "Grows large then snaps back"
        case .doubleBounce: return "Two quick bounces then rest"
        case .wavyRing: return "Wobbly animated ring outline"
        case .beacon: return "Sharp on/off flash like a lighthouse"
        }
    }
}

// MARK: - Button Pulse Settings View

struct ButtonPulseSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @AppStorage("fabPulseEffect") private var selectedEffect = "springPop"
    @AppStorage("hasUsedTransferButton") private var hasUsedTransferButton = false
    
    var body: some View {
        ZStack {
            themeService.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Button Pulse")
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // Sticky preview area
                VStack(spacing: 12) {
                    Text("Preview")
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    FABPreviewView(
                        effect: FABPulseEffect(rawValue: selectedEffect) ?? .rippleRing
                    )
                    .id(selectedEffect)
                    .frame(height: 120)
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
                .background(themeService.backgroundColor)
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 0) {
                            ForEach(Array(FABPulseEffect.allCases.enumerated()), id: \.element.id) { index, effect in
                                let isFirst = index == 0
                                let isLast = index == FABPulseEffect.allCases.count - 1
                                let position: RowPosition = isFirst && isLast ? .standalone : isFirst ? .top : isLast ? .bottom : .middle
                                
                                EffectRow(
                                    effect: effect,
                                    isSelected: selectedEffect == effect.rawValue,
                                    position: position,
                                    onTap: {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedEffect = effect.rawValue
                                        }
                                    }
                                )
                            }
                        }
                        
                        // Reset pulse button
                        Button(action: {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            hasUsedTransferButton = false
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Reset pulse")
                                    .font(.custom("Inter-Bold", size: 16))
                            }
                            .foregroundColor(Color(hex: "FF5113"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeService.cardBackgroundColor)
                            .cornerRadius(16)
                        }
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(hasUsedTransferButton ? Color(hex: "7B7B7B") : Color(hex: "57CE43"))
                                .frame(width: 8, height: 8)
                            
                            Text(hasUsedTransferButton ? "Pulse dismissed (tap reset to re-enable)" : "Pulse is active on FAB")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Effect Row

struct EffectRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let effect: FABPulseEffect
    let isSelected: Bool
    let position: RowPosition
    let onTap: () -> Void
    @State private var isPressed = false
    
    private var corners: UIRectCorner {
        switch position {
        case .top: return [.topLeft, .topRight]
        case .middle: return []
        case .bottom: return [.bottomLeft, .bottomRight]
        case .standalone: return .allCorners
        }
    }
    
    private var cornerRadius: CGFloat {
        switch position {
        case .top, .bottom, .standalone: return 16
        case .middle: return 0
        }
    }
    
    private var showDivider: Bool {
        position == .top || position == .middle
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "FFF0E8"))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "FF5113"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(effect.displayName)
                        .font(.custom("Inter-Bold", size: 16))
                        .tracking(-0.32)
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text(effect.description)
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "FF5113"))
                } else {
                    Circle()
                        .stroke(Color(hex: "D9D9D9"), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            if showDivider {
                Rectangle()
                    .fill(themeService.textPrimaryColor.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.leading, 64)
            }
        }
        .background(isPressed ? (themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F7F7F7")) : themeService.cardBackgroundColor)
        .clipShape(RoundedCornerShape(corners: corners, radius: cornerRadius))
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - FAB Preview View

struct FABPreviewView: View {
    let effect: FABPulseEffect
    
    private let fabSize: CGFloat = 56
    private let fabColor = Color(hex: "FF5113")
    
    // Animation states
    @State private var a = false   // generic toggle
    @State private var b: CGFloat = 0  // generic progress/angle
    @State private var c: CGFloat = 0  // secondary
    @State private var d: CGFloat = 0  // tertiary
    @State private var phase: Int = 0  // for multi-phase animations
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "F7F7F7"))
            
            fabWithEffect
        }
    }
    
    @ViewBuilder
    private var fabWithEffect: some View {
        switch effect {
            
        // ═══════ 1. Ripple Ring ═══════
        case .rippleRing:
            ZStack {
                Circle()
                    .stroke(fabColor.opacity(a ? 0 : 0.5), lineWidth: a ? 2 : 4)
                    .frame(width: fabSize, height: fabSize)
                    .scaleEffect(a ? 1.8 : 1.0)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: a)
                fab
            }.onAppear { a = true }
            
        // ═══════ 2. Double Ripple ═══════
        case .doubleRipple:
            ZStack {
                Circle()
                    .stroke(fabColor.opacity(a ? 0 : 0.5), lineWidth: a ? 2 : 4)
                    .frame(width: fabSize, height: fabSize)
                    .scaleEffect(a ? 1.8 : 1.0)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: a)
                Circle()
                    .stroke(fabColor.opacity(a ? 0 : 0.4), lineWidth: a ? 2 : 3)
                    .frame(width: fabSize, height: fabSize)
                    .scaleEffect(a ? 1.8 : 1.0)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.5), value: a)
                fab
            }.onAppear { a = true }
            
        // ═══════ 3. Glow Breathe ═══════
        case .glowBreathe:
            fab
                .shadow(color: fabColor.opacity(a ? 0.6 : 0.1), radius: a ? 20 : 4, x: 0, y: 0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: a)
                .onAppear { a = true }
            
        // ═══════ 4. Bounce ═══════
        case .bounce:
            fab
                .offset(y: a ? -8 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.4).repeatForever(autoreverses: true), value: a)
                .onAppear { a = true }
            
        // ═══════ 5. Wiggle ═══════
        case .wiggle:
            fab
                .rotationEffect(.degrees(a ? 8 : -8))
                .animation(.spring(response: 0.15, dampingFraction: 0.3).repeatForever(autoreverses: true), value: a)
                .onAppear { a = true }
            
        // ═══════ 6. Scale Pulse ═══════
        case .scalePulse:
            fab
                .scaleEffect(a ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: a)
                .onAppear { a = true }
            
        // ═══════ 7. Orbiting Dot ═══════
        case .orbitingDot:
            ZStack {
                fab
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(x: fabSize / 2 + 6)
                    .rotationEffect(.degrees(b))
            }.onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) { b = 360 }
            }
            
        // ═══════ 8. Arrow Peek ═══════
        case .arrowPeek:
            ZStack {
                fab
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: a ? -6 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.4).repeatForever(autoreverses: true), value: a)
            }.onAppear { a = true }
            
        // ═══════ 9. Ring Fill ═══════
        case .ringFill:
            ZStack {
                Circle().stroke(fabColor.opacity(0.2), lineWidth: 3).frame(width: fabSize + 12, height: fabSize + 12)
                Circle().trim(from: 0, to: b)
                    .stroke(fabColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: fabSize + 12, height: fabSize + 12)
                    .rotationEffect(.degrees(-90))
                fab
            }.onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) { b = 1.0 }
            }
            
        // ═══════ 10. Spotlight Sweep ═══════
        case .spotlightSweep:
            fab
                .overlay(
                    LinearGradient(colors: [.clear, .white.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 16)
                        .offset(x: b)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: b)
                )
                .clipShape(Circle())
                .onAppear { b = 40 }
            
        // ═══════ 11. Triple Ripple ═══════
        case .tripleRipple:
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(fabColor.opacity(a ? 0 : 0.45), lineWidth: a ? 1.5 : 3.5)
                        .frame(width: fabSize, height: fabSize)
                        .scaleEffect(a ? 1.9 : 1.0)
                        .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(Double(i) * 0.4), value: a)
                }
                fab
            }.onAppear { a = true }
            
        // ═══════ 12. Heartbeat ═══════
        case .heartbeat:
            fab
                .scaleEffect(heartbeatScale)
                .onAppear { startHeartbeat() }
            
        // ═══════ 13. Pendulum ═══════
        case .pendulum:
            fab
                .offset(x: a ? 10 : -10)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: a)
                .onAppear { a = true }
            
        // ═══════ 14. Jelly ═══════
        case .jelly:
            fab
                .scaleEffect(x: a ? 1.15 : 0.9, y: a ? 0.9 : 1.15)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: a)
                .onAppear { a = true }
            
        // ═══════ 15. Spin ═══════
        case .spin:
            fab
                .rotationEffect(.degrees(b))
                .onAppear {
                    withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { b = 360 }
                }
            
        // ═══════ 16. Shadow Orbit ═══════
        case .shadowOrbit:
            fab
                .shadow(color: fabColor.opacity(0.5), radius: 12,
                        x: CGFloat(cos(Double(b) / 180.0 * Double.pi)) * 10,
                        y: CGFloat(sin(Double(b) / 180.0 * Double.pi)) * 10)
                .onAppear {
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) { b = 360 }
                }
            
        // ═══════ 17. Color Cycle ═══════
        case .colorCycle:
            ZStack {
                Circle()
                    .fill(fabColor)
                    .frame(width: fabSize, height: fabSize)
                    .hueRotation(.degrees(b))
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .onAppear {
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { b = 360 }
            }
            
        // ═══════ 18. Trailing Dots ═══════
        case .trailingDots:
            ZStack {
                fab
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(1.0 - Double(i) * 0.25))
                        .frame(width: 6 - CGFloat(i), height: 6 - CGFloat(i))
                        .offset(x: fabSize / 2 + 6)
                        .rotationEffect(.degrees(b - Double(i) * 20))
                }
            }.onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) { b = 360 }
            }
            
        // ═══════ 19. Pulsing Border ═══════
        case .pulsingBorder:
            ZStack {
                Circle()
                    .stroke(fabColor, lineWidth: a ? 5 : 1.5)
                    .frame(width: fabSize + 8, height: fabSize + 8)
                    .opacity(a ? 0.3 : 0.8)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: a)
                fab
            }.onAppear { a = true }
            
        // ═══════ 20. 3D Tilt ═══════
        case .tilt3D:
            fab
                .rotation3DEffect(.degrees(a ? 15 : -15), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: a)
                .onAppear { a = true }
            
        // ═══════ 21. Float Drift ═══════
        case .floatDrift:
            fab
                .offset(y: a ? -6 : 4)
                .rotationEffect(.degrees(a ? 3 : -3))
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: a)
                .onAppear { a = true }
            
        // ═══════ 22. Dash Ring ═══════
        case .dashRing:
            ZStack {
                Circle()
                    .stroke(fabColor, style: StrokeStyle(lineWidth: 2.5, dash: [6, 6]))
                    .frame(width: fabSize + 14, height: fabSize + 14)
                    .rotationEffect(.degrees(b))
                fab
            }.onAppear {
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { b = 360 }
            }
            
        // ═══════ 23. Spring Pop ═══════
        case .springPop:
            fab
                .scaleEffect(a ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: a)
                .onAppear { startSpringPop() }
            
        // ═══════ 24. Twinkle ═══════
        case .twinkle:
            ZStack {
                fab
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 6...10)))
                        .foregroundColor(fabColor)
                        .offset(
                            x: CGFloat(cos(Double(i) * 1.2566)) * (fabSize / 2 + 10),
                            y: CGFloat(sin(Double(i) * 1.2566)) * (fabSize / 2 + 10)
                        )
                        .opacity(a ? 1.0 : 0.0)
                        .scaleEffect(a ? 1.0 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                            value: a
                        )
                }
            }.onAppear { a = true }
            
        // ═══════ 25. Breathe Fade ═══════
        case .breatheFade:
            fab
                .opacity(a ? 1.0 : 0.4)
                .scaleEffect(a ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: a)
                .onAppear { a = true }
            
        // ═══════ 26. Shake ═══════
        case .shake:
            fab
                .offset(x: c)
                .onAppear { startShake() }
            
        // ═══════ 27. Magnify ═══════
        case .magnify:
            fab
                .scaleEffect(a ? 1.3 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: a)
                .onAppear { startMagnify() }
            
        // ═══════ 28. Double Bounce ═══════
        case .doubleBounce:
            fab
                .offset(y: c)
                .onAppear { startDoubleBounce() }
            
        // ═══════ 29. Wavy Ring ═══════
        case .wavyRing:
            ZStack {
                WavyCircle(phase: b, amplitude: 3)
                    .stroke(fabColor.opacity(0.6), lineWidth: 2.5)
                    .frame(width: fabSize + 14, height: fabSize + 14)
                fab
            }.onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) { b = CGFloat.pi * 2 }
            }
            
        // ═══════ 30. Beacon ═══════
        case .beacon:
            fab
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(a ? 0.35 : 0))
                        .frame(width: fabSize, height: fabSize)
                        .animation(.easeOut(duration: 0.15), value: a)
                )
                .clipShape(Circle())
                .onAppear { startBeacon() }
        }
    }
    
    // MARK: - Shared FAB circle
    
    private var fab: some View {
        ZStack {
            Circle()
                .fill(fabColor)
                .frame(width: fabSize, height: fabSize)
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Timer-based animations
    
    private var heartbeatScale: CGFloat {
        switch phase {
        case 1: return 1.18
        case 2: return 1.0
        case 3: return 1.12
        default: return 1.0
        }
    }
    
    private func startHeartbeat() {
        func beat() {
            withAnimation(.easeOut(duration: 0.12)) { phase = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeIn(duration: 0.1)) { phase = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeOut(duration: 0.1)) { phase = 3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                withAnimation(.easeIn(duration: 0.15)) { phase = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                beat()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { beat() }
    }
    
    private func startSpringPop() {
        func pop() {
            withAnimation(.easeOut(duration: 0.5)) { a = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.6)) { a = false }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { pop() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { pop() }
    }
    
    private func startShake() {
        func shake() {
            withAnimation(.spring(response: 0.06, dampingFraction: 0.2)) { c = 6 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.spring(response: 0.06, dampingFraction: 0.2)) { c = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.06, dampingFraction: 0.2)) { c = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.06, dampingFraction: 0.2)) { c = -3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) { c = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { shake() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake() }
    }
    
    private func startMagnify() {
        func mag() {
            withAnimation { a = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { a = false }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { mag() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { mag() }
    }
    
    private func startDoubleBounce() {
        func bounce() {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { c = -10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) { c = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { c = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { c = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { bounce() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { bounce() }
    }
    
    private func startBeacon() {
        func flash() {
            a = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { a = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { a = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { a = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { flash() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { flash() }
    }
}

// MARK: - Wavy Circle Shape

struct WavyCircle: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var waveCount: Int = 8
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2
        var path = Path()
        let steps = 120
        
        for i in 0...steps {
            let angle = Double(i) / Double(steps) * Double.pi * 2
            let waveOffset = CGFloat(sin(angle * Double(waveCount) + Double(phase))) * amplitude
            let radius = baseRadius + waveOffset
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    ButtonPulseSettingsView(isPresented: .constant(true))
}
