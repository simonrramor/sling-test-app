import SwiftUI
import UIKit

enum Tab: String, CaseIterable {
    case home = "Home"
    case card = "Card"
    case invest = "Invest"
    case savings = "Savings"
    
    // Tabs that appear in the left pill (no transfer - it's a sheet now)
    static var pillTabs: [Tab] {
        [.home, .card, .invest, .savings]
    }
}

struct BottomNavView: View {
    @Binding var selectedTab: Tab
    var onTabChange: ((Tab) -> Void)? = nil
    var onTransferTap: (() -> Void)? = nil
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        HStack {
            // Left pill container with 3 tabs
            HStack(spacing: 0) {
                ForEach(Tab.pillTabs, id: \.self) { tab in
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
        case .savings: return "NavSavings"
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
        .buttonStyle(NoFeedbackButtonStyle())
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        Color(hex: DesignSystem.Colors.backgroundLight)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            BottomNavView(selectedTab: .constant(.home))
        }
    }
}
