import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Home"
    case transfer = "Transfer"
    case card = "Card"
    case invest = "Invest"
}

struct BottomNavView: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabButton(tab: tab, selectedTab: $selectedTab)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 32)
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
        switch tab {
        case .home: return "NavHome"
        case .transfer: return "NavTransfer"
        case .card: return "NavCard"
        case .invest: return "NavInvest"
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? Color(hex: "FF5113") : Color(hex: "7B7B7B"))
                
                Text(tab.rawValue)
                    .font(.custom("Inter-Regular", size: 10))
                    .foregroundColor(isSelected ? Color(hex: "FF5113") : Color(hex: "7B7B7B"))
            }
            .frame(width: 80)
        }
    }
}

#Preview {
    BottomNavView(selectedTab: .constant(.home))
}
