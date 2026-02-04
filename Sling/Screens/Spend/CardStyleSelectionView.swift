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
    @State private var currentSelection: String = "orange"
    
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
                GeometryReader { outerGeometry in
                    let cardDisplayWidth: CGFloat = 195 // Card height after rotation becomes width
                    let horizontalInset = (outerGeometry.size.width - cardDisplayWidth) / 2
                    let screenCenter = outerGeometry.size.width / 2
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(CardColorOption.allOptions) { option in
                                GeometryReader { cardGeometry in
                                    let cardCenter = cardGeometry.frame(in: .global).midX
                                    let distanceFromCenter = abs(screenCenter - cardCenter)
                                    let maxDistance: CGFloat = 200
                                    let normalizedDistance = min(distanceFromCenter / maxDistance, 1.0)
                                    let scale = 1.0 - (normalizedDistance * 0.1) // 100% at center, 90% at edges
                                    let isClosestToCenter = distanceFromCenter < 50
                                    
                                    CardStyleOption(
                                        color: option.color,
                                        onTap: {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                            currentSelection = option.id
                                        }
                                    )
                                    .scaleEffect(scale)
                                    .animation(.easeOut(duration: 0.15), value: scale)
                                    .onChange(of: isClosestToCenter) { _, newValue in
                                        if newValue && currentSelection != option.id {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                            currentSelection = option.id
                                        }
                                    }
                                }
                                .frame(width: cardDisplayWidth, height: 311)
                            }
                        }
                        .padding(.horizontal, horizontalInset)
                        .frame(maxHeight: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Select card button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    selectedCardStyle = currentSelection
                    hasCard = true
                    isPresented = false
                    NotificationCenter.default.post(name: .navigateToCard, object: nil)
                }) {
                    Text("Select card")
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
    let onTap: () -> Void
    
    // Card dimensions
    private let cardWidth: CGFloat = 311
    private let cardHeight: CGFloat = 195
    private let cornerRadius: CGFloat = 24
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                ZStack {
                    // Base color
                    color
                    
                    // Background watermark logo (SlingLogoBg asset - 8% opacity filled logo)
                    Image("SlingLogoBg")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                    
                    // Sling logo in top left, Visa logo in bottom right
                    VStack {
                        HStack {
                            Image("SlingLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .padding(.top, 16)
                                .padding(.leading, 16)
                            Spacer()
                        }
                        Spacer()
                        HStack {
                            Spacer()
                            Image("VisaLogo")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 58, height: 19)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.bottom, 16)
                                .padding(.trailing, 16)
                        }
                    }
                    
                    // Border stroke
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .rotationEffect(.degrees(90))
                .shadow(color: Color.black.opacity(0.25), radius: 22, x: 0, y: 24)
                .shadow(color: Color.black.opacity(0.15), radius: 11, x: 0, y: 12)
            }
            // Account for rotated dimensions in layout
            .frame(width: cardHeight, height: cardWidth)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CardStyleSelectionView(isPresented: .constant(true))
}
