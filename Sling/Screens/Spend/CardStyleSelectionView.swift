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
    
    // Get color for current selection
    private var currentSelectionColor: Color {
        CardColorOption.allOptions.first { $0.id == currentSelection }?.color ?? Color(hex: "FF5113")
    }
    
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
                        .scrollTargetLayout()
                        .padding(.horizontal, horizontalInset)
                        .frame(maxHeight: .infinity)
                    }
                    .scrollTargetBehavior(.viewAligned)
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
                        .background(currentSelectionColor)
                        .cornerRadius(20)
                }
                .animation(.easeOut(duration: 0.2), value: currentSelection)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Card Style Option (uses same styling as SwiftUICardView)

struct CardStyleOption: View {
    let color: Color
    let onTap: () -> Void
    
    // Card dimensions (same ratio as SwiftUICardView: 690x432 = 1.597:1)
    private let cardWidth: CGFloat = 311
    private let cardHeight: CGFloat = 195
    private let cornerRadius: CGFloat = 24
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                ZStack {
                    // Base color
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color)
                    
                    // Sling logo watermark - centered (same as SwiftUICardView)
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
                    
                    // VISA logo - bottom right, 16px from edges (no card number)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
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
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .rotationEffect(.degrees(90))
                .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 8)
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
