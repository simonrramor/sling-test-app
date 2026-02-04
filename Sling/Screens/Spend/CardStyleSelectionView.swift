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
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 24)
                    .fill(color)
                    .frame(width: 140, height: 245)
                    .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 24)
                    .shadow(color: Color.black.opacity(0.15), radius: 22, x: 0, y: 12)
                
                // Card content
                VStack {
                    // Sling logo at top left
                    HStack {
                        SlingLogoMark()
                            .frame(width: 24, height: 24)
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    // Visa logo at bottom right
                    HStack {
                        Spacer()
                        VisaLogoVertical()
                            .frame(width: 18, height: 54)
                    }
                    .padding(.bottom, 16)
                    .padding(.trailing, 16)
                }
                .frame(width: 140, height: 245)
                
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "FF5113"), lineWidth: 3)
                        .frame(width: 146, height: 251)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sling Logo Mark

struct SlingLogoMark: View {
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.white, lineWidth: 2.5)
                .frame(width: 24, height: 24)
            
            // Inner ring
            Circle()
                .stroke(Color.white, lineWidth: 2.5)
                .frame(width: 16, height: 16)
        }
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
