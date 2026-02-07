import SwiftUI

// MARK: - Screenshot Mode
// Tap the orange camera button in the bottom right to open screenshot mode
// Or launch with --screenshot-mode argument

struct ScreenshotModeView: View {
    @State private var currentIndex = 0
    @State private var isAutoCapturing = false
    @State private var capturedCount = 0
    @State private var hideControls = false
    @Environment(\.dismiss) private var dismiss
    
    // Auto-start when launched with --screenshot-mode
    private var shouldAutoStart: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshot-mode")
    }
    
    // Screens that can be captured
    let screens: [(name: String, id: String, view: AnyView)] = [
        ("Home", "home", AnyView(HomeView())),
        ("Invest", "invest", AnyView(ScreenshotInvestWrapper())),
        ("Spend", "spend", AnyView(ScreenshotSpendWrapper())),
        ("Activity", "activity", AnyView(ActivityView())),
        ("Settings", "settings", AnyView(ScreenshotSettingsWrapper())),
        ("Search", "search", AnyView(SearchView())),
        ("Chat", "chat", AnyView(ChatView())),
        ("Pending Requests", "pending_requests", AnyView(PendingRequestsView())),
        ("Send Money", "send", AnyView(ScreenshotSendWrapper())),
        ("Withdraw", "withdraw", AnyView(ScreenshotWithdrawWrapper())),
        ("Split Bill", "split_bill", AnyView(ScreenshotSplitBillWrapper())),
        ("Add Money", "add_money", AnyView(ScreenshotAddMoneyWrapper())),
        ("Stock Detail", "stock_detail", AnyView(ScreenshotStockDetailWrapper())),
        ("Transaction Detail", "transaction_detail", AnyView(ScreenshotTransactionWrapper())),
        ("Onboarding", "onboarding", AnyView(ScreenshotOnboardingWrapper())),
        ("QR Scanner", "qr_scanner", AnyView(QRCodePlaceholder())),
    ]
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            // Current screen
            screens[currentIndex].view
                .id(currentIndex)
            
            // Screenshot mode controls (hidden during auto-capture)
            if !hideControls && !isAutoCapturing {
                VStack {
                    // Top bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Label("Exit", systemImage: "xmark.circle.fill")
                                .font(.subheadline.bold())
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) / \(screens.count)")
                            .font(.caption.bold())
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                        
                        Spacer()
                        
                        Button(action: { hideControls = true }) {
                            Label("Hide", systemImage: "eye.slash")
                                .font(.subheadline.bold())
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Screen name badge
                    Text(screens[currentIndex].name)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.bottom, 10)
                    
                    // Navigation controls
                    HStack(spacing: 24) {
                        Button(action: previousScreen) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(currentIndex == 0 ? .gray : .primary)
                        }
                        .disabled(currentIndex == 0)
                        
                        Button(action: startAutoCapture) {
                            VStack(spacing: 4) {
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 60))
                                Text("Capture All")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(.orange)
                        }
                        
                        Button(action: nextScreen) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(currentIndex == screens.count - 1 ? .gray : .primary)
                        }
                        .disabled(currentIndex == screens.count - 1)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .padding(.bottom, 50)
                }
            }
            
            // Tap to show controls when hidden
            if hideControls && !isAutoCapturing {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideControls = false
                    }
            }
            
            // No overlay during auto-capture - clean screenshots only
        }
        .onAppear {
            // Auto-start capture if launched with --screenshot-mode
            if shouldAutoStart {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    startAutoCapture()
                }
            }
        }
    }
    
    private func nextScreen() {
        if currentIndex < screens.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentIndex += 1
            }
        }
    }
    
    private func previousScreen() {
        if currentIndex > 0 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentIndex -= 1
            }
        }
    }
    
    private func startAutoCapture() {
        isAutoCapturing = true
        capturedCount = 0
        currentIndex = 0
        hideControls = true
        
        // Start capture sequence
        captureNext()
    }
    
    private func captureNext() {
        guard capturedCount < screens.count else {
            // Done!
            isAutoCapturing = false
            hideControls = false
            print("📸 AppShot: Capture complete! \(screens.count) screens captured.")
            return
        }
        
        currentIndex = capturedCount
        
        // Wait for screen to fully render (no overlay shown during this time)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Print marker for external capture tool
            print("📸 APPSHOT_CAPTURE:\(screens[currentIndex].id):\(screens[currentIndex].name)")
            
            capturedCount += 1
            
            // Next screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                captureNext()
            }
        }
    }
}

// MARK: - Wrapper Views (to handle @Binding parameters)

struct ScreenshotSettingsWrapper: View {
    @State private var isPresented = true
    var body: some View {
        SettingsView(isPresented: $isPresented)
    }
}

struct ScreenshotInvestWrapper: View {
    @State private var isPresented = true
    var body: some View {
        InvestView(isPresented: $isPresented)
    }
}

struct ScreenshotSpendWrapper: View {
    @State private var heroState: HeroAnimationState = .idle
    var body: some View {
        SpendView(showSubscriptionsOverlay: .constant(false), showCardStyleSelection: .constant(false), heroAnimationState: $heroState)
    }
}

struct ScreenshotAddMoneyWrapper: View {
    @State private var isPresented = true
    var body: some View {
        AddMoneyView(isPresented: $isPresented)
    }
}

struct ScreenshotSendWrapper: View {
    @State private var isPresented = true
    var body: some View {
        SendView(isPresented: $isPresented)
    }
}

struct ScreenshotWithdrawWrapper: View {
    @State private var isPresented = true
    var body: some View {
        WithdrawView(isPresented: $isPresented)
    }
}

struct ScreenshotSplitBillWrapper: View {
    @State private var isPresented = true
    var body: some View {
        SplitBillView(isPresented: $isPresented)
    }
}

struct ScreenshotStockDetailWrapper: View {
    var body: some View {
        let sampleStock = Stock(
            name: "Apple Inc.",
            symbol: "AAPL",
            price: "$178.50",
            change: "+2.34%",
            isPositive: true,
            iconName: "StockApple"
        )
        StockDetailView(stock: sampleStock)
    }
}

struct ScreenshotTransactionWrapper: View {
    var body: some View {
        let sampleActivity = ActivityItem(
            avatar: "person.circle.fill",
            titleLeft: "John Smith",
            subtitleLeft: "Payment received",
            titleRight: "+£50.00",
            subtitleRight: "Completed",
            date: Date()
        )
        TransactionDetailView(activity: sampleActivity)
    }
}

struct ScreenshotOnboardingWrapper: View {
    @State private var isComplete = false
    var body: some View {
        OnboardingView(isComplete: $isComplete)
    }
}

// MARK: - QR Code Placeholder
struct QRCodePlaceholder: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 120))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Scan QR Code")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("Point your camera at a QR code to scan")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

#Preview {
    ScreenshotModeView()
}
