import SwiftUI
import UIKit

struct HomeView: View {
    @State private var showAddMoney = false
    @State private var showWithdraw = false
    @State private var showSendMoney = false
    @State private var showSetup = false
    @ObservedObject private var activityService = ActivityService.shared
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Balance (without button - buttons are below)
                BalanceView()
                    .padding(.horizontal, 24)
                
                // Add money + Withdraw buttons
                HStack(spacing: 8) {
                    // Add money button
                    TertiaryButton(title: "Add money") {
                        showAddMoney = true
                    }
                    
                    // Withdraw button
                    TertiaryButton(title: "Withdraw") {
                        showWithdraw = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Get started on Sling section
                GetStartedSection(
                    onAddMoney: { showAddMoney = true },
                    onSendMoney: { showSendMoney = true },
                    onSetup: { showSetup = true }
                )
                
                // Invest promo card
                InvestPromoCard()
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                
                // Sling Card promo card
                SlingCardPromoCard()
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                
                // Activity Section
                Text("Activity")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, -8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 0) {
                    if activityService.activities.isEmpty && !activityService.isLoading {
                        // Empty state
                        HomeEmptyStateCard()
                            .padding(.vertical, 24)
                    } else if activityService.isLoading && activityService.activities.isEmpty {
                        // Loading state with skeleton rows
                        VStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonTransactionRow()
                            }
                        }
                        .padding(.top, 8)
                    } else {
                        // Transaction list
                        TransactionListContent()
                    }
                }
                .padding(.horizontal, themeService.currentTheme == .white ? 8 : 16)
                .padding(.vertical, 8)
                .background(themeService.currentTheme == .white ? Color.clear : themeService.backgroundSecondaryColor)
                .cornerRadius(themeService.currentTheme == .white ? 0 : 24)
                .padding(.horizontal, themeService.currentTheme == .white ? 0 : 16)
                .padding(.top, 8)
                
                // Bottom padding for scroll content to clear nav bar
                Spacer()
                    .frame(height: 120)
            }
        }
        .scrollIndicators(.hidden)
        .background(themeService.backgroundColor)
        .onAppear {
            Task {
                await activityService.fetchActivities()
            }
        }
        .fullScreenCover(isPresented: $showAddMoney) {
            AddMoneyView(isPresented: $showAddMoney)
        }
        .fullScreenCover(isPresented: $showWithdraw) {
            WithdrawView(isPresented: $showWithdraw)
        }
        .fullScreenCover(isPresented: $showSendMoney) {
            SendView(isPresented: $showSendMoney)
        }
        .fullScreenCover(isPresented: $showSetup) {
            SettingsView(isPresented: $showSetup)
        }
    }
}

// MARK: - Get Started Section

struct GetStartedSection: View {
    let onAddMoney: () -> Void
    let onSendMoney: () -> Void
    let onSetup: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Get started on Sling")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(Color("TextSecondary"))
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            
            // Horizontal scrollable cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    GetStartedCard(
                        title: "Add money",
                        iconName: "plus",
                        iconColor: Color(hex: "78D381"),
                        backgroundColor: Color(hex: "E9FAEB"),
                        action: onAddMoney
                    )
                    
                    GetStartedCard(
                        title: "Send money",
                        iconName: "arrow.up.right",
                        iconColor: Color(hex: "74CDFF"),
                        backgroundColor: Color(hex: "E8F8FF"),
                        action: onSendMoney
                    )
                    
                    GetStartedCard(
                        title: "Set up",
                        iconName: "building.columns.fill",
                        iconColor: Color(hex: "FF74E0"),
                        backgroundColor: Color(hex: "FFE8F9"),
                        action: onSetup
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Get Started Card

struct GetStartedCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    let title: String
    let iconName: String
    let iconColor: Color
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: 40) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(backgroundColor)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                // Title
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color("TextPrimary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(width: 150)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeService.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PressedButtonStyle())
    }
}

// MARK: - Invest Promo Card

struct InvestPromoCard: View {
    // Stock logos with rotation angles (tilted like Figma design)
    private let stockIcons: [(name: String, rotation: Double)] = [
        ("StockTesla", -13),
        ("StockApple", 0),
        ("StockGoogle", 13)
    ]
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @State private var showStockList = false
    
    // Only show if user has no stock holdings
    private var hasStockHoldings: Bool {
        !portfolioService.holdings.isEmpty
    }
    
    var body: some View {
        if !hasStockHoldings {
        VStack(spacing: 24) {
            // Overlapping stock logos with tilt
            HStack(spacing: -26) {
                ForEach(stockIcons, id: \.name) { icon in
                    Image(icon.name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 65, height: 65)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                        .rotationEffect(.degrees(icon.rotation))
                }
            }
            
            // Text content
            VStack(spacing: 4) {
                Text("Start building your wealth with investing from just $1")
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundColor(Color("TextPrimary"))
                    .multilineTextAlignment(.center)
                
                Text("Buy stocks in your favorite companies to give your money a chance to grow.")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
            }
            
            // Start investing button - 32px from body copy
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showStockList = true
            }) {
                Text("Start investing")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(themeService.currentTheme == .white ? .white : themeService.textPrimaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(height: 36)
                    .background(themeService.buttonSecondaryColor)
                    .cornerRadius(12)
            }
            .buttonStyle(PressedButtonStyle())
            .padding(.top, 8)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeService.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
        )
        .fullScreenCover(isPresented: $showStockList) {
            BrowseStocksView(isPresented: $showStockList)
        }
        }
    }
}

// MARK: - Stock Logo View

struct StockLogoView: View {
    let logoName: String
    
    var body: some View {
        Image(logoName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }
}

// MARK: - Sling Card Promo Card

struct SlingCardPromoCard: View {
    @AppStorage("hasCard") private var hasCard = false
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        // Only show if user doesn't have a card yet
        if !hasCard {
            VStack(spacing: 24) {
                // Card illustration
                Image("SlingCardFront")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Text content
                VStack(spacing: 4) {
                    Text("Create your Sling Card today")
                        .font(.custom("Inter-Bold", size: 24))
                        .foregroundColor(Color("TextPrimary"))
                        .multilineTextAlignment(.center)
                    
                    Text("Get your new virtual debit card, and start spending digital dollars around the world, with no fees.")
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                }
                
                // Create Sling Card button - 32px from body copy
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    NotificationCenter.default.post(name: .navigateToCard, object: nil)
                }) {
                    Text("Create Sling Card")
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(themeService.currentTheme == .white ? .white : themeService.textPrimaryColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(height: 36)
                        .background(themeService.buttonSecondaryColor)
                        .cornerRadius(12)
                }
                .buttonStyle(PressedButtonStyle())
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeService.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Pending Requests Card

struct PendingRequestsCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Icon with badge
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FF5113").opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "FF5113"))
                    }
                    
                    // Badge
                    Text("\(count)")
                        .font(.custom("Inter-Bold", size: 11))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Color(hex: "FF5113"))
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Payment Requests")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text("\(count) pending request\(count == 1 ? "" : "s")")
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeService.textTertiaryColor)
            }
            .padding(16)
            .background(Color(hex: "FFF8F5"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "FF5113").opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Home Empty State Card

struct HomeEmptyStateCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    var onAddTransactions: (() -> Void)? = nil
    @State private var showTransactionOptions = false
    
    var body: some View {
        VStack(spacing: 16) {
            // List icon
            Image("IconList")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .opacity(0.4)
            
            // Text content
            VStack(spacing: 4) {
                Text("Your activity feed")
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundColor(Color("TextPrimary"))
                    .multilineTextAlignment(.center)
                
                Text("When you send, spend, or receive money, it will show here.")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
            }
            
            // Add transactions button - 32px from body copy
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showTransactionOptions = true
            }) {
                Text("Add transactions")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(themeService.textPrimaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "EDEDED"))
                    .cornerRadius(12)
            }
            .padding(.top, 16)
            .padding(.horizontal, 40)
            .confirmationDialog("Add Transaction", isPresented: $showTransactionOptions, titleVisibility: .visible) {
                Button("Card Payment") {
                    ActivityService.shared.generateCardPayment()
                }
                Button("P2P Outbound (Send)") {
                    ActivityService.shared.generateP2POutbound()
                }
                Button("P2P Inbound (Receive)") {
                    ActivityService.shared.generateP2PInbound()
                }
                Button("Top Up") {
                    ActivityService.shared.generateTopUp()
                }
                Button("Withdrawal") {
                    ActivityService.shared.generateWithdrawal()
                }
                Button("Random Mix (8 transactions)") {
                    ActivityService.shared.generateRandomMix()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}

// MARK: - Skeleton Transaction Row

struct SkeletonTransactionRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F7F7F7"))
                .frame(width: 44, height: 44)
            
            // Text placeholders
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 32) {
                    // Title placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "F7F7F7"))
                        .frame(height: 16)
                    
                    // Status placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "F7F7F7"))
                        .frame(width: 59, height: 16)
                }
                .padding(.vertical, 4)
                
                // Subtitle placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "F7F7F7"))
                    .frame(width: 150, height: 16)
                    .padding(.vertical, 4)
            }
        }
        .padding(16)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(
            Animation.easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    HomeView()
}
