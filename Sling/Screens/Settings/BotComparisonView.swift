import SwiftUI

// MARK: - Bot Comparison View
// Shows 3 different bot face styles side by side for comparison

struct BotComparisonView: View {
    @ObservedObject private var themeService = ThemeService.shared
    
    // Shared state for all bots (so they animate together)
    @State private var emotion: BotEmotion = .neutral
    @State private var lookX: CGFloat = 0
    @State private var lookY: CGFloat = 0
    @State private var blinkTrigger = false
    
    // Auto-blink timer
    @State private var blinkTimer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("Bot Face Styles")
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundColor(themeService.textPrimaryColor)
                
                // Three bots side by side
                HStack(spacing: 16) {
                    // Mini Robot Face style
                    VStack(spacing: 8) {
                        MiniRobotFaceView(
                            emotion: emotion,
                            lookX: lookX,
                            lookY: lookY,
                            blink: blinkTrigger
                        )
                        .frame(width: 100, height: 100)
                        
                        Text("Mini Robot")
                            .font(.custom("Inter-SemiBold", size: 11))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                    
                    // Procedural Expression style
                    VStack(spacing: 8) {
                        ProceduralFaceView(
                            emotion: emotion,
                            lookX: lookX,
                            lookY: lookY,
                            blink: blinkTrigger
                        )
                        .frame(width: 100, height: 100)
                        
                        Text("Procedural")
                            .font(.custom("Inter-SemiBold", size: 11))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                    
                    // ESP32 Eyes style
                    VStack(spacing: 8) {
                        ESP32EyesFaceView(
                            emotion: emotion,
                            lookX: lookX,
                            lookY: lookY,
                            blink: blinkTrigger
                        )
                        .frame(width: 100, height: 100)
                        
                        Text("ESP32 Eyes")
                            .font(.custom("Inter-SemiBold", size: 11))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                }
                
                // Look joystick
                VStack(spacing: 8) {
                    Text("Look Direction")
                        .font(.custom("Inter-SemiBold", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    CompactJoystickView(positionX: $lookX, positionY: $lookY)
                }
                
                // Emotion picker
                VStack(spacing: 12) {
                    Text("Emotion")
                        .font(.custom("Inter-SemiBold", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BotEmotion.allCases, id: \.self) { emo in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        emotion = emo
                                    }
                                }) {
                                    Text(emo.icon)
                                        .font(.system(size: 24))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(emotion == emo ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(emotion == emo ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // Blink button
                Button(action: {
                    triggerBlink()
                }) {
                    Text("👁️ Blink")
                        .font(.custom("Inter-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.blue))
                }
            }
            .padding()
        }
        .background(themeService.backgroundColor)
        .onAppear {
            startAutoBlinking()
        }
        .onDisappear {
            blinkTimer?.invalidate()
        }
    }
    
    private func triggerBlink() {
        blinkTrigger = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            blinkTrigger = false
        }
    }
    
    private func startAutoBlinking() {
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            triggerBlink()
        }
    }
}

// MARK: - Bot Emotions

enum BotEmotion: String, CaseIterable {
    case neutral, happy, sad, angry, surprised, sleepy, confused, scared, focused, skeptical
    
    var icon: String {
        switch self {
        case .neutral: return "😐"
        case .happy: return "😊"
        case .sad: return "😢"
        case .angry: return "😠"
        case .surprised: return "😲"
        case .sleepy: return "😴"
        case .confused: return "😕"
        case .scared: return "😨"
        case .focused: return "🧐"
        case .skeptical: return "🤨"
        }
    }
}

// MARK: - Compact Joystick

struct CompactJoystickView: View {
    @Binding var positionX: CGFloat
    @Binding var positionY: CGFloat
    
    let size: CGFloat = 80
    let dotSize: CGFloat = 20
    
    private var dotOffset: CGSize {
        CGSize(
            width: positionX * (size - dotSize) / 2,
            height: positionY * (size - dotSize) / 2
        )
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .frame(width: size, height: size)
            
            Circle()
                .fill(Color.blue)
                .frame(width: dotSize, height: dotSize)
                .offset(dotOffset)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let x = value.location.x - size / 2
                    let y = value.location.y - size / 2
                    let maxOffset = (size - dotSize) / 2
                    positionX = max(-1, min(1, x / maxOffset))
                    positionY = max(-1, min(1, y / maxOffset))
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        positionX = 0
                        positionY = 0
                    }
                }
        )
    }
}

// MARK: - Style 1: Mini Robot Face (Cozmo-like simple rectangles)
// Inspired by: https://github.com/EzioGraphy/mini-robot-face

struct MiniRobotFaceView: View {
    let emotion: BotEmotion
    let lookX: CGFloat
    let lookY: CGFloat
    let blink: Bool
    
    private var eyeConfig: MiniRobotEyeConfig {
        MiniRobotEyeConfig.forEmotion(emotion)
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black)
            
            // Eyes
            HStack(spacing: 8) {
                // Left eye
                RoundedRectangle(cornerRadius: eyeConfig.leftCornerRadius)
                    .fill(Color.white)
                    .frame(
                        width: eyeConfig.leftWidth,
                        height: blink ? 2 : eyeConfig.leftHeight
                    )
                    .rotationEffect(.degrees(eyeConfig.leftRotation))
                    .offset(
                        x: lookX * 6,
                        y: lookY * 4 + eyeConfig.leftOffsetY
                    )
                
                // Right eye
                RoundedRectangle(cornerRadius: eyeConfig.rightCornerRadius)
                    .fill(Color.white)
                    .frame(
                        width: eyeConfig.rightWidth,
                        height: blink ? 2 : eyeConfig.rightHeight
                    )
                    .rotationEffect(.degrees(eyeConfig.rightRotation))
                    .offset(
                        x: lookX * 6,
                        y: lookY * 4 + eyeConfig.rightOffsetY
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: emotion)
        .animation(.easeInOut(duration: 0.08), value: blink)
    }
}

struct MiniRobotEyeConfig {
    var leftWidth: CGFloat = 20
    var leftHeight: CGFloat = 20
    var leftCornerRadius: CGFloat = 4
    var leftRotation: CGFloat = 0
    var leftOffsetY: CGFloat = 0
    
    var rightWidth: CGFloat = 20
    var rightHeight: CGFloat = 20
    var rightCornerRadius: CGFloat = 4
    var rightRotation: CGFloat = 0
    var rightOffsetY: CGFloat = 0
    
    static func forEmotion(_ emotion: BotEmotion) -> MiniRobotEyeConfig {
        switch emotion {
        case .neutral:
            return MiniRobotEyeConfig()
        case .happy:
            return MiniRobotEyeConfig(
                leftHeight: 8, leftCornerRadius: 2, leftOffsetY: 2,
                rightHeight: 8, rightCornerRadius: 2, rightOffsetY: 2
            )
        case .sad:
            return MiniRobotEyeConfig(
                leftWidth: 18, leftHeight: 14, leftRotation: -10, leftOffsetY: 4,
                rightWidth: 18, rightHeight: 14, rightRotation: 10, rightOffsetY: 4
            )
        case .angry:
            return MiniRobotEyeConfig(
                leftHeight: 12, leftRotation: 15, leftOffsetY: 2,
                rightHeight: 12, rightRotation: -15, rightOffsetY: 2
            )
        case .surprised:
            return MiniRobotEyeConfig(
                leftWidth: 24, leftHeight: 28, leftCornerRadius: 8, leftOffsetY: -2,
                rightWidth: 24, rightHeight: 28, rightCornerRadius: 8, rightOffsetY: -2
            )
        case .sleepy:
            return MiniRobotEyeConfig(
                leftHeight: 6, leftCornerRadius: 2, leftOffsetY: 3,
                rightHeight: 6, rightCornerRadius: 2, rightOffsetY: 3
            )
        case .confused:
            return MiniRobotEyeConfig(
                leftWidth: 22, leftHeight: 18, leftCornerRadius: 6,
                rightWidth: 16, rightHeight: 22, rightCornerRadius: 4, rightRotation: 10
            )
        case .scared:
            return MiniRobotEyeConfig(
                leftWidth: 22, leftHeight: 26, leftCornerRadius: 8, leftOffsetY: -2,
                rightWidth: 22, rightHeight: 26, rightCornerRadius: 8, rightOffsetY: -2
            )
        case .focused:
            return MiniRobotEyeConfig(
                leftHeight: 10, leftCornerRadius: 2,
                rightHeight: 10, rightCornerRadius: 2
            )
        case .skeptical:
            return MiniRobotEyeConfig(
                leftWidth: 18, leftHeight: 10, leftRotation: -5,
                rightWidth: 20, rightHeight: 18, rightCornerRadius: 6, rightRotation: 5
            )
        }
    }
}

// MARK: - Style 2: Procedural Expression (8-point polygon eyes)
// Inspired by: https://github.com/ggldnl/Procedural-Expression-Library

struct ProceduralFaceView: View {
    let emotion: BotEmotion
    let lookX: CGFloat
    let lookY: CGFloat
    let blink: Bool
    
    private var eyePolygon: ProceduralEyePolygon {
        ProceduralEyePolygon.forEmotion(emotion, blink: blink)
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "1a1a2e"))
            
            // Eyes using polygon shapes
            HStack(spacing: 6) {
                // Left eye (mirrored)
                ProceduralEyeShape(polygon: eyePolygon.left, mirror: true)
                    .fill(Color(hex: "eaf6ff"))
                    .frame(width: 28, height: 32)
                    .offset(
                        x: lookX * 5,
                        y: lookY * 4
                    )
                
                // Right eye
                ProceduralEyeShape(polygon: eyePolygon.right, mirror: false)
                    .fill(Color(hex: "eaf6ff"))
                    .frame(width: 28, height: 32)
                    .offset(
                        x: lookX * 5,
                        y: lookY * 4
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: emotion)
        .animation(.easeInOut(duration: 0.08), value: blink)
    }
}

struct ProceduralEyePolygon {
    // 8 points defining the eye shape (normalized 0-1)
    var left: [CGPoint]
    var right: [CGPoint]
    
    static let neutral: [CGPoint] = [
        CGPoint(x: 0.1, y: 0.2),   // Top left
        CGPoint(x: 0.9, y: 0.2),   // Top right
        CGPoint(x: 1.0, y: 0.3),   // Right top curve
        CGPoint(x: 1.0, y: 0.7),   // Right bottom curve
        CGPoint(x: 0.9, y: 0.8),   // Bottom right
        CGPoint(x: 0.1, y: 0.8),   // Bottom left
        CGPoint(x: 0.0, y: 0.7),   // Left bottom curve
        CGPoint(x: 0.0, y: 0.3),   // Left top curve
    ]
    
    static let blink: [CGPoint] = [
        CGPoint(x: 0.0, y: 0.48),
        CGPoint(x: 1.0, y: 0.48),
        CGPoint(x: 1.0, y: 0.49),
        CGPoint(x: 1.0, y: 0.51),
        CGPoint(x: 1.0, y: 0.52),
        CGPoint(x: 0.0, y: 0.52),
        CGPoint(x: 0.0, y: 0.51),
        CGPoint(x: 0.0, y: 0.49),
    ]
    
    static func forEmotion(_ emotion: BotEmotion, blink: Bool) -> ProceduralEyePolygon {
        if blink {
            return ProceduralEyePolygon(left: Self.blink, right: Self.blink)
        }
        
        switch emotion {
        case .neutral:
            return ProceduralEyePolygon(left: Self.neutral, right: Self.neutral)
        case .happy:
            let happy: [CGPoint] = [
                CGPoint(x: 0.0, y: 0.3),
                CGPoint(x: 1.0, y: 0.3),
                CGPoint(x: 1.0, y: 0.35),
                CGPoint(x: 0.8, y: 0.6),
                CGPoint(x: 0.5, y: 0.7),
                CGPoint(x: 0.2, y: 0.6),
                CGPoint(x: 0.0, y: 0.35),
                CGPoint(x: 0.0, y: 0.32),
            ]
            return ProceduralEyePolygon(left: happy, right: happy)
        case .sad:
            let sadLeft: [CGPoint] = [
                CGPoint(x: 0.2, y: 0.15),
                CGPoint(x: 0.8, y: 0.3),
                CGPoint(x: 0.95, y: 0.4),
                CGPoint(x: 0.95, y: 0.75),
                CGPoint(x: 0.8, y: 0.85),
                CGPoint(x: 0.2, y: 0.85),
                CGPoint(x: 0.05, y: 0.75),
                CGPoint(x: 0.05, y: 0.35),
            ]
            let sadRight: [CGPoint] = [
                CGPoint(x: 0.2, y: 0.3),
                CGPoint(x: 0.8, y: 0.15),
                CGPoint(x: 0.95, y: 0.35),
                CGPoint(x: 0.95, y: 0.75),
                CGPoint(x: 0.8, y: 0.85),
                CGPoint(x: 0.2, y: 0.85),
                CGPoint(x: 0.05, y: 0.75),
                CGPoint(x: 0.05, y: 0.4),
            ]
            return ProceduralEyePolygon(left: sadLeft, right: sadRight)
        case .angry:
            let angryLeft: [CGPoint] = [
                CGPoint(x: 0.0, y: 0.45),
                CGPoint(x: 0.9, y: 0.2),
                CGPoint(x: 1.0, y: 0.3),
                CGPoint(x: 1.0, y: 0.7),
                CGPoint(x: 0.9, y: 0.8),
                CGPoint(x: 0.1, y: 0.8),
                CGPoint(x: 0.0, y: 0.7),
                CGPoint(x: 0.0, y: 0.5),
            ]
            let angryRight: [CGPoint] = [
                CGPoint(x: 0.1, y: 0.2),
                CGPoint(x: 1.0, y: 0.45),
                CGPoint(x: 1.0, y: 0.5),
                CGPoint(x: 1.0, y: 0.7),
                CGPoint(x: 0.9, y: 0.8),
                CGPoint(x: 0.1, y: 0.8),
                CGPoint(x: 0.0, y: 0.7),
                CGPoint(x: 0.0, y: 0.3),
            ]
            return ProceduralEyePolygon(left: angryLeft, right: angryRight)
        case .surprised:
            let surprised: [CGPoint] = [
                CGPoint(x: 0.15, y: 0.05),
                CGPoint(x: 0.85, y: 0.05),
                CGPoint(x: 1.0, y: 0.2),
                CGPoint(x: 1.0, y: 0.8),
                CGPoint(x: 0.85, y: 0.95),
                CGPoint(x: 0.15, y: 0.95),
                CGPoint(x: 0.0, y: 0.8),
                CGPoint(x: 0.0, y: 0.2),
            ]
            return ProceduralEyePolygon(left: surprised, right: surprised)
        case .sleepy:
            let sleepy: [CGPoint] = [
                CGPoint(x: 0.0, y: 0.35),
                CGPoint(x: 1.0, y: 0.35),
                CGPoint(x: 1.0, y: 0.4),
                CGPoint(x: 1.0, y: 0.6),
                CGPoint(x: 1.0, y: 0.65),
                CGPoint(x: 0.0, y: 0.65),
                CGPoint(x: 0.0, y: 0.6),
                CGPoint(x: 0.0, y: 0.4),
            ]
            return ProceduralEyePolygon(left: sleepy, right: sleepy)
        case .confused:
            let confusedLeft: [CGPoint] = [
                CGPoint(x: 0.1, y: 0.2),
                CGPoint(x: 0.9, y: 0.2),
                CGPoint(x: 1.0, y: 0.3),
                CGPoint(x: 1.0, y: 0.7),
                CGPoint(x: 0.9, y: 0.8),
                CGPoint(x: 0.1, y: 0.8),
                CGPoint(x: 0.0, y: 0.7),
                CGPoint(x: 0.0, y: 0.3),
            ]
            let confusedRight: [CGPoint] = [
                CGPoint(x: 0.15, y: 0.3),
                CGPoint(x: 0.85, y: 0.25),
                CGPoint(x: 0.95, y: 0.35),
                CGPoint(x: 0.95, y: 0.65),
                CGPoint(x: 0.85, y: 0.75),
                CGPoint(x: 0.15, y: 0.8),
                CGPoint(x: 0.05, y: 0.7),
                CGPoint(x: 0.05, y: 0.4),
            ]
            return ProceduralEyePolygon(left: confusedLeft, right: confusedRight)
        case .scared:
            let scared: [CGPoint] = [
                CGPoint(x: 0.1, y: 0.0),
                CGPoint(x: 0.9, y: 0.0),
                CGPoint(x: 1.0, y: 0.15),
                CGPoint(x: 1.0, y: 0.85),
                CGPoint(x: 0.9, y: 1.0),
                CGPoint(x: 0.1, y: 1.0),
                CGPoint(x: 0.0, y: 0.85),
                CGPoint(x: 0.0, y: 0.15),
            ]
            return ProceduralEyePolygon(left: scared, right: scared)
        case .focused:
            let focused: [CGPoint] = [
                CGPoint(x: 0.0, y: 0.35),
                CGPoint(x: 1.0, y: 0.35),
                CGPoint(x: 1.0, y: 0.4),
                CGPoint(x: 1.0, y: 0.6),
                CGPoint(x: 1.0, y: 0.65),
                CGPoint(x: 0.0, y: 0.65),
                CGPoint(x: 0.0, y: 0.6),
                CGPoint(x: 0.0, y: 0.4),
            ]
            return ProceduralEyePolygon(left: focused, right: focused)
        case .skeptical:
            let skeptLeft: [CGPoint] = [
                CGPoint(x: 0.0, y: 0.4),
                CGPoint(x: 0.9, y: 0.35),
                CGPoint(x: 1.0, y: 0.4),
                CGPoint(x: 1.0, y: 0.6),
                CGPoint(x: 0.9, y: 0.65),
                CGPoint(x: 0.1, y: 0.7),
                CGPoint(x: 0.0, y: 0.65),
                CGPoint(x: 0.0, y: 0.45),
            ]
            let skeptRight: [CGPoint] = [
                CGPoint(x: 0.1, y: 0.15),
                CGPoint(x: 0.9, y: 0.15),
                CGPoint(x: 1.0, y: 0.25),
                CGPoint(x: 1.0, y: 0.75),
                CGPoint(x: 0.9, y: 0.85),
                CGPoint(x: 0.1, y: 0.85),
                CGPoint(x: 0.0, y: 0.75),
                CGPoint(x: 0.0, y: 0.25),
            ]
            return ProceduralEyePolygon(left: skeptLeft, right: skeptRight)
        }
    }
}

struct ProceduralEyeShape: Shape {
    var polygon: [CGPoint]
    var mirror: Bool
    
    var animatableData: AnimatablePolygon {
        get { AnimatablePolygon(points: polygon) }
        set { polygon = newValue.points }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard polygon.count >= 3 else { return path }
        
        let points = polygon.map { point in
            CGPoint(
                x: (mirror ? (1 - point.x) : point.x) * rect.width,
                y: point.y * rect.height
            )
        }
        
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        path.closeSubpath()
        
        return path
    }
}

struct AnimatablePolygon: VectorArithmetic {
    var points: [CGPoint]
    
    static var zero: AnimatablePolygon {
        AnimatablePolygon(points: Array(repeating: .zero, count: 8))
    }
    
    static func + (lhs: AnimatablePolygon, rhs: AnimatablePolygon) -> AnimatablePolygon {
        let count = max(lhs.points.count, rhs.points.count)
        var result: [CGPoint] = []
        for i in 0..<count {
            let l = i < lhs.points.count ? lhs.points[i] : .zero
            let r = i < rhs.points.count ? rhs.points[i] : .zero
            result.append(CGPoint(x: l.x + r.x, y: l.y + r.y))
        }
        return AnimatablePolygon(points: result)
    }
    
    static func - (lhs: AnimatablePolygon, rhs: AnimatablePolygon) -> AnimatablePolygon {
        let count = max(lhs.points.count, rhs.points.count)
        var result: [CGPoint] = []
        for i in 0..<count {
            let l = i < lhs.points.count ? lhs.points[i] : .zero
            let r = i < rhs.points.count ? rhs.points[i] : .zero
            result.append(CGPoint(x: l.x - r.x, y: l.y - r.y))
        }
        return AnimatablePolygon(points: result)
    }
    
    mutating func scale(by rhs: Double) {
        points = points.map { CGPoint(x: $0.x * rhs, y: $0.y * rhs) }
    }
    
    var magnitudeSquared: Double {
        points.reduce(0) { $0 + Double($1.x * $1.x + $1.y * $1.y) }
    }
}

// MARK: - Style 3: ESP32 Eyes (OLED-style with eyelids and pupils)
// Inspired by: https://github.com/playfultechnology/esp32-eyes

struct ESP32EyesFaceView: View {
    let emotion: BotEmotion
    let lookX: CGFloat
    let lookY: CGFloat
    let blink: Bool
    
    private var eyeConfig: ESP32EyeConfig {
        ESP32EyeConfig.forEmotion(emotion)
    }
    
    var body: some View {
        ZStack {
            // Background - OLED black
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black)
            
            // Eyes
            HStack(spacing: 10) {
                // Left eye
                ESP32EyeView(
                    config: eyeConfig.left,
                    lookX: lookX,
                    lookY: lookY,
                    blink: blink,
                    eyeColor: Color(hex: "00ff88")
                )
                .frame(width: 32, height: 36)
                
                // Right eye
                ESP32EyeView(
                    config: eyeConfig.right,
                    lookX: lookX,
                    lookY: lookY,
                    blink: blink,
                    eyeColor: Color(hex: "00ff88")
                )
                .frame(width: 32, height: 36)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: emotion)
        .animation(.easeInOut(duration: 0.08), value: blink)
    }
}

struct ESP32EyeView: View {
    let config: ESP32SingleEyeConfig
    let lookX: CGFloat
    let lookY: CGFloat
    let blink: Bool
    let eyeColor: Color
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let eyeHeight = blink ? 2 : height * config.heightRatio
            let eyelidHeight = height * config.eyelidClosure
            
            ZStack {
                // Eye sclera/iris
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(eyeColor)
                    .frame(width: width, height: eyeHeight)
                    .rotationEffect(.degrees(config.rotation))
                
                // Pupil
                Circle()
                    .fill(Color.black)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: lookX * 6,
                        y: lookY * 5
                    )
                
                // Top eyelid
                Rectangle()
                    .fill(Color.black)
                    .frame(width: width + 4, height: eyelidHeight)
                    .offset(y: -height/2 + eyelidHeight/2)
                
                // Bottom eyelid (for some expressions)
                if config.bottomEyelidClosure > 0 {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: width + 4, height: height * config.bottomEyelidClosure)
                        .offset(y: height/2 - (height * config.bottomEyelidClosure)/2)
                }
            }
            .frame(width: width, height: height)
        }
    }
}

struct ESP32SingleEyeConfig {
    var heightRatio: CGFloat = 1.0      // 0-1, how open the eye is
    var cornerRadius: CGFloat = 6
    var rotation: CGFloat = 0
    var eyelidClosure: CGFloat = 0      // 0-1, top eyelid closure
    var bottomEyelidClosure: CGFloat = 0 // 0-1, bottom eyelid closure
}

struct ESP32EyeConfig {
    var left: ESP32SingleEyeConfig
    var right: ESP32SingleEyeConfig
    
    static func forEmotion(_ emotion: BotEmotion) -> ESP32EyeConfig {
        switch emotion {
        case .neutral:
            return ESP32EyeConfig(
                left: ESP32SingleEyeConfig(),
                right: ESP32SingleEyeConfig()
            )
        case .happy:
            return ESP32EyeConfig(
                left: ESP32SingleEyeConfig(heightRatio: 0.4, bottomEyelidClosure: 0.3),
                right: ESP32SingleEyeConfig(heightRatio: 0.4, bottomEyelidClosure: 0.3)
            )
        case .sad:
            return ESP32EyeConfig(
                left: ESP32SingleEyeConfig(heightRatio: 0.7, rotation: -10, eyelidClosure: 0.2),
                right: ESP32SingleEyeConfig(heightRatio: 0.7, rotation: 10, eyelidClosure: 0.2)
            )
        case .angry:
            return ESP32EyeConfig(
                left: ESP32SingleEyeConfig(heightRatio: 0.6, rotation: 20, eyelidClosure: 0.3),
                right: ESP32SingleEyeConfig(heightRatio: 0.6, rotation: -20, eyelidClosure: 0.3)
            )
        case .surprised:
            return ESP32EyeConfig(
                left: ESP32SingleEyeConfig(heightRatio: 1.2, cornerRadius: 10),
                right: ESP32SingleEyeConfig(heightRatio: 1.2, cornerRadius: 10)
            )
        case .sleepy:
            return ESP32EyeConfig(
                left: ESP32SingleEyeConfig(heightRatio: 0.3, eyelidClosure: 0.5),
                right: ESP32SingleEyeConfig(heightRatio: 0.3, eyelidClosure: 0.5)
            )
        case .confused:
            return ESP32EyeConfig(
                left: ESP32SingleEyeConfig(heightRatio: 1.0),
                right: ESP32SingleEyeConfig(heightRatio: 0.7, rotation: 15, eyelidClosure: 0.15)
            )
        case .scared:
            return ESP32EyeConfig(
                left: ESP32SingleEyeConfig(heightRatio: 1.3, cornerRadius: 12),
                right: ESP32SingleEyeConfig(heightRatio: 1.3, cornerRadius: 12)
            )
        case .focused:
            return ESP32EyeConfig(
                left: ESP32SingleEyeConfig(heightRatio: 0.5, eyelidClosure: 0.25, bottomEyelidClosure: 0.25),
                right: ESP32SingleEyeConfig(heightRatio: 0.5, eyelidClosure: 0.25, bottomEyelidClosure: 0.25)
            )
        case .skeptical:
            return ESP32EyeConfig(
                left: ESP32SingleEyeConfig(heightRatio: 0.5, rotation: -10, eyelidClosure: 0.3),
                right: ESP32SingleEyeConfig(heightRatio: 1.0, rotation: 5)
            )
        }
    }
}

#Preview {
    BotComparisonView()
}
