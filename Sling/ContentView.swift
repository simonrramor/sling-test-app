import SwiftUI
import UIKit

// Notifications for tab navigation
extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
    static let navigateToInvest = Notification.Name("navigateToInvest")
    static let navigateToCard = Notification.Name("navigateToCard")
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var previousTab: Tab = .home
    @State private var showSettings = false
    @State private var showChat = false
    @State private var showQRScanner = false
    @State private var showSearch = false
    @State private var showInviteSheet = false
    @State private var showFABMenu = false
    @State private var showSendMoney = false
    @State private var showRequestMoney = false
    @State private var showTransferBetweenAccounts = false
    
    @ObservedObject private var themeService = ThemeService.shared
    
    var backgroundColor: Color {
        themeService.backgroundColor
    }
    
    // Get index of a tab for directional comparison
    private func tabIndex(_ tab: Tab) -> Int {
        switch tab {
        case .home: return 0
        case .card: return 1
        case .invest: return 2
        }
    }
    
    // Determine if we're moving right (positive) or left (negative)
    private var isMovingRight: Bool {
        tabIndex(selectedTab) > tabIndex(previousTab)
    }
    
    // Asymmetric transition based on direction
    private var tabTransition: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .opacity.combined(with: .offset(x: isMovingRight ? 30 : -30)),
            removal: .opacity.combined(with: .offset(x: isMovingRight ? -30 : 30))
        )
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (dynamic based on current tab)
                HeaderView(
                    currentTab: selectedTab,
                    previousTab: previousTab,
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
                
                // Tab Content with directional transitions
                ZStack {
                    switch selectedTab {
                    case .home:
                        HomeView()
                            .transition(tabTransition)
                    case .card:
                        SpendView()
                            .transition(tabTransition)
                    case .invest:
                        InvestView()
                            .transition(tabTransition)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.86), value: selectedTab)
            }
            
            // Bottom Navigation - overlaid at bottom
            VStack {
                Spacer()
                BottomNavView(selectedTab: $selectedTab, onTabChange: { newTab in
                    previousTab = selectedTab
                })
            }
            
            // In-app notification overlay
            NotificationOverlay()
                .ignoresSafeArea(.container, edges: .top)
        }
        .fullScreenCover(isPresented: $showFABMenu) {
            FABMenuSheet(
                onSend: {
                    showFABMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSendMoney = true
                    }
                },
                onRequest: {
                    showFABMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showRequestMoney = true
                    }
                },
                onTransfer: {
                    showFABMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showTransferBetweenAccounts = true
                    }
                }
            )
            .background(ClearBackgroundView())
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
        }
        .fullScreenCover(isPresented: $showSendMoney) {
            SendView(isPresented: $showSendMoney)
        }
        .fullScreenCover(isPresented: $showRequestMoney) {
            SendView(isPresented: $showRequestMoney, mode: .request)
        }
        .fullScreenCover(isPresented: $showTransferBetweenAccounts) {
            TransferBetweenAccountsView(isPresented: $showTransferBetweenAccounts)
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
            previousTab = selectedTab
            selectedTab = .home
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToInvest)) { _ in
            previousTab = selectedTab
            selectedTab = .invest
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCard)) { _ in
            previousTab = selectedTab
            selectedTab = .card
        }
        .preferredColorScheme(themeService.colorScheme)
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            isMenuOpen = true
        }) {
            ZStack {
                Circle()
                    .fill(Color(hex: "080808"))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                Image("NavTransfer")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(FABButtonStyle())
    }
}

struct FABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - FAB Menu Sheet

struct FABMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSend: () -> Void
    var onRequest: () -> Void
    var onTransfer: () -> Void
    
    var body: some View {
        ZStack {
            // Dimmed background with blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Bottom aligned menu
            VStack {
                Spacer()
                
                // Menu container
                VStack(spacing: 0) {
                    // Send row
                    FABMenuRow(
                        iconName: "arrow.up.right",
                        iconColor: Color(hex: "74CDFF"),
                        iconBgColor: Color(hex: "E8F8FF"),
                        title: "Send",
                        subtitle: "Pay anyone in seconds",
                        isFirst: true,
                        action: onSend
                    )
                    
                    // Request row
                    FABMenuRow(
                        iconName: "arrow.down.left",
                        iconColor: Color(hex: "78D381"),
                        iconBgColor: Color(hex: "E9FAEB"),
                        title: "Request",
                        subtitle: "Ask someone to pay you back",
                        action: onRequest
                    )
                    
                    // Transfer row
                    FABMenuRow(
                        iconName: "arrow.left.arrow.right",
                        iconColor: Color(hex: "FFC774"),
                        iconBgColor: Color(hex: "FFF5E5"),
                        title: "Transfer",
                        subtitle: "Move money between your accounts",
                        isLast: true,
                        action: onTransfer
                    )
                }
                .background(Color.white)
                .cornerRadius(24)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .background(ClearBackgroundView())
    }
}

struct FABMenuRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let iconName: String
    let iconColor: Color
    let iconBgColor: Color
    let title: String
    let subtitle: String
    var isFirst: Bool = false
    var isLast: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconBgColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text(subtitle)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeService.textTertiaryColor)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(isFirst ? 24 : (isLast ? 24 : 16), corners: isFirst ? [.topLeft, .topRight] : (isLast ? [.bottomLeft, .bottomRight] : []))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Helper for selective corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Helper to make fullScreenCover background transparent
struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}


#Preview {
    ContentView()
}
