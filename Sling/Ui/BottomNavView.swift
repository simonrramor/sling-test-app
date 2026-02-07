import SwiftUI
import UIKit

enum Tab: String, CaseIterable {
    case home = "Home"
    case card = "Card"
    case invest = "Invest"
    
    // Tabs that appear in the left pill
    static var pillTabs: [Tab] {
        [.home, .card, .invest]
    }
}

struct BottomNavView: View {
    @Binding var selectedTab: Tab
    var onTabChange: ((Tab) -> Void)? = nil
    var onTransferTap: (() -> Void)? = nil
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.selectedAppVariant) private var selectedAppVariant
    
    private var visibleTabs: [Tab] {
        if selectedAppVariant == .newNavMVP {
            return [.home, .card]
        }
        return Tab.pillTabs
    }
    
    var body: some View {
        HStack {
            // Left pill container with tabs
            HStack(spacing: 0) {
                ForEach(visibleTabs, id: \.self) { tab in
                    PillTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        onTap: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onTabChange?(tab)
                            selectedTab = tab
                        }
                    )
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(
                Capsule()
                    .fill(themeService.currentTheme == .dark ? Color.black : Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: DesignSystem.CornerRadius.small, x: 0, y: 4)
            )
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.md)
        .padding(.bottom, 0)
        .background(Color.clear)
    }
}

struct PillTabButton: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var themeService = ThemeService.shared
    
    var iconName: String {
        switch tab {
        case .home: return "NavHomeFilled"
        case .card: return "NavCardFilled"
        case .invest: return "NavInvest"
        }
    }
    
    // Icon color based on theme
    private var iconColor: Color {
        switch themeService.currentTheme {
        case .dark:
            return .white
        case .grey, .white:
            return Color(hex: DesignSystem.Colors.dark)
        }
    }
    
    // Selected pill background color based on theme
    private var selectedBackgroundColor: Color {
        switch themeService.currentTheme {
        case .dark:
            return Color(hex: "2C2C2E") // Slightly lighter dark
        case .grey, .white:
            return Color(hex: DesignSystem.Colors.backgroundLight)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: DesignSystem.IconSize.medium, height: DesignSystem.IconSize.medium)
                .foregroundColor(iconColor)
                .padding(.horizontal, 20)
                .padding(.vertical, DesignSystem.CornerRadius.small)
                .background(
                    Capsule()
                        .fill(isSelected ? selectedBackgroundColor : Color.clear)
                )
        }
        .buttonStyle(NavPressStyle())
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Nav Press Style

struct NavPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview("iPhone 15 Pro") {
    ZStack {
        Color(hex: DesignSystem.Colors.backgroundLight)
            .ignoresSafeArea()
        VStack {
            Spacer()
            BottomNavView(selectedTab: .constant(.home))
        }
    }
    .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
}

#Preview("iPhone 13") {
    ZStack {
        Color(hex: DesignSystem.Colors.backgroundLight)
            .ignoresSafeArea()
        VStack {
            Spacer()
            BottomNavView(selectedTab: .constant(.home))
        }
    }
    .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
}
