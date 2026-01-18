import SwiftUI
import UIKit

struct HomeView: View {
    @State private var showAddMoney = false
    @State private var showFloatingButton = false
    @State private var showPendingRequests = false
    @StateObject private var activityService = ActivityService.shared
    @StateObject private var requestService = RequestService.shared
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Balance (fixed at top)
                BalanceView()
                    .padding(.horizontal, 24)
                    .background(Color(.systemBackground))
                
                // Empty state, Loading state, or Scrollable content
                if activityService.activities.isEmpty && !activityService.isLoading {
                    // Add money button (fixed)
                    TertiaryButton(title: "Add money") {
                        showAddMoney = true
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Empty state centered in remaining space
                    Spacer()
                    
                    HomeEmptyStateCard(onAddTransactions: {
                        Task {
                            await activityService.fetchActivities(force: true)
                        }
                    })
                    
                    Spacer()
                } else if activityService.isLoading && activityService.activities.isEmpty {
                    // Loading state with skeleton rows
                    TertiaryButton(title: "Add money") {
                        showAddMoney = true
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    VStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonTransactionRow()
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Add money button
                            TertiaryButton(title: "Add money") {
                                showAddMoney = true
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onChange(of: geo.frame(in: .named("scroll")).maxY) { _, newValue in
                                            // Show floating button when the add money button scrolls out of view
                                            showFloatingButton = newValue < 0
                                        }
                                }
                            )
                            
                            // Pending requests card
                            if !requestService.pendingRequests.isEmpty {
                                PendingRequestsCard(
                                    count: requestService.pendingRequests.count,
                                    onTap: { showPendingRequests = true }
                                )
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                            }
                            
                            TransactionListContent()
                                .padding(.top, 20)
                        }
                    }
                    .coordinateSpace(name: "scroll")
                    .refreshable {
                        await ActivityService.shared.fetchActivities(force: true)
                    }
                }
            }
            
            // Floating Add Money Icon Button (appears when scrolled)
            if showFloatingButton {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showAddMoney = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "EDEDED"))
                        .cornerRadius(12)
                }
                .padding(.top, 16)
                .padding(.trailing, 24)
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.2), value: showFloatingButton)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showFloatingButton)
        .fullScreenCover(isPresented: $showAddMoney) {
            AddMoneyView(isPresented: $showAddMoney)
        }
        .fullScreenCover(isPresented: $showPendingRequests) {
            PendingRequestsView()
        }
    }
}

// MARK: - Pending Requests Card

struct PendingRequestsCard: View {
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Icon with badge
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FF5113").opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "FF5113"))
                    }
                    
                    // Badge
                    Text("\(count)")
                        .font(.custom("Inter-Bold", size: 11))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Color(hex: "FF5113"))
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Payment Requests")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                    
                    Text("\(count) pending request\(count == 1 ? "" : "s")")
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "CCCCCC"))
            }
            .padding(16)
            .background(Color(hex: "FFF8F5"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "FF5113").opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Home Empty State Card

struct HomeEmptyStateCard: View {
    var onAddTransactions: () -> Void
    @State private var showTransactionOptions = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Text content
            VStack(spacing: 8) {
                Text("Your activity feed")
                    .font(.custom("Inter-Bold", size: 18))
                    .tracking(-0.36)
                    .foregroundColor(Color(hex: "080808"))
                    .multilineTextAlignment(.center)
                
                Text("When you send, spend, or receive money, it will show here.")
                    .font(.custom("Inter-Regular", size: 16))
                    .tracking(-0.32)
                    .lineSpacing(4)
                    .foregroundColor(Color(hex: "7B7B7B"))
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
                    .foregroundColor(Color(hex: "080808"))
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
        .padding(.horizontal, 48)
    }
}

// MARK: - Skeleton Transaction Row

struct SkeletonTransactionRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F7F7F7"))
                .frame(width: 44, height: 44)
            
            // Text placeholders
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 32) {
                    // Title placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "F7F7F7"))
                        .frame(height: 16)
                    
                    // Status placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "F7F7F7"))
                        .frame(width: 59, height: 16)
                }
                .padding(.vertical, 4)
                
                // Subtitle placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "F7F7F7"))
                    .frame(width: 150, height: 16)
                    .padding(.vertical, 4)
            }
        }
        .padding(16)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(
            Animation.easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    HomeView()
}
