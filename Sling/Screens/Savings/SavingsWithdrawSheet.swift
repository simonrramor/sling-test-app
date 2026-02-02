import SwiftUI
import UIKit

struct SavingsWithdrawSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var savingsService = SavingsService.shared
    @ObservedObject private var themeService = ThemeService.shared
    
    @State private var amountString = ""
    @State private var showConfirmation = false
    @State private var showingUSDYOnTop = true // true = USDY primary, false = USD primary
    
    private var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    // USDY amount (what user is withdrawing)
    private var usdyAmount: Double {
        if showingUSDYOnTop {
            return amountValue
        } else {
            // User entered USD, convert to USDY
            return amountValue / savingsService.currentUsdyPrice
        }
    }
    
    // USD amount (what user will receive)
    private var usdAmount: Double {
        if showingUSDYOnTop {
            // User entered USDY, convert to USD
            return amountValue * savingsService.currentUsdyPrice
        } else {
            return amountValue
        }
    }
    
    private var availableUSDY: Double {
        savingsService.usdyBalance
    }
    
    private var availableUSD: Double {
        savingsService.totalValueUSD
    }
    
    private var isOverBalance: Bool {
        usdyAmount > availableUSDY && usdyAmount > 0
    }
    
    private var canWithdraw: Bool {
        usdyAmount > 0 && usdyAmount <= availableUSDY
    }
    
    // Formatted USDY amount
    private var formattedUSDY: String {
        let value = showingUSDYOnTop ? amountValue : usdyAmount
        if amountString.isEmpty || value == 0 {
            return "0 USDY"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.4f", value)
        return "\(formattedNumber) USDY"
    }
    
    // Formatted USD amount
    private var formattedUSD: String {
        let value = showingUSDYOnTop ? usdAmount : amountValue
        if amountString.isEmpty || value == 0 {
            return "$0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2  // Always show 2 decimals for USD
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "$\(formattedNumber)"
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    // Back button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image("ArrowLeft")
                            .renderingMode(.template)
                            .foregroundColor(themeService.textSecondaryColor)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Go back")
                    
                    // Savings icon with withdrawal badge
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
                        
                        // Purple badge with arrow down icon
                        ZStack {
                            Circle()
                                .fill(Color(hex: "9874FF"))
                                .frame(width: 14, height: 14)
                            
                            Image(systemName: "arrow.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(themeService.currentTheme == .dark ? themeService.cardBackgroundColor : Color.white, lineWidth: 2)
                        )
                        .offset(x: 4, y: 4)
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Withdraw from")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text("Savings")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                    
                    // Currency tag
                    Text("USDY")
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "F7F7F7"))
                        )
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                Spacer()
                
                // Amount display with currency swap
                AnimatedCurrencySwapView(
                    primaryDisplay: formattedUSDY,
                    secondaryDisplay: formattedUSD,
                    showingPrimaryOnTop: showingUSDYOnTop,
                    onSwap: {
                        // Convert current amount to the other currency before swapping
                        if showingUSDYOnTop {
                            // Switching to USD input
                            let newAmount = usdAmount
                            amountString = newAmount > 0 ? formatForInput(newAmount) : ""
                        } else {
                            // Switching to USDY input
                            let newAmount = usdyAmount
                            amountString = newAmount > 0 ? formatForInput(newAmount) : ""
                        }
                        showingUSDYOnTop.toggle()
                    },
                    errorMessage: isOverBalance ? "Insufficient balance" : nil
                )
                
                Spacer()
                
                // Payment source row (Savings)
                PaymentInstrumentRow(
                    iconName: "dollarsign.arrow.circlepath",
                    title: "Savings",
                    subtitleParts: ["\(savingsService.formatTokens(availableUSDY)) USDY"],
                    showMenu: true,
                    useSystemIcon: true
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Number pad
                NumberPadView(amountString: $amountString)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Next button
                SecondaryButton(
                    title: "Next",
                    isEnabled: canWithdraw
                ) {
                    showConfirmation = true
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
            // Confirmation overlay
            if showConfirmation {
                SavingsWithdrawConfirmView(
                    isPresented: $showConfirmation,
                    usdyAmount: usdyAmount,
                    usdcToReceive: usdAmount,
                    onComplete: {
                        isPresented = false
                    }
                )
                .transition(.fluidConfirm)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showConfirmation)
    }
    
    private func formatForInput(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Withdraw Confirm View

struct SavingsWithdrawConfirmView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var savingsService = SavingsService.shared
    @ObservedObject private var portfolioService = PortfolioService.shared
    
    let usdyAmount: Double
    let usdcToReceive: Double
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    
    private var formattedUSDY: String {
        "\(savingsService.formatTokens(usdyAmount)) USDY"
    }
    
    private var formattedUSDC: String {
        savingsService.formatUSD(usdcToReceive)
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    // Back button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image("ArrowLeft")
                            .renderingMode(.template)
                            .foregroundColor(themeService.textSecondaryColor)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Go back")
                    
                    // Savings icon with withdrawal badge
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
                        
                        // Purple badge with arrow down icon
                        ZStack {
                            Circle()
                                .fill(Color(hex: "9874FF"))
                                .frame(width: 14, height: 14)
                            
                            Image(systemName: "arrow.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(themeService.currentTheme == .dark ? themeService.cardBackgroundColor : Color.white, lineWidth: 2)
                        )
                        .offset(x: 4, y: 4)
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Withdraw from")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text("Savings")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Amount display
                Text(formattedUSDY)
                    .font(.custom("Inter-Bold", size: 48))
                    .foregroundColor(themeService.textPrimaryColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Spacer()
                
                // Details section
                VStack(spacing: 0) {
                    DetailRow(label: "From", value: "Savings")
                    DetailRow(label: "To", value: "Sling Balance")
                    
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    DetailRow(label: "Amount", value: formattedUSDY)
                    DetailRow(label: "USDY price", value: savingsService.formatPrice(savingsService.currentUsdyPrice))
                    DetailRow(label: "You receive", value: formattedUSDC)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Withdraw button
                LoadingButton(
                    title: "Withdraw \(formattedUSDC)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    // Withdraw from savings
                    savingsService.withdraw(usdyAmount: usdyAmount)
                    
                    // Add to Sling balance
                    portfolioService.addCash(usdcToReceive)
                    
                    // Record activity
                    ActivityService.shared.addActivity(
                        avatar: "IconSavings",
                        titleLeft: "Savings",
                        subtitleLeft: "Withdrawal",
                        titleRight: "-\(formattedUSDC)",
                        subtitleRight: ""
                    )
                    
                    // Navigate back to savings and complete
                    NotificationCenter.default.post(name: .navigateToSavings, object: nil)
                    onComplete()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
    }
}

#Preview {
    SavingsWithdrawSheet(isPresented: .constant(true))
}
