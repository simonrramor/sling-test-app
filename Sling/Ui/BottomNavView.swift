import SwiftUI
import UIKit

enum Tab: String, CaseIterable {
    case home = "Home"
    case card = "Card"
    case transfer = "Transfer"
    case invest = "Invest"
}

struct BottomNavView: View {
    @Binding var selectedTab: Tab
    var useLiquidGlass: Bool = false
    var onTabChange: ((Tab) -> Void)? = nil
    
    var body: some View {
        if useLiquidGlass {
            liquidGlassNav
        } else {
            standardNav
        }
    }
    
    private var standardNav: some View {
        HStack(spacing: 32) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabButton(tab: tab, selectedTab: $selectedTab, onTabChange: onTabChange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color("BackgroundSecondary"))
        .overlay(
            Rectangle()
                .fill(Color("Divider"))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    private var liquidGlassNav: some View {
        HStack(spacing: 24) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabButton(tab: tab, selectedTab: $selectedTab, onTabChange: onTabChange)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .glassEffect(.regular.interactive())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct TabButton: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    var onTabChange: ((Tab) -> Void)? = nil
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var iconName: String {
        let baseName: String
        switch tab {
        case .home: baseName = "NavHome"
        case .transfer: baseName = "NavTransfer"
        case .card: baseName = "NavCard"
        case .invest: baseName = "NavInvest"
        }
        return isSelected ? "\(baseName)Filled" : baseName
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            // Notify parent before changing tab (so it can track previousTab)
            onTabChange?(tab)
            selectedTab = tab
        }) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .foregroundColor(isSelected ? Color(hex: "FF5113") : Color("TextSecondary"))
                .frame(width: 40)
        }
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            BottomNavView(selectedTab: .constant(.home))
        }
    }
}
