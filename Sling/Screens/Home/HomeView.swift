import SwiftUI
import UIKit

struct HomeView: View {
    @State private var showAddMoney = false
    @State private var showWithdraw = false
    @State private var showSendMoney = false
    @State private var showSetup = false
    @State private var showAllActivity = false
    @ObservedObject private var activityService = ActivityService.shared
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Balance (without button - buttons are below)
                BalanceView(onBalanceTap: {
                    NotificationCenter.default.post(name: .showBalanceSheet, object: nil)
                })
                    .padding(.horizontal, 16)
                
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
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                // Get started on Sling section
                GetStartedSection(
                    onAddMoney: { showAddMoney = true },
                    onSendMoney: { showSendMoney = true },
                    onSetup: { showSetup = true }
                )
                
                // Savings Summary Card
                HomeSavingsCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Activity Section
                VStack(spacing: 0) {
                    // Activity title with See more button
                    HStack {
                        Text("Activity")
                            .font(.custom("Inter-Bold", size: 24))
                            .tracking(-0.48) // -2% of 24px
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        Spacer()
                        
                        // See all button (only show if there are more than 3 activities)
                        if activityService.activities.count > 3 {
                            Button(action: { showAllActivity = true }) {
                                Text("See all")
                                    .font(.custom("Inter-SemiBold", size: 14))
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    if activityService.activities.isEmpty && !activityService.isLoading {
                        // Empty state
                        HomeEmptyStateCard()
                            .padding(.vertical, 24)
                            .padding(.horizontal, 32)
                    } else if activityService.isLoading && activityService.activities.isEmpty {
                        // Loading state with skeleton rows
                        VStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonTransactionRow()
                            }
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 32)
                    } else {
                        // Transaction list - show only 3 on home (no See more at bottom)
                        TransactionListContent(
                            limit: 3,
                            onTransactionSelected: { activity in
                                NotificationCenter.default.post(name: .showTransactionDetail, object: activity)
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
                .background(themeService.currentTheme == .white ? Color.clear : themeService.backgroundSecondaryColor)
                .cornerRadius(themeService.currentTheme == .white ? 0 : 24)
                .padding(.horizontal, themeService.currentTheme == .white ? 0 : 16)
                .padding(.top, 16)
                
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                // Horizontal scrollable cards
                ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                                NotificationCenter.default.post(name: .navigateToCard, object: nil)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
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
                // Label with APY
                HStack(spacing: 4) {
                    Text("Savings")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    Text("·")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    Text("3.50% APY")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(Color(hex: "57CE43"))
                }
                
                // Balance
                Text(formattedBalance)
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
    
    var body: some View {
        if chartData.count >= 2 {
            Path { path in
                let stepX = chartWidth / CGFloat(chartData.count - 1)
                
                // Normalize data to fit in chart height
                let minVal = chartData.min() ?? 0
                let maxVal = chartData.max() ?? 1
                let range = maxVal - minVal
                
                let normalizedData = chartData.map { value -> CGFloat in
                    if range == 0 { return chartHeight / 2 }
                    return chartHeight - ((value - minVal) / range * chartHeight * 0.8 + chartHeight * 0.1)
                }
                
                path.move(to: CGPoint(x: 0, y: normalizedData[0]))
                for (index, y) in normalizedData.enumerated().dropFirst() {
                    path.addLine(to: CGPoint(x: CGFloat(index) * stepX, y: y))
                }
            }
            .stroke(chartColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            .frame(width: chartWidth, height: chartHeight)
        } else {
            // Fallback static chart
            Path { path in
                let points: [(CGFloat, CGFloat)] = [
                    (0, 45), (20, 35), (40, 40), (60, 25), (80, 30), (100, 15), (119, 5)
                ]
                path.move(to: CGPoint(x: points[0].0, y: points[0].1))
                for point in points.dropFirst() {
                    path.addLine(to: CGPoint(x: point.0, y: point.1))
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
        NavigationStack {
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
            .background(themeService.backgroundColor)
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(hex: "B0B0B0"), Color(hex: "E8E8E8"))
                    }
                }
            }
        }
        .transactionDetailDrawer(isPresented: $showTransactionDetail, activity: selectedActivity)
    }
}

#Preview {
    HomeView()
}
