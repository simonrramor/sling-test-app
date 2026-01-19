import SwiftUI

// Notification for navigating to home after transactions
extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var showSettings = false
    @State private var showChat = false
    @State private var showQRScanner = false
    @State private var showSearch = false
    @State private var showInviteSheet = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (always visible)
                HeaderView(
                    onProfileTap: {
                        showSettings = true
                    },
                    onChatTap: {
                        showChat = true
                    },
                    onQRCodeTap: {
                        showQRScanner = true
                    },
                    onSearchTap: {
                        showSearch = true
                    },
                    onInviteTap: {
                        showInviteSheet = true
                    }
                )
                    .padding(.horizontal, 24)
                
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
            
            // In-app notification overlay
            NotificationOverlay()
                .ignoresSafeArea(.container, edges: .top)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
        }
        .sheet(isPresented: $showChat) {
            ChatView()
        }
        .fullScreenCover(isPresented: $showQRScanner) {
            QRScannerView()
        }
        .fullScreenCover(isPresented: $showSearch) {
            SearchView()
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteShareSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            selectedTab = .home
        }
    }
}

#Preview {
    ContentView()
}
