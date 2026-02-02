import SwiftUI

struct SavingsView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var savingsService = SavingsService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @AppStorage("hasStartedSaving") private var hasStartedSaving = false
    @State private var showDepositSheet = false
    @State private var showWithdrawSheet = false
    @State private var showHowItWorks = false
    @State private var showAllTransactions = false
    @State private var exchangeRate: Double = 1.0
    @State private var selectedActivity: ActivityItem?
    @State private var showTransactionDetail = false
    
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
        .fullScreenCover(isPresented: $showHowItWorks) {
            SavingsHowItWorksSheet(isPresented: $showHowItWorks)
                .background(ClearBackgroundView())
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
        .transactionDetailDrawer(isPresented: $showTransactionDetail, activity: selectedActivity)
    }
    
    // MARK: - Main Savings View (after onboarding)
    
    /// Formatted savings balance in display currency
    private var formattedSavingsBalance: String {
        let usdValue = savingsService.totalValueUSD
        if displayCurrencyService.displayCurrency == "USD" {
            return String(format: "%@%.2f", displayCurrencyService.currencySymbol, usdValue)
        } else {
            let convertedValue = usdValue * exchangeRate
            return String(format: "%@%.2f", displayCurrencyService.currencySymbol, convertedValue)
        }
    }
    
    /// Formatted USDY token amount
    private var formattedUSDYAmount: String {
        let tokens = savingsService.usdyBalance
        if tokens == 0 {
            return "0 USDY"
        }
        return String(format: "%.2f USDY", tokens)
    }
    
    /// Formatted total earnings in display currency
    private var formattedTotalEarnings: String {
        let usdEarnings = savingsService.totalEarnings
        if displayCurrencyService.displayCurrency == "USD" {
            return String(format: "+%@%.2f", displayCurrencyService.currencySymbol, usdEarnings)
        } else {
            let convertedEarnings = usdEarnings * exchangeRate
            return String(format: "+%@%.2f", displayCurrencyService.currencySymbol, convertedEarnings)
        }
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
        
        if displayCurrencyService.displayCurrency == "USD" {
            return String(format: "+%@%.2f", displayCurrencyService.currencySymbol, usdMonthlyEarnings)
        } else {
            let convertedEarnings = usdMonthlyEarnings * exchangeRate
            return String(format: "+%@%.2f", displayCurrencyService.currencySymbol, convertedEarnings)
        }
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
        let formattedAmount = String(format: "%@%@%.2f", prefix, displayCurrencyService.currencySymbol, transaction.usdAmount)
        let formattedUSDY = String(format: "%.2f USDY", transaction.usdyAmount)
        
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
                
                // Earnings rows
                VStack(spacing: 8) {
                    earningsRow(
                        title: "Earned this month",
                        subtitle: monthlyEarningsSubtitle,
                        value: formattedMonthlyEarnings
                    )
                    
                    earningsRow(
                        title: "Total earned",
                        subtitle: totalEarningsSubtitle,
                        value: formattedTotalEarnings
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                
                // Transaction history
                if !savingsService.transactions.isEmpty {
                    let displayedTransactions = showAllTransactions 
                        ? savingsService.transactions 
                        : Array(savingsService.transactions.prefix(3))
                    let hasMore = savingsService.transactions.count > 3
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity")
                            .font(.custom("Inter-Bold", size: 18))
                            .tracking(-0.36)
                            .foregroundColor(themeService.textPrimaryColor)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 0) {
                            ForEach(displayedTransactions) { transaction in
                                SavingsTransactionRow(transaction: transaction)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        selectedActivity = activityItem(from: transaction)
                                        showTransactionDetail = true
                                    }
                                
                                if transaction.id != displayedTransactions.last?.id {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                            
                            // "See more" button
                            if hasMore && !showAllTransactions {
                                Divider()
                                    .padding(.horizontal, 16)
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showAllTransactions = true
                                    }
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
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 24)
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
                    }
                    .padding(16)
                }
                .background(themeService.cardBackgroundColor)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .fullScreenCover(isPresented: $showDepositSheet) {
            SavingsDepositSheet(isPresented: $showDepositSheet)
        }
        .fullScreenCover(isPresented: $showWithdrawSheet) {
            SavingsWithdrawSheet(isPresented: $showWithdrawSheet)
        }
        .onAppear {
            fetchExchangeRate()
        }
        .onChange(of: displayCurrencyService.displayCurrency) {
            fetchExchangeRate()
        }
    }
    
    // MARK: - Savings Balance Header
    
    private var savingsBalanceHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label with USDY amount
            HStack(spacing: 8) {
                Text("Savings")
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(themeService.textSecondaryColor)
                
                if savingsService.usdyBalance > 0 {
                    Text("·")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    Text(formattedUSDYAmount)
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(themeService.textSecondaryColor)
                } else {
                    Text("3.75% APY")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(Color(hex: "57CE43"))
                }
            }
            
            // Balance in display currency
            Text(formattedSavingsBalance)
                .font(.custom("Inter-Bold", size: 42))
                .foregroundColor(themeService.textPrimaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
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
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
            }
        }
        .scrollIndicators(.hidden)
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
    
    private func earningsRow(title: String, subtitle: String, value: String) -> some View {
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
        .background(themeService.cardBackgroundColor)
        .cornerRadius(16)
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
                            
                            Text("Your savings earn 3.75% APY, with yield accumulating daily. You can withdraw your funds at any time back to your Sling balance.")
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
                                .font(.custom("Inter-SemiBold", size: 16))
                                .foregroundColor(Color(hex: "7B7B7B"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(hex: "E5E5E5"))
                                .cornerRadius(16)
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
                .transition(.move(edge: .bottom))
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
            // Fade in background separately
            withAnimation(.easeOut(duration: 0.25)) {
                backgroundOpacity = 0.4
            }
            // Slide in card with spring
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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
        return String(format: "%@%@%.2f", prefix, displayCurrencyService.currencySymbol, transaction.usdAmount)
    }
    
    private var formattedUSDY: String {
        return String(format: "%.2f USDY", transaction.usdyAmount)
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

#Preview {
    SavingsView()
}
