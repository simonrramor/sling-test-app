import SwiftUI
import UIKit
import Combine

// Helper function to format currency with commas
private func formatCurrency(_ amount: Double, withPrefix prefix: String = "") -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.groupingSeparator = ","
    formatter.decimalSeparator = "."
    let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    return "\(prefix)£\(formatted)"
}

struct SellStockView: View {
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
    
    // Get current stock price from service
    var stockPrice: Double {
        StockService.shared.stockData[stock.iconName]?.currentPrice ?? 100
    }
    
    // Number of shares user owns
    var sharesOwned: Double {
        portfolioService.sharesOwned(for: stock.iconName)
    }
    
    // Max value user can sell (in dollars)
    var maxSellValue: Double {
        sharesOwned * stockPrice
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
    
    // Number of shares to sell
    var sharesToSell: Double {
        sharesAmount
    }
    
    // Dollar display string (with ~ prefix when calculated)
    var dollarDisplay: String {
        if isSharesMode {
            // This is calculated (secondary) - add ~ prefix
            return dollarAmount > 0 ? formatCurrency(dollarAmount, withPrefix: "~") : "~£0"
        } else {
            // This is the input (primary)
            if amountString.isEmpty {
                return "£0"
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
    
    // Check if amount is valid (not more than owned)
    var isValidAmount: Bool {
        dollarAmount > 0 && dollarAmount <= maxSellValue
    }
    
    // Check if over max (for red text)
    var isOverMax: Bool {
        dollarAmount > maxSellValue
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
                            Text("Sell")
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
                    errorMessage: isOverMax ? "Insufficient balance" : nil
                )
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Current holdings display (shows remaining value after amount being typed)
                PaymentInstrumentRow(
                    iconName: stock.iconName,
                    title: stock.name,
                    subtitleParts: [stock.symbol, formatCurrency(max(0, maxSellValue - dollarAmount))],
                    actionButtonTitle: "Max",
                    onActionTap: {
                        if isSharesMode {
                            amountString = String(format: "%.2f", sharesOwned)
                        } else {
                            amountString = String(format: "%.2f", maxSellValue)
                        }
                    },
                    showMenu: true,
                    onMenuTap: {
                        // TODO: Show options menu
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
                    isEnabled: isValidAmount
                ) {
                    showConfirmation = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .overlay {
            if showConfirmation {
                SellConfirmView(
                    stock: stock,
                    amount: dollarAmount,
                    sharesToSell: sharesToSell,
                    isPresented: $showConfirmation,
                    isSellFlowPresented: $isPresented,
                    onComplete: onComplete
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showConfirmation)
    }
}

struct SellConfirmView: View {
    @ObservedObject private var themeService = ThemeService.shared
    let stock: Stock
    let amount: Double
    let sharesToSell: Double
    @Binding var isPresented: Bool
    @Binding var isSellFlowPresented: Bool
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    @State private var quoteTimeRemaining: Int = 30
    @State private var currentStockPrice: Double? = nil
    private let portfolioService = PortfolioService.shared
    
    // Timer for quote countdown
    let quoteTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Get current stock price from service (or use cached quote price)
    var stockPrice: Double {
        currentStockPrice ?? StockService.shared.stockData[stock.iconName]?.currentPrice ?? 100
    }
    
    var formattedShares: String {
        String(format: "%.2f", sharesToSell)
    }
    
    var platformFee: Double {
        0.00 // No fee for selling in this demo
    }
    
    var totalProceeds: Double {
        amount - platformFee
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
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    
                    // Stock name
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            Text("Sell")
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
                .padding(.horizontal, 24)
                .frame(height: 64)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Amount display - centered between header and details
                Text(formatCurrency(amount))
                    .font(.custom("Inter-Bold", size: 62))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                // Details section
                VStack(spacing: 0) {
                    // To
                    DetailRow(
                        label: "To",
                        value: "Sling balance",
                        showSlingIcon: true
                    )
                    
                    // Speed
                    DetailRow(
                        label: "Speed",
                        value: "Instant"
                    )
                    
                    // Divider
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    // Quote validity countdown
                    QuoteValidityRow(secondsRemaining: quoteTimeRemaining)
                    
                    // Approx. share price
                    DetailRow(
                        label: "Approx. share price",
                        value: String(format: "~$%.2f", stockPrice),
                        isHighlighted: true
                    )
                    
                    // Approx. shares
                    DetailRow(
                        label: "Approx. shares",
                        value: String(format: "~%.2f", sharesToSell)
                    )
                    
                    // Platform fee
                    DetailRow(
                        label: "Platform fee",
                        value: "Free"
                    )
                    
                    // Total proceeds
                    DetailRow(
                        label: "You'll receive",
                        value: formatCurrency(totalProceeds)
                    )
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Sell button with smooth loading animation
                LoadingButton(
                    title: "Sell \(formattedShares) \(stock.symbol)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    // Execute the sale through PortfolioService
                    portfolioService.sell(
                        iconName: stock.iconName,
                        shares: sharesToSell,
                        pricePerShare: stockPrice
                    )
                    
                    // Record the transaction in activity feed
                    ActivityService.shared.recordSellStock(
                        stockName: stock.name,
                        stockIcon: stock.iconName,
                        amount: amount,
                        shares: sharesToSell,
                        symbol: stock.symbol
                    )
                    
                    // Navigate home and complete
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    onComplete()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
        .onAppear {
            // Initialize with current price
            currentStockPrice = StockService.shared.stockData[stock.iconName]?.currentPrice ?? 100
        }
        .onReceive(quoteTimer) { _ in
            // Don't count down if loading
            guard !isButtonLoading else { return }
            
            if quoteTimeRemaining > 0 {
                quoteTimeRemaining -= 1
            } else {
                // Refresh the quote
                refreshQuote()
            }
        }
    }
    
    private func refreshQuote() {
        // Get fresh price from service
        let newPrice = StockService.shared.stockData[stock.iconName]?.currentPrice ?? 100
        
        // Add small random variation to simulate real market movement (±0.5%)
        let variation = Double.random(in: -0.005...0.005)
        currentStockPrice = newPrice * (1 + variation)
        
        // Reset timer
        quoteTimeRemaining = 30
        
        // Haptic feedback to indicate refresh
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    SellStockView(
        stock: Stock(
            name: "Apple Inc",
            symbol: "AAPL",
            price: "$178.50",
            change: "1.23%",
            isPositive: true,
            iconName: "StockApple"
        ),
        isPresented: .constant(true)
    )
}
