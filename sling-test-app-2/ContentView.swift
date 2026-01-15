import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (always visible)
                HeaderView()
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Tab Content
                switch selectedTab {
                case .home:
                    HomeView()
                case .transfer:
                    TransferView()
                case .card:
                    SpendView()
                case .invest:
                    InvestView()
                }
                
                // Bottom Navigation
                BottomNavView(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    ContentView()
}
