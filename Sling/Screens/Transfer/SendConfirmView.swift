import SwiftUI
import UIKit

struct SendConfirmView: View {
    let contact: Contact
    let amount: Double
    let mode: PaymentMode
    @ObservedObject private var themeService = ThemeService.shared
    @AppStorage("hasSentMoney") private var hasSentMoney = false
    @Binding var isPresented: Bool
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    @Namespace private var animation
    
    private let portfolioService = PortfolioService.shared
    private let activityService = ActivityService.shared
    private let displayCurrencyService = DisplayCurrencyService.shared
    
    // Get the currency symbol from user's display currency
    var currencySymbol: String {
        ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
    }
    
    // Full formatted amount with decimals (for info rows)
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "\(currencySymbol)\(formattedNumber)"
    }
    
    // Short formatted amount (no decimals for whole numbers, for title/button)
    var shortAmount: String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(currencySymbol)\(Int(amount))"
        }
        return formattedAmount
    }
    
    var titleText: String {
        mode == .send ? "Send \(shortAmount) to \(contact.name)" : "Request \(shortAmount) from \(contact.name)"
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Simple header with back button
                HStack {
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
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 48)
                .opacity(isButtonLoading ? 0 : 1)
                
                // Spacer - grows when loading to push content to center
                Spacer()
                
                // Main content - avatar and title (animates from bottom to center)
                VStack(alignment: .leading, spacing: 24) {
                    // Large avatar with verified badge
                    ZStack(alignment: .topTrailing) {
                        Image(contact.avatarName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                        
                        // Verified badge
                        if contact.isVerified {
                            Image("BadgeVerified")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .offset(x: 3, y: -3)
                        }
                    }
                    .matchedGeometryEffect(id: "avatar", in: animation)
                    
                    // Title - left aligned
                    Text(titleText)
                        .font(.custom("Inter-Bold", size: 32))
                        .foregroundColor(themeService.textPrimaryColor)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .matchedGeometryEffect(id: "title", in: animation)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.bottom, isButtonLoading ? 0 : 16)
                
                // Spacer - grows when loading to push content to center
                Spacer()
                    .frame(maxHeight: isButtonLoading ? .infinity : 0)
                
                // Info card section - fades out when loading
                if !isButtonLoading {
                    VStack(spacing: 4) {
                        // From row
                        InfoListItem(
                            label: mode == .send ? "From" : "To",
                            detail: "Sling Balance",
                            showImage: true
                        )
                        
                        // Average speed row
                        InfoListItem(
                            label: "Average speed",
                            detail: "Instant"
                        )
                        
                        // Divider
                        Rectangle()
                            .fill(Color.black.opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        // Total sent row with pip
                        InfoListItem(
                            label: mode == .send ? "Total sent" : "Amount requested",
                            detail: formattedAmount,
                            showPip: true
                        )
                        
                        // Fees row
                        InfoListItem(
                            label: "Fees",
                            detail: "No fee"
                        )
                        
                        // Recipient receives row
                        InfoListItem(
                            label: mode == .send ? "\(contact.name.components(separatedBy: " ").first ?? contact.name) gets" : "You receive",
                            detail: formattedAmount
                        )
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }
                
                // Space between details and button
                Spacer()
                    .frame(height: 16)
                
                // Action button
                LoadingButton(
                    title: "\(mode.buttonPrefix) \(shortAmount)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    if mode == .send {
                        portfolioService.deductCash(amount)
                        activityService.recordSendMoney(
                            toContactName: contact.name,
                            toContactAvatar: contact.avatarName,
                            amount: amount
                        )
                    } else {
                        activityService.recordRequestMoney(
                            fromContactName: contact.name,
                            fromContactAvatar: contact.avatarName,
                            amount: amount
                        )
                    }
                    
                    // Mark as completed for Get Started cards
                    hasSentMoney = true
                    
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    onComplete()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isButtonLoading)
    }
}

// MARK: - Info List Item

struct InfoListItem: View {
    @ObservedObject private var themeService = ThemeService.shared
    let label: String
    let detail: String
    var showImage: Bool = false
    var showPip: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(themeService.textSecondaryColor)
            
            Spacer()
            
            HStack(spacing: 6) {
                if showImage {
                    Image("SlingBalanceLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 18, height: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                if showPip {
                    Circle()
                        .fill(Color(hex: "FF5113"))
                        .frame(width: 4, height: 4)
                }
                
                Text(detail)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
    }
}

// MARK: - Send Confirm From Bank View

struct SendConfirmFromBankView: View {
    let contact: Contact
    let amount: Double
    let bankName: String
    let bankIcon: String
    let bankCurrency: String
    @ObservedObject private var themeService = ThemeService.shared
    @AppStorage("hasSentMoney") private var hasSentMoney = false
    @Binding var isPresented: Bool
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    @Namespace private var animation
    
    private let portfolioService = PortfolioService.shared
    private let activityService = ActivityService.shared
    private let displayCurrencyService = DisplayCurrencyService.shared
    
    // Fee percentage
    private let feeRate: Double = 0.0037
    
    // Exchange rate (mock: GBP to USD)
    private var exchangeRate: Double {
        switch bankCurrency {
        case "GBP": return 0.87
        case "EUR": return 0.93
        case "BRL": return 5.12
        case "MXN": return 17.15
        default: return 1.0
        }
    }
    
    private var bankCurrencySymbol: String {
        ExchangeRateService.symbol(for: bankCurrency)
    }
    
    private var displayCurrencySymbol: String {
        ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
    }
    
    // Amount in bank currency
    private var bankAmount: Double {
        amount * exchangeRate
    }
    
    // Fee in bank currency
    private var feeAmount: Double {
        bankAmount * feeRate
    }
    
    // Amount after fees
    private var amountExchanged: Double {
        bankAmount - feeAmount
    }
    
    private func formatBankCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(bankCurrencySymbol)\(formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value))"
    }
    
    private func formatDisplayCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(displayCurrencySymbol)\(formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value))"
    }
    
    private var shortAmount: String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(displayCurrencySymbol)\(Int(amount))"
        }
        return formatDisplayCurrency(amount)
    }
    
    private var firstName: String {
        contact.name.components(separatedBy: " ").first ?? contact.name
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
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
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 48)
                .opacity(isButtonLoading ? 0 : 1)
                
                Spacer()
                
                // Main content - avatar and title
                VStack(alignment: .leading, spacing: 24) {
                    // Contact avatar with verified badge
                    ZStack(alignment: .topTrailing) {
                        Image(contact.avatarName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                        
                        if contact.isVerified {
                            Image("BadgeVerified")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .offset(x: 3, y: -3)
                        }
                    }
                    .matchedGeometryEffect(id: "avatar", in: animation)
                    
                    // Title: "Send €100 to Brendon Arnold from Monzo Bank"
                    Text("Send \(shortAmount) to \(contact.name) from \(bankName)")
                        .font(.custom("Inter-Bold", size: 32))
                        .tracking(-0.64)
                        .foregroundColor(themeService.textPrimaryColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .matchedGeometryEffect(id: "title", in: animation)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.bottom, isButtonLoading ? 0 : 16)
                
                Spacer()
                    .frame(maxHeight: isButtonLoading ? .infinity : 0)
                
                // Detail rows - fades out when loading
                if !isButtonLoading {
                    VStack(spacing: 4) {
                        // Transfer speed
                        InfoListItem(
                            label: "Transfer speed",
                            detail: "Instant"
                        )
                        
                        // Divider
                        Rectangle()
                            .fill(Color.black.opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        // Total withdrawn
                        InfoListItem(
                            label: "Total withdrawn",
                            detail: formatBankCurrency(bankAmount)
                        )
                        
                        // Fees (red)
                        HStack {
                            Text("Fees")
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(themeService.textSecondaryColor)
                            
                            Spacer()
                            
                            Text("-\(formatBankCurrency(feeAmount))")
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(Color(hex: "E30000"))
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 16)
                        
                        // Amount exchanged
                        InfoListItem(
                            label: "Amount exchanged",
                            detail: formatBankCurrency(amountExchanged)
                        )
                        
                        // Exchange rate (source/bank currency on left - money flows from bank)
                        HStack {
                            Text("Exchange rate")
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(themeService.textSecondaryColor)
                            
                            Spacer()
                            
                            Text("\(bankCurrencySymbol)1 = \(displayCurrencySymbol)\(String(format: "%.2f", 1.0 / exchangeRate))")
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(Color(hex: "FF5113"))
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 16)
                        
                        // Recipient gets
                        InfoListItem(
                            label: "\(firstName) gets",
                            detail: formatDisplayCurrency(amount)
                        )
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }
                
                Spacer()
                    .frame(height: 16)
                
                // Orange CTA button
                LoadingButton(
                    title: "Send \(shortAmount)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    portfolioService.deductCash(amount)
                    activityService.recordSendMoney(
                        toContactName: contact.name,
                        toContactAvatar: contact.avatarName,
                        amount: amount
                    )
                    hasSentMoney = true
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    onComplete()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isButtonLoading)
    }
}

#Preview("Send from Balance") {
    SendConfirmView(
        contact: Contact(name: "Kwame Dlamini", username: "kwame", avatarName: "AvatarAgustinAlvarez"),
        amount: 100.00,
        mode: .send,
        isPresented: .constant(true)
    )
}

#Preview("Send from Bank") {
    SendConfirmFromBankView(
        contact: Contact(name: "Brendon Arnold", username: "brendon", avatarName: "AvatarProfile", isVerified: true),
        amount: 100.00,
        bankName: "Monzo Bank",
        bankIcon: "AccountMonzo",
        bankCurrency: "GBP",
        isPresented: .constant(true)
    )
}
