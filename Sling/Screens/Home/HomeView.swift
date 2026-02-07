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
    
    let onAddMoney: () -> Void
    let onSendMoney: () -> Void
    let onSetup: () -> Void
    
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
                                showCardStyleSelection = true
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
    
    // Virtual accounts data
    private let accounts: [(currency: String, label: String, lastFour: String, flagAsset: String)] = [
        ("BRL", "BRL account details", "8900", "FlagBR"),
        ("USD", "USD account details", "6789", "FlagUS"),
        ("EUR", "EUR account details", "0130", "FlagEUR"),
        ("GBP", "GBP account details", "9268", "FlagGB")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth: CGFloat = 353
            let horizontalInset = (geometry.size.width - cardWidth) / 2
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(accounts, id: \.currency) { account in
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
                    
                    // Add new account card
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        // TODO: Open add new account flow
                    }) {
                        AddNewAccountCard()
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .scrollTargetLayout()
                .padding(.horizontal, horizontalInset)
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .frame(height: 88)
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
    
    // Mock spending data in USD
    private let spentThisMonthUSD: Double = 3430
    
    private var currencySymbol: String {
        ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
    }
    
    private var formattedAmount: String {
        if displayCurrencyService.displayCurrency == "USD" {
            return spentThisMonthUSD.asCurrency("$")
        }
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: displayCurrencyService.displayCurrency) {
            return (spentThisMonthUSD * rate).asCurrency(currencySymbol)
        }
        return spentThisMonthUSD.asCurrency("$")
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
    var body: some View {
        ZStack {
            // Orange background
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "FF5113"))
            
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
