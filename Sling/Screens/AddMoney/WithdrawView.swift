import SwiftUI
import UIKit

struct WithdrawView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @State private var amountString = ""
    @State private var selectedAccount: PaymentAccount = .monzoBankLimited
    @State private var showAccountPicker = false
    @State private var showConfirmation = false
    
    var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    var formattedAmount: String {
        if amountString.isEmpty {
            return "£0"
        }
        return "£\(amountString)"
    }
    
    var canWithdraw: Bool {
        amountValue > 0 && amountValue <= portfolioService.cashBalance
    }
    
    var selectedAccountIconName: String {
        switch selectedAccount.iconType {
        case .asset(let assetName):
            return assetName
        }
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - shows DESTINATION (where money goes TO)
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
                    
                    // Destination account icon
                    AccountIconView(iconType: selectedAccount.iconType)
                    
                    // Title
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Withdraw to")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text(selectedAccount.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                    
                    // Currency tag
                    Text(selectedAccount.currency.isEmpty ? "GBP" : selectedAccount.currency)
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
                
                // Amount display
                VStack(spacing: 8) {
                    Text(formattedAmount)
                        .font(.custom("Inter-Bold", size: 56))
                        .foregroundColor(amountValue > portfolioService.cashBalance ? .red : Color(hex: "080808"))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    if amountValue > portfolioService.cashBalance {
                        Text("Insufficient balance")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                // Source account (Sling Balance)
                PaymentInstrumentRow(
                    iconName: "SlingBalanceLogo",
                    title: "Sling Balance",
                    subtitleParts: ["£\(String(format: "%.2f", portfolioService.cashBalance))"],
                    actionButtonTitle: "Max",
                    onActionTap: {
                        amountString = String(format: "%.0f", floor(portfolioService.cashBalance))
                    },
                    showMenu: true,
                    onMenuTap: {
                        // TODO: Show source selector if needed
                    }
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
                WithdrawConfirmView(
                    amount: amountValue,
                    destinationAccount: selectedAccount,
                    isPresented: $showConfirmation,
                    onComplete: {
                        isPresented = false
                    }
                )
                .transition(.fluidConfirm)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showConfirmation)
        .accountSelectorOverlay(
            isPresented: $showAccountPicker,
            selectedAccount: $selectedAccount
        )
    }
}

// MARK: - Withdraw Confirm View

struct WithdrawConfirmView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var feeService = FeeService.shared
    let amount: Double
    let destinationAccount: PaymentAccount
    @Binding var isPresented: Bool
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    
    private let portfolioService = PortfolioService.shared
    private let slingCurrency = "USD" // Sling balance currency
    
    /// Destination currency from account
    private var destinationCurrency: String {
        destinationAccount.currency.isEmpty ? "GBP" : destinationAccount.currency
    }
    
    /// Calculate fee for this withdrawal
    /// Fee applies when payment instrument currency differs from display currency
    private var withdrawalFee: FeeResult {
        feeService.calculateFee(
            for: .withdrawal,
            paymentInstrumentCurrency: destinationCurrency
        )
    }
    
    /// Total amount deducted from balance (amount + fee)
    private var totalDeducted: Double {
        if withdrawalFee.isFree {
            return amount
        }
        return amount + withdrawalFee.amount
    }
    
    var formattedAmount: String {
        String(format: "£%.2f", amount)
    }
    
    var formattedTotalDeducted: String {
        String(format: "£%.2f", totalDeducted)
    }
    
    var destinationAccountIcon: String {
        switch destinationAccount.iconType {
        case .asset(let assetName):
            return assetName
        }
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
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
                    
                    AccountIconView(iconType: destinationAccount.iconType)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Withdraw to")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text(destinationAccount.name)
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
                Text(formattedAmount)
                    .font(.custom("Inter-Bold", size: 56))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                // Details section
                VStack(spacing: 0) {
                    DetailRow(label: "To", value: destinationAccount.name)
                    DetailRow(label: "Speed", value: "1-2 business days")
                    
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    DetailRow(label: "Amount", value: formattedAmount)
                    
                    // Fee row
                    FeeRow(fee: withdrawalFee)
                    
                    // Total deducted (if fee applies)
                    if !withdrawalFee.isFree {
                        DetailRow(label: "Total from balance", value: formattedTotalDeducted)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Withdraw button with smooth loading animation
                LoadingButton(
                    title: "Withdraw \(formattedAmount)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    // Perform withdrawal (deduct total including fee)
                    portfolioService.deductCash(totalDeducted)
                    
                    // Record activity
                    ActivityService.shared.addActivity(
                        avatar: destinationAccountIcon,
                        titleLeft: destinationAccount.name,
                        subtitleLeft: "Withdrawal",
                        titleRight: "-\(formattedTotalDeducted)",
                        subtitleRight: ""
                    )
                    
                    // Navigate home and complete
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    onComplete()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
    }
}

// MARK: - Quick Amount Button

struct QuickAmountButton: View {
    @ObservedObject private var themeService = ThemeService.shared
    let amount: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            Text(amount == "All" ? "All" : "£\(amount)")
                .font(.custom("Inter-Bold", size: 14))
                .foregroundColor(themeService.textPrimaryColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "F7F7F7"))
                .cornerRadius(12)
        }
    }
}

#Preview {
    WithdrawView(isPresented: .constant(true))
}
