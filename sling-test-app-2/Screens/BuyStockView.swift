import SwiftUI
import UIKit

struct BuyStockView: View {
    let stock: Stock
    @Binding var isPresented: Bool
    var onComplete: () -> Void = {}
    @State private var amountString: String = ""
    @State private var showConfirmation = false
    @State private var isSharesMode: Bool = false  // false = dollars, true = shares
    
    private let portfolioService = PortfolioService.shared
    
    var inputValue: Double {
        Double(amountString) ?? 0
    }
    
    // Get current stock price from service
    var stockPrice: Double {
        StockService.shared.stockData[stock.iconName]?.currentPrice ?? 100
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
    
    // Formatted cash balance for display
    var formattedCashBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: portfolioService.cashBalance)) ?? String(format: "%.2f", portfolioService.cashBalance)
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
                            .foregroundColor(Color(hex: "7B7B7B"))
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
                                .foregroundColor(Color(hex: "7B7B7B"))
                            Text("·")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(Color(hex: "7B7B7B"))
                            Text(stock.symbol)
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(Color(hex: "7B7B7B"))
                        }
                        Text(stock.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                
                Spacer()
                
                // Amount input display with swap animation
                AmountSwapView(
                    dollarDisplay: dollarDisplay,
                    sharesDisplay: sharesDisplay,
                    isSharesMode: isSharesMode,
                    onSwap: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        
                        // Convert current value to the other mode
                        if isSharesMode {
                            let dollars = dollarAmount
                            amountString = dollars > 0 ? String(format: "%.2f", dollars) : ""
                        } else {
                            let shares = sharesAmount
                            amountString = shares > 0 ? String(format: "%.2f", shares) : ""
                        }
                        
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                            isSharesMode.toggle()
                        }
                    },
                    errorMessage: isOverBalance ? "Insufficient balance" : nil
                )
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Payment source
                PaymentInstrumentRow(
                    iconName: "SlingBalanceLogo",
                    title: "Sling balance",
                    subtitleParts: [formattedCashBalance],
                    showMenu: true,
                    onMenuTap: {
                        // TODO: Show payment source selector
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Number pad
                NumberPadView(amountString: $amountString)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Next button
                SecondaryButton(
                    title: "Next",
                    isEnabled: dollarAmount > 0 && dollarAmount <= portfolioService.cashBalance
                ) {
                    showConfirmation = true
                }
                .padding(.horizontal, 24)
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
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showConfirmation)
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
    let key: String
    let action: () -> Void
    
    @GestureState private var isPressed = false
    
    var body: some View {
        Text(key)
            .font(.custom("Inter-Bold", size: 28))
            .foregroundColor(Color(hex: "080808"))
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

struct AmountSwapView: View {
    let dollarDisplay: String
    let sharesDisplay: String
    let isSharesMode: Bool
    let onSwap: () -> Void
    var textColor: Color = Color(hex: "080808")
    var errorMessage: String? = nil
    
    private let topOffset: CGFloat = 0
    private let bottomOffset: CGFloat = 45
    
    private var hasError: Bool {
        errorMessage != nil
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: onSwap) {
                VStack(spacing: 4) {
                    // Primary amount (always visible)
                    Text(isSharesMode ? sharesDisplay : dollarDisplay)
                        .font(.custom("Inter-Bold", size: 56))
                        .foregroundColor(textColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    // Secondary amount with swap icon (hidden when error)
                    if !hasError {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "7B7B7B"))
                            
                            Text(isSharesMode ? dollarDisplay : sharesDisplay)
                                .font(.custom("Inter-Medium", size: 18))
                                .foregroundColor(Color(hex: "7B7B7B"))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                    }
                    
                    // Error message (shown instead of secondary amount)
                    if let error = errorMessage {
                        Text(error)
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(Color(hex: "E30000"))
                    }
                }
            }
            .buttonStyle(.plain)
        }
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
