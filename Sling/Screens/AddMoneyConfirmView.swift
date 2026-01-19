import SwiftUI
import UIKit

struct AddMoneyConfirmView: View {
    @Binding var isPresented: Bool
    let sourceAccount: PaymentAccount // The selected payment account
    let sourceAmount: Double // Amount in source currency (e.g., GBP)
    let sourceCurrency: String // Source currency code (e.g., "GBP")
    let destinationAmount: Double // Amount in USD (Sling balance currency)
    let exchangeRate: Double // Rate from source to USD
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    
    private let portfolioService = PortfolioService.shared
    private let activityService = ActivityService.shared
    private let slingCurrency = "USD" // Sling balance is always in USD
    
    // Extract avatar asset name from account icon type
    private var sourceAccountAvatar: String {
        switch sourceAccount.iconType {
        case .asset(let assetName):
            return assetName
        }
    }
    
    var hasCurrencyDifference: Bool {
        sourceCurrency != slingCurrency
    }
    
    var formattedSourceAmount: String {
        let symbol = ExchangeRateService.symbol(for: sourceCurrency)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: sourceAmount)) ?? String(format: "%.2f", sourceAmount)
        return "\(symbol)\(formattedNumber)"
    }
    
    var formattedDestinationAmount: String {
        let symbol = ExchangeRateService.symbol(for: slingCurrency)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: destinationAmount)) ?? String(format: "%.2f", destinationAmount)
        return "\(symbol)\(formattedNumber)"
    }
    
    var formattedExchangeRate: String {
        let sourceSymbol = ExchangeRateService.symbol(for: sourceCurrency)
        let destSymbol = ExchangeRateService.symbol(for: slingCurrency)
        return "\(sourceSymbol)1 = \(destSymbol)\(String(format: "%.2f", exchangeRate))"
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
                    
                    // Sling logo
                    Image("SlingBalanceLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    
                    // Title
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Add to")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        Text("Sling Balance")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Amount display - centered (shows source amount being sent)
                Text(formattedSourceAmount)
                    .font(.custom("Inter-Bold", size: 56))
                    .foregroundColor(Color(hex: "080808"))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .opacity(isButtonLoading ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Details section
                VStack(spacing: 0) {
                    // From row
                    HStack {
                        Text("From")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            // Account icon
                            switch sourceAccount.iconType {
                            case .asset(let assetName):
                                Image(assetName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 20, height: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            
                            Text(sourceAccount.name)
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(Color(hex: "080808"))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
                    // Transfer speed row
                    HStack {
                        Text("Transfer speed")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Spacer()
                        
                        Text("Instant")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
                    // Divider
                    Rectangle()
                        .fill(Color(hex: "EDEDED"))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    // Total withdrawn row (in source currency)
                    HStack {
                        Text("Total withdrawn")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Spacer()
                        
                        Text(formattedSourceAmount)
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
                    // Fees row
                    HStack {
                        Text("Fees")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Spacer()
                        
                        Text("\(ExchangeRateService.symbol(for: sourceCurrency))0.00")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color(hex: "00C853"))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
                    // Amount exchanged row (in source currency)
                    HStack {
                        Text("Amount exchanged")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Spacer()
                        
                        Text(formattedSourceAmount)
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
                    // Exchange rate row (only show if currencies differ)
                    if hasCurrencyDifference {
                        HStack {
                            Text("Exchange rate")
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(Color(hex: "7B7B7B"))
                            
                            Spacer()
                            
                            Text(formattedExchangeRate)
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(Color(hex: "FF5113"))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    
                    // You receive row (in USD - Sling balance)
                    HStack {
                        Text("You receive")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: "EDEDED"))
                                .frame(width: 6, height: 6)
                            
                            Text(formattedDestinationAmount)
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(Color(hex: "080808"))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Add button (shows destination amount in USD)
                AnimatedLoadingButton(
                    title: "Add \(formattedDestinationAmount)",
                    isLoadingBinding: $isButtonLoading
                ) {
                    // Add money to portfolio (in USD)
                    portfolioService.addCash(destinationAmount)
                    
                    // Record the transaction in activity feed
                    activityService.recordAddMoney(
                        fromAccountName: sourceAccount.name,
                        fromAccountAvatar: sourceAccountAvatar,
                        amount: destinationAmount,
                        currency: slingCurrency
                    )
                    
                    onComplete()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            // Centered amount overlay (appears when loading)
            if isButtonLoading {
                Text(formattedSourceAmount)
                    .font(.custom("Inter-Bold", size: 56))
                    .foregroundColor(Color(hex: "080808"))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
    }
}

#Preview {
    AddMoneyConfirmView(
        isPresented: .constant(true),
        sourceAccount: .monzoBankLimited,
        sourceAmount: 100,
        sourceCurrency: "GBP",
        destinationAmount: 126.50,
        exchangeRate: 1.265
    )
}
