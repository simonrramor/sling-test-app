import SwiftUI
import UIKit

struct ManageRecurringBuysView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var recurringService = RecurringPurchaseService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @State private var selectedTab = 0
    @State private var showingDeleteConfirmation: RecurringPurchase? = nil
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
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
                    
                    Text("Recurring Purchases")
                        .font(.custom("Inter-Bold", size: 17))
                        .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Summary Cards
                if !recurringService.activePurchases.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            SummaryCard(
                                title: "Monthly Investment",
                                value: "£\(NumberFormatService.shared.formatWholeNumber(recurringService.totalMonthlyInvestment))",
                                subtitle: "Estimated total",
                                iconName: "calendar.badge.clock",
                                color: DesignSystem.Colors.primary
                            )
                            
                            SummaryCard(
                                title: "Total Invested",
                                value: recurringService.totalInvested.asGBP,
                                subtitle: "\(recurringService.totalExecutions) purchases",
                                iconName: "chart.line.uptrend.xyaxis",
                                color: DesignSystem.Colors.positiveGreen
                            )
                            
                            SummaryCard(
                                title: "Active Plans",
                                value: "\(recurringService.activePurchases.count)",
                                subtitle: "\(recurringService.pausedPurchases.count) paused",
                                iconName: "repeat.circle.fill",
                                color: "007AFF"
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 24)
                }
                
                // Tab Selector
                HStack(spacing: 0) {
                    TabButton(
                        title: "Active (\(recurringService.activePurchases.count))",
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }
                    
                    TabButton(
                        title: "History",
                        isSelected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Content
                if selectedTab == 0 {
                    ActivePurchasesTab()
                } else {
                    HistoryTab()
                }
            }
        }
        .actionSheet(item: $showingDeleteConfirmation) { purchase in
            ActionSheet(
                title: Text("Cancel Recurring Purchase"),
                message: Text("Are you sure you want to cancel the recurring purchase for \(purchase.stockName)?"),
                buttons: [
                    .destructive(Text("Cancel Purchase")) {
                        recurringService.cancelRecurringPurchase(purchase.id)
                    },
                    .cancel()
                ]
            )
        }
    }
    
    @ViewBuilder
    private func ActivePurchasesTab() -> some View {
        if recurringService.activePurchases.isEmpty && recurringService.pausedPurchases.isEmpty {
            // Empty state
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "repeat.circle")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                
                VStack(spacing: 8) {
                    Text("No recurring purchases")
                        .font(.custom("Inter-Bold", size: 20))
                        .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                    
                    Text("Set up recurring stock purchases to invest automatically")
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                Button("Browse Stocks") {
                    isPresented = false
                    // TODO: Navigate to stocks tab
                }
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(.white)
                .frame(height: DesignSystem.Button.height)
                .frame(maxWidth: .infinity)
                .background(Color(hex: DesignSystem.Colors.primary))
                .cornerRadius(DesignSystem.CornerRadius.large)
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Active purchases
                    ForEach(recurringService.activePurchases) { purchase in
                        RecurringPurchaseRow(purchase: purchase) { action in
                            handlePurchaseAction(action, for: purchase)
                        }
                    }
                    
                    // Paused purchases
                    ForEach(recurringService.pausedPurchases) { purchase in
                        RecurringPurchaseRow(purchase: purchase) { action in
                            handlePurchaseAction(action, for: purchase)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    @ViewBuilder
    private func HistoryTab() -> some View {
        if recurringService.executionHistory.isEmpty {
            // Empty state
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "clock")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                
                VStack(spacing: 8) {
                    Text("No purchase history")
                        .font(.custom("Inter-Bold", size: 20))
                        .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                    
                    Text("Your recurring purchase history will appear here")
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recurringService.executionHistory) { execution in
                        ExecutionHistoryRow(execution: execution)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func handlePurchaseAction(_ action: PurchaseAction, for purchase: RecurringPurchase) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        switch action {
        case .pause:
            recurringService.pauseRecurringPurchase(purchase.id)
        case .resume:
            recurringService.resumeRecurringPurchase(purchase.id)
        case .cancel:
            showingDeleteConfirmation = purchase
        }
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let iconName: String
    let color: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: color))
                
                Spacer()
            }
            
            Text(value)
                .font(.custom("Inter-Bold", size: 24))
                .foregroundColor(Color(hex: DesignSystem.Colors.dark))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                
                Text(subtitle)
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
            }
        }
        .padding(16)
        .frame(width: 160, height: 120, alignment: .topLeading)
        .background(Color(hex: DesignSystem.Colors.backgroundLight))
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(Color(hex: isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary))
                
                Rectangle()
                    .fill(Color(hex: isSelected ? DesignSystem.Colors.primary : "clear"))
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

enum PurchaseAction {
    case pause
    case resume
    case cancel
}

struct RecurringPurchaseRow: View {
    let purchase: RecurringPurchase
    let onAction: (PurchaseAction) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Main content
            HStack(spacing: 12) {
                // Stock icon
                Image(purchase.stockIconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(purchase.stockName)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                        
                        Spacer()
                        
                        Text(purchase.formattedAmount)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                    }
                    
                    HStack {
                        Text(purchase.frequency.displayName + " • " + purchase.status.displayName)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(Color(hex: purchase.status.color))
                        
                        Spacer()
                        
                        Text(purchase.nextPurchaseDescription)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                    }
                }
            }
            
            // Stats
            HStack {
                StatView(title: "Invested", value: purchase.formattedTotalInvested)
                StatView(title: "Purchases", value: "\(purchase.purchaseCount)")
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    if purchase.status == .active {
                        ActionButton(title: "Pause", style: .secondary) {
                            onAction(.pause)
                        }
                    } else if purchase.status == .paused {
                        ActionButton(title: "Resume", style: .primary) {
                            onAction(.resume)
                        }
                    }
                    
                    ActionButton(title: "Cancel", style: .destructive) {
                        onAction(.cancel)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: DesignSystem.Colors.backgroundLight))
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.custom("Inter-Regular", size: 12))
                .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
            
            Text(value)
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(Color(hex: DesignSystem.Colors.dark))
        }
    }
}

enum ActionButtonStyle {
    case primary
    case secondary
    case destructive
    
    var backgroundColor: String {
        switch self {
        case .primary:
            return DesignSystem.Colors.primary
        case .secondary:
            return DesignSystem.Colors.tertiary
        case .destructive:
            return DesignSystem.Colors.negativeRed
        }
    }
    
    var textColor: String {
        switch self {
        case .primary:
            return "FFFFFF"
        case .secondary:
            return DesignSystem.Colors.dark
        case .destructive:
            return "FFFFFF"
        }
    }
}

struct ActionButton: View {
    let title: String
    let style: ActionButtonStyle
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.custom("Inter-Medium", size: 12))
                .foregroundColor(Color(hex: style.textColor))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: style.backgroundColor))
                .cornerRadius(8)
        }
    }
}

struct ExecutionHistoryRow: View {
    let execution: RecurringPurchaseExecution
    
    var body: some View {
        HStack(spacing: 12) {
            // Stock icon
            Image(execution.stockIconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(execution.stockSymbol)
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                    
                    if !execution.success {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(hex: DesignSystem.Colors.negativeRed))
                            .font(.system(size: 12))
                    }
                    
                    Spacer()
                    
                    Text(execution.formattedAmount)
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(Color(hex: execution.success ? DesignSystem.Colors.dark : DesignSystem.Colors.negativeRed))
                }
                
                HStack {
                    Text(execution.success ? "\(execution.formattedShares) shares" : execution.errorMessage ?? "Failed")
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                    
                    Spacer()
                    
                    Text(execution.formattedDate)
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                }
            }
        }
        .padding(12)
        .background(Color(hex: DesignSystem.Colors.backgroundLight))
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
}

// MARK: - Preview

struct ManageRecurringBuysView_Previews: PreviewProvider {
    static var previews: some View {
        ManageRecurringBuysView(isPresented: .constant(true))
    }
}