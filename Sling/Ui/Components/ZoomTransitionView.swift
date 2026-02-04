import SwiftUI

/// Menu option for the zoom transition
enum ZoomMenuOption: String, CaseIterable, Identifiable {
    case send = "Send"
    case request = "Request"
    case transfer = "Transfer"
    case receiveSalary = "Receive your salary"
    
    var id: String { rawValue }
    
    var subtitle: String {
        switch self {
        case .send: return "Pay anyone on Sling in seconds"
        case .request: return "Ask someone to pay you back"
        case .transfer: return "Move money between accounts"
        case .receiveSalary: return "Get paid into Sling"
        }
    }
    
    var iconName: String {
        switch self {
        case .send: return "TransferSend"
        case .request: return "TransferRequest"
        case .transfer: return "TransferTransfer"
        case .receiveSalary: return "TransferSalary"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .send: return Color(hex: "5FB0DB")
        case .request: return Color(hex: "5DB468")
        case .transfer: return Color(hex: "DB61C0")
        case .receiveSalary: return Color(hex: "080808")
        }
    }
}

/// A simple morph transition view that animates between a circle and a rectangle
struct ZoomTransitionView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @State private var isExpanded = false
    @State private var isPressed = false
    
    // Action callback when a menu option is selected
    var onAction: ((ZoomMenuOption) -> Void)?
    
    // Animated properties (3 menu options: send, request, receive salary)
    private var height: CGFloat { isExpanded ? 240 : DesignSystem.Button.height }
    private var cornerRadius: CGFloat { isExpanded ? DesignSystem.CornerRadius.extraLarge : DesignSystem.CornerRadius.pill }
    
    // Scale for pressed state using DesignSystem constant
    private var buttonScale: CGFloat { (!isExpanded && isPressed) ? DesignSystem.Animation.pressedScale : 1.0 }
    
    private func width(in screenWidth: CGFloat) -> CGFloat {
        let expandedWidth = screenWidth - DesignSystem.Spacing.xl // 16px margin on each side
        return isExpanded ? max(expandedWidth, DesignSystem.Button.height) : DesignSystem.Button.height
    }
    
    private func xOffset(in screenWidth: CGFloat) -> CGFloat {
        // When collapsed: position at right side with 24px margin
        // When expanded: center the card (24px from each edge)
        let cardWidth = width(in: screenWidth)
        let collapsedX = screenWidth - cardWidth - DesignSystem.Spacing.lg // 24px from right
        let expandedX = DesignSystem.Spacing.lg // 24px from left
        return isExpanded ? expandedX : collapsedX
    }
    
    var body: some View {
        ZStack {
            // Dimmed background overlay - tap to close (full screen)
            if isExpanded {
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                            isExpanded = false
                        }
                    }
            }
            
            // Position card at bottom using VStack layout (matches BottomNavView)
            VStack {
                Spacer()
                
                GeometryReader { geometry in
                    // The morphing card/circle
                    ZStack(alignment: .bottomLeading) {
                        // Menu content - only visible when expanded
                        VStack(spacing: 0) {
                            ForEach(ZoomMenuOption.allCases.filter { $0 != .transfer }) { option in
                                ZoomMenuRow(option: option) {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                                        isExpanded = false
                                    }
                                    // Trigger action after a short delay for animation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.springResponse) {
                                        onAction?(option)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.CornerRadius.small)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .allowsHitTesting(isExpanded)
                        .opacity(isExpanded ? 1 : 0)
                        
                        // Transfer icon - only visible when collapsed
                        if !isExpanded {
                            Image("NavTransfer")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: DesignSystem.IconSize.medium, height: DesignSystem.IconSize.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: width(in: geometry.size.width), height: height)
                    .background(isExpanded ? themeService.cardBackgroundColor : Color(hex: DesignSystem.Colors.primary))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .scaleEffect(buttonScale)
                    .animation(.easeInOut(duration: DesignSystem.Animation.pressDuration), value: isPressed)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, isExpanded ? DesignSystem.Spacing.md : DesignSystem.Spacing.lg) // 16px when expanded, 24px when collapsed
                }
                .frame(height: height)
            }
            .padding(.top, DesignSystem.Spacing.md) // Match BottomNavView padding
            .padding(.bottom, DesignSystem.Spacing.sm) // Match pill container padding
        }
        .allowsHitTesting(isExpanded ? true : false)
        .overlay(
            // Invisible button that's always tappable when collapsed
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Color.clear
                        .contentShape(Circle())
                        .frame(width: DesignSystem.Button.height, height: DesignSystem.Button.height)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isPressed {
                                        isPressed = true
                                    }
                                }
                                .onEnded { _ in
                                    isPressed = false
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                                        isExpanded = true
                                    }
                                }
                        )
                }
                .padding(.trailing, DesignSystem.Spacing.lg) // Collapsed button is 24px from right
            }
            .padding(.top, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.sm)
            .allowsHitTesting(!isExpanded)
        )
    }
}

// MARK: - Menu Row

struct ZoomMenuRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let option: ZoomMenuOption
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon with light background
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F7F7F7"))
                    .frame(width: DesignSystem.IconSize.large, height: DesignSystem.IconSize.large)
                
                Image(option.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: DesignSystem.IconSize.medium, height: DesignSystem.IconSize.medium)
                    .foregroundColor(option.iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(option.rawValue)
                    .font(DesignSystem.Typography.headerTitle)
                    .foregroundColor(themeService.textPrimaryColor)
                
                Text(option.subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(themeService.textSecondaryColor)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.CornerRadius.small)
        .padding(.horizontal, DesignSystem.CornerRadius.small)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(isPressed ? (themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F0F0F0")) : Color.clear)
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    onTap()
                }
        )
        .animation(.easeInOut(duration: DesignSystem.Animation.pressDuration), value: isPressed)
    }
}

#Preview {
    ZStack {
        Color(hex: DesignSystem.Colors.backgroundLight)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            ZoomTransitionView()
                .padding(.bottom, 40)
        }
    }
}
