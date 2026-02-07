import SwiftUI

/// Menu option for the zoom transition
enum ZoomMenuOption: String, CaseIterable, Identifiable {
    case send = "Send"
    case request = "Request"
    case transfer = "Transfer"
    case receiveSalary = "Receive your salary"
    
    var id: String { rawValue }
    
    var subtitle: String {
        switch self {
        case .send: return "Pay anyone on Sling in seconds"
        case .request: return "Ask someone to pay you back"
        case .transfer: return "Move money between accounts"
        case .receiveSalary: return "Get paid into Sling"
        }
    }
    
    var iconName: String {
        switch self {
        case .send: return "TransferSend"
        case .request: return "TransferRequest"
        case .transfer: return "TransferTransfer"
        case .receiveSalary: return "TransferSalary"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .send: return Color(hex: "5FB0DB")
        case .request: return Color(hex: "5DB468")
        case .transfer: return Color(hex: "DB61C0")
        case .receiveSalary: return Color(hex: "080808")
        }
    }
}

/// A simple morph transition view that animates between a circle and a rectangle
struct ZoomTransitionView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @AppStorage("selectedCardStyle") private var selectedCardStyle = "orange"
    @AppStorage("hasUsedTransferButton") private var hasUsedTransferButton = false
    @AppStorage("fabPulseEffect") private var fabPulseEffectRaw = "springPop"
    @State private var isExpanded = false
    @State private var isPressed = false
    
    // Generic animation states (shared across effects)
    @State private var anim = false      // generic toggle
    @State private var progress: CGFloat = 0   // generic angle/progress
    @State private var secondary: CGFloat = 0  // secondary value
    @State private var phase: Int = 0          // multi-phase
    
    private var currentEffect: FABPulseEffect {
        FABPulseEffect(rawValue: fabPulseEffectRaw) ?? .rippleRing
    }
    
    private var shouldPulse: Bool {
        !isExpanded && !hasUsedTransferButton
    }
    
    // Action callback when a menu option is selected
    var onAction: ((ZoomMenuOption) -> Void)?
    
    // Map card style to FAB color
    private var fabColor: Color {
        switch selectedCardStyle {
        case "orange": return Color(hex: "FF5113")
        case "blue": return Color(hex: "0887DC")
        case "green": return Color(hex: "34C759")
        case "purple": return Color(hex: "AF52DE")
        case "pink": return Color(hex: "FF2D55")
        case "teal": return Color(hex: "5AC8FA")
        case "indigo": return Color(hex: "5856D6")
        case "black": return Color(hex: "1C1C1E")
        default: return Color(hex: "FF5113") // Default orange
        }
    }
    
    // Animated properties (4 menu options: send, request, transfer, receive salary)
    private var height: CGFloat { isExpanded ? 320 : DesignSystem.Button.height }
    private var cornerRadius: CGFloat { isExpanded ? DesignSystem.CornerRadius.extraLarge : DesignSystem.CornerRadius.pill }
    
    // Scale for pressed state using DesignSystem constant
    private var buttonScale: CGFloat { (!isExpanded && isPressed) ? DesignSystem.Animation.pressedScale : 1.0 }
    
    private func width(in screenWidth: CGFloat) -> CGFloat {
        let expandedWidth = screenWidth - DesignSystem.Spacing.xl // 16px margin on each side
        return isExpanded ? max(expandedWidth, DesignSystem.Button.height) : DesignSystem.Button.height
    }
    
    private func xOffset(in screenWidth: CGFloat) -> CGFloat {
        // When collapsed: position at right side with 24px margin
        // When expanded: center the card (24px from each edge)
        let cardWidth = width(in: screenWidth)
        let collapsedX = screenWidth - cardWidth - DesignSystem.Spacing.lg // 24px from right
        let expandedX = DesignSystem.Spacing.lg // 24px from left
        return isExpanded ? expandedX : collapsedX
    }
    
    var body: some View {
        ZStack {
            // Dimmed background overlay - tap to close (full screen)
            if isExpanded {
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                            isExpanded = false
                        }
                    }
            }
            
            // Position card at bottom using VStack layout (matches BottomNavView)
            VStack {
                Spacer()
                
                GeometryReader { geometry in
                    // The morphing card/circle
                    ZStack(alignment: .bottomLeading) {
                        // Menu content - only visible when expanded
                        VStack(spacing: 0) {
                            ForEach(ZoomMenuOption.allCases) { option in
                                ZoomMenuRow(option: option) {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                                        isExpanded = false
                                    }
                                    // Trigger action after a short delay for animation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.springResponse) {
                                        onAction?(option)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.CornerRadius.small)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .allowsHitTesting(isExpanded)
                        .opacity(isExpanded ? 1 : 0)
                        
                        // Transfer icon - only visible when collapsed
                        if !isExpanded {
                            Image("NavTransfer")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: DesignSystem.IconSize.medium, height: DesignSystem.IconSize.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: width(in: geometry.size.width), height: height)
                    .background(isExpanded ? themeService.cardBackgroundColor : fabColor)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .shadow(
                        color: shouldPulse && currentEffect == .glowBreathe
                            ? fabColor.opacity(anim ? 0.6 : 0.1)
                            : shouldPulse && currentEffect == .shadowOrbit
                                ? fabColor.opacity(0.5)
                                : Color.black.opacity(0.15),
                        radius: shouldPulse && currentEffect == .glowBreathe
                            ? (anim ? 20 : 4)
                            : shouldPulse && currentEffect == .shadowOrbit ? 12 : 20,
                        x: shouldPulse && currentEffect == .shadowOrbit ? CGFloat(cos(Double(progress) / 180.0 * Double.pi)) * 10 : 0,
                        y: shouldPulse && currentEffect == .glowBreathe ? 0
                            : shouldPulse && currentEffect == .shadowOrbit ? CGFloat(sin(Double(progress) / 180.0 * Double.pi)) * 10 : 10
                    )
                    // Overlay effects (rings, dots, sparkles, etc.)
                    .overlay(fabOverlayEffect)
                    // Motion modifiers driven by animation states
                    .offset(x: shouldPulse ? motionOffsetX : 0, y: shouldPulse ? motionOffsetY : 0)
                    .rotationEffect(.degrees(shouldPulse ? motionRotation : 0))
                    .scaleEffect(x: shouldPulse ? motionScaleX : 1.0, y: shouldPulse ? motionScaleY : 1.0)
                    .rotation3DEffect(.degrees(shouldPulse && currentEffect == .tilt3D ? (anim ? 15 : -15) : 0), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                    .opacity(shouldPulse && currentEffect == .breatheFade ? (anim ? 1.0 : 0.4) : 1.0)
                    .hueRotation(.degrees(shouldPulse && currentEffect == .colorCycle ? progress : 0))
                    .scaleEffect(buttonScale)
                    .animation(.easeInOut(duration: DesignSystem.Animation.pressDuration), value: isPressed)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, isExpanded ? DesignSystem.Spacing.md : DesignSystem.Spacing.lg) // 16px when expanded, 24px when collapsed
                }
                .frame(height: height)
            }
            .padding(.top, DesignSystem.Spacing.md) // Match BottomNavView padding
            .padding(.bottom, DesignSystem.Spacing.sm) // Match pill container padding
        }
        .allowsHitTesting(isExpanded ? true : false)
        .overlay(
            // Invisible button that's always tappable when collapsed
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Color.clear
                        .contentShape(Circle())
                        .frame(width: DesignSystem.Button.height, height: DesignSystem.Button.height)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isPressed {
                                        isPressed = true
                                    }
                                }
                                .onEnded { _ in
                                    isPressed = false
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    // Stop pulsing on first use
                                    if !hasUsedTransferButton {
                                        hasUsedTransferButton = true
                                        anim = false
                                    }
                                    withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                                        isExpanded = true
                                    }
                                }
                        )
                }
                .padding(.trailing, DesignSystem.Spacing.lg) // Collapsed button is 24px from right
            }
            .padding(.top, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.sm)
            .allowsHitTesting(!isExpanded)
        )
        .onAppear {
            if !hasUsedTransferButton {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startPulseAnimations()
                }
            }
        }
        .onChange(of: fabPulseEffectRaw) { _, _ in
            // Reset all animation states when effect changes
            resetAnimations()
            if !hasUsedTransferButton {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    startPulseAnimations()
                }
            }
        }
        .onChange(of: hasUsedTransferButton) { _, newValue in
            if !newValue {
                // Re-enable: restart animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startPulseAnimations()
                }
            } else {
                resetAnimations()
            }
        }
    }
    
    // MARK: - Computed Motion Properties
    
    private var motionOffsetX: CGFloat {
        switch currentEffect {
        case .pendulum: return anim ? 10 : -10
        case .shake: return secondary
        default: return 0
        }
    }
    
    private var motionOffsetY: CGFloat {
        switch currentEffect {
        case .bounce: return anim ? -8 : 0
        case .floatDrift: return anim ? -6 : 4
        case .doubleBounce: return secondary
        default: return 0
        }
    }
    
    private var motionRotation: Double {
        switch currentEffect {
        case .wiggle: return anim ? 8 : -8
        case .spin: return progress
        case .floatDrift: return anim ? 3 : -3
        default: return 0
        }
    }
    
    private var motionScaleX: CGFloat {
        switch currentEffect {
        case .scalePulse: return anim ? 1.15 : 1.0
        case .jelly: return anim ? 1.15 : 0.9
        case .breatheFade: return anim ? 1.05 : 0.95
        case .magnify: return anim ? 1.3 : 1.0
        case .springPop: return anim ? 1.1 : 1.0
        case .heartbeat:
            switch phase { case 1: return 1.18; case 3: return 1.12; default: return 1.0 }
        default: return 1.0
        }
    }
    
    private var motionScaleY: CGFloat {
        switch currentEffect {
        case .scalePulse: return anim ? 1.15 : 1.0
        case .jelly: return anim ? 0.9 : 1.15
        case .breatheFade: return anim ? 1.05 : 0.95
        case .magnify: return anim ? 1.3 : 1.0
        case .springPop: return anim ? 1.1 : 1.0
        case .heartbeat:
            switch phase { case 1: return 1.18; case 3: return 1.12; default: return 1.0 }
        default: return 1.0
        }
    }
    
    // MARK: - Overlay Effects
    
    private let h = DesignSystem.Button.height
    
    @ViewBuilder
    private var fabOverlayEffect: some View {
        if shouldPulse {
            switch currentEffect {
            case .rippleRing:
                Circle()
                    .stroke(fabColor.opacity(anim ? 0 : 0.5), lineWidth: anim ? 2 : 4)
                    .scaleEffect(anim ? 1.8 : 1.0)
                    .frame(width: h, height: h)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: anim)
                    
            case .doubleRipple:
                ZStack {
                    Circle().stroke(fabColor.opacity(anim ? 0 : 0.5), lineWidth: anim ? 2 : 4)
                        .scaleEffect(anim ? 1.8 : 1.0).frame(width: h, height: h)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: anim)
                    Circle().stroke(fabColor.opacity(anim ? 0 : 0.4), lineWidth: anim ? 2 : 3)
                        .scaleEffect(anim ? 1.8 : 1.0).frame(width: h, height: h)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.5), value: anim)
                }
                    
            case .tripleRipple:
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle().stroke(fabColor.opacity(anim ? 0 : 0.45), lineWidth: anim ? 1.5 : 3.5)
                            .scaleEffect(anim ? 1.9 : 1.0).frame(width: h, height: h)
                            .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(Double(i) * 0.4), value: anim)
                    }
                }
                    
            case .orbitingDot:
                Circle().fill(Color.white).frame(width: 8, height: 8)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(x: h / 2 + 6)
                    .rotationEffect(.degrees(progress))
                    
            case .trailingDots:
                ZStack {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(1.0 - Double(i) * 0.25))
                            .frame(width: 6 - CGFloat(i), height: 6 - CGFloat(i))
                            .offset(x: h / 2 + 6)
                            .rotationEffect(.degrees(progress - Double(i) * 20))
                    }
                }
                    
            case .arrowPeek:
                Image("NavTransfer").renderingMode(.template).resizable().aspectRatio(contentMode: .fit)
                    .frame(width: DesignSystem.IconSize.medium, height: DesignSystem.IconSize.medium)
                    .foregroundColor(.white)
                    .offset(y: anim ? -6 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.4).repeatForever(autoreverses: true), value: anim)
                    
            case .ringFill:
                ZStack {
                    Circle().stroke(fabColor.opacity(0.2), lineWidth: 3).frame(width: h + 12, height: h + 12)
                    Circle().trim(from: 0, to: progress / 360)
                        .stroke(fabColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: h + 12, height: h + 12)
                        .rotationEffect(.degrees(-90))
                }
                    
            case .spotlightSweep:
                LinearGradient(colors: [.clear, .white.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 16).offset(x: secondary)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: secondary)
                    .clipShape(Circle()).frame(width: h, height: h)
                    
            case .pulsingBorder:
                Circle()
                    .stroke(fabColor, lineWidth: anim ? 5 : 1.5)
                    .frame(width: h + 8, height: h + 8)
                    .opacity(anim ? 0.3 : 0.8)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: anim)
                    
            case .dashRing:
                Circle()
                    .stroke(fabColor, style: StrokeStyle(lineWidth: 2.5, dash: [6, 6]))
                    .frame(width: h + 14, height: h + 14)
                    .rotationEffect(.degrees(progress))
                    
            case .twinkle:
                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: CGFloat([7, 9, 6, 8, 10][i])))
                            .foregroundColor(fabColor)
                            .offset(
                                x: CGFloat(cos(Double(i) * 1.2566)) * (h / 2 + 10),
                                y: CGFloat(sin(Double(i) * 1.2566)) * (h / 2 + 10)
                            )
                            .opacity(anim ? 1.0 : 0.0)
                            .scaleEffect(anim ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(Double(i) * 0.15), value: anim)
                    }
                }
                    
            case .wavyRing:
                WavyCircle(phase: progress, amplitude: 3)
                    .stroke(fabColor.opacity(0.6), lineWidth: 2.5)
                    .frame(width: h + 14, height: h + 14)
                    
            case .beacon:
                Circle()
                    .fill(Color.white.opacity(anim ? 0.35 : 0))
                    .frame(width: h, height: h)
                    .animation(.easeOut(duration: 0.15), value: anim)
                    
            default:
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Animation Control
    
    private func startPulseAnimations() {
        let effect = currentEffect
        switch effect {
        // Simple toggle-based
        case .rippleRing, .doubleRipple, .tripleRipple,
             .glowBreathe, .bounce, .wiggle, .scalePulse,
             .arrowPeek, .pendulum, .jelly, .tilt3D,
             .floatDrift, .breatheFade, .pulsingBorder, .twinkle:
            anim = true
            
        // Continuous rotation/progress
        case .orbitingDot, .trailingDots:
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) { progress = 360 }
        case .spin, .shadowOrbit:
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { progress = 360 }
        case .colorCycle:
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { progress = 360 }
        case .dashRing:
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { progress = 360 }
        case .wavyRing:
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) { progress = 360 }
        case .ringFill:
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) { progress = 360 }
        case .spotlightSweep:
            secondary = 40
            
        // Timer-based multi-phase
        case .heartbeat: startHeartbeat()
        case .springPop: startSpringPop()
        case .shake: startShake()
        case .magnify: startMagnify()
        case .doubleBounce: startDoubleBounce()
        case .beacon: startBeacon()
        }
    }
    
    private func resetAnimations() {
        anim = false
        progress = 0
        secondary = -40
        phase = 0
    }
    
    // MARK: - Timer-based Animations
    
    private func startHeartbeat() {
        func beat() {
            guard shouldPulse, currentEffect == .heartbeat else { return }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { beat() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { beat() }
    }
    
    private func startSpringPop() {
        func pop() {
            guard shouldPulse, currentEffect == .springPop else { return }
            withAnimation(.easeOut(duration: 0.5)) { anim = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.6)) { anim = false }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { pop() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { pop() }
    }
    
    private func startShake() {
        func shake() {
            guard shouldPulse, currentEffect == .shake else { return }
            withAnimation(.spring(response: 0.06, dampingFraction: 0.2)) { secondary = 6 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.spring(response: 0.06, dampingFraction: 0.2)) { secondary = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.06, dampingFraction: 0.2)) { secondary = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.06, dampingFraction: 0.2)) { secondary = -3 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) { secondary = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { shake() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake() }
    }
    
    private func startMagnify() {
        func mag() {
            guard shouldPulse, currentEffect == .magnify else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { anim = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { anim = false }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { mag() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { mag() }
    }
    
    private func startDoubleBounce() {
        func bounce() {
            guard shouldPulse, currentEffect == .doubleBounce else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { secondary = -10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) { secondary = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { secondary = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { secondary = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { bounce() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { bounce() }
    }
    
    private func startBeacon() {
        func flash() {
            guard shouldPulse, currentEffect == .beacon else { return }
            anim = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { anim = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { anim = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { anim = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { flash() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { flash() }
    }
}

// MARK: - Menu Row

struct ZoomMenuRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let option: ZoomMenuOption
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon with light background
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F7F7F7"))
                    .frame(width: DesignSystem.IconSize.large, height: DesignSystem.IconSize.large)
                
                Image(option.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: DesignSystem.IconSize.medium, height: DesignSystem.IconSize.medium)
                    .foregroundColor(option.iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(option.rawValue)
                    .font(DesignSystem.Typography.headerTitle)
                    .foregroundColor(themeService.textPrimaryColor)
                
                Text(option.subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(themeService.textSecondaryColor)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.CornerRadius.small)
        .padding(.horizontal, DesignSystem.CornerRadius.small)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(isPressed ? (themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F0F0F0")) : Color.clear)
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    onTap()
                }
        )
        .animation(.easeInOut(duration: DesignSystem.Animation.pressDuration), value: isPressed)
    }
}

#Preview {
    ZStack {
        Color(hex: DesignSystem.Colors.backgroundLight)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            ZoomTransitionView()
                .padding(.bottom, 40)
        }
    }
}
