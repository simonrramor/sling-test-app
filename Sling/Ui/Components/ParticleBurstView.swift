import SwiftUI
import SpriteKit

// MARK: - Particle Burst Scene

class ParticleBurstScene: SKScene {
    
    var particleColor: UIColor = UIColor(red: 1.0, green: 0.32, blue: 0.07, alpha: 1.0) // FF5113
    var particleCount: Int = 200
    var burstSpeed: CGFloat = 300
    var particleLifetime: CGFloat = 2.0
    var particleSize: CGFloat = 4
    var spreadAngle: CGFloat = 360
    var hasTrails: Bool = true
    
    // Additional properties
    var gravity: CGFloat = -50          // yAcceleration (negative = down)
    var xDrift: CGFloat = 0             // xAcceleration
    var particleRotation: CGFloat = 0   // Rotation speed in radians/sec
    var colorVariation: CGFloat = 0.1   // Color range variation
    var speedVariation: CGFloat = 0.5   // Speed range as fraction of burstSpeed
    var sizeVariation: CGFloat = 0.5    // Size range as fraction of particleSize
    var fadeSpeed: CGFloat = 1.0        // How fast particles fade (1.0 = normal)
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.allowsTransparency = true
    }
    
    func triggerBurst(at position: CGPoint? = nil) {
        // Don't remove existing emitters - let them accumulate
        
        // Create new emitter
        let emitter = SKEmitterNode()
        
        // Position at center or specified location
        let burstPosition = position ?? CGPoint(x: size.width / 2, y: size.height / 2)
        emitter.position = burstPosition
        
        // Particle appearance
        emitter.particleTexture = createParticleTexture()
        emitter.particleColor = particleColor
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .alpha // Use alpha blending for visibility on any background
        
        // Particle size with variation
        emitter.particleSize = CGSize(width: particleSize, height: particleSize)
        emitter.particleScaleRange = particleSize * sizeVariation
        emitter.particleScaleSpeed = -particleSize / particleLifetime * 0.5
        
        // Emission settings - burst all at once
        emitter.numParticlesToEmit = particleCount
        emitter.particleBirthRate = CGFloat(particleCount) * 10 // Emit all quickly
        
        // Particle lifetime
        emitter.particleLifetime = particleLifetime
        emitter.particleLifetimeRange = particleLifetime * 0.3
        
        // Movement - radiate outward
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = spreadAngle * .pi / 180
        emitter.particleSpeed = burstSpeed
        emitter.particleSpeedRange = burstSpeed * speedVariation
        
        // Physics
        emitter.yAcceleration = gravity
        emitter.xAcceleration = xDrift
        
        // Rotation
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = particleRotation
        
        // Fade out
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = (-1.0 / particleLifetime) * fadeSpeed
        emitter.particleAlphaRange = 0.2
        
        // Color variation
        emitter.particleColorSequence = nil
        emitter.particleColorRedRange = colorVariation
        emitter.particleColorGreenRange = colorVariation
        emitter.particleColorBlueRange = colorVariation * 0.5
        
        // Add trails if enabled
        if hasTrails {
            emitter.particleAction = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: particleLifetime * 0.8),
                SKAction.fadeOut(withDuration: particleLifetime * 0.2)
            ])
        }
        
        addChild(emitter)
        
        // Auto-remove this emitter after animation completes (but others stay)
        let wait = SKAction.wait(forDuration: Double(particleLifetime) + 0.5)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }
    
    private func createParticleTexture() -> SKTexture {
        let size: CGFloat = 32
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        let image = renderer.image { context in
            // Draw a soft glowing circle
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.white.cgColor,
                    UIColor.white.withAlphaComponent(0.5).cgColor,
                    UIColor.white.withAlphaComponent(0).cgColor
                ] as CFArray,
                locations: [0, 0.3, 1]
            )!
            
            let center = CGPoint(x: size / 2, y: size / 2)
            context.cgContext.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: size / 2,
                options: []
            )
        }
        
        return SKTexture(image: image)
    }
}

// MARK: - SwiftUI Wrapper

struct ParticleBurstView: View {
    var color: Color = Color(hex: "FF5113")
    var particleCount: Int = 200
    var burstSpeed: CGFloat = 300
    var particleLifetime: CGFloat = 2.0
    var particleSize: CGFloat = 4
    var spreadAngle: CGFloat = 360
    var hasTrails: Bool = true
    
    // Additional properties
    var gravity: CGFloat = -50
    var xDrift: CGFloat = 0
    var particleRotation: CGFloat = 0
    var colorVariation: CGFloat = 0.1
    var speedVariation: CGFloat = 0.5
    var sizeVariation: CGFloat = 0.5
    var fadeSpeed: CGFloat = 1.0
    
    @Binding var trigger: Int
    
    @State private var scene: ParticleBurstScene?
    
    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: makeScene(size: geo.size), options: [.allowsTransparency])
                .ignoresSafeArea()
                .onChange(of: trigger) { _, _ in
                    scene?.triggerBurst()
                }
        }
    }
    
    private func makeScene(size: CGSize) -> ParticleBurstScene {
        if let existing = scene {
            // Update cached scene with new property values from sliders
            existing.particleColor = UIColor(color)
            existing.particleCount = particleCount
            existing.burstSpeed = burstSpeed
            existing.particleLifetime = particleLifetime
            existing.particleSize = particleSize
            existing.spreadAngle = spreadAngle
            existing.hasTrails = hasTrails
            existing.gravity = gravity
            existing.xDrift = xDrift
            existing.particleRotation = particleRotation
            existing.colorVariation = colorVariation
            existing.speedVariation = speedVariation
            existing.sizeVariation = sizeVariation
            existing.fadeSpeed = fadeSpeed
            
            return existing
        }
        
        let newScene = ParticleBurstScene(size: size)
        newScene.scaleMode = .resizeFill
        newScene.backgroundColor = .clear
        newScene.particleColor = UIColor(color)
        newScene.particleCount = particleCount
        newScene.burstSpeed = burstSpeed
        newScene.particleLifetime = particleLifetime
        newScene.particleSize = particleSize
        newScene.spreadAngle = spreadAngle
        newScene.hasTrails = hasTrails
        newScene.gravity = gravity
        newScene.xDrift = xDrift
        newScene.particleRotation = particleRotation
        newScene.colorVariation = colorVariation
        newScene.speedVariation = speedVariation
        newScene.sizeVariation = sizeVariation
        newScene.fadeSpeed = fadeSpeed
        
        DispatchQueue.main.async {
            self.scene = newScene
        }
        
        return newScene
    }
}

// MARK: - Auto-triggering version

struct AutoParticleBurstView: View {
    var color: Color = Color(hex: "FF5113")
    var particleCount: Int = 200
    var burstSpeed: CGFloat = 300
    var particleLifetime: CGFloat = 2.0
    var particleSize: CGFloat = 4
    var spreadAngle: CGFloat = 360
    var hasTrails: Bool = true
    var gravity: CGFloat = -50
    var xDrift: CGFloat = 0
    var particleRotation: CGFloat = 0
    var colorVariation: CGFloat = 0.1
    var speedVariation: CGFloat = 0.5
    var sizeVariation: CGFloat = 0.5
    var fadeSpeed: CGFloat = 1.0
    var delay: TimeInterval = 0.3
    
    @State private var trigger = 0
    
    var body: some View {
        ParticleBurstView(
            color: color,
            particleCount: particleCount,
            burstSpeed: burstSpeed,
            particleLifetime: particleLifetime,
            particleSize: particleSize,
            spreadAngle: spreadAngle,
            hasTrails: hasTrails,
            gravity: gravity,
            xDrift: xDrift,
            particleRotation: particleRotation,
            colorVariation: colorVariation,
            speedVariation: speedVariation,
            sizeVariation: sizeVariation,
            fadeSpeed: fadeSpeed,
            trigger: $trigger
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                trigger += 1
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            AutoParticleBurstView()
                .frame(width: 300, height: 300)
        }
    }
}
