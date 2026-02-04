import SwiftUI

struct CardColorOption: Identifiable {
    let id: String
    let color: Color
    
    static let allOptions: [CardColorOption] = [
        CardColorOption(id: "orange", color: Color(hex: "FF5113")),
        CardColorOption(id: "blue", color: Color(hex: "0887DC")),
        CardColorOption(id: "green", color: Color(hex: "34C759")),
        CardColorOption(id: "purple", color: Color(hex: "AF52DE")),
        CardColorOption(id: "pink", color: Color(hex: "FF2D55")),
        CardColorOption(id: "teal", color: Color(hex: "5AC8FA")),
        CardColorOption(id: "indigo", color: Color(hex: "5856D6")),
        CardColorOption(id: "black", color: Color(hex: "1C1C1E"))
    ]
}

struct CardStyleSelectionView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @AppStorage("hasCard") private var hasCard = false
    @AppStorage("selectedCardStyle") private var selectedCardStyle = "orange"
    
    @State private var selectedStyle: String = "orange"
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with X close button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .frame(width: 24, height: 24)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .frame(height: 64)
                
                // Card selection area - horizontal scroll (fills available space)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(CardColorOption.allOptions) { option in
                            CardStyleOption(
                                color: option.color,
                                isSelected: selectedStyle == option.id,
                                onTap: {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    selectedStyle = option.id
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
                
                // Pick card button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    selectedCardStyle = selectedStyle
                    hasCard = true
                    isPresented = false
                    // Navigate to card tab
                    NotificationCenter.default.post(name: .navigateToCard, object: nil)
                }) {
                    Text("Pick card")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "FF5113"))
                        .cornerRadius(20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Card Style Option

struct CardStyleOption: View {
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    // Card dimensions - landscape orientation matching real card ratio (1035:648 = 1.597)
    private let cardWidth: CGFloat = 311
    private let cardHeight: CGFloat = 195
    private let cornerRadius: CGFloat = 24
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Card content container
                ZStack {
                    // Base color
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color)
                    
                    // Background circles watermark - matching real card
                    // Original card: 1035x648, circles at 654px and 435px with 18px stroke
                    // Scale: 311/1035 = 0.30
                    CardWatermarkCircles()
                    
                    // Subtle border stroke
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: Color.black.opacity(0.25), radius: 22, x: 0, y: 24)
                .shadow(color: Color.black.opacity(0.15), radius: 11, x: 0, y: 12)
                
                // Card content overlay
                VStack(alignment: .leading) {
                    // Sling logo at top left
                    SlingLogoMark(size: 32)
                        .padding(.top, 16)
                        .padding(.leading, 16)
                    
                    Spacer()
                    
                    // Bottom section: card number and Visa logo
                    HStack(alignment: .center) {
                        // Card number
                        HStack(spacing: 6) {
                            // Dots
                            HStack(spacing: 3) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: 4, height: 4)
                                }
                            }
                            
                            Text("9543")
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(-0.32)
                        }
                        
                        Spacer()
                        
                        // Visa logo
                        Image("VisaLogo")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 58, height: 19)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
                
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius + 4)
                        .stroke(color, lineWidth: 3)
                        .frame(width: cardWidth + 10, height: cardHeight + 10)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Card Watermark Circles (matches real Sling card)

struct CardWatermarkCircles: View {
    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / 1035.0
            
            // Large circle: 654px diameter, positioned center-right
            // Original position: x = 189 from right edge, y = -33 from top
            let largeSize = 654 * scale
            let largeX = geo.size.width - (189 * scale) - (largeSize / 2)
            let largeY = (-33 * scale) + (largeSize / 2)
            
            // Small circle: 435px diameter
            // Original position: x = 300 from right edge, y = 78 from top
            let smallSize = 435 * scale
            let smallX = geo.size.width - (300 * scale) - (smallSize / 2)
            let smallY = (78 * scale) + (smallSize / 2)
            
            let strokeWidth = 18 * scale
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: strokeWidth)
                    .frame(width: largeSize, height: largeSize)
                    .position(x: largeX, y: largeY)
                
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: strokeWidth)
                    .frame(width: smallSize, height: smallSize)
                    .position(x: smallX, y: smallY)
            }
        }
        .clipped()
    }
}

// MARK: - Sling Logo Mark

struct SlingLogoMark: View {
    var size: CGFloat = 24
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.white, lineWidth: size * 0.12)
                .frame(width: size, height: size)
            
            // Inner ring
            Circle()
                .stroke(Color.white, lineWidth: size * 0.12)
                .frame(width: size * 0.667, height: size * 0.667)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    CardStyleSelectionView(isPresented: .constant(true))
}
