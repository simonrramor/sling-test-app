import SwiftUI

struct SavingsView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @AppStorage("hasStartedSaving") private var hasStartedSaving = false
    @State private var showBalanceSheet = false
    @State private var showDepositSheet = false
    @State private var showWithdrawSheet = false
    
    var body: some View {
        if hasStartedSaving {
            savingsMainView
        } else {
            savingsIntroView
        }
    }
    
    // MARK: - Main Savings View (after onboarding)
    
    private var savingsMainView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Balance header - tappable to show currency sheet
                savingsBalanceHeader
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showBalanceSheet = true
                    }
                
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
                        subtitle: "From 1 Jul until today",
                        value: "+\(displayCurrencyService.currencySymbol)0.00"
                    )
                    
                    earningsRow(
                        title: "Total earned",
                        subtitle: "Started in Feb 2026",
                        value: "+\(displayCurrencyService.currencySymbol)0.00"
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                
                // How it works row
                PressableRow(onTap: {
                    // TODO: Show how it works
                }) {
                    HStack(spacing: 16) {
                        // Icon in rounded square background
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "F7F7F7"))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(Color(hex: "888888"))
                        }
                        
                        Text("How it works")
                            .font(.custom("Inter-Bold", size: 16))
                            .tracking(-0.32)
                            .foregroundColor(Color(hex: "080808"))
                        
                        Spacer()
                    }
                    .padding(16)
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .overlay {
            if showBalanceSheet {
                SavingsBalanceSheet(isPresented: $showBalanceSheet)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showBalanceSheet)
        .fullScreenCover(isPresented: $showDepositSheet) {
            SavingsDepositSheet(isPresented: $showDepositSheet)
        }
        .fullScreenCover(isPresented: $showWithdrawSheet) {
            SavingsWithdrawSheet(isPresented: $showWithdrawSheet)
        }
    }
    
    // MARK: - Savings Balance Header
    
    private var savingsBalanceHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label with APY
            HStack(spacing: 8) {
                Text("Your savings")
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(themeService.textSecondaryColor)
                
                Text("3.75% APY")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "57CE43"))
            }
            
            // Balance
            Text("\(displayCurrencyService.currencySymbol)0")
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
                    .foregroundColor(Color(hex: "080808"))
                
                Text(subtitle)
                    .font(.custom("Inter-Regular", size: 14))
                    .tracking(-0.28)
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            
            Spacer()
            
            // Right side: Green amount
            Text(value)
                .font(.custom("Inter-Bold", size: 16))
                .tracking(-0.32)
                .foregroundColor(Color(hex: "57CE43"))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }
}

#Preview {
    SavingsView()
}
