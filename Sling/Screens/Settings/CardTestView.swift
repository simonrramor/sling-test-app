import SwiftUI

struct CardTestView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    
    // 3D rotation state
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var isDragging = false
    
    // Color slider state (hue value 0-1)
    @State private var hueValue: Double = 0
    @State private var saturation: Double = 0  // 0 = grey, 1 = full color
    
    // Card dimensions (690x432 ratio = 1.597:1)
    private let cardAspectRatio: CGFloat = 690.0 / 432.0
    
    // Computed card color from hue slider
    private var cardColor: Color {
        Color(hue: hueValue, saturation: saturation, brightness: 0.9)
    }
    
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
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Card Test")
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // 3D Card - near top
                GeometryReader { geometry in
                    let cardWidth = min(geometry.size.width - 48, 345)
                    let cardHeight = cardWidth / cardAspectRatio
                    
                    VStack {
                        Spacer()
                            .frame(height: 40)
                        
                        ZStack {
                            // Card rectangle with dynamic color
                            RoundedRectangle(cornerRadius: 24)
                                .fill(cardColor)
                                .frame(width: cardWidth, height: cardHeight)
                            
                            // Sling logo watermark - centered, scaled up
                            Image("SlingLogo")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: cardWidth * 0.73)
                                .foregroundColor(Color.white.opacity(0.08))
                            
                            // Small Sling logo - top left, 16px from edges
                            VStack {
                                HStack {
                                    Image("SlingLogo")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(.white)
                                        .padding(.leading, 16)
                                        .padding(.top, 16)
                                    Spacer()
                                }
                                Spacer()
                            }
                            
                            // Bottom row: card number (left) and VISA logo (right)
                            VStack {
                                Spacer()
                                HStack {
                                    // Card number - bottom left
                                    Text("•••• 9543")
                                        .font(.custom("Inter-Medium", size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.leading, 16)
                                        .padding(.bottom, 16)
                                    
                                    Spacer()
                                    
                                    // VISA logo - bottom right
                                    Image("VisaLogo")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 72, height: 24)
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.trailing, 16)
                                        .padding(.bottom, 16)
                                }
                            }
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(
                            color: Color.black.opacity(0.12),
                            radius: 24,
                            x: 0,
                            y: 8
                        )
                        .rotation3DEffect(
                            .degrees(rotationX),
                            axis: (x: 1, y: 0, z: 0),
                            perspective: 0.5
                        )
                        .rotation3DEffect(
                            .degrees(rotationY),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.5
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    let sensitivity: Double = 0.2
                                    rotationY = value.translation.width * sensitivity
                                    rotationX = -value.translation.height * sensitivity
                                    rotationX = max(-15, min(15, rotationX))
                                    rotationY = max(-15, min(15, rotationY))
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        rotationX = 0
                                        rotationY = 0
                                    }
                                }
                        )
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Color controls
                VStack(spacing: 24) {
                    // Hue slider with rainbow gradient
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        ZStack(alignment: .leading) {
                            // Rainbow gradient background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hue: 0.0, saturation: saturation, brightness: 0.9),
                                            Color(hue: 0.1, saturation: saturation, brightness: 0.9),
                                            Color(hue: 0.2, saturation: saturation, brightness: 0.9),
                                            Color(hue: 0.3, saturation: saturation, brightness: 0.9),
                                            Color(hue: 0.4, saturation: saturation, brightness: 0.9),
                                            Color(hue: 0.5, saturation: saturation, brightness: 0.9),
                                            Color(hue: 0.6, saturation: saturation, brightness: 0.9),
                                            Color(hue: 0.7, saturation: saturation, brightness: 0.9),
                                            Color(hue: 0.8, saturation: saturation, brightness: 0.9),
                                            Color(hue: 0.9, saturation: saturation, brightness: 0.9),
                                            Color(hue: 1.0, saturation: saturation, brightness: 0.9)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 32)
                            
                            // Slider
                            Slider(value: $hueValue, in: 0...1)
                                .accentColor(.clear)
                                .frame(height: 32)
                        }
                    }
                    
                    // Saturation slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saturation")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        ZStack(alignment: .leading) {
                            // Grey to color gradient
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hue: hueValue, saturation: 0, brightness: 0.9),
                                            Color(hue: hueValue, saturation: 1, brightness: 0.9)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 32)
                            
                            Slider(value: $saturation, in: 0...1)
                                .accentColor(.clear)
                                .frame(height: 32)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    CardTestView(isPresented: .constant(true))
}
