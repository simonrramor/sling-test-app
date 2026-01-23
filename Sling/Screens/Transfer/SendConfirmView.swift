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
    
    // Get the currency symbol from user's display currency
    var currencySymbol: String {
        ExchangeRateService.symbol(for: portfolioService.displayCurrency)
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

#Preview {
    SendConfirmView(
        contact: Contact(name: "Kwame Dlamini", username: "kwame", avatarName: "AvatarAgustinAlvarez"),
        amount: 100.00,
        mode: .send,
        isPresented: .constant(true)
    )
}
