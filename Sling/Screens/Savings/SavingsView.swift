import SwiftUI

struct SavingsView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var savingsService = SavingsService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @AppStorage("hasStartedSaving") private var hasStartedSaving = false
    @State private var showDepositSheet = false
    @State private var showWithdrawSheet = false
    @State private var showHowItWorks = false
    @State private var showAllActivity = false
    @State private var exchangeRate: Double = 1.0
    
    private let exchangeRateService = ExchangeRateService.shared
    
    var body: some View {
        // Always show main view if user has savings, otherwise respect hasStartedSaving
        Group {
            if hasStartedSaving || savingsService.usdyBalance > 0 {
                savingsMainView
            } else {
                savingsIntroView
            }
        }
        .fullScreenCover(isPresented: $showDepositSheet) {
            SavingsDepositSheet(isPresented: $showDepositSheet)
        }
        .fullScreenCover(isPresented: $showWithdrawSheet) {
            SavingsWithdrawSheet(isPresented: $showWithdrawSheet)
        }
        .fullScreenCover(isPresented: $showHowItWorks) {
            SavingsHowItWorksSheet(isPresented: $showHowItWorks)
                .background(ClearBackgroundView())
        }
    }
    
    // MARK: - Main Savings View (after onboarding)
    
    /// Number formatter with thousand separators
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter
    }
    
    /// Formatted savings balance in display currency
    private var formattedSavingsBalance: String {
        let usdValue = savingsService.totalValueUSD
        let value = displayCurrencyService.displayCurrency == "USD" ? usdValue : usdValue * exchangeRate
        let formatted = currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "\(displayCurrencyService.currencySymbol)\(formatted)"
    }
    
    /// Formatted USDY token amount
    private var formattedUSDYAmount: String {
        let tokens = savingsService.usdyBalance
        if tokens == 0 {
            return "0 USDY"
        }
        let formatted = currencyFormatter.string(from: NSNumber(value: tokens)) ?? String(format: "%.2f", tokens)
        return "\(formatted) USDY"
    }
    
    /// Formatted total earnings in display currency
    private var formattedTotalEarnings: String {
        let usdEarnings = savingsService.totalEarnings
        let value = displayCurrencyService.displayCurrency == "USD" ? usdEarnings : usdEarnings * exchangeRate
        let formatted = currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "+\(displayCurrencyService.currencySymbol)\(formatted)"
    }
    
    /// Formatted monthly earnings in display currency
    /// For now, we calculate earnings since the start of current month
    private var formattedMonthlyEarnings: String {
        // Get the start of the current month
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return formattedTotalEarnings
        }
        
        // Calculate earnings since start of month (approximation based on time elapsed)
        guard let depositTimestamp = savingsService.depositTimestamp else {
            return "+\(displayCurrencyService.currencySymbol)0.00"
        }
        
        // If deposit was after start of month, use full earnings
        if depositTimestamp >= startOfMonth {
            return formattedTotalEarnings
        }
        
        // Otherwise, calculate proportional earnings for this month
        let totalSecondsElapsed = now.timeIntervalSince(depositTimestamp)
        let monthSecondsElapsed = now.timeIntervalSince(startOfMonth)
        
        guard totalSecondsElapsed > 0 else {
            return "+\(displayCurrencyService.currencySymbol)0.00"
        }
        
        let monthlyProportion = monthSecondsElapsed / totalSecondsElapsed
        let usdMonthlyEarnings = savingsService.totalEarnings * monthlyProportion
        let value = displayCurrencyService.displayCurrency == "USD" ? usdMonthlyEarnings : usdMonthlyEarnings * exchangeRate
        let formatted = currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "+\(displayCurrencyService.currencySymbol)\(formatted)"
    }
    
    /// Subtitle for monthly earnings showing date range
    private var monthlyEarningsSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
            return "This month"
        }
        return "From \(formatter.string(from: startOfMonth)) until today"
    }
    
    /// Subtitle for total earnings showing start date
    private var totalEarningsSubtitle: String {
        guard let startDate = savingsService.depositTimestamp else {
            return "No deposits yet"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return "Started in \(formatter.string(from: startDate))"
    }
    
    /// Fetch current exchange rate
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
    
    /// Convert a SavingsTransaction to ActivityItem for detail view
    private func activityItem(from transaction: SavingsTransaction) -> ActivityItem {
        let title = transaction.isDeposit ? "Savings" : "Savings"
        let subtitle = transaction.isDeposit ? "Deposit" : "Withdrawal"
        let prefix = transaction.isDeposit ? "+" : "-"
        let formattedAmount = "\(prefix)\(transaction.usdAmount.asCurrency(displayCurrencyService.currencySymbol))"
        let formattedUSDY = "\(NumberFormatService.shared.formatNumber(transaction.usdyAmount)) USDY"
        
        return ActivityItem(
            avatar: "IconSavings",
            titleLeft: title,
            subtitleLeft: subtitle,
            titleRight: formattedAmount,
            subtitleRight: formattedUSDY,
            date: transaction.date
        )
    }
    
    private var savingsMainView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Balance header
                savingsBalanceHeader
                    .padding(.horizontal, 16)
                
                // Deposit + Withdraw buttons
                HStack(spacing: 8) {
                    TertiaryButton(title: "Deposit") {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showDepositSheet = true
                    }
                    
                    TertiaryButton(title: "Withdraw") {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showWithdrawSheet = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Set a savings goal row
                PressableRow(onTap: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    // TODO: Navigate to savings goal screen
                }) {
                    HStack(spacing: 16) {
                        // Icon in rounded square background
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeService.currentTheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F7F7F7"))
                                .frame(width: 44, height: 44)
                            
                            Image("IconSavingsGoal")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                                .foregroundColor(Color(hex: "888888"))
                        }
                        
                        Text("Set a savings goal")
                            .font(.custom("Inter-Bold", size: 16))
                            .tracking(-0.32)
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                    .padding(16)
                }
                .background(themeService.cardBackgroundColor)
                .cornerRadius(24)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Earnings card (combined)
                VStack(spacing: 0) {
                    earningsRowContent(
                        title: "Earned this month",
                        subtitle: monthlyEarningsSubtitle,
                        value: formattedMonthlyEarnings
                    )
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    earningsRowContent(
                        title: "Total earned",
                        subtitle: totalEarningsSubtitle,
                        value: formattedTotalEarnings
                    )
                }
                .background(themeService.cardBackgroundColor)
                .cornerRadius(24)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // MARK: - Savings Activity Feed (temporarily hidden - set showSavingsActivity to true to re-enable)
                // Transaction history
                let showSavingsActivity = false
                if showSavingsActivity && !savingsService.transactions.isEmpty {
                    let displayedTransactions = Array(savingsService.transactions.prefix(3))
                    let hasMore = savingsService.transactions.count > 3
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Title inside card
                        Text("Savings activity")
                            .font(.custom("Inter-Bold", size: 18))
                            .tracking(-0.36)
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 12)
                        
                        ForEach(displayedTransactions) { transaction in
                            SavingsTransactionRow(transaction: transaction)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    let activity = activityItem(from: transaction)
                                    NotificationCenter.default.post(name: .showTransactionDetail, object: activity)
                                }
                        }
                        
                        // "See more" button - opens full screen
                        if hasMore {
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                showAllActivity = true
                            }) {
                                HStack {
                                    Text("See more")
                                        .font(.custom("Inter-SemiBold", size: 16))
                                        .foregroundColor(Color(hex: "FF5113"))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "FF5113"))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    .background(themeService.cardBackgroundColor)
                    .cornerRadius(24)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                
                // How it works row
                PressableRow(onTap: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showHowItWorks = true
                }) {
                    HStack(spacing: 16) {
                        // Icon in rounded square background
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeService.currentTheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F7F7F7"))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(Color(hex: "888888"))
                        }
                        
                        Text("How it works")
                            .font(.custom("Inter-Bold", size: 16))
                            .tracking(-0.32)
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                    .padding(16)
                }
                .background(themeService.cardBackgroundColor)
                .cornerRadius(24)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Demo speed-up notice
                Text("Accumulation is sped up \(NumberFormatService.shared.formatWholeNumber(savingsService.demoTimeMultiplier))x for demo")
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundColor(themeService.textSecondaryColor.opacity(0.6))
                    .padding(.top, 16)
            }
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .sheet(isPresented: $showAllActivity) {
            SavingsAllActivityView(isPresented: $showAllActivity)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            fetchExchangeRate()
        }
        .onChange(of: displayCurrencyService.displayCurrency) {
            fetchExchangeRate()
        }
        // SavingsService.refreshTrigger updates every second, forcing UI refresh
        .onChange(of: savingsService.refreshTrigger) { _, _ in
            // View automatically refreshes when refreshTrigger changes
        }
    }
    
    // MARK: - Savings Balance Header
    
    private var savingsBalanceHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                // Label with USDY amount - matches home balance subtitle style
                HStack(spacing: 0) {
                    Text("Savings")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    Text("・")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    if savingsService.usdyBalance > 0 {
                        Text(formattedUSDYAmount)
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                    } else {
                        Text("3.50% APY")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "57CE43"))
                    }
                }
                
                // Balance in display currency - matches home balance H1 style
                SlidingNumberText(
                    text: formattedSavingsBalance,
                    font: .custom("Inter-Bold", size: 48),
                    color: themeService.textPrimaryColor
                )
                .tracking(-0.96) // -2% letter spacing at 48pt
            }
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    
    // MARK: - Intro View (onboarding)
    
    private var savingsIntroView: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                
                // Green icon
                savingsIcon
                
                // Title and subtitle
                VStack(spacing: 12) {
                    Text("A better way to save")
                        .font(.custom("Inter-Bold", size: 32))
                        .foregroundColor(themeService.textPrimaryColor)
                        .multilineTextAlignment(.center)
                    
                    Text("Save money on Sling and more and more and more and more")
                        .font(.custom("Inter-Regular", size: 17))
                        .foregroundColor(themeService.textSecondaryColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Feature list
                VStack(spacing: 20) {
                    featureRow(icon: "chart.line.uptrend.xyaxis", iconColor: Color(hex: "4FC3F7"), text: "Earn up to 4% interest")
                    featureRow(icon: "scope", iconColor: Color(hex: "4FC3F7"), text: "Set a savings goal")
                    featureRow(icon: "lock.fill", iconColor: Color(hex: "6B7280"), text: "Built in security")
                    featureRow(icon: "dollarsign.circle", iconColor: Color(hex: "4FC3F7"), text: "No minimum balances or fees")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
            }
            
            // Start saving button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                withAnimation {
                    hasStartedSaving = true
                }
            }) {
                Text("Start saving")
                    .font(.custom("Inter-Bold", size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "080808"))
                    .cornerRadius(24)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
            }
        }
        .scrollIndicators(.hidden)
        .background(themeService.backgroundGradient.ignoresSafeArea())
    }
    
    // MARK: - Savings Icon
    
    private var savingsIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "4CAF50"))
                .frame(width: 100, height: 100)
            
            Image(systemName: "dollarsign.arrow.circlepath")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Feature Row
    
    private func featureRow(icon: String, iconColor: Color, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            Text(text)
                .font(.custom("Inter-Bold", size: 17))
                .foregroundColor(themeService.textPrimaryColor)
            
            Spacer()
        }
    }
    
    // MARK: - Earnings Row
    
    private func earningsRowContent(title: String, subtitle: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Left side: Title and subtitle stacked vertically
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .tracking(-0.32)
                    .foregroundColor(themeService.textPrimaryColor)
                
                Text(subtitle)
                    .font(.custom("Inter-Regular", size: 14))
                    .tracking(-0.28)
                    .foregroundColor(themeService.textSecondaryColor)
            }
            
            Spacer()
            
            // Right side: Green amount
            Text(value)
                .font(.custom("Inter-Bold", size: 16))
                .tracking(-0.32)
                .foregroundColor(Color(hex: "57CE43"))
        }
        .padding(16)
    }
}

// MARK: - How It Works Sheet

struct SavingsHowItWorksSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    
    @State private var backgroundOpacity: Double = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showCard = false
    
    // Device corner radius for matching physical device corners
    private var deviceCornerRadius: CGFloat {
        UIScreen.displayCornerRadius
    }
    
    // Rubber band clamping for elastic effect
    private func rubberBandClamp(_ x: CGFloat, limit: CGFloat) -> CGFloat {
        let c: CGFloat = 0.55
        let absX = abs(x)
        let sign = x >= 0 ? 1.0 : -1.0
        return sign * (1 - (1 / ((absX * c / limit) + 1))) * limit
    }
    
    // Calculate stretch scale when pulling up
    private var stretchScale: CGFloat {
        guard dragOffset > 0 else { return 1.0 }
        let stretchAmount = dragOffset / 80.0 * 0.05
        return 1.0 + min(stretchAmount, 0.05)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background - fills entire screen
            Color.black.opacity(backgroundOpacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissSheet()
                }
            
            // Sheet content - anchored to bottom
            if showCard {
                VStack(spacing: 0) {
                    // Drawer handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        Text("How Sling Savings works")
                            .font(.custom("Inter-Bold", size: 24))
                            .tracking(-0.48)
                            .foregroundColor(Color(hex: "080808"))
                        
                        // Body copy
                        VStack(alignment: .leading, spacing: 12) {
                            Text("When you deposit money into Sling Savings, your funds are converted to USDY - a yield-bearing stablecoin backed by US Treasuries.")
                                .font(.custom("Inter-Regular", size: 16))
                                .tracking(-0.32)
                                .foregroundColor(Color(hex: "7B7B7B"))
                            
                            Text("Your savings earn 3.50% APY, with yield accumulating daily. You can withdraw your funds at any time back to your Sling balance.")
                                .font(.custom("Inter-Regular", size: 16))
                                .tracking(-0.32)
                                .foregroundColor(Color(hex: "7B7B7B"))
                            
                            Text("USDY is issued by Ondo Finance and is fully backed by short-term US Treasury securities, making it one of the safest ways to earn yield on your dollars.")
                                .font(.custom("Inter-Regular", size: 16))
                                .tracking(-0.32)
                                .foregroundColor(Color(hex: "7B7B7B"))
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        // Done button
                        Button(action: {
                            dismissSheet()
                        }) {
                            Text("Done")
                                .font(.custom("Inter-Bold", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: DesignSystem.Button.height)
                                .background(Color(hex: "080808"))
                                .cornerRadius(DesignSystem.CornerRadius.large)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
                .background(Color(hex: "F2F2F2"))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 40,
                        bottomLeadingRadius: deviceCornerRadius,
                        bottomTrailingRadius: deviceCornerRadius,
                        topTrailingRadius: 40,
                        style: .continuous
                    )
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .scaleEffect(x: 1.0, y: stretchScale, anchor: .bottom)
                .offset(y: min(0, -dragOffset))
                .transition(.opacity)
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            let translation = value.translation.height
                            
                            if translation > 0 {
                                // Dragging down - allow to dismiss
                                dragOffset = -translation
                                let progress = min(translation / 300, 1.0)
                                backgroundOpacity = 0.4 * (1 - progress)
                            } else {
                                // Dragging up - rubber band
                                dragOffset = rubberBandClamp(-translation, limit: 60)
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.height
                            let velocity = value.predictedEndTranslation.height
                            
                            if translation > 100 || velocity > 500 {
                                // Dismiss
                                dismissSheet()
                            } else {
                                // Snap back
                                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.25)) {
                                    dragOffset = 0
                                    backgroundOpacity = 0.4
                                }
                            }
                        }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            // Fade in background and card together
            withAnimation(.easeOut(duration: 0.25)) {
                backgroundOpacity = 0.4
                showCard = true
            }
        }
    }
    
    private func dismissSheet() {
        // Fade out background
        withAnimation(.easeOut(duration: 0.25)) {
            backgroundOpacity = 0
        }
        // Slide out card
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            showCard = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Savings Transaction Row

struct SavingsTransactionRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    let transaction: SavingsTransaction
    
    private var title: String {
        transaction.isDeposit ? "Savings deposit" : "Savings withdrawal"
    }
    
    private var formattedAmount: String {
        let prefix = transaction.isDeposit ? "+" : "-"
        return "\(prefix)\(transaction.usdAmount.asCurrency(displayCurrencyService.currencySymbol))"
    }
    
    private var formattedUSDY: String {
        return "\(NumberFormatService.shared.formatNumber(transaction.usdyAmount)) USDY"
    }
    
    // Badge color based on transaction type
    private var badgeColor: Color {
        transaction.isDeposit ? Color(hex: "78D381") : Color(hex: "9874FF")
    }
    
    // Amount color based on transaction type
    private var amountColor: Color {
        transaction.isDeposit ? Color(hex: "57CE43") : themeService.textPrimaryColor
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar with savings icon and badge
            ZStack(alignment: .bottomTrailing) {
                // Black square background with savings icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "000000"))
                        .frame(width: 44, height: 44)
                    
                    Image("NavSavings")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                }
                
                // Badge in bottom-right corner
                ZStack {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 14, height: 14)
                    
                    Image(systemName: transaction.isDeposit ? "plus" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(themeService.cardBackgroundColor, lineWidth: 2)
                )
                .offset(x: 4, y: 4)
            }
            
            // Title
            Text(title)
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(themeService.textPrimaryColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Amount and USDY on right side
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedAmount)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(amountColor)
                
                Text(formattedUSDY)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(16)
    }
}

// MARK: - Savings All Activity View (full screen)

struct SavingsAllActivityView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var savingsService = SavingsService.shared
    @State private var selectedActivity: ActivityItem?
    @State private var showTransactionDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(savingsService.transactions) { transaction in
                        SavingsTransactionRow(transaction: transaction)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                let activity = activityItem(from: transaction)
                                NotificationCenter.default.post(name: .showTransactionDetail, object: activity)
                            }
                    }
                }
                .background(themeService.cardBackgroundColor)
                .cornerRadius(24)
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(themeService.backgroundColor)
            .navigationTitle("Savings Activity")
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
        .sheet(isPresented: $showTransactionDetail) {
            if let activity = selectedActivity {
                TransactionDetailView(activity: activity)
            }
        }
    }
    
    private func activityItem(from transaction: SavingsTransaction) -> ActivityItem {
        let isDeposit = transaction.type == .deposit
        let amountPrefix = isDeposit ? "+" : "-"
        let formattedAmount = amountPrefix + transaction.usdAmount.asUSD
        
        return ActivityItem(
            avatar: "IconSavings",
            titleLeft: isDeposit ? "Savings deposit" : "Savings withdrawal",
            subtitleLeft: transaction.formattedDate,
            titleRight: formattedAmount,
            subtitleRight: "\(NumberFormatService.shared.formatNumber(transaction.usdyAmount)) USDY",
            date: transaction.date
        )
    }
}

#Preview {
    SavingsView()
}
