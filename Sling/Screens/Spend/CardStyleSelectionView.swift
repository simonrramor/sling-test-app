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
    
    // Card dimensions - landscape orientation matching Figma and new reference
    // Figma width: 345, height: 196 (ratio 1.76)
    // We'll scale slightly for mobile screens
    private let cardWidth: CGFloat = 320
    private let cardHeight: CGFloat = 182 // 320 / 1.76
    private let cornerRadius: CGFloat = 24
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Card background with watermark
                ZStack {
                    // Base color
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color)
                    
                    // Sling Logo Watermark
                    // Figma: 218x218 on 345x196 card. Centered horizontally, slightly up vertically.
                    // Scale factor: 320/345 = 0.927 -> Watermark size ~202
                    GeometryReader { geo in
                        SlingLogoMark(size: 202)
                            .opacity(0.08) // 8% white opacity from Figma
                            .position(x: geo.size.width / 2, y: geo.size.height / 2 - 8)
                    }
                    .clipped()
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 16)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
                
                // Card content overlay
                VStack(alignment: .leading) {
                    // Sling logo at top left
                    SlingLogoMark(size: 32)
                        .padding(.top, 20)
                        .padding(.leading, 20)
                    
                    Spacer()
                    
                    // Bottom section: card number and Visa logo
                    HStack(alignment: .center) {
                        // Card number
                        HStack(spacing: 6) {
                            // Dots (custom drawing to match Figma "Card number dots")
                            HStack(spacing: 4) {
                                ForEach(0..<4) { _ in
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
                            .frame(width: 58, height: 19) // Approx scale from 72x24
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
                
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius + 4)
                        .stroke(Color(hex: "FF5113"), lineWidth: 3)
                        .frame(width: cardWidth + 10, height: cardHeight + 10)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
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
                .frame(width: size * 0.62, height: size * 0.62)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    CardStyleSelectionView(isPresented: .constant(true))
}
