import SwiftUI
import UIKit

// Notifications for tab navigation
extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
    static let navigateToInvest = Notification.Name("navigateToInvest")
    static let navigateToCard = Notification.Name("navigateToCard")
    static let navigateToSavings = Notification.Name("navigateToSavings")
    static let showBalanceSheet = Notification.Name("showBalanceSheet")
    static let showTransactionDetail = Notification.Name("showTransactionDetail")
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
    @State private var showReceiveSalary = false
    
    // Global transaction detail state
    @State private var selectedTransaction: ActivityItem?
    @State private var showTransactionDetail = false
    
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var feedbackManager = FeedbackModeManager.shared
    @State private var showSubscriptionsOverlay = false
    @State private var showBalanceSheet = false
    
    var backgroundGradient: LinearGradient {
        themeService.backgroundGradient
    }
    
    // Get index of a tab for directional comparison
    private func tabIndex(_ tab: Tab) -> Int {
        switch tab {
        case .home: return 0
        case .card: return 1
        case .invest: return 2
        case .savings: return 3
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
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (dynamic based on current tab)
                HeaderView(
                    currentTab: selectedTab,
                    previousTab: previousTab,
                    onProfileTap: {
                        showSettings = true
                    },
                    onSearchTap: {
                        showSearch = true
                    },
                    onInviteTap: {
                        showInviteSheet = true
                    }
                )
                    .padding(.horizontal, 16)
                
                // Tab Content with directional transitions
                ZStack {
                    switch selectedTab {
                    case .home:
                        HomeView()
                            .transition(tabTransition)
                    case .card:
                        SpendView(showSubscriptionsOverlay: $showSubscriptionsOverlay)
                            .transition(tabTransition)
                    case .invest:
                        // Investments removed from nav - redirect to home
                        HomeView()
                            .transition(tabTransition)
                    case .savings:
                        SavingsView()
                            .transition(tabTransition)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.86), value: selectedTab)
            }
            
            // Progressive blur behind nav - positioned at very bottom
            ProgressiveBlurView(
                blurAmount: 1.0,
                blurStyle: themeService.currentTheme == .dark ? .dark : .prominent,
                backgroundColorValue: themeService.currentTheme == .dark ? 0.95 : 0.05,
                backgroundOpacity: 0.79
            )
                .frame(height: 140)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
            
            // Bottom Navigation - overlaid at bottom
            VStack(spacing: 0) {
                Spacer()
                
                BottomNavView(
                    selectedTab: $selectedTab,
                    onTabChange: { newTab in
                        previousTab = selectedTab
                    }
                )
            }
            
            // Transfer menu overlay
            ZoomTransitionView(onAction: { option in
                switch option {
                case .send:
                    showSendMoney = true
                case .request:
                    showRequestMoney = true
                case .transfer:
                    showTransferBetweenAccounts = true
                case .receiveSalary:
                    showReceiveSalary = true
                }
            })
            
            // In-app notification overlay
            NotificationOverlay()
                .ignoresSafeArea(.container, edges: .top)
            
            // Feedback selection overlay
            if feedbackManager.isActive {
                FeedbackSelectionOverlay()
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // Subscriptions card overlay (covers everything including nav)
            if showSubscriptionsOverlay {
                SubscriptionsCardOverlay(isPresented: $showSubscriptionsOverlay)
            }
            
            // Balance sheet overlay (covers everything including nav)
            if showBalanceSheet {
                BalanceSheet(isPresented: $showBalanceSheet)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: feedbackManager.isActive)
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
        .fullScreenCover(isPresented: $showReceiveSalary) {
            ReceiveSalaryView(isPresented: $showReceiveSalary)
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
        .sheet(isPresented: $feedbackManager.showFeedbackPopup) {
            FeedbackPopupView()
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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSavings)) { _ in
            previousTab = selectedTab
            selectedTab = .savings
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBalanceSheet)) { _ in
            showBalanceSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTransactionDetail)) { notification in
            if let activity = notification.object as? ActivityItem {
                selectedTransaction = activity
                showTransactionDetail = true
            }
        }
        .transactionDetailDrawer(isPresented: $showTransactionDetail, activity: selectedTransaction)
        .onFlip {
            // Only activate if not already in feedback mode and no popups are showing
            if !feedbackManager.isActive && !feedbackManager.showFeedbackPopup {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                feedbackManager.toggleFeedbackMode()
            }
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
                    .fill(Color(hex: "FF5113"))
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
            .scaleEffect(configuration.isPressed ? DesignSystem.Animation.pressedScale : 1.0)
            .animation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping), value: configuration.isPressed)
    }
}

// MARK: - FAB Menu Sheet

struct FABMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSend: () -> Void
    var onRequest: () -> Void
    
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
                        isLast: true,
                        action: onRequest
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
            .cornerRadius(isFirst ? 24 : (isLast ? 24 : 24), corners: isFirst ? [.topLeft, .topRight] : (isLast ? [.bottomLeft, .bottomRight] : []))
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


// MARK: - Blur Style Options

enum BlurStyleOption: String, CaseIterable, Identifiable {
    case systemUltraThinMaterial = "Ultra Thin"
    case systemThinMaterial = "Thin"
    case systemMaterial = "Material"
    case systemThickMaterial = "Thick"
    case systemChromeMaterial = "Chrome"
    case regular = "Regular"
    case prominent = "Prominent"
    case light = "Light"
    case extraLight = "Extra Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var uiBlurStyle: UIBlurEffect.Style {
        switch self {
        case .systemUltraThinMaterial: return .systemUltraThinMaterial
        case .systemThinMaterial: return .systemThinMaterial
        case .systemMaterial: return .systemMaterial
        case .systemThickMaterial: return .systemThickMaterial
        case .systemChromeMaterial: return .systemChromeMaterial
        case .regular: return .regular
        case .prominent: return .prominent
        case .light: return .light
        case .extraLight: return .extraLight
        case .dark: return .dark
        }
    }
}

// MARK: - Progressive Blur View

struct ProgressiveBlurView: View {
    var blurAmount: Double = 1.0
    var blurStyle: BlurStyleOption = .systemUltraThinMaterial
    var backgroundColorValue: Double = 0.0  // 0 = white, 1 = black
    var backgroundOpacity: Double = 1.0
    
    // Computed background color interpolating between white and black
    private var backgroundColor: Color {
        let white = 1.0 - backgroundColorValue
        return Color(red: white, green: white, blue: white)
    }
    
    var body: some View {
        ZStack {
            // Gradient fade to background color
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: backgroundColor.opacity(0), location: 0),
                    .init(color: backgroundColor.opacity(backgroundOpacity * 0.3), location: 0.3),
                    .init(color: backgroundColor.opacity(backgroundOpacity * 0.7), location: 0.6),
                    .init(color: backgroundColor.opacity(backgroundOpacity), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Blur layer with gradient mask
            VisualEffectBlur(blurStyle: blurStyle.uiBlurStyle)
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.3), location: 0.3),
                            .init(color: .white.opacity(0.7), location: 0.6),
                            .init(color: .white, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(blurAmount)
                .id(blurStyle.rawValue)
        }
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

#Preview {
    ContentView()
}
