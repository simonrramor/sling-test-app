import SwiftUI

struct ParticleTestView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeService = ThemeService.shared
    
    // Particle parameters
    @State private var particleCount: Double = 200
    @State private var burstSpeed: Double = 300
    @State private var particleLifetime: Double = 2.0
    @State private var particleSize: Double = 4
    @State private var spreadAngle: Double = 360
    @State private var hasTrails: Bool = true
    
    // Additional parameters
    @State private var gravity: Double = -50
    @State private var xDrift: Double = 0
    @State private var particleRotation: Double = 0
    @State private var colorVariation: Double = 0.1
    @State private var speedVariation: Double = 0.5
    @State private var sizeVariation: Double = 0.5
    @State private var fadeSpeed: Double = 1.0
    
    // Color - Sling orange (FF5113) is approximately hue 0.044
    @State private var colorHue: Double = 0.044
    
    // Trigger
    @State private var trigger = 0
    
    var particleColor: Color {
        Color(hue: colorHue, saturation: 0.93, brightness: 1.0)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeService.textSecondaryColor)
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "F5F5F5"))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Particle Burst Test")
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                // Trigger button
                Button(action: {
                    trigger += 1
                }) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "FF5113"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Particle demo area
            ZStack {
                Color.white
                
                ParticleBurstView(
                    color: particleColor,
                    particleCount: Int(particleCount),
                    burstSpeed: CGFloat(burstSpeed),
                    particleLifetime: CGFloat(particleLifetime),
                    particleSize: CGFloat(particleSize),
                    spreadAngle: CGFloat(spreadAngle),
                    hasTrails: hasTrails,
                    gravity: CGFloat(gravity),
                    xDrift: CGFloat(xDrift),
                    particleRotation: CGFloat(particleRotation),
                    colorVariation: CGFloat(colorVariation),
                    speedVariation: CGFloat(speedVariation),
                    sizeVariation: CGFloat(sizeVariation),
                    fadeSpeed: CGFloat(fadeSpeed),
                    trigger: $trigger
                )
                
                // Center indicator
                Circle()
                    .fill(Color(hex: "FF5113"))
                    .frame(width: 50, height: 50)
                    .shadow(color: Color(hex: "FF5113").opacity(0.5), radius: 10)
                
                // Tap instruction
                VStack {
                    Text("Tap button or here to trigger")
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundColor(themeService.textSecondaryColor)
                    Spacer()
                }
                .padding(.top, 16)
            }
            .frame(height: 250)
            .clipped()
            .onTapGesture {
                trigger += 1
            }
            
            // Controls
            ScrollView {
                VStack(spacing: 12) {
                    // Particle Count
                    ParameterSlider(
                        title: "Particle Count",
                        value: $particleCount,
                        range: 50...500,
                        description: "Number of particles in burst"
                    )
                    
                    // Burst Speed
                    ParameterSlider(
                        title: "Burst Speed",
                        value: $burstSpeed,
                        range: 50...800,
                        description: "How fast particles radiate outward"
                    )
                    
                    // Particle Lifetime
                    ParameterSlider(
                        title: "Lifetime",
                        value: $particleLifetime,
                        range: 0.5...5,
                        description: "How long particles live"
                    )
                    
                    // Particle Size
                    ParameterSlider(
                        title: "Particle Size",
                        value: $particleSize,
                        range: 1...15,
                        description: "Size of each particle"
                    )
                    
                    // Spread Angle
                    ParameterSlider(
                        title: "Spread Angle",
                        value: $spreadAngle,
                        range: 30...360,
                        description: "Emission angle (360 = full circle)"
                    )
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Section: Physics
                    Text("Physics")
                        .font(.custom("Inter-Bold", size: 12))
                        .foregroundColor(themeService.textSecondaryColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    
                    // Gravity
                    ParameterSlider(
                        title: "Gravity",
                        value: $gravity,
                        range: -200...200,
                        description: "Vertical acceleration (negative = down)"
                    )
                    
                    // X Drift
                    ParameterSlider(
                        title: "X Drift",
                        value: $xDrift,
                        range: -200...200,
                        description: "Horizontal acceleration"
                    )
                    
                    // Particle Rotation
                    ParameterSlider(
                        title: "Rotation Speed",
                        value: $particleRotation,
                        range: -10...10,
                        description: "Particle spin speed (radians/sec)"
                    )
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Section: Variation
                    Text("Variation")
                        .font(.custom("Inter-Bold", size: 12))
                        .foregroundColor(themeService.textSecondaryColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    
                    // Speed Variation
                    ParameterSlider(
                        title: "Speed Variation",
                        value: $speedVariation,
                        range: 0...1,
                        description: "Randomness of particle speed"
                    )
                    
                    // Size Variation
                    ParameterSlider(
                        title: "Size Variation",
                        value: $sizeVariation,
                        range: 0...1,
                        description: "Randomness of particle size"
                    )
                    
                    // Color Variation
                    ParameterSlider(
                        title: "Color Variation",
                        value: $colorVariation,
                        range: 0...0.5,
                        description: "Randomness of particle color"
                    )
                    
                    // Fade Speed
                    ParameterSlider(
                        title: "Fade Speed",
                        value: $fadeSpeed,
                        range: 0.2...3,
                        description: "How fast particles fade (1 = normal)"
                    )
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Trails toggle
                    Toggle(isOn: $hasTrails) {
                        VStack(alignment: .leading) {
                            Text("Particle Trails")
                                .font(.custom("Inter-Medium", size: 14))
                                .foregroundColor(themeService.textPrimaryColor)
                            Text("Adds fading trail effect")
                                .font(.custom("Inter-Regular", size: 11))
                                .foregroundColor(Color(hex: "AAAAAA"))
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Color Hue
                    ParameterSlider(
                        title: "Color Hue",
                        value: $colorHue,
                        range: 0...1,
                        description: "Particle color"
                    )
                    
                    // Color preview - includes Sling orange (0.044)
                    HStack(spacing: 12) {
                        ForEach([0.0, 0.044, 0.15, 0.35, 0.55, 0.75], id: \.self) { hue in
                            Circle()
                                .fill(Color(hue: hue, saturation: 0.93, brightness: 1.0))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(abs(hue - colorHue) < 0.01 ? 0.3 : 0), lineWidth: 2)
                                )
                                .onTapGesture {
                                    colorHue = hue
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Reset button
                    Button(action: resetToDefaults) {
                        Text("Reset to Defaults")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(Color(hex: "FF5113"))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "FFF5F2"))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    
                    // Current values
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Values:")
                            .font(.custom("Inter-Bold", size: 12))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Text("count: \(Int(particleCount)), speed: \(Int(burstSpeed)), life: \(String(format: "%.1f", particleLifetime))s")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Text("size: \(String(format: "%.1f", particleSize)), angle: \(Int(spreadAngle))°, gravity: \(Int(gravity))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Text("rotation: \(String(format: "%.1f", particleRotation)), fade: \(String(format: "%.1f", fadeSpeed))x")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white)
    }
    
    private func resetToDefaults() {
        particleCount = 200
        burstSpeed = 300
        particleLifetime = 2.0
        particleSize = 4
        spreadAngle = 360
        hasTrails = true
        gravity = -50
        xDrift = 0
        particleRotation = 0
        colorVariation = 0.1
        speedVariation = 0.5
        sizeVariation = 0.5
        fadeSpeed = 1.0
        colorHue = 0.044
    }
}

// Slider component for parameter controls
struct ParameterSlider: View {
    @ObservedObject private var themeService = ThemeService.shared
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var description: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                Text(String(format: range.upperBound >= 10 ? "%.0f" : "%.2f", value))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(themeService.textSecondaryColor)
            }
            
            Slider(value: $value, in: range)
                .accentColor(Color(hex: "FF5113"))
            
            if !description.isEmpty {
                Text(description)
                    .font(.custom("Inter-Regular", size: 11))
                    .foregroundColor(Color(hex: "AAAAAA"))
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    ParticleTestView()
}
