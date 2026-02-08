import SwiftUI
import UIKit

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct HomeView: View {
    @State private var showAddMoney = false
    @State private var showWithdraw = false
    @State private var showSendMoney = false
    @State private var showSetup = false
    @State private var showAllActivity = false
    @State private var selectedAccountCurrency: String? = nil
    @State private var onboardingCurrency: String? = nil
    @State private var showAllAccountDetails = false
    @ObservedObject private var activityService = ActivityService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.selectedAppVariant) private var selectedAppVariant
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Balance (without button - buttons are below)
                BalanceView(onBalanceTap: {
                    NotificationCenter.default.post(name: .showBalanceSheet, object: nil)
                })
                    .padding(.horizontal, 20)
                
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
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                // Get started on Sling section
                GetStartedSection(
                    onAddMoney: { showAddMoney = true },
                    onSendMoney: { showSendMoney = true },
                    onSetup: { showSetup = true }
                )
                
                // Virtual accounts carousel
                if selectedAppVariant == .newNavMVP || selectedAppVariant == .investmentsMVP {
                    VirtualAccountsCarousel(
                        onAccountTap: { currency in
                            selectedAccountCurrency = currency
                        },
                        onLockedAccountTap: { currency in
                            if currency == "ALL" {
                                showAllAccountDetails = true
                            } else {
                                onboardingCurrency = currency
                            }
                        }
                    )
                    .padding(.top, 12)
                    
                    // Spent this month card
                    SpentThisMonthCard()
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    // Portfolio card (investments MVP only, shows after buying a stock)
                    if selectedAppVariant == .investmentsMVP && !PortfolioService.shared.holdings.isEmpty {
                        HomePortfolioCard()
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }
                }
                
                // Activity Section
                if activityService.activities.isEmpty && !activityService.isLoading {
                    // Empty state in a card
                    HomeEmptyStateCard()
                        .padding(.vertical, 40)
                        .padding(.horizontal, 60)
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                } else {
                    VStack(spacing: 0) {
                        // Activity title with See more button
                        if !activityService.activities.isEmpty || activityService.isLoading {
                            HStack {
                                Text("Activity")
                                    .font(.custom("Inter-Bold", size: 24))
                                    .tracking(-0.48)
                                    .foregroundColor(themeService.textPrimaryColor)
                                
                                Spacer()
                                
                                if activityService.activities.count > 3 {
                                    Button(action: { showAllActivity = true }) {
                                        Text("See all")
                                            .font(.custom("Inter-Bold", size: 14))
                                            .foregroundColor(themeService.textPrimaryColor)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F0F0F0"))
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                        
                        if activityService.isLoading && activityService.activities.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(0..<3, id: \.self) { _ in
                                    SkeletonTransactionRow()
                                }
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 20)
                        } else {
                            TransactionListContent(
                                limit: 3,
                                onTransactionSelected: { activity in
                                    NotificationCenter.default.post(name: .showTransactionDetail, object: activity)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                    .background(themeService.backgroundSecondaryColor)
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                
                // Bottom padding for scroll content to clear nav bar
                Spacer()
                    .frame(height: 120)
            }
        }
        .scrollIndicators(.hidden)
        .background(themeService.backgroundGradient.ignoresSafeArea())
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
        .fullScreenCover(isPresented: $showAllActivity) {
            AllActivityView(isPresented: $showAllActivity)
        }
        .fullScreenCover(item: $selectedAccountCurrency) { currency in
            currencyAccountDetailsSheet(for: currency)
        }
        .fullScreenCover(isPresented: $showAllAccountDetails) {
            AllAccountDetailsView(
                isPresented: $showAllAccountDetails,
                onOpenOnboarding: { currency in
                    showAllAccountDetails = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onboardingCurrency = currency
                    }
                },
                onOpenDetails: { currency in
                    showAllAccountDetails = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        selectedAccountCurrency = currency
                    }
                }
            )
        }
        .fullScreenCover(item: $onboardingCurrency) { currency in
            AccountOnboardingView(
                currency: currency,
                onCreateAccount: {
                    onboardingCurrency = nil
                    // Small delay so dismiss animation completes before showing details
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        selectedAccountCurrency = currency
                    }
                },
                onDismiss: {
                    onboardingCurrency = nil
                }
            )
        }
    }
    
    @ViewBuilder
    private func currencyAccountDetailsSheet(for currency: String) -> some View {
        let dismissBinding = Binding<Bool>(
            get: { selectedAccountCurrency != nil },
            set: { if !$0 { selectedAccountCurrency = nil } }
        )
        
        switch currency {
        case "BRL":
            CurrencyAccountDetailsSheet(
                isPresented: dismissBinding,
                title: "BRL account details",
                subtitle: "Money sent to these details will be converted to digital dollars and added to your Sling Wallet.",
                infoBadges: [("percent", "0% fee"), ("arrow.down", "R$10 min"), ("clock", "Instant")],
                details: [
                    ("Pix Key", "12345678900", false),
                    ("Bank", "Sling", false),
                    ("Account Holder", "Brendon Arnold", false)
                ]
            )
        case "USD":
            CurrencyAccountDetailsSheet(
                isPresented: dismissBinding,
                title: "US account details",
                subtitle: "Money sent to these details will be converted to digital dollars and added to your Sling Wallet.",
                infoBadges: [("percent", "0.25% fee"), ("arrow.down", "$2 min"), ("clock", "1-3 business days")],
                details: [
                    ("Routing number", "123456789", false),
                    ("Account number", "123456789123", true),
                    ("Bank name", "Lead Bank", false),
                    ("Beneficiary name", "Brendon Arnold", false),
                    ("Bank address", "1801 Main St.\nKansas City\nMO 64108", true)
                ]
            )
        case "EUR":
            CurrencyAccountDetailsSheet(
                isPresented: dismissBinding,
                title: "EUR account details",
                subtitle: "Money sent to these details will be converted to digital dollars and added to your Sling Wallet.",
                infoBadges: [("percent", "0.25% fee"), ("arrow.down", "€2 min"), ("clock", "1-2 business days")],
                details: [
                    ("IBAN", "DE89 3704 0044 0532 0130 00", true),
                    ("BIC/SWIFT", "COBADEFFXXX", true),
                    ("Account Holder", "Brendon Arnold", false),
                    ("Bank name", "Sling EU", false),
                    ("Bank address", "Finanzplatz 1\n60311 Frankfurt\nGermany", true)
                ]
            )
        case "MXN":
            CurrencyAccountDetailsSheet(
                isPresented: dismissBinding,
                title: "MXN account details",
                subtitle: "Money sent to these details will be converted to digital dollars and added to your Sling Wallet.",
                infoBadges: [("percent", "0% fee"), ("arrow.down", "$500 MXN min"), ("clock", "Instant")],
                details: [
                    ("CLABE", "0211 8000 1234 5678 90", true),
                    ("Beneficiary name", "Brendon Arnold", false),
                    ("Bank", "Sling MX", false),
                    ("Reference", "SLING-BA2026", true)
                ]
            )
        case "GBP":
            CurrencyAccountDetailsSheet(
                isPresented: dismissBinding,
                title: "GBP account details",
                subtitle: "Money sent to these details will be converted to digital dollars and added to your Sling Wallet.",
                infoBadges: [("percent", "0.25% fee"), ("arrow.down", "£2 min"), ("clock", "Same day")],
                details: [
                    ("Account number", "12345678", true),
                    ("Sort code", "04-00-75", true),
                    ("IBAN", "GB29 NWBK 6016 1331 9268 19", true),
                    ("Account Holder", "Brendon Arnold", false),
                    ("Bank name", "Sling UK", false),
                    ("Bank address", "1 Bank Street\nLondon E14 5JP", true)
                ]
            )
        default:
            EmptyView()
        }
    }
}

// MARK: - Get Started Section

struct GetStartedSection: View {
    @ObservedObject private var portfolioService = PortfolioService.shared
    @AppStorage("hasCard") private var hasCard = false
    @AppStorage("hasAddedMoney") private var hasAddedMoney = false
    @AppStorage("hasSentMoney") private var hasSentMoney = false
    @AppStorage("hasSetupAccount") private var hasSetupAccount = false
    @AppStorage("selectedCardStyle") private var selectedCardStyle = "orange"
    @AppStorage("cardSpendingUSD") private var cardSpendingUSD: Double = 0
    
    let onAddMoney: () -> Void
    let onSendMoney: () -> Void
    let onSetup: () -> Void
    
    @Environment(\.selectedAppVariant) private var selectedAppVariant
    @State private var showAccountDetails = false
    @State private var showCardStyleSelection = false
    
    // Check if any cards should be shown
    private var hasAnyCards: Bool {
        !hasAddedMoney || !hasSentMoney || !hasSetupAccount || !hasCard
    }
    
    var body: some View {
        if hasAnyCards {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Get started on Sling")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                
                // Horizontal scrollable cards
                ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Add money card
                    if !hasAddedMoney {
                        GetStartedCard(
                            iconContent: AnyView(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: "E9FAEB"))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Color(hex: "78D381"))
                                }
                            ),
                            title: "Add money to your account",
                            subtitle: "Top up your balance to start sending and spending.",
                            buttonTitle: "Add money",
                            action: onAddMoney
                        )
                    }
                    
                    // Send money card
                    if !hasSentMoney {
                        GetStartedCard(
                            iconContent: AnyView(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: "E8F8FF"))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Color(hex: "74CDFF"))
                                }
                            ),
                            title: "Send money to anyone, instantly",
                            subtitle: "Pay friends and family with zero fees.",
                            buttonTitle: "Send money",
                            action: onSendMoney
                        )
                    }
                    
                    // Account details card
                    if !hasSetupAccount {
                        GetStartedCard(
                            iconContent: AnyView(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: "FFE8F9"))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "building.columns.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Color(hex: "FF74E0"))
                                }
                            ),
                            title: "View your USD and EUR account details",
                            subtitle: "Get your own account details to receive payments from anywhere.",
                            buttonTitle: "View details",
                            action: { showAccountDetails = true }
                        )
                    }
                    
                    
                    // Sling Card promo card
                    if !hasCard {
                        GetStartedCard(
                            iconContent: AnyView(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: "FFF0E8"))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Color(hex: "FF8C42"))
                                }
                            ),
                            title: "Create your Sling Card today",
                            subtitle: "Get your new virtual debit card, and start spending around the world.",
                            buttonTitle: "Create Sling Card",
                            action: {
                                if selectedAppVariant == .newNavMVP {
                                    // MVP: skip card selection, create orange card directly
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    selectedCardStyle = "orange"
                                    cardSpendingUSD = 0
                                    hasCard = true
                                } else {
                                    showCardStyleSelection = true
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            }
            .padding(.top, 16)
            .sheet(isPresented: $showAccountDetails, onDismiss: {
                hasSetupAccount = true
            }) {
                HomeAccountDetailsSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showCardStyleSelection) {
                CardStyleSelectionView(isPresented: $showCardStyleSelection)
            }
        }
    }
}

// MARK: - Home Account Details Sheet

struct HomeAccountDetailsSheet: View {
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "FFE8F9"))
                        .frame(width: 56, height: 56)
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "FF74E0"))
                }
                
                Text("Your Account Details")
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
            
            // USD Account
            VStack(spacing: 0) {
                HomeAccountDetailRow(label: "USD Account", value: "")
                HomeAccountDetailRow(label: "Account Name", value: "Sling Money Inc.")
                HomeAccountDetailRow(label: "Account Number", value: "8427193650")
                HomeAccountDetailRow(label: "Routing Number", value: "026009593")
                HomeAccountDetailRow(label: "Bank", value: "Community Federal Savings Bank")
            }
            .background(themeService.currentTheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F5F5F5"))
            .cornerRadius(24)
            .padding(.horizontal, 16)
            
            Spacer().frame(height: 16)
            
            // EUR Account
            VStack(spacing: 0) {
                HomeAccountDetailRow(label: "EUR Account", value: "")
                HomeAccountDetailRow(label: "IBAN", value: "DE89 3704 0044 0532 0130 00")
                HomeAccountDetailRow(label: "BIC/SWIFT", value: "COBADEFFXXX")
                HomeAccountDetailRow(label: "Bank", value: "Commerzbank AG")
            }
            .background(themeService.currentTheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F5F5F5"))
            .cornerRadius(24)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeService.backgroundColor)
    }
}

struct HomeAccountDetailRow: View {
    let label: String
    let value: String
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom(value.isEmpty ? "Inter-Bold" : "Inter-Regular", size: value.isEmpty ? 14 : 16))
                .foregroundColor(value.isEmpty ? themeService.textSecondaryColor : themeService.textSecondaryColor)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, value.isEmpty ? 12 : 14)
    }
}

// MARK: - Get Started Card

struct GetStartedCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    let iconContent: AnyView
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    
    private let cardWidth: CGFloat = 280
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 0) {
                // Icon/Image content
                iconContent
                    .frame(height: 80)
                
                Spacer().frame(height: 16)
                
                // Text content
                VStack(spacing: 4) {
                    Text(title)
                        .font(.custom("Inter-Bold", size: 20))
                        .foregroundColor(Color("TextPrimary"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(subtitle)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Space between body and button
                Spacer()
                    .frame(height: 24)
                
                // Button (on-card style - always grey)
                Text(buttonTitle)
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(themeService.textPrimaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(height: 36)
                    .background(Color(hex: themeService.currentTheme == .dark ? "3A3A3C" : "EDEDED"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
            .frame(width: cardWidth)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeService.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PressedButtonStyle())
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
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
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
    @ObservedObject private var themeService = ThemeService.shared
    @State private var isAnimating = false
    
    private var skeletonColor: Color {
        themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F7F7F7")
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(skeletonColor)
                .frame(width: 44, height: 44)
            
            // Text placeholders
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 32) {
                    // Title placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(skeletonColor)
                        .frame(height: 16)
                    
                    // Status placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(skeletonColor)
                        .frame(width: 59, height: 16)
                }
                .padding(.vertical, 4)
                
                // Subtitle placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
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

// MARK: - Home Savings Card

struct HomeSavingsCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var savingsService = SavingsService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @State private var exchangeRate: Double = 1.0
    
    private let exchangeRateService = ExchangeRateService.shared
    
    private var formattedBalance: String {
        let usdValue = savingsService.totalValueUSD
        if displayCurrencyService.displayCurrency == "USD" {
            return usdValue.asCurrency(displayCurrencyService.currencySymbol)
        } else {
            let convertedValue = usdValue * exchangeRate
            return convertedValue.asCurrency(displayCurrencyService.currencySymbol)
        }
    }
    
    private var formattedBalanceUSD: String {
        let usdValue = savingsService.totalValueUSD
        return usdValue.asCurrency("$")
    }
    
    private func fetchExchangeRate() {
        let currency = displayCurrencyService.displayCurrency
        guard currency != "USD" else {
            exchangeRate = 1.0
            return
        }
        
        Task {
            if let rate = await exchangeRateService.getRate(from: "USD", to: currency) {
                await MainActor.run {
                    exchangeRate = rate
                }
            }
        }
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            NotificationCenter.default.post(name: .navigateToSavings, object: nil)
        }) {
            VStack(alignment: .leading, spacing: 4) {
                // Label with APY and display currency
                HStack(spacing: 4) {
                    Text("3.50% APY")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(Color(hex: "57CE43"))
                    
                    // Show display currency amount if not USD
                    if displayCurrencyService.displayCurrency != "USD" {
                        Text("·")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Text(formattedBalance)
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                }
                
                // Balance in USD
                Text(formattedBalanceUSD)
                    .font(.custom("Inter-Bold", size: 32))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(themeService.cardBackgroundColor)
            .cornerRadius(24)
        }
        .buttonStyle(PressedButtonStyle())
        .onAppear {
            fetchExchangeRate()
        }
        .onChange(of: displayCurrencyService.displayCurrency) {
            fetchExchangeRate()
        }
    }
}

// MARK: - Home Portfolio Card

struct HomePortfolioCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    
    @State private var exchangeRate: Double = 1.0
    
    private let exchangeRateService = ExchangeRateService.shared
    
    private var portfolioValueUSD: Double {
        portfolioService.portfolioValue()
    }
    
    private var portfolioValueDisplay: Double {
        displayCurrencyService.displayCurrency == "USD" ? portfolioValueUSD : portfolioValueUSD * exchangeRate
    }
    
    private var formattedBalance: String {
        let symbol = ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
        return portfolioValueDisplay.asCurrency(symbol)
    }
    
    private var totalGainLossUSD: Double {
        let costBasis = portfolioService.holdings.values.reduce(0) { $0 + $1.totalCost }
        return portfolioValueUSD - costBasis
    }
    
    private var totalGainLossDisplay: Double {
        displayCurrencyService.displayCurrency == "USD" ? totalGainLossUSD : totalGainLossUSD * exchangeRate
    }
    
    private var isPositive: Bool {
        totalGainLossUSD >= 0
    }
    
    private var formattedGainLoss: String {
        let symbol = ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
        return abs(totalGainLossDisplay).asCurrency(symbol)
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            NotificationCenter.default.post(name: .navigateToInvest, object: nil)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Label with gain
                    HStack(spacing: 5) {
                        Text("Portfolio")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        if portfolioValueUSD > 0 {
                            Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isPositive ? Color(hex: "57CE43") : Color(hex: "E30000"))
                            
                            Text(formattedGainLoss)
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(isPositive ? Color(hex: "57CE43") : Color(hex: "E30000"))
                        }
                    }
                    
                    // Balance
                    Text(formattedBalance)
                        .font(.custom("Inter-Bold", size: 32))
                        .foregroundColor(themeService.textPrimaryColor)
                }
                
                Spacer()
                
                // Mini chart (only show if has holdings)
                if portfolioValueUSD > 0 {
                    MiniPortfolioChart()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(themeService.cardBackgroundColor)
            .cornerRadius(24)
        }
        .buttonStyle(PressedButtonStyle())
        .onAppear {
            fetchExchangeRate()
        }
        .onChange(of: displayCurrencyService.displayCurrency) { _, _ in
            fetchExchangeRate()
        }
    }
    
    private func fetchExchangeRate() {
        let currency = displayCurrencyService.displayCurrency
        guard currency != "USD" else {
            exchangeRate = 1.0
            return
        }
        
        Task {
            if let rate = await exchangeRateService.getRate(from: "USD", to: currency) {
                await MainActor.run {
                    exchangeRate = rate
                }
            }
        }
    }
}

// MARK: - Mini Portfolio Chart

struct MiniPortfolioChart: View {
    @ObservedObject private var portfolioService = PortfolioService.shared
    
    private let chartWidth: CGFloat = 119
    private let chartHeight: CGFloat = 55
    
    private var chartData: [CGFloat] {
        portfolioService.generateChartData(period: "1D", sampleCount: 10)
    }
    
    private var isPositive: Bool {
        guard chartData.count >= 2 else { return true }
        return chartData.last ?? 0 >= chartData.first ?? 0
    }
    
    private var chartColor: Color {
        isPositive ? Color(hex: "57CE43") : Color(hex: "E30000")
    }
    
    private let inset: CGFloat = 4 // Keep stroke away from edges
    
    var body: some View {
        if chartData.count >= 2 {
            Path { path in
                let drawWidth = chartWidth - inset * 2
                let drawHeight = chartHeight - inset * 2
                let stepX = drawWidth / CGFloat(chartData.count - 1)
                
                // Normalize data to fit in chart height
                let minVal = chartData.min() ?? 0
                let maxVal = chartData.max() ?? 1
                let range = maxVal - minVal
                
                let normalizedData = chartData.map { value -> CGFloat in
                    if range == 0 { return inset + drawHeight / 2 }
                    return inset + drawHeight - ((value - minVal) / range * drawHeight * 0.8 + drawHeight * 0.1)
                }
                
                path.move(to: CGPoint(x: inset, y: normalizedData[0]))
                for (index, y) in normalizedData.enumerated().dropFirst() {
                    path.addLine(to: CGPoint(x: inset + CGFloat(index) * stepX, y: y))
                }
            }
            .stroke(chartColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            .frame(width: chartWidth, height: chartHeight)
        } else {
            // Fallback static chart
            Path { path in
                let drawWidth = chartWidth - inset * 2
                let drawHeight = chartHeight - inset * 2
                let points: [(CGFloat, CGFloat)] = [
                    (0, 0.82), (0.17, 0.55), (0.34, 0.64), (0.50, 0.36), (0.67, 0.45), (0.84, 0.18), (1.0, 0.0)
                ]
                path.move(to: CGPoint(x: inset + points[0].0 * drawWidth, y: inset + points[0].1 * drawHeight))
                for point in points.dropFirst() {
                    path.addLine(to: CGPoint(x: inset + point.0 * drawWidth, y: inset + point.1 * drawHeight))
                }
            }
            .stroke(chartColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            .frame(width: chartWidth, height: chartHeight)
        }
    }
}

// MARK: - All Activity View (full screen wrapper)

struct AllActivityView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @State private var selectedActivity: ActivityItem?
    @State private var showTransactionDetail = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button on left
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // Title
                Text("Activity")
                    .font(.custom("Inter-Bold", size: 32))
                    .tracking(-0.64)
                    .foregroundColor(themeService.textPrimaryColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 32)
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Activity list
                ScrollView {
                    TransactionListContent(
                        onTransactionSelected: { activity in
                            selectedActivity = activity
                            showTransactionDetail = true
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
        }
        .transactionDetailDrawer(isPresented: $showTransactionDetail, activity: selectedActivity)
    }
}

// MARK: - Virtual Accounts Carousel

struct VirtualAccountsCarousel: View {
    let onAccountTap: (String) -> Void
    var onLockedAccountTap: ((String) -> Void)? = nil
    @AppStorage("unlockedAccounts") private var unlockedAccountsRaw = "USD"
    
    // All available accounts in display order
    private static let allAccounts: [(currency: String, label: String, lastFour: String)] = [
        ("USD", "USD account details", "6789"),
        ("BRL", "BRL account details", "8900"),
        ("MXN", "MXN account details", "4521"),
        ("EUR", "EUR account details", "0130"),
        ("GBP", "GBP account details", "9268")
    ]
    
    private var unlockedCurrencies: Set<String> {
        Set(unlockedAccountsRaw.split(separator: ",").map(String.init))
    }
    
    private func isUnlocked(_ currency: String) -> Bool {
        unlockedCurrencies.contains(currency)
    }
    
    private func unlockAccount(_ currency: String) {
        var currencies = unlockedCurrencies
        currencies.insert(currency)
        unlockedAccountsRaw = currencies.sorted().joined(separator: ",")
    }
    
    private var visibleAccounts: [(currency: String, label: String, lastFour: String)] {
        Self.allAccounts.filter { isUnlocked($0.currency) }
    }
    
    private var hasLockedAccounts: Bool {
        Self.allAccounts.contains { !isUnlocked($0.currency) }
    }
    
    private var firstLockedCurrency: String? {
        Self.allAccounts.first { !isUnlocked($0.currency) }?.currency
    }
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth: CGFloat = 353
            let horizontalInset = (geometry.size.width - cardWidth) / 2
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Show unlocked accounts
                    ForEach(visibleAccounts, id: \.currency) { account in
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onAccountTap(account.currency)
                        }) {
                            VirtualAccountCard(
                                label: account.label,
                                lastFour: account.lastFour
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // "Get more" card if there are still locked accounts
                    if hasLockedAccounts {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onLockedAccountTap?("ALL")
                        }) {
                            GetMoreAccountsCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, horizontalInset)
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .frame(height: 88)
    }
}

// MARK: - All Account Details View

struct AllAccountDetailsView: View {
    @Binding var isPresented: Bool
    var onOpenOnboarding: (String) -> Void
    var onOpenDetails: (String) -> Void
    @AppStorage("unlockedAccounts") private var unlockedAccountsRaw = "USD"
    @ObservedObject private var themeService = ThemeService.shared
    
    private let allCurrencies: [(code: String, name: String, transferType: String, secondaryText: String?, icon: String)] = [
        ("BRL", "Brazilian real", "Pix transfer", nil, "FlagBR"),
        ("USD", "US dollar", "ACH or Wire transfer", nil, "FlagUS"),
        ("MXN", "Mexican peso", "CLABE transfer", nil, "FlagMX"),
        ("EUR", "Euro", "IBAN", "SEPA transfer", "FlagEUR"),
        ("GBP", "British pound", "Sort code & Account number", nil, "FlagGB")
    ]
    
    private var unlockedCurrencies: Set<String> {
        Set(unlockedAccountsRaw.split(separator: ",").map(String.init))
    }
    
    private var unlockedRows: [(code: String, name: String, transferType: String, secondaryText: String?, icon: String)] {
        allCurrencies.filter { unlockedCurrencies.contains($0.code) }
    }
    
    private var lockedRows: [(code: String, name: String, transferType: String, secondaryText: String?, icon: String)] {
        allCurrencies.filter { !unlockedCurrencies.contains($0.code) }
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 32, height: 32)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title and subtitle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your account details")
                                .font(.custom("Inter-Bold", size: 28))
                                .tracking(-0.56)
                                .foregroundColor(themeService.textPrimaryColor)
                            
                            Text("Send money to these details, or share them to get paid. Funds arrive as digital dollars in your Sling Balance.")
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(themeService.textSecondaryColor)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        
                        // Currency rows
                        VStack(spacing: 0) {
                            // Unlocked accounts
                            ForEach(Array(unlockedRows.enumerated()), id: \.element.code) { index, row in
                                let isLast = index == unlockedRows.count - 1 && lockedRows.isEmpty
                                CurrencyAccountRow(
                                    currencyName: row.name,
                                    transferType: row.transferType,
                                    secondaryText: row.secondaryText,
                                    currencyIcon: row.icon,
                                    position: index == 0 ? .top : (isLast ? .bottom : .middle),
                                    onTap: { onOpenDetails(row.code) }
                                )
                            }
                            
                            // "Get new account details" section header
                            if !lockedRows.isEmpty {
                                HStack {
                                    Text("Get new account details")
                                        .font(.custom("Inter-Bold", size: 14))
                                        .foregroundColor(themeService.textSecondaryColor)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                // Locked accounts
                                ForEach(Array(lockedRows.enumerated()), id: \.element.code) { index, row in
                                    CurrencyAccountRow(
                                        currencyName: row.name,
                                        transferType: row.transferType,
                                        secondaryText: row.secondaryText,
                                        currencyIcon: row.icon,
                                        position: index == lockedRows.count - 1 ? .bottom : .middle,
                                        onTap: { onOpenOnboarding(row.code) }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Get More Accounts Card

struct GetMoreAccountsCard: View {
    @AppStorage("unlockedAccounts") private var unlockedAccountsRaw = "USD"
    
    private let allCurrencies = ["USD", "BRL", "MXN", "EUR", "GBP"]
    
    private var availableTickers: String {
        let unlocked = Set(unlockedAccountsRaw.split(separator: ",").map(String.init))
        let locked = allCurrencies.filter { !unlocked.contains($0) }
        return locked.joined(separator: " · ")
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Get other account details")
                    .font(.custom("Inter-Bold", size: 18))
                    .tracking(-0.36)
                    .foregroundColor(Color(hex: "080808"))
                
                Text(availableTickers)
                    .font(.custom("Inter-Medium", size: 14))
                    .tracking(-0.28)
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            
            Spacer()
            
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "FF5113"))
        }
        .padding(16)
        .frame(width: 353)
        .frame(maxHeight: .infinity)
        .background(.white)
        .cornerRadius(24)
    }
}

// MARK: - Account Onboarding View

struct AccountOnboardingView: View {
    let currency: String
    let onCreateAccount: () -> Void
    let onDismiss: () -> Void
    
    @AppStorage("unlockedAccounts") private var unlockedAccountsRaw = "USD"
    @ObservedObject private var themeService = ThemeService.shared
    
    private func unlockAccount() {
        var currencies = Set(unlockedAccountsRaw.split(separator: ",").map(String.init))
        currencies.insert(currency)
        unlockedAccountsRaw = currencies.sorted().joined(separator: ",")
    }
    
    // Currency-specific content
    private var accountTypeName: String {
        switch currency {
        case "BRL": return "Pix key"
        case "MXN": return "CLABE"
        case "EUR": return "IBAN"
        case "GBP": return "sort code"
        case "USD": return "routing number"
        default: return "account"
        }
    }
    
    private var currencyCode: String { currency }
    
    private var flagEmoji: String {
        switch currency {
        case "BRL": return "🇧🇷"
        case "MXN": return "🇲🇽"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "USD": return "🇺🇸"
        default: return "🌐"
        }
    }
    
    private var benefits: [(icon: String, text: String)] {
        switch currency {
        case "BRL":
            return [
                ("person.2", "Get paid by clients or employers"),
                ("building.columns", "Add money from your bank account"),
                ("dollarsign.circle", "Hold money in digital dollars"),
                ("checkmark.shield", "No management fees")
            ]
        case "MXN":
            return [
                ("person.2", "Get paid by clients or employers"),
                ("building.columns", "Add money from your Mexican bank"),
                ("dollarsign.circle", "Hold money in digital dollars"),
                ("checkmark.shield", "No management fees")
            ]
        case "EUR":
            return [
                ("person.2", "Receive SEPA payments from anyone"),
                ("building.columns", "Add money from your EU bank"),
                ("dollarsign.circle", "Hold money in digital dollars"),
                ("checkmark.shield", "No management fees")
            ]
        case "GBP":
            return [
                ("person.2", "Get paid by UK clients or employers"),
                ("building.columns", "Add money from your UK bank"),
                ("dollarsign.circle", "Hold money in digital dollars"),
                ("checkmark.shield", "No management fees")
            ]
        default:
            return [
                ("person.2", "Get paid by clients or employers"),
                ("building.columns", "Add money from your bank account"),
                ("dollarsign.circle", "Hold money in digital dollars"),
                ("checkmark.shield", "No management fees")
            ]
        }
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onDismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "080808"))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Illustration: two overlapping cards with flag
                        ZStack {
                            // Bank card (back)
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "1C1C1E"))
                                    .frame(width: 72, height: 72)
                                
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -20, y: 0)
                            .rotationEffect(.degrees(-8))
                            
                            // Details card (front)
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "1C1C1E"))
                                    .frame(width: 72, height: 72)
                                
                                VStack(spacing: 4) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.white.opacity(0.4))
                                            .frame(width: 36, height: 4)
                                    }
                                }
                            }
                            .offset(x: 20, y: 0)
                            .rotationEffect(.degrees(5))
                            
                            // Account number preview
                            HStack(spacing: 2) {
                                Text("••••")
                                    .font(.custom("Inter-Bold", size: 11))
                                    .foregroundColor(Color(hex: "7B7B7B"))
                                Text("7241")
                                    .font(.custom("Inter-Bold", size: 11))
                                    .foregroundColor(Color(hex: "080808"))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                            .offset(x: 20, y: -36)
                            
                            // Flag badge
                            Text(flagEmoji)
                                .font(.system(size: 18))
                                .offset(x: -28, y: 36)
                            
                            // Green checkmark
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "57CE43"))
                                    .frame(width: 20, height: 20)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 44, y: 36)
                        }
                        .frame(height: 140)
                        .padding(.top, 24)
                        
                        // Title
                        Text("Get your own \(accountTypeName) to receive \(currencyCode)")
                            .font(.custom("Inter-Bold", size: 32))
                            .tracking(-0.64)
                            .foregroundColor(Color(hex: "080808"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        
                        // Subtitle
                        Text("Money sent to your \(accountTypeName) arrives as **digital dollars** in your Sling Balance. By opening this account, you agree to our **user terms**.")
                            .font(.custom("Inter-Regular", size: 16))
                            .tracking(-0.32)
                            .lineSpacing(4)
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                        
                        // Benefits list
                        VStack(spacing: 0) {
                            ForEach(Array(benefits.enumerated()), id: \.offset) { _, benefit in
                                HStack(spacing: 16) {
                                    Image(systemName: benefit.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: "5AC8FA"))
                                        .frame(width: 28, height: 28)
                                    
                                    Text(benefit.text)
                                        .font(.custom("Inter-Bold", size: 16))
                                        .tracking(-0.32)
                                        .foregroundColor(Color(hex: "080808"))
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                }
                
                // CTA button pinned at bottom
                Button(action: {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    unlockAccount()
                    onCreateAccount()
                }) {
                    Text("Create account details")
                        .font(.custom("Inter-Bold", size: 16))
                        .tracking(-0.32)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "080808"))
                        .cornerRadius(20)
                }
                .buttonStyle(PressedButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Virtual Account Card

struct VirtualAccountCard: View {
    let label: String
    let lastFour: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Image("IconBankSmall")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color(hex: "7B7B7B"))
                    
                    Text(label)
                        .font(.custom("Inter-Medium", size: 16))
                        .tracking(-0.32)
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
                
                HStack(spacing: 12) {
                    Text(lastFour)
                        .font(.custom("Inter-Bold", size: 32))
                        .tracking(-0.64)
                        .foregroundColor(Color(hex: "080808"))
                    
                    Text("••••")
                        .font(.custom("Inter-Bold", size: 32))
                        .tracking(-0.64)
                        .foregroundColor(Color(hex: "080808"))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .frame(width: 353)
        .background(.white)
        .cornerRadius(24)
    }
}

// MARK: - Add New Account Card

struct AddNewAccountCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add new account")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                Text("Get new account details")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            
            Spacer()
            
            // Plus icon in circle
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "F7F7F7"))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "080808"))
            }
        }
        .padding(16)
        .frame(width: 353)
        .frame(maxHeight: .infinity)
        .background(.white)
        .cornerRadius(24)
    }
}

// MARK: - Spent This Month Card

struct SpentThisMonthCard: View {
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @AppStorage("hasCard") private var hasCard = false
    @AppStorage("cardSpendingUSD") private var cardSpendingUSD: Double = 0
    
    private var currencySymbol: String {
        ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
    }
    
    private var formattedAmount: String {
        if displayCurrencyService.displayCurrency == "USD" {
            return cardSpendingUSD.asCurrency("$")
        }
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: displayCurrencyService.displayCurrency) {
            return (cardSpendingUSD * rate).asCurrency(currencySymbol)
        }
        return cardSpendingUSD.asCurrency("$")
    }
    
    var body: some View {
        if hasCard {
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                NotificationCenter.default.post(name: .navigateToCard, object: nil)
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Spent this month")
                            .font(.custom("Inter-Medium", size: 16))
                            .tracking(-0.32)
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Text(formattedAmount)
                            .font(.custom("Inter-Bold", size: 32))
                            .tracking(-0.64)
                            .foregroundColor(Color(hex: "080808"))
                    }
                    
                    Spacer()
                    
                    // Mini card thumbnail
                    MiniCardThumbnail()
                        .frame(width: 56, height: 36)
                }
                .padding(16)
                .background(.white)
                .cornerRadius(24)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Mini Card Thumbnail

struct MiniCardThumbnail: View {
    @AppStorage("selectedCardStyle") private var selectedCardStyle = "orange"
    
    private var cardOption: CardBackgroundOption? {
        CardBackgroundOption.option(for: selectedCardStyle)
    }
    
    var body: some View {
        ZStack {
            // Background: color or image based on selected style
            if let option = cardOption {
                switch option.type {
                case .color(let color):
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                case .image(let horizontal, _):
                    Image(horizontal)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 36)
                        .clipped()
                        .cornerRadius(6)
                }
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "FF5113"))
            }
            
            // Sling logo watermark
            Image("SlingLogo")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 36)
                .foregroundColor(Color.white.opacity(0.08))
            
            // Visa logo bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("VisaLogo")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.trailing, 4)
                        .padding(.bottom, 4)
                }
            }
        }
        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
}
