import SwiftUI
import UIKit

struct TransferBetweenAccountsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @State private var amountString = ""
    @State private var fromAccount: PaymentAccount = .slingWallet
    @State private var toAccount: PaymentAccount = .monzoBankLimited
    @State private var showFromAccountPicker = false
    @State private var showToAccountPicker = false
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
    
    var body: some View {
        ZStack {
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
                    .zIndex(1)
                    
                    Spacer()
                    
                    Text("Transfer")
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
                    // Amount display
                    Text(formattedAmount)
                        .font(.custom("Inter-Bold", size: 48))
                        .foregroundColor(themeService.textPrimaryColor)
                        .padding(.top, 32)
                    
                    // From account
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Button(action: { showFromAccountPicker = true }) {
                            HStack(spacing: 12) {
                                AccountIconView(iconType: fromAccount.iconType)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fromAccount.name)
                                        .font(.custom("Inter-Bold", size: 16))
                                        .foregroundColor(themeService.textPrimaryColor)
                                    
                                    Text(fromAccount.subtitle)
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
                            .cornerRadius(24)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Swap button
                    Button(action: {
                        let temp = fromAccount
                        fromAccount = toAccount
                        toAccount = temp
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "EDEDED"))
                            .cornerRadius(22)
                    }
                    
                    // To account
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Button(action: { showToAccountPicker = true }) {
                            HStack(spacing: 12) {
                                AccountIconView(iconType: toAccount.iconType)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(toAccount.name)
                                        .font(.custom("Inter-Bold", size: 16))
                                        .foregroundColor(themeService.textPrimaryColor)
                                    
                                    Text(toAccount.subtitle)
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
                            .cornerRadius(24)
                        }
                    }
                    .padding(.horizontal, 16)
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
                    Text("Transfer £\(amountString.isEmpty ? "0" : amountString)")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(amountValue > 0 ? Color(hex: "080808") : Color(hex: "CCCCCC"))
                        .cornerRadius(24)
                }
                .disabled(amountValue <= 0)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
            }
            .background(Color.white)
            
            // WIP Overlay - allows X button to be tapped
            Color.red.opacity(0.5)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            Text("WIP")
                .font(.custom("Inter-Bold", size: 64))
                .foregroundColor(.white)
                .allowsHitTesting(false)
        }
        .alert("Transfer Complete", isPresented: $showConfirmation) {
            Button("Done") {
                isPresented = false
            }
        } message: {
            Text("£\(amountString) has been transferred from \(fromAccount.name) to \(toAccount.name).")
        }
        .accountSelectorOverlay(
            isPresented: $showFromAccountPicker,
            selectedAccount: $fromAccount
        )
        .accountSelectorOverlay(
            isPresented: $showToAccountPicker,
            selectedAccount: $toAccount
        )
    }
}

// Helper view for account icons
struct AccountIconView: View {
    let iconType: PaymentAccount.AccountIconType
    
    var body: some View {
        switch iconType {
        case .asset(let assetName):
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// Simple numpad for this view
struct NumpadView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Binding var value: String
    
    let buttons = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { button in
                        Button(action: {
                            handleTap(button)
                        }) {
                            Text(button)
                                .font(.custom("Inter-Bold", size: 24))
                                .foregroundColor(themeService.textPrimaryColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func handleTap(_ button: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        switch button {
        case "⌫":
            if !value.isEmpty {
                value.removeLast()
            }
        case ".":
            if !value.contains(".") {
                value += value.isEmpty ? "0." : "."
            }
        default:
            if value.count < 8 {
                value += button
            }
        }
    }
}

#Preview {
    TransferBetweenAccountsView(isPresented: .constant(true))
}
