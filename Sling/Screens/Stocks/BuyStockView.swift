import SwiftUI
import UIKit

struct BuyStockView: View {
    let stock: Stock
    @Binding var isPresented: Bool
    var onComplete: () -> Void = {}
    @ObservedObject private var themeService = ThemeService.shared
    @State private var amountString: String = ""
    @State private var showConfirmation = false
    @State private var isSharesMode: Bool = false  // false = dollars, true = shares
    
    private let portfolioService = PortfolioService.shared
    
    var inputValue: Double {
        Double(amountString) ?? 0
    }
    
    // Get current stock price from Ondo service
    var stockPrice: Double {
        OndoService.shared.tokenData[stock.iconName]?.currentPrice ?? 100
    }
    
    // Dollar amount (what we actually use for the transaction)
    var dollarAmount: Double {
        if isSharesMode {
            return inputValue * stockPrice
        } else {
            return inputValue
        }
    }
    
    // Shares amount
    var sharesAmount: Double {
        if isSharesMode {
            return inputValue
        } else {
            return inputValue / stockPrice
        }
    }
    
    // Dollar display string (with ~ prefix when calculated)
    var dollarDisplay: String {
        if isSharesMode {
            // This is calculated (secondary) - add ~ prefix
            return dollarAmount > 0 ? String(format: "~£%.2f", dollarAmount) : "~£0"
        } else {
            // This is the input (primary)
            if amountString.isEmpty {
                return "$0"
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "£"
            formatter.maximumFractionDigits = amountString.contains(".") ? 2 : 0
            return formatter.string(from: NSNumber(value: inputValue)) ?? "£\(amountString)"
        }
    }
    
    // Shares display string (with ~ prefix when calculated)
    var sharesDisplay: String {
        if isSharesMode {
            // This is the input (primary)
            return amountString.isEmpty ? "0 \(stock.symbol)" : "\(amountString) \(stock.symbol)"
        } else {
            // This is calculated (secondary) - add ~ prefix
            return sharesAmount > 0 ? String(format: "~%.2f %@", sharesAmount, stock.symbol) : "0 \(stock.symbol)"
        }
    }
    
    // Formatted cash balance for display (shows remaining after amount being typed)
    var formattedCashBalance: String {
        let remainingBalance = max(0, portfolioService.cashBalance - dollarAmount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: remainingBalance)) ?? String(format: "%.2f", remainingBalance)
        return "£\(formatted)"
    }
    
    // Check if over balance (for red text and error)
    var isOverBalance: Bool {
        dollarAmount > portfolioService.cashBalance
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
                    
                    // Stock avatar
                    Image(stock.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    
                    // Stock name
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            Text("Buy")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                            Text("·")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                            Text(stock.symbol)
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                        }
                        Text(stock.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                Spacer()
                
                // Amount input display with swap animation
                AnimatedCurrencySwapView(
                    primaryDisplay: dollarDisplay,
                    secondaryDisplay: sharesDisplay,
                    showingPrimaryOnTop: !isSharesMode,
                    onSwap: {
                        // Convert current value to the other mode
                        if isSharesMode {
                            let dollars = dollarAmount
                            amountString = dollars > 0 ? String(format: "%.2f", dollars) : ""
                        } else {
                            let shares = sharesAmount
                            amountString = shares > 0 ? String(format: "%.2f", shares) : ""
                        }
                        isSharesMode.toggle()
                    },
                    errorMessage: isOverBalance ? "Insufficient balance" : nil
                )
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Payment source
                PaymentInstrumentRow(
                    iconName: "SlingBalanceLogo",
                    title: "Sling balance",
                    subtitleParts: [formattedCashBalance],
                    actionButtonTitle: "Max",
                    onActionTap: {
                        // Set amount to max available balance
                        if isSharesMode {
                            // Convert cash balance to shares
                            let maxShares = portfolioService.cashBalance / stockPrice
                            amountString = String(format: "%.2f", maxShares)
                        } else {
                            // Use full cash balance
                            amountString = String(format: "%.2f", portfolioService.cashBalance)
                        }
                    },
                    showMenu: true,
                    onMenuTap: {
                        // TODO: Show payment source selector
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Number pad
                NumberPadView(amountString: $amountString)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Next button (black)
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showConfirmation = true
                }) {
                    Text("Next")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(dollarAmount > 0 && dollarAmount <= portfolioService.cashBalance ? Color(hex: "080808") : Color(hex: "080808").opacity(0.5))
                        .cornerRadius(20)
                }
                .buttonStyle(PressedButtonStyle())
                .disabled(!(dollarAmount > 0 && dollarAmount <= portfolioService.cashBalance))
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .overlay {
            if showConfirmation {
                BuyConfirmView(
                    stock: stock,
                    amount: dollarAmount,
                    isPresented: $showConfirmation,
                    isBuyFlowPresented: $isPresented,
                    onComplete: onComplete
                )
                .transition(.fluidConfirm)
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showConfirmation)
    }
}

struct NumberPadView: View {
    @Binding var amountString: String
    
    let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        NumberKeyView(key: key) {
                            handleKeyPress(key)
                        }
                    }
                }
            }
        }
    }
    
    private func handleKeyPress(_ key: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        switch key {
        case "⌫":
            if !amountString.isEmpty {
                amountString.removeLast()
            }
        case ".":
            if !amountString.contains(".") && !amountString.isEmpty {
                amountString += "."
            }
        default:
            // Limit to reasonable amount
            if amountString.count < 10 {
                // Don't allow leading zeros except for "0."
                if amountString == "0" && key != "." {
                    amountString = key
                } else {
                    amountString += key
                }
            }
        }
    }
}

struct NumberKeyView: View {
    @ObservedObject private var themeService = ThemeService.shared
    let key: String
    let action: () -> Void
    
    @GestureState private var isPressed = false
    
    var body: some View {
        Text(key)
            .font(.custom("Inter-Bold", size: 28))
            .foregroundColor(themeService.textPrimaryColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isPressed ? Color(hex: "EDEDED") : Color.clear)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
                    .onEnded { value in
                        if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
                            action()
                        }
                    }
            )
    }
}

#Preview {
    BuyStockView(
        stock: Stock(
            name: "Meta",
            symbol: "META",
            price: "$620.80",
            change: "0.43%",
            isPositive: true,
            iconName: "StockMeta"
        ),
        isPresented: .constant(true)
    )
}
