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
                
                Spacer()
                
                // Card selection area - horizontal scroll
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
                    .padding(.vertical, 40)
                }
                
                Spacer()
                
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
    
    // Card dimensions - portrait orientation matching real card ratio
    private let cardWidth: CGFloat = 200
    private let cardHeight: CGFloat = 316
    private let cornerRadius: CGFloat = 20
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Card background with watermark
                ZStack {
                    // Base color
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color)
                    
                    // Concentric circle watermark (positioned to right side)
                    GeometryReader { geo in
                        ZStack {
                            // Large outer circle
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 12)
                                .frame(width: geo.size.width * 1.1, height: geo.size.width * 1.1)
                            
                            // Medium circle
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 10)
                                .frame(width: geo.size.width * 0.75, height: geo.size.width * 0.75)
                            
                            // Inner circle
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 8)
                                .frame(width: geo.size.width * 0.45, height: geo.size.width * 0.45)
                        }
                        .position(x: geo.size.width * 0.65, y: geo.size.height * 0.45)
                    }
                    .clipped()
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 16)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 8)
                
                // Card content overlay
                VStack(alignment: .leading) {
                    // Sling logo at top left
                    SlingLogoMark(size: 32)
                        .padding(.top, 20)
                        .padding(.leading, 20)
                    
                    Spacer()
                    
                    // Bottom section: card number and Visa logo
                    HStack(alignment: .bottom) {
                        // Card number
                        HStack(spacing: 4) {
                            Text("••••")
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(.white.opacity(0.7))
                            Text("9543")
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // Visa logo
                        Image("VisaLogo")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 24)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
                
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius + 2)
                        .stroke(Color(hex: "FF5113"), lineWidth: 3)
                        .frame(width: cardWidth + 6, height: cardHeight + 6)
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
                .stroke(Color.white, lineWidth: size * 0.1)
                .frame(width: size, height: size)
            
            // Inner ring
            Circle()
                .stroke(Color.white, lineWidth: size * 0.1)
                .frame(width: size * 0.66, height: size * 0.66)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Visa Logo Vertical

struct VisaLogoVertical: View {
    var body: some View {
        Image("VisaLogo")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.white.opacity(0.8))
            .rotationEffect(.degrees(-90))
    }
}

#Preview {
    CardStyleSelectionView(isPresented: .constant(true))
}
