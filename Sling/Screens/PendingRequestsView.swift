import SwiftUI
import UIKit

struct PendingRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var requestService = RequestService.shared
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @State private var selectedRequest: PaymentRequest?
    @State private var showPayConfirmation = false
    @State private var showDeclineConfirmation = false
    @State private var showInsufficientFunds = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(themeService.textPrimaryColor)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "F5F5F5"))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Payment Requests")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            if requestService.pendingRequests.isEmpty {
                // Empty state
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "57CE43"))
                    
                    Text("All caught up!")
                        .font(.custom("Inter-Bold", size: 20))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text("You don't have any pending payment requests.")
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundColor(themeService.textSecondaryColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                }
                
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(requestService.pendingRequests) { request in
                            RequestRow(
                                request: request,
                                onPay: {
                                    selectedRequest = request
                                    if portfolioService.cashBalance >= request.amount {
                                        showPayConfirmation = true
                                    } else {
                                        showInsufficientFunds = true
                                    }
                                },
                                onDecline: {
                                    selectedRequest = request
                                    showDeclineConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .background(Color.white)
        .alert("Pay Request", isPresented: $showPayConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Pay \(selectedRequest?.formattedAmount ?? "")") {
                if let request = selectedRequest {
                    requestService.payRequest(request)
                }
            }
        } message: {
            Text("Pay \(selectedRequest?.formattedAmount ?? "") to \(selectedRequest?.fromName ?? "")?")
        }
        .alert("Decline Request", isPresented: $showDeclineConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Decline", role: .destructive) {
                if let request = selectedRequest {
                    requestService.declineRequest(request)
                }
            }
        } message: {
            Text("Decline payment request from \(selectedRequest?.fromName ?? "")?")
        }
        .alert("Insufficient Funds", isPresented: $showInsufficientFunds) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You don't have enough balance to pay this request. Add money to your account first.")
        }
    }
}

struct RequestRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let request: PaymentRequest
    let onPay: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar
                Image(request.fromAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.fromName)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    if !request.note.isEmpty {
                        Text(request.note)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                    } else {
                        Text(request.formattedDate)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                }
                
                Spacer()
                
                // Amount
                Text(request.formattedAmount)
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(themeService.textPrimaryColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "F7F7F7"))
                        .cornerRadius(12)
                }
                
                Button(action: onPay) {
                    Text("Pay")
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "080808"))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.leading, 76)
        }
    }
}

#Preview {
    PendingRequestsView()
}
