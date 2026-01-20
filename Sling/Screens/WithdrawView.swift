import SwiftUI
import UIKit

struct WithdrawView: View {
    @Binding var isPresented: Bool
    @StateObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @State private var amountString = ""
    @State private var selectedAccount: PaymentAccount = .monzoBankLimited
    @State private var showAccountPicker = false
    @State private var showConfirmation = false
    @State private var showSuccess = false
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(themeService.textPrimaryColor)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "F5F5F5"))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Withdraw")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Balance info
                    VStack(spacing: 4) {
                        Text("Available Balance")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Text("£\(String(format: "%.2f", portfolioService.cashBalance))")
                            .font(.custom("Inter-Bold", size: 20))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    .padding(.top, 16)
                    
                    // Amount display
                    Text(formattedAmount)
                        .font(.custom("Inter-Bold", size: 48))
                        .foregroundColor(amountValue > portfolioService.cashBalance ? .red : Color(hex: "080808"))
                    
                    if amountValue > portfolioService.cashBalance {
                        Text("Insufficient balance")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(.red)
                    }
                    
                    // Withdraw to account
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Withdraw to")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Button(action: { showAccountPicker = true }) {
                            HStack(spacing: 12) {
                                AccountIconView(iconType: selectedAccount.iconType)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedAccount.name)
                                        .font(.custom("Inter-Bold", size: 16))
                                        .foregroundColor(themeService.textPrimaryColor)
                                    
                                    Text(selectedAccount.subtitle)
                                        .font(.custom("Inter-Regular", size: 14))
                                        .foregroundColor(themeService.textSecondaryColor)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeService.textSecondaryColor)
                            }
                            .padding(16)
                            .background(Color(hex: "F7F7F7"))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Quick amounts
                    HStack(spacing: 12) {
                        QuickAmountButton(amount: "50", onTap: { amountString = "50" })
                        QuickAmountButton(amount: "100", onTap: { amountString = "100" })
                        QuickAmountButton(amount: "250", onTap: { amountString = "250" })
                        QuickAmountButton(amount: "All", onTap: { 
                            amountString = String(format: "%.0f", portfolioService.cashBalance)
                        })
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Numpad and button
            VStack(spacing: 16) {
                NumpadView(value: $amountString)
                
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showConfirmation = true
                }) {
                    Text("Withdraw £\(amountString.isEmpty ? "0" : amountString)")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(canWithdraw ? Color(hex: "080808") : Color(hex: "CCCCCC"))
                        .cornerRadius(16)
                }
                .disabled(!canWithdraw)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .alert("Confirm Withdrawal", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Withdraw") {
                performWithdraw()
            }
        } message: {
            Text("Withdraw £\(amountString) to \(selectedAccount.name)?")
        }
        .alert("Withdrawal Complete", isPresented: $showSuccess) {
            Button("Done") {
                isPresented = false
            }
        } message: {
            Text("£\(amountString) has been sent to your \(selectedAccount.name) account. It may take 1-2 business days to arrive.")
        }
        .sheet(isPresented: $showAccountPicker) {
            AccountSelectorView(
                selectedAccount: $selectedAccount,
                isPresented: $showAccountPicker
            )
        }
    }
    
    private func performWithdraw() {
        portfolioService.deductCash(amountValue)
        
        // Get icon name from account
        let iconName: String
        switch selectedAccount.iconType {
        case .asset(let assetName):
            iconName = assetName
        }
        
        // Record activity
        ActivityService.shared.addActivity(
            avatar: iconName,
            titleLeft: selectedAccount.name,
            subtitleLeft: "Withdrawal",
            titleRight: "-£\(amountString)",
            subtitleRight: ""
        )
        
        showSuccess = true
    }
}

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
