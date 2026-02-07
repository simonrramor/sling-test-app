import SwiftUI

// #region agent log
private func debugLog(_ location: String, _ message: String, _ data: [String: Any] = [:]) {
    let logPath = "/Users/simonamor/Desktop/sling-test-app-2/.cursor/debug.log"
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let logData: [String: Any] = [
        "timestamp": timestamp,
        "location": location,
        "message": message,
        "data": data,
        "sessionId": "debug-session",
        "hypothesisId": "H1-H4"
    ]
    if let jsonData = try? JSONSerialization.data(withJSONObject: logData),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        if let fileHandle = FileHandle(forWritingAtPath: logPath) {
            fileHandle.seekToEndOfFile()
            fileHandle.write((jsonString + "\n").data(using: .utf8)!)
            fileHandle.closeFile()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: (jsonString + "\n").data(using: .utf8))
        }
    }
}
// #endregion

// MARK: - Card Background Types

enum CardBackgroundType {
    case color(Color)
    /// Image background with horizontal and vertical variants
    /// - horizontal: Asset name for landscape orientation (690x432 recommended)
    /// - vertical: Asset name for portrait orientation (432x690 recommended)
    case image(horizontal: String, vertical: String)
}

struct CardBackgroundOption: Identifiable {
    let id: String
    let type: CardBackgroundType
    /// Creative display name for the card style
    let displayName: String
    /// Custom accent color for image backgrounds (used for "Select card" button, etc.)
    private let customAccentColor: Color?
    
    init(id: String, type: CardBackgroundType, displayName: String, accentColor: Color? = nil) {
        self.id = id
        self.type = type
        self.displayName = displayName
        self.customAccentColor = accentColor
    }
    
    /// Returns the accent color for this background (used for button tints, etc.)
    var accentColor: Color {
        // Use custom accent if provided
        if let custom = customAccentColor {
            return custom
        }
        // For colors, use the color itself
        switch type {
        case .color(let color):
            return color
        case .image:
            // Default accent color for image backgrounds
            return Color(hex: "FF5113")
        }
    }
    
    /// Returns the color if this is a color-based background, nil otherwise
    var color: Color? {
        if case .color(let color) = type {
            return color
        }
        return nil
    }
    
    /// Returns the horizontal image name if this is an image-based background, nil otherwise
    var horizontalImageName: String? {
        if case .image(let horizontal, _) = type {
            return horizontal
        }
        return nil
    }
    
    /// Returns the vertical image name if this is an image-based background, nil otherwise
    var verticalImageName: String? {
        if case .image(_, let vertical) = type {
            return vertical
        }
        return nil
    }
    
    /// Returns the appropriate image name for the given orientation
    func imageName(isVertical: Bool) -> String? {
        if case .image(let horizontal, let vertical) = type {
            return isVertical ? vertical : horizontal
        }
        return nil
    }
    
    /// Legacy property - returns horizontal image name for backward compatibility
    var imageName: String? {
        horizontalImageName
    }
    
    /// Check if this is an image-based background
    var isImage: Bool {
        if case .image = type {
            return true
        }
        return false
    }
    
    static let allOptions: [CardBackgroundOption] = [
        // ═══════════════════════════════════════════════════════════════
        // SLING ORANGE (default)
        // ═══════════════════════════════════════════════════════════════
        CardBackgroundOption(id: "orange", type: .color(Color(hex: "FF5113")), displayName: "Sling Orange"),
        
        // ═══════════════════════════════════════════════════════════════
        // ARTIST CARDS
        // Each image option requires two assets:
        // - Horizontal: for landscape card display (690x432 recommended)
        // - Vertical: for portrait card display in selection carousel (432x690 recommended)
        // ═══════════════════════════════════════════════════════════════
        CardBackgroundOption(
            id: "art",
            type: .image(horizontal: "CardBgArt", vertical: "CardBgArtVertical"),
            displayName: "Tania Baca Alvarado",
            accentColor: Color(hex: "E85D4C")
        ),
        CardBackgroundOption(
            id: "art-hilda",
            type: .image(horizontal: "CardBgHilda", vertical: "CardBgHildaVertical"),
            displayName: "Hilda Palafox",
            accentColor: Color(hex: "1E3A5F")
        ),
        CardBackgroundOption(
            id: "art-yollotl",
            type: .image(horizontal: "CardBgYollotl", vertical: "CardBgYollotlVertical"),
            displayName: "Yollotl Gómez Alvarado",
            accentColor: Color(hex: "9B4DCA")
        ),
        
        // ═══════════════════════════════════════════════════════════════
        // SOLID COLOR OPTIONS
        // ═══════════════════════════════════════════════════════════════
        CardBackgroundOption(id: "blue", type: .color(Color(hex: "0887DC")), displayName: "Ocean Wave"),
        CardBackgroundOption(id: "green", type: .color(Color(hex: "34C759")), displayName: "Spring Meadow"),
        CardBackgroundOption(id: "purple", type: .color(Color(hex: "AF52DE")), displayName: "Lavender Dream"),
        CardBackgroundOption(id: "pink", type: .color(Color(hex: "FF2D55")), displayName: "Rose Petal"),
        CardBackgroundOption(id: "teal", type: .color(Color(hex: "5AC8FA")), displayName: "Arctic Sky"),
        CardBackgroundOption(id: "indigo", type: .color(Color(hex: "5856D6")), displayName: "Midnight Iris"),
        CardBackgroundOption(id: "black", type: .color(Color(hex: "1C1C1E")), displayName: "Obsidian"),
    ]
    
    /// Helper to get a CardBackgroundOption by id
    static func option(for id: String) -> CardBackgroundOption? {
        allOptions.first { $0.id == id }
    }
}

// Legacy alias for backward compatibility
typealias CardColorOption = CardBackgroundOption

// MARK: - Hero Transition Overlay (used from SpendView)

struct CardStyleSelectionOverlay: View {
    @Binding var isPresented: Bool
    @Binding var heroAnimationState: HeroAnimationState
    
    @ObservedObject private var themeService = ThemeService.shared
    @AppStorage("hasCard") private var hasCard = false
    @AppStorage("selectedCardStyle") private var selectedCardStyle = "orange"
    @State private var currentSelection: String = "orange"
    @State private var hasAppeared = false
    
    // First card hidden while floating card is animating
    private var isHeroCardVisible: Bool {
        heroAnimationState == .inOverlay || heroAnimationState == .idle
    }
    
    // Get accent color for current selection (for button background)
    private var currentSelectionColor: Color {
        CardBackgroundOption.option(for: currentSelection)?.accentColor ?? Color(hex: "FF5113")
    }
    
    // Get the current background option
    private var currentBackgroundOption: CardBackgroundOption? {
        CardBackgroundOption.option(for: currentSelection)
    }
    
    // Get display name for current selection
    private var currentDisplayName: String {
        CardBackgroundOption.option(for: currentSelection)?.displayName ?? "Card"
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header with X close button - fades in
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        heroAnimationState = .animatingBack
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .frame(width: 24, height: 24)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .frame(height: 44)
                .opacity(hasAppeared ? 1 : 0)
                
                Spacer()
                
                // Card style title - changes based on selection
                Text(currentDisplayName)
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundColor(Color(hex: "1C1C1E"))
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.2), value: currentSelection)
                    .padding(.bottom, 24)
                
                // Card selection area - horizontal scroll (centered vertically)
                GeometryReader { outerGeometry in
                    let cardDisplayWidth: CGFloat = 195
                    let horizontalInset = (outerGeometry.size.width - cardDisplayWidth) / 2
                    let screenCenter = outerGeometry.size.width / 2
                    
                    ScrollViewReader { scrollProxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(CardBackgroundOption.allOptions.enumerated()), id: \.element.id) { index, option in
                                    GeometryReader { cardGeometry in
                                        let cardCenter = cardGeometry.frame(in: .global).midX
                                        let distanceFromCenter = abs(screenCenter - cardCenter)
                                        let maxDistance: CGFloat = 200
                                        let normalizedDistance = min(distanceFromCenter / maxDistance, 1.0)
                                        let scale = 1.0 - (normalizedDistance * 0.1)
                                        let isClosestToCenter = distanceFromCenter < 50
                                        
                                        // First card (orange) - hidden while floating hero card animates
                                        if index == 0 {
                                            CardStyleOption(
                                                backgroundType: option.type,
                                                isSelected: currentSelection == option.id,
                                                onTap: {
                                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                                    generator.impactOccurred()
                                                    currentSelection = option.id
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                                        scrollProxy.scrollTo(option.id, anchor: .center)
                                                    }
                                                }
                                            )
                                            .scaleEffect(scale)
                                            .opacity(isHeroCardVisible ? 1 : 0)
                                            .animation(.easeOut(duration: 0.15), value: scale)
                                            .onChange(of: isClosestToCenter) { _, newValue in
                                                if newValue && currentSelection != option.id {
                                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                                    generator.impactOccurred()
                                                    currentSelection = option.id
                                                }
                                            }
                                        } else {
                                            // Other cards slide in from right with staggered delay
                                            CardStyleOption(
                                                backgroundType: option.type,
                                                isSelected: currentSelection == option.id,
                                                onTap: {
                                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                                    generator.impactOccurred()
                                                    currentSelection = option.id
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                                        scrollProxy.scrollTo(option.id, anchor: .center)
                                                    }
                                                }
                                            )
                                            .scaleEffect(scale)
                                            .offset(x: hasAppeared ? 0 : 400)
                                            .opacity(hasAppeared ? 1 : 0)
                                            .animation(
                                                .spring(response: 0.5, dampingFraction: 0.8)
                                                .delay(Double(index) * 0.03),
                                                value: hasAppeared
                                            )
                                            .animation(.easeOut(duration: 0.15), value: scale)
                                            .onChange(of: isClosestToCenter) { _, newValue in
                                                if newValue && currentSelection != option.id {
                                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                                    generator.impactOccurred()
                                                    currentSelection = option.id
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: cardDisplayWidth, height: 311)
                                    .id(option.id)
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, horizontalInset)
                            .padding(.vertical, 40) // Space for card shadows
                        }
                        .scrollTargetBehavior(.viewAligned)
                    }
                }
                .frame(height: 400)
                
                Spacer()
                
                // Select card button - slides up from bottom
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    selectedCardStyle = currentSelection
                    hasCard = true
                    heroAnimationState = .animatingBack
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
                .padding(.bottom, 24)
                .offset(y: hasAppeared ? 0 : 100)
                .opacity(hasAppeared ? 1 : 0)
            }
        }
        .onAppear {
            // #region agent log
            debugLog("CardStyleSelectionOverlay:onAppear", "Overlay appeared", ["hasAppeared": hasAppeared])
            // #endregion
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                hasAppeared = true
                // #region agent log
                debugLog("CardStyleSelectionOverlay:onAppear", "Set hasAppeared to true", ["hasAppeared": true])
                // #endregion
            }
        }
    }
}

// MARK: - Hero Card (with matchedGeometryEffect for the orange card)
// Note: Color cards are drawn landscape and rotated 90°.
// Image cards use the vertical image directly in portrait orientation.

struct CardStyleOptionHero: View {
    let backgroundType: CardBackgroundType
    var cardTransition: Namespace.ID
    var isSelected: Bool = false
    var effectType: ShaderEffectType = .shimmer
    let onTap: () -> Void
    
    // Card dimensions for landscape (color cards)
    private let landscapeWidth: CGFloat = 311
    private let landscapeHeight: CGFloat = 195
    
    // Card dimensions for portrait (image cards)
    private let portraitWidth: CGFloat = 195
    private let portraitHeight: CGFloat = 311
    
    private let cornerRadius: CGFloat = 24
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                switch backgroundType {
                case .color(let color):
                    // Color cards: draw landscape, then rotate 90°
                    colorCardContent(color: color)
                        .frame(width: landscapeWidth, height: landscapeHeight)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .applyShaderEffect(isActive: isSelected, effectType: effectType)
                        .rotationEffect(.degrees(90))
                        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 8)
                    
                case .image(_, let verticalImageName):
                    // Image cards: draw directly in portrait orientation
                    imageCardContent(imageName: verticalImageName)
                        .frame(width: portraitWidth, height: portraitHeight)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .applyShaderEffect(isActive: isSelected, effectType: effectType)
                        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 8)
                }
            }
            .frame(width: portraitWidth, height: portraitHeight)
            .matchedGeometryEffect(id: "heroCard", in: cardTransition)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func colorCardContent(color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color)
            
            Image("SlingLogo")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: landscapeWidth * 0.73)
                .foregroundColor(Color.white.opacity(0.08))
            
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
    }
    
    @ViewBuilder
    private func imageCardContent(imageName: String) -> some View {
        ZStack {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: portraitWidth, height: portraitHeight)
                .clipped()
            
            VStack {
                HStack {
                    Spacer()
                    Image("SlingLogo")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                }
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Image("VisaLogo")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 24)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.leading, 16)
                        .padding(.bottom, 16)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Original CardStyleSelectionView (for fullScreenCover fallback)

struct CardStyleSelectionView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @AppStorage("hasCard") private var hasCard = false
    @AppStorage("selectedCardStyle") private var selectedCardStyle = "orange"
    @State private var currentSelection: String = "orange"
    
    // Get accent color for current selection (for button background)
    private var currentSelectionColor: Color {
        CardBackgroundOption.option(for: currentSelection)?.accentColor ?? Color(hex: "FF5113")
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)
            
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
                .padding(.top, 8)
                .frame(height: 44)
                
                // Card selection area - horizontal scroll (fills available space)
                GeometryReader { outerGeometry in
                    let cardDisplayWidth: CGFloat = 195 // Card height after rotation becomes width
                    let horizontalInset = (outerGeometry.size.width - cardDisplayWidth) / 2
                    let screenCenter = outerGeometry.size.width / 2
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(CardBackgroundOption.allOptions) { option in
                                GeometryReader { cardGeometry in
                                    let cardCenter = cardGeometry.frame(in: .global).midX
                                    let distanceFromCenter = abs(screenCenter - cardCenter)
                                    let maxDistance: CGFloat = 200
                                    let normalizedDistance = min(distanceFromCenter / maxDistance, 1.0)
                                    let scale = 1.0 - (normalizedDistance * 0.1) // 100% at center, 90% at edges
                                    let isClosestToCenter = distanceFromCenter < 50
                                    
                                    CardStyleOption(
                                        backgroundType: option.type,
                                        isSelected: currentSelection == option.id,
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
                
                Spacer()
                
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
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Card Style Option (uses same styling as SwiftUICardView)
// Note: Color cards are drawn landscape and rotated 90°.
// Image cards use the vertical image directly in portrait orientation (no rotation needed).

struct CardStyleOption: View {
    let backgroundType: CardBackgroundType
    var isSelected: Bool = false
    var effectType: ShaderEffectType = .shimmer
    let onTap: () -> Void
    
    // Card dimensions for landscape (color cards) - ratio 690x432 = 1.597:1
    private let landscapeWidth: CGFloat = 311
    private let landscapeHeight: CGFloat = 195
    
    // Card dimensions for portrait (image cards) - swapped for vertical display
    private let portraitWidth: CGFloat = 195
    private let portraitHeight: CGFloat = 311
    
    private let cornerRadius: CGFloat = 24
    
    /// Helper to check if this is an image background
    private var isImageBackground: Bool {
        if case .image = backgroundType {
            return true
        }
        return false
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Different layout for color vs image backgrounds
                switch backgroundType {
                case .color(let color):
                    // Color cards: draw landscape, then rotate 90°
                    colorCardContent(color: color)
                        .frame(width: landscapeWidth, height: landscapeHeight)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .applyShaderEffect(isActive: isSelected, effectType: effectType)
                        .rotationEffect(.degrees(90))
                        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 8)
                    
                case .image(_, let verticalImageName):
                    // Image cards: draw directly in portrait orientation (no rotation)
                    imageCardContent(imageName: verticalImageName)
                        .frame(width: portraitWidth, height: portraitHeight)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .applyShaderEffect(isActive: isSelected, effectType: effectType)
                        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 8)
                }
            }
            // Both end up with the same display dimensions
            .frame(width: portraitWidth, height: portraitHeight)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Color Card Content (landscape, will be rotated)
    @ViewBuilder
    private func colorCardContent(color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color)
            
            // Sling logo watermark - centered
            Image("SlingLogo")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: landscapeWidth * 0.73)
                .foregroundColor(Color.white.opacity(0.08))
            
            // Small Sling logo - top left
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
            
            // VISA logo - bottom right
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
    }
    
    // MARK: - Image Card Content (portrait, no rotation needed)
    @ViewBuilder
    private func imageCardContent(imageName: String) -> some View {
        ZStack {
            // Background image
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: portraitWidth, height: portraitHeight)
                .clipped()
            
            // Small Sling logo - top right (portrait orientation)
            VStack {
                HStack {
                    Spacer()
                    Image("SlingLogo")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                }
                Spacer()
            }
            
            // VISA logo - bottom left (portrait orientation)
            VStack {
                Spacer()
                HStack {
                    Image("VisaLogo")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 24)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.leading, 16)
                        .padding(.bottom, 16)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    CardStyleSelectionView(isPresented: .constant(true))
}
