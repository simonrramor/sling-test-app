import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Home"
    case transfer = "Transfer"
    case invest = "Invest"
    case activity = "Activity"
    
    var iconName: String {
        switch self {
        case .home: return "NavHome"
        case .transfer: return "NavTransfer"
        case .invest: return "NavInvest"
        case .activity: return "NavActivity"
        }
    }
}

struct BottomNavView: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                Spacer()
                TabButton(tab: tab, selectedTab: $selectedTab)
                Spacer()
            }
        }
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
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(tab.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? Color(hex: "FF5113") : Color(hex: "7B7B7B"))
                
                Text(tab.rawValue)
                    .font(.custom("Inter-Regular", size: 10))
                    .foregroundColor(isSelected ? Color(hex: "FF5113") : Color(hex: "7B7B7B"))
            }
        }
    }
}

#Preview {
    BottomNavView(selectedTab: .constant(.home))
}
