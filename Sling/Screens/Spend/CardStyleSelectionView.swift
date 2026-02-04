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
                                onTap: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    selectedCardStyle = option.id
                                    hasCard = true
                                    isPresented = false
                                    NotificationCenter.default.post(name: .navigateToCard, object: nil)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
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
                    
                    // Sling logo in top left corner
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
                    }
                    
                    // Border stroke
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: Color.black.opacity(0.25), radius: 22, x: 0, y: 24)
                .shadow(color: Color.black.opacity(0.15), radius: 11, x: 0, y: 12)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CardStyleSelectionView(isPresented: .constant(true))
}
