import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Home"
    case transfer = "Transfer"
    case spend = "Spend"
    case invest = "Invest"
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .transfer: return "arrow.up.arrow.down"
        case .spend: return "creditcard"
        case .invest: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var iconFilled: String {
        switch self {
        case .home: return "house.fill"
        case .transfer: return "arrow.up.arrow.down"
        case .spend: return "creditcard.fill"
        case .invest: return "chart.line.uptrend.xyaxis"
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
        .padding(.vertical, 12)
        .background(Color(hex: "F5F5F5"))
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
                Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(hex: "FF6B35") : Color(hex: "8E8E93"))
                
                Text(tab.rawValue)
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundColor(isSelected ? Color(hex: "FF6B35") : Color(hex: "8E8E93"))
            }
        }
    }
}

#Preview {
    BottomNavView(selectedTab: .constant(.home))
}
