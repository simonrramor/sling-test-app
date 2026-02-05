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

// MARK: - Hero Card Animation Support

// PreferenceKey to capture the source card frame from SpendView
struct SourceCardFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// PreferenceKey to capture the target card frame from CardStyleSelectionOverlay
struct TargetCardFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

enum HeroAnimationState {
    case idle
    case animatingToOverlay
    case inOverlay
    case animatingBack
}

// #region agent log
private func debugLogContentView(_ location: String, _ message: String, _ data: [String: Any] = [:]) {
    let logPath = "/Users/simonamor/Desktop/sling-test-app-2/.cursor/debug.log"
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let logData: [String: Any] = [
        "timestamp": timestamp,
        "location": location,
        "message": message,
        "data": data,
        "sessionId": "debug-session",
        "hypothesisId": "H5-H8"
    ]
    if let jsonData = try? JSONSerialization.data(withJSONObject: logData),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        if let fileHandle = FileHandle(forWritingAtPath: logPath) {
            fileHandle.seekToEndOfFile()
            fileHandle.write((jsonString + "\n").data(using: .utf8)!)
            fileHandle.closeFile()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: (jsonString + "\n").data(using: .utf8))
        }
    }
}
// #endregion

// Floating hero card that animates between source and target positions
struct FloatingHeroCard: View {
    let animationState: HeroAnimationState
    let screenSize: CGSize
    
    // Internal state to trigger animation after view appears
    @State private var hasAppeared = false
    
    // Safe screen width (avoid negative values)
    private var safeWidth: CGFloat {
        max(screenSize.width, 100)
    }
    
    // Source card: horizontal, in SpendView position
    private var sourcePosition: CGPoint {
        CGPoint(
            x: safeWidth / 2,
            y: 100 + 120 // header + half card height
        )
    }
    
    // Target card: vertical (rotated 90°), in CardStyleSelectionOverlay position
    private var targetPosition: CGPoint {
        CGPoint(
            x: safeWidth / 2,
            y: 44 + 16 + 155 // header(44) + padding(16) + half card height(311/2)
        )
    }
    
    // Determine if we should be at target position
    private var isAtTarget: Bool {
        switch animationState {
        case .animatingToOverlay:
            return hasAppeared // Animate to target after appearing
        case .inOverlay:
            return true
        case .animatingBack:
            return !hasAppeared // Animate back to source
        case .idle:
            return false
        }
    }
    
    private var currentPosition: CGPoint {
        isAtTarget ? targetPosition : sourcePosition
    }
    
    private var rotation: Double {
        isAtTarget ? 90 : 0
    }
    
    private var cardWidth: CGFloat {
        isAtTarget ? 195 : max(safeWidth - 48, 100)
    }
    
    private var cardHeight: CGFloat {
        isAtTarget ? 311 : 240
    }
    
    var body: some View {
        // Only render if we have valid screen size
        if screenSize.width > 0 && screenSize.height > 0 {
            SwiftUICardView(
                isLocked: .constant(false),
                cardColor: Color(hex: "FF5113"),
                cardStyle: "orange",
                showCardNumber: false,
                fixedWidth: isAtTarget ? 311 : nil
            )
            .frame(width: cardWidth, height: cardHeight)
            .rotationEffect(.degrees(rotation))
            .position(currentPosition)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: hasAppeared)
            .onAppear {
                // #region agent log
                debugLogContentView("FloatingHeroCard:onAppear", "Card appeared, triggering animation", [
                    "hasAppeared": hasAppeared,
                    "animationState": String(describing: animationState),
                    "sourcePos": "\(sourcePosition)",
                    "targetPos": "\(targetPosition)"
                ])
                // #endregion
                // Trigger animation on next frame
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        hasAppeared = true
                        // #region agent log
                        debugLogContentView("FloatingHeroCard:animate", "Set hasAppeared to true", [:])
                        // #endregion
                    }
                }
            }
            .onChange(of: animationState) { _, newState in
                // #region agent log
                debugLogContentView("FloatingHeroCard:stateChange", "Animation state changed", [
                    "newState": String(describing: newState),
                    "hasAppeared": hasAppeared
                ])
                // #endregion
                // Reset hasAppeared for reverse animation
                if newState == .animatingBack {
                    hasAppeared = true // Start at target
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            hasAppeared = false // Animate back to source
                        }
                    }
                }
            }
        }
    }
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
    @State private var showCardStyleSelection = false
    
    // Hero card animation state
    @State private var heroAnimationState: HeroAnimationState = .idle
    
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
    
    // Handle hero animation state transitions
    private func handleHeroAnimationStateChange(from oldState: HeroAnimationState, to newState: HeroAnimationState) {
        // #region agent log
        debugLogContentView("ContentView:heroStateChange", "State changed", [
            "from": String(describing: oldState),
            "to": String(describing: newState)
        ])
        // #endregion
        
        switch newState {
        case .animatingToOverlay:
            // Animation started - after animation completes, transition to inOverlay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // #region agent log
                debugLogContentView("ContentView:animationComplete", "Transitioning to inOverlay", [:])
                // #endregion
                withAnimation {
                    heroAnimationState = .inOverlay
                    showCardStyleSelection = true
                }
            }
        case .inOverlay:
            // Card is now in the overlay - nothing more to do
            break
        case .animatingBack:
            // Animation back to source - after animation completes, reset to idle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // #region agent log
                debugLogContentView("ContentView:animationBackComplete", "Transitioning to idle", [:])
                // #endregion
                withAnimation {
                    heroAnimationState = .idle
                    showCardStyleSelection = false
                }
            }
        case .idle:
            // Reset complete
            break
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
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
                    },
                    onQRScannerTap: {
                        showQRScanner = true
                    }
                )
                    .padding(.horizontal, 16)
                    .opacity(showCardStyleSelection ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: showCardStyleSelection)
                
                // Tab Content with directional transitions
                ZStack {
                    switch selectedTab {
                    case .home:
                        HomeView()
                            .transition(tabTransition)
                    case .card:
                        SpendView(
                            showSubscriptionsOverlay: $showSubscriptionsOverlay,
                            showCardStyleSelection: $showCardStyleSelection,
                            heroAnimationState: $heroAnimationState
                        )
                        .transition(tabTransition)
                    case .invest:
                        InvestView(isPresented: .constant(true))
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
                .opacity(showCardStyleSelection ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: showCardStyleSelection)
            
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
            .opacity(showCardStyleSelection ? 0 : 1)
            .allowsHitTesting(!showCardStyleSelection)
            .animation(.easeInOut(duration: 0.2), value: showCardStyleSelection)
            
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
            .opacity(showCardStyleSelection ? 0 : 1)
            .allowsHitTesting(!showCardStyleSelection)
            .animation(.easeInOut(duration: 0.2), value: showCardStyleSelection)
            
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
            
            // Card style selection overlay (covers entire screen)
            if showCardStyleSelection || heroAnimationState != .idle {
                CardStyleSelectionOverlay(
                    isPresented: $showCardStyleSelection,
                    heroAnimationState: $heroAnimationState
                )
                .zIndex(200)
            }
            
            // Floating hero card for seamless animation
            // Show during animation AND briefly during inOverlay for crossfade
            if heroAnimationState == .animatingToOverlay || heroAnimationState == .animatingBack || heroAnimationState == .inOverlay {
                FloatingHeroCard(
                    animationState: heroAnimationState,
                    screenSize: geometry.size
                )
                .opacity(heroAnimationState == .inOverlay ? 0 : 1)
                .allowsHitTesting(heroAnimationState != .inOverlay) // Don't block taps when invisible
                .animation(.easeOut(duration: 0.15), value: heroAnimationState)
                .zIndex(300)
            }
        }
        .onChange(of: heroAnimationState) { oldState, newState in
            handleHeroAnimationStateChange(from: oldState, to: newState)
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
        } // End GeometryReader
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    @Binding var isMenuOpen: Bool
    @AppStorage("selectedCardStyle") private var selectedCardStyle = "orange"
    
    // Map card style to color
    private var fabColor: Color {
        switch selectedCardStyle {
        case "orange": return Color(hex: "FF5113")
        case "blue": return Color(hex: "0887DC")
        case "green": return Color(hex: "34C759")
        case "purple": return Color(hex: "AF52DE")
        case "pink": return Color(hex: "FF2D55")
        case "teal": return Color(hex: "5AC8FA")
        case "indigo": return Color(hex: "5856D6")
        case "black": return Color(hex: "1C1C1E")
        default: return Color(hex: "FF5113") // Default orange
        }
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            isMenuOpen = true
        }) {
            ZStack {
                Circle()
                    .fill(fabColor)
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
