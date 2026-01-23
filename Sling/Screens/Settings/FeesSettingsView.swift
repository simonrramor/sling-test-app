import SwiftUI
import UIKit

/// Settings screen showing fee schedule matching Figma design
/// Grid layout showing fees for local currency vs other currencies
struct FeesSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var feeService = FeeService.shared
    
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
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hex: "080808"))
                            .frame(width: 24, height: 24)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title
                        Text("Sling fees")
                            .font(.custom("Inter-Bold", size: 32))
                            .foregroundColor(Color(hex: "080808"))
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                        
                        // Subtitle - local currency info
                        Text("Your local currency is \(localCurrencyName) (\(feeService.localCurrency))")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                        
                        // Divider before header
                        Divider()
                            .padding(.horizontal, 24)
                        
                        // Currency header row
                        CurrencyHeaderRow(localCurrency: feeService.localCurrency)
                            .padding(.horizontal, 24)
                        
                        // Divider after header
                        Divider()
                            .padding(.horizontal, 24)
                        
                        // Fee rows
                        VStack(spacing: 0) {
                            // Send to someone
                            FeeGridRow(
                                title: "Send to someone",
                                subtitle: "From Sling",
                                localFee: .free,
                                otherFee: .free
                            )
                            
                            Divider()
                                .padding(.horizontal, 24)
                            
                            // Send to your accounts
                            FeeGridRow(
                                title: "Send to your accounts",
                                subtitle: "From Sling",
                                localFee: .free,
                                otherFee: .amount(0.50, currency: feeService.localCurrency)
                            )
                            
                            Divider()
                                .padding(.horizontal, 24)
                            
                            // Add money to Sling
                            FeeGridRow(
                                title: "Add money to Sling",
                                subtitle: "From your accounts",
                                localFee: .free,
                                otherFee: .amount(0.50, currency: feeService.localCurrency)
                            )
                            
                            Divider()
                                .padding(.horizontal, 24)
                            
                            // Receive money
                            FeeGridRow(
                                title: "Receive money",
                                subtitle: "From Sling",
                                localFee: .free,
                                otherFee: .free
                            )
                            
                            Divider()
                                .padding(.horizontal, 24)
                            
                            // Account details deposit
                            FeeGridRow(
                                title: "Account details deposit",
                                subtitle: "Receive money to Sling",
                                localFee: .free,
                                otherFee: .percentage(0.1)
                            )
                            
                            Divider()
                                .padding(.horizontal, 24)
                            
                            // Sling Card payments
                            FeeGridRow(
                                title: "Sling Card payments",
                                subtitle: "Online and contactless",
                                localFee: .free,
                                otherFee: .free
                            )
                        }
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
        }
    }
    
    /// Full name for the local currency
    private var localCurrencyName: String {
        switch feeService.localCurrency {
        case "GBP": return "British Pound"
        case "EUR": return "Euro"
        case "USD": return "US Dollar"
        case "JPY": return "Japanese Yen"
        case "CHF": return "Swiss Franc"
        case "CAD": return "Canadian Dollar"
        case "AUD": return "Australian Dollar"
        default: return feeService.localCurrency
        }
    }
}

// MARK: - Fee Column Constants

/// Shared constants for fee column layout
private enum FeeColumnLayout {
    static let columnWidth: CGFloat = 60
    static let columnSpacing: CGFloat = 12
}

// MARK: - Currency Header Row

/// Header row showing "Transaction currency" with EUR and Other columns
struct CurrencyHeaderRow: View {
    let localCurrency: String
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Transaction currency label
            Text("Transaction currency")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(Color(hex: "999999"))
            
            Spacer()
            
            // Right side - Currency columns
            HStack(spacing: FeeColumnLayout.columnSpacing) {
                // Local currency column
                VStack(spacing: 8) {
                    currencyIcon(for: localCurrency)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    
                    Text(localCurrency)
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(Color(hex: "080808"))
                }
                .frame(minWidth: FeeColumnLayout.columnWidth)
                
                // Other currency column
                VStack(spacing: 8) {
                    Image("IconGlobe")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    
                    Text("Other")
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(Color(hex: "080808"))
                }
                .frame(minWidth: FeeColumnLayout.columnWidth)
            }
        }
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private func currencyIcon(for currency: String) -> some View {
        switch currency {
        case "EUR":
            Image("FlagEUR")
                .resizable()
                .aspectRatio(contentMode: .fill)
        case "GBP":
            Image("FlagGB")
                .resizable()
                .aspectRatio(contentMode: .fill)
        case "USD":
            Image("FlagUS")
                .resizable()
                .aspectRatio(contentMode: .fill)
        case "JPY":
            Image("FlagJP")
                .resizable()
                .aspectRatio(contentMode: .fill)
        case "CHF":
            Image("FlagCH")
                .resizable()
                .aspectRatio(contentMode: .fill)
        case "CAD":
            Image("FlagCA")
                .resizable()
                .aspectRatio(contentMode: .fill)
        case "AUD":
            Image("FlagAU")
                .resizable()
                .aspectRatio(contentMode: .fill)
        default:
            Image("FlagEUR")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}

// MARK: - Fee Value Type

enum FeeValue {
    case free
    case amount(Double, currency: String)
    case percentage(Double)
    
    var displayText: String {
        switch self {
        case .free:
            return "Free"
        case .amount(let value, let currency):
            let symbol = currencySymbol(for: currency)
            return "\(symbol)\(String(format: "%.2f", value))"
        case .percentage(let value):
            return "\(String(format: "%.1f", value))%"
        }
    }
    
    var isFree: Bool {
        if case .free = self { return true }
        return false
    }
    
    private func currencySymbol(for currency: String) -> String {
        switch currency {
        case "EUR": return "€"
        case "GBP": return "£"
        case "USD": return "$"
        case "JPY": return "¥"
        case "CHF": return "CHF "
        default: return "$"
        }
    }
}

// MARK: - Fee Grid Row

/// A row in the fee grid showing title, subtitle, and two fee columns
struct FeeGridRow: View {
    let title: String
    let subtitle: String
    let localFee: FeeValue
    let otherFee: FeeValue
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                Text(subtitle)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            
            Spacer(minLength: 16)
            
            // Right side - Fee columns
            HStack(spacing: FeeColumnLayout.columnSpacing) {
                // Local currency fee
                FeeBadge(fee: localFee)
                    .frame(minWidth: FeeColumnLayout.columnWidth)
                
                // Other currency fee
                FeeBadge(fee: otherFee)
                    .frame(minWidth: FeeColumnLayout.columnWidth)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - Fee Badge

/// Badge showing fee value with appropriate styling
struct FeeBadge: View {
    let fee: FeeValue
    
    var body: some View {
        Text(fee.displayText)
            .font(.custom("Inter-Medium", size: 14))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundColor(fee.isFree ? Color(hex: "57CE43") : Color(hex: "080808"))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(fee.isFree ? Color(hex: "E6F9E3") : Color(hex: "F7F7F7"))
            )
    }
}

#Preview {
    FeesSettingsView(isPresented: .constant(true))
}
