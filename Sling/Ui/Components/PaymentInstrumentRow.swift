import SwiftUI

/// A reusable row component for payment instruments (accounts, stocks, etc.)
/// Matches the Figma "payment instrument selector" design
struct PaymentInstrumentRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    
    // MARK: - Configuration
    
    /// The icon to display (asset name)
    let iconName: String
    
    /// Main title text
    let title: String
    
    /// Subtitle parts (joined with " • ")
    var subtitleParts: [String] = []
    
    /// Optional action button (e.g., "Max", "Sell all")
    var actionButtonTitle: String? = nil
    var onActionTap: (() -> Void)? = nil
    
    /// Whether to show the vertical dots menu
    var showMenu: Bool = false
    var onMenuTap: (() -> Void)? = nil
    
    /// Use system icon instead of asset
    var useSystemIcon: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if useSystemIcon {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(themeService.textPrimaryColor)
                    .frame(width: 44, height: 44)
                    .background(themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F7F7F7"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeService.textPrimaryColor.opacity(0.06), lineWidth: 1)
                    )
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                if !subtitleParts.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(Array(subtitleParts.enumerated()), id: \.offset) { index, part in
                            if index > 0 {
                                Text("•")
                                    .font(.custom("Inter-Regular", size: 14))
                                    .foregroundColor(themeService.textSecondaryColor)
                            }
                            Text(part)
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Action button and menu button with 4px spacing
            HStack(spacing: 4) {
                // Action button
                if let buttonTitle = actionButtonTitle {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onActionTap?()
                    }) {
                        Text(buttonTitle)
                            .font(.custom("Inter-Bold", size: 14))
                            .foregroundColor(themeService.textPrimaryColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "EDEDED"))
                            )
                    }
                }
                
                // Menu button
                if showMenu {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onMenuTap?()
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeService.textSecondaryColor)
                            .rotationEffect(.degrees(90))
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeService.currentTheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F7F7F7"))
        )
    }
}

// MARK: - Convenience Initializers

extension PaymentInstrumentRow {
    /// Create a row for a payment account
    static func forAccount(
        _ account: PaymentAccount,
        showMenu: Bool = true,
        onMenuTap: (() -> Void)? = nil
    ) -> PaymentInstrumentRow {
        var iconName: String
        switch account.iconType {
        case .asset(let assetName):
            iconName = assetName
        }
        
        var subtitles: [String] = []
        if !account.accountNumber.isEmpty {
            subtitles.append(account.accountNumber)
        }
        
        return PaymentInstrumentRow(
            iconName: iconName,
            title: account.name,
            subtitleParts: subtitles,
            showMenu: showMenu,
            onMenuTap: onMenuTap
        )
    }
    
    /// Create a row for a stock holding
    static func forStock(
        _ stock: Stock,
        symbol: String,
        value: String,
        actionTitle: String? = "Max",
        onActionTap: (() -> Void)? = nil,
        showMenu: Bool = true,
        onMenuTap: (() -> Void)? = nil
    ) -> PaymentInstrumentRow {
        PaymentInstrumentRow(
            iconName: stock.iconName,
            title: stock.name,
            subtitleParts: [symbol, value],
            actionButtonTitle: actionTitle,
            onActionTap: onActionTap,
            showMenu: showMenu,
            onMenuTap: onMenuTap
        )
    }
}

// MARK: - Tappable Variant

/// A tappable version of the row that opens a selector
struct TappablePaymentInstrumentRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let iconName: String
    let title: String
    var subtitleParts: [String] = []
    var trailingText: String? = nil
    var showMenu: Bool = true
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeService.textPrimaryColor.opacity(0.06), lineWidth: 1)
                    )
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    if !subtitleParts.isEmpty {
                        HStack(spacing: 5) {
                            ForEach(Array(subtitleParts.enumerated()), id: \.offset) { index, part in
                                if index > 0 {
                                    Text("•")
                                        .font(.custom("Inter-Regular", size: 14))
                                        .foregroundColor(themeService.textSecondaryColor)
                                }
                                Text(part)
                                    .font(.custom("Inter-Regular", size: 14))
                                    .foregroundColor(themeService.textSecondaryColor)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Trailing text (e.g., currency code)
                if let trailing = trailingText {
                    Text(trailing)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                // Menu icon
                if showMenu {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeService.textSecondaryColor)
                        .rotationEffect(.degrees(90))
                        .frame(width: 24, height: 24)
                }
            }
            .padding(12)
        }
        .buttonStyle(PaymentInstrumentRowButtonStyle())
    }
}

struct PaymentInstrumentRowButtonStyle: ButtonStyle {
    @ObservedObject private var themeService = ThemeService.shared
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isPressed ? 
                          (themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "EDEDED")) : 
                          (themeService.currentTheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F7F7F7")))
            )
    }
}

#Preview {
    VStack(spacing: 16) {
        // Stock example with Max button
        PaymentInstrumentRow(
            iconName: "StockApple",
            title: "Apple Inc",
            subtitleParts: ["AAPL", "£1,277.65"],
            actionButtonTitle: "Max",
            onActionTap: {},
            showMenu: true
        )
        
        // Account example (tappable)
        TappablePaymentInstrumentRow(
            iconName: "AccountMonzo",
            title: "Monzo Bank Limited",
            subtitleParts: ["•••• 4567"],
            trailingText: "GBP",
            onTap: {}
        )
    }
    .padding(.horizontal, 16)
}
