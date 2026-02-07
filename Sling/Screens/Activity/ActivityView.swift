import SwiftUI

struct ActivityView: View {
    @ObservedObject private var activityService = ActivityService.shared
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Activity")
                .font(.custom("Inter-Bold", size: 24))
                .foregroundColor(themeService.textPrimaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            if activityService.activities.isEmpty && !activityService.isLoading {
                // Empty state centered in remaining space
                Spacer()
                
                ActivityEmptyStateCard(onAddTransactions: {
                    Task {
                        await activityService.fetchActivities(force: true)
                    }
                })
                
                Spacer()
            } else if activityService.isLoading && activityService.activities.isEmpty {
                // Loading state with skeleton rows
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonTransactionRow()
                    }
                }
                .padding(.top, 8)
                
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        TransactionListContent()
                            .padding(.top, 8)
                    }
                }
                .refreshable {
                    await ActivityService.shared.fetchActivities(force: true)
                }
            }
        }
    }
}

// MARK: - Activity Empty State Card

struct ActivityEmptyStateCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    var onAddTransactions: () -> Void
    @State private var showTransactionOptions = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Text content
            VStack(spacing: 8) {
                Text("Your activity feed")
                    .font(.custom("Inter-Bold", size: 18))
                    .tracking(-0.36)
                    .foregroundColor(themeService.textPrimaryColor)
                    .multilineTextAlignment(.center)
                
                Text("When you send, spend, or receive money, it will show here.")
                    .font(.custom("Inter-Regular", size: 16))
                    .tracking(-0.32)
                    .lineSpacing(4)
                    .foregroundColor(themeService.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }
            
            // Add transactions button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showTransactionOptions = true
            }) {
                Text("Add transactions")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(themeService.textPrimaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "EDEDED"))
                    .cornerRadius(12)
            }
            .confirmationDialog("Add Transaction", isPresented: $showTransactionOptions, titleVisibility: .visible) {
                Button("Card Payment") {
                    ActivityService.shared.generateCardPayment()
                }
                Button("P2P Outbound (Send)") {
                    ActivityService.shared.generateP2POutbound()
                }
                Button("P2P Inbound (Receive)") {
                    ActivityService.shared.generateP2PInbound()
                }
                Button("Top Up") {
                    ActivityService.shared.generateTopUp()
                }
                Button("Withdrawal") {
                    ActivityService.shared.generateWithdrawal()
                }
                Button("Random Mix (8 transactions)") {
                    ActivityService.shared.generateRandomMix()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        .padding(.horizontal, 64)
    }
}

#Preview {
    ActivityView()
}
