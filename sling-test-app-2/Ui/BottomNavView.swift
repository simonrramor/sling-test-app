import SwiftUI
import UIKit

enum Tab: String, CaseIterable {
    case home = "Home"
    case transfer = "Transfer"
    case card = "Card"
    case invest = "Invest"
}

struct BottomNavView: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack(spacing: 32) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabButton(tab: tab, selectedTab: $selectedTab)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: "F7F7F7"))
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct TabButton: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    
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
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                selectedTab = tab
            }
        }) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .foregroundColor(isSelected ? Color(hex: "FF5113") : Color(hex: "7B7B7B"))
                .frame(width: 40)
        }
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .transaction { $0.animation = nil }
    }
}

#Preview {
    BottomNavView(selectedTab: .constant(.home))
}
