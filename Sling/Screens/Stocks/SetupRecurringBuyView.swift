import SwiftUI
import UIKit

struct SetupRecurringBuyView: View {
    let stock: Stock
    @Binding var isPresented: Bool
    var onComplete: () -> Void = {}
    
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var recurringService = RecurringPurchaseService.shared
    @State private var amountString: String = ""
    @State private var selectedFrequency: RecurringFrequency = .monthly
    @State private var showConfirmation = false
    @State private var isLoading = false
    
    private let portfolioService = PortfolioService.shared
    
    var inputAmount: Double {
        Double(amountString) ?? 0
    }
    
    // Get current stock price from Ondo service
    var stockPrice: Double {
        OndoService.shared.tokenData[stock.iconName]?.currentPrice ?? 100
    }
    
    // Estimate shares per purchase
    var estimatedShares: Double {
        guard inputAmount > 0 else { return 0 }
        return inputAmount / stockPrice
    }
    
    // Monthly investment estimate
    var monthlyEstimate: Double {
        switch selectedFrequency {
        case .daily:
            return inputAmount * 30
        case .weekly:
            return inputAmount * 4.33
        case .biweekly:
            return inputAmount * 2.17
        case .monthly:
            return inputAmount
        }
    }
    
    // Check if valid amount
    var isValidAmount: Bool {
        inputAmount >= 10 && inputAmount <= 1000 && inputAmount <= portfolioService.cashBalance
    }
    
    // Check if user already has recurring purchase for this stock
    var hasExistingRecurring: Bool {
        recurringService.hasRecurringPurchase(for: stock.iconName)
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
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                            .frame(width: 44, height: 44)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Setup Recurring Buy")
                            .font(.custom("Inter-Bold", size: 17))
                            .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                        Text(stock.name)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                    }
                    
                    Spacer()
                    
                    // Stock icon
                    Image(stock.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Warning if already has recurring purchase
                        if hasExistingRecurring {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(Color(hex: "FF8C00"))
                                        .font(.system(size: 20))
                                    
                                    Text("You already have a recurring purchase for \(stock.symbol)")
                                        .font(.custom("Inter-Medium", size: 14))
                                        .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(hex: "FFF8E1"))
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                                
                                Button("Manage Existing Purchase") {
                                    // TODO: Navigate to management view
                                    isPresented = false
                                }
                                .foregroundColor(Color(hex: "FF8C00"))
                                .font(.custom("Inter-Medium", size: 14))
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Amount Input Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Amount per purchase")
                                    .font(.custom("Inter-Bold", size: 16))
                                    .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                                Spacer()
                            }
                            
                            // Amount input
                            VStack(spacing: 8) {
                                HStack {
                                    Text("£")
                                        .font(.custom("Inter-Bold", size: 24))
                                        .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                                    
                                    TextField("0", text: $amountString)
                                        .font(.custom("Inter-Bold", size: 24))
                                        .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(hex: DesignSystem.Colors.backgroundLight))
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                                
                                // Amount validation feedback
                                HStack {
                                    if !amountString.isEmpty {
                                        if inputAmount < 10 {
                                            Text("Minimum £10 per purchase")
                                                .font(.custom("Inter-Regular", size: 13))
                                                .foregroundColor(Color(hex: DesignSystem.Colors.negativeRed))
                                        } else if inputAmount > 1000 {
                                            Text("Maximum £1,000 per purchase")
                                                .font(.custom("Inter-Regular", size: 13))
                                                .foregroundColor(Color(hex: DesignSystem.Colors.negativeRed))
                                        } else if inputAmount > portfolioService.cashBalance {
                                            Text("Insufficient balance")
                                                .font(.custom("Inter-Regular", size: 13))
                                                .foregroundColor(Color(hex: DesignSystem.Colors.negativeRed))
                                        } else {
                                            Text("~\(String(format: "%.4f", estimatedShares)) shares at current price")
                                                .font(.custom("Inter-Regular", size: 13))
                                                .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Frequency Selection
                        VStack(spacing: 16) {
                            HStack {
                                Text("Frequency")
                                    .font(.custom("Inter-Bold", size: 16))
                                    .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                                Spacer()
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(RecurringFrequency.allCases) { frequency in
                                    FrequencyRow(
                                        frequency: frequency,
                                        isSelected: selectedFrequency == frequency
                                    ) {
                                        selectedFrequency = frequency
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Investment Summary
                        if inputAmount > 0 {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Investment summary")
                                        .font(.custom("Inter-Bold", size: 16))
                                        .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    SummaryRow(
                                        title: "Per purchase",
                                        value: "£\(Int(inputAmount))",
                                        subtitle: selectedFrequency.displayName.lowercased()
                                    )
                                    
                                    SummaryRow(
                                        title: "Monthly estimate",
                                        value: String(format: "£%.0f", monthlyEstimate),
                                        subtitle: "Approximate based on frequency"
                                    )
                                    
                                    SummaryRow(
                                        title: "Next purchase", 
                                        value: selectedFrequency.nextDate(from: Date()).formatted(.dateTime.month(.abbreviated).day()),
                                        subtitle: "First purchase will be tomorrow"
                                    )
                                }
                                .padding(16)
                                .background(Color(hex: DesignSystem.Colors.backgroundLight))
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 100) // Space for button
                    }
                }
                
                // Bottom action button
                VStack(spacing: 16) {
                    // Setup button
                    Button(action: setupRecurringPurchase) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isLoading ? "Setting up..." : "Setup Recurring Buy")
                                .font(.custom("Inter-Bold", size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(height: DesignSystem.Button.height)
                        .frame(maxWidth: .infinity)
                        .background(
                            Color(hex: isValidAmount && !hasExistingRecurring ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                        )
                        .cornerRadius(DesignSystem.CornerRadius.large)
                        .scaleEffect(1.0)
                    }
                    .disabled(!isValidAmount || hasExistingRecurring || isLoading)
                    .padding(.horizontal, 24)
                    
                    // Disclaimer
                    Text("Recurring purchases will be automatically executed when you have sufficient balance. You can pause or cancel anytime.")
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 34)
            }
        }
    }
    
    private func setupRecurringPurchase() {
        guard isValidAmount && !hasExistingRecurring else { return }
        
        isLoading = true
        
        // Create the recurring purchase
        let recurringPurchase = RecurringPurchase(
            stockIconName: stock.iconName,
            stockSymbol: stock.symbol,
            stockName: stock.name,
            amount: inputAmount,
            frequency: selectedFrequency
        )
        
        // Add to service
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Simulate API delay
            recurringService.addRecurringPurchase(recurringPurchase)
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            isLoading = false
            onComplete()
            isPresented = false
        }
    }
}

// MARK: - Supporting Views

struct FrequencyRow: View {
    let frequency: RecurringFrequency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(frequency.displayName)
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                    
                    Text(nextPurchaseDescription)
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                }
                
                Spacer()
                
                // Radio button
                Circle()
                    .fill(isSelected ? Color(hex: DesignSystem.Colors.primary) : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary), lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(hex: isSelected ? "FFF5F0" : DesignSystem.Colors.backgroundLight)
            )
            .cornerRadius(DesignSystem.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var nextPurchaseDescription: String {
        let nextDate = frequency.nextDate(from: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Next: \(formatter.string(from: nextDate))"
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                
                Text(subtitle)
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
            }
            
            Spacer()
            
            Text(value)
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(Color(hex: DesignSystem.Colors.dark))
        }
    }
}

// MARK: - Preview

struct SetupRecurringBuyView_Previews: PreviewProvider {
    static var previews: some View {
        SetupRecurringBuyView(
            stock: Stock(
                name: "Apple Inc",
                symbol: "AAPL",
                price: "$150.25",
                change: "+2.5%",
                isPositive: true,
                iconName: "StockApple"
            ),
            isPresented: .constant(true)
        )
    }
}