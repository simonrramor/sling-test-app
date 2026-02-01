import SwiftUI
import UIKit

struct ReceiptSplitSummaryView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    let receipt: ScannedReceipt
    let onDismissAll: () -> Void
    
    @State private var isButtonLoading = false
    private let activityService = ActivityService.shared
    
    // Get all unique contacts who have items assigned
    var participants: [Contact] {
        var seen = Set<UUID>()
        var result: [Contact] = []
        
        for item in receipt.items {
            for contact in item.assignedTo {
                if !seen.contains(contact.id) {
                    seen.insert(contact.id)
                    result.append(contact)
                }
            }
        }
        
        return result
    }
    
    // Format currency
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "£\(String(format: "%.2f", amount))"
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image("ArrowLeft")
                            .renderingMode(.template)
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Back")
                    
                    Spacer()
                    
                    Text("Split Summary")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear
                        .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Subtitle
                Text("Here's what each person owes")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .opacity(isButtonLoading ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Participants list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(participants) { contact in
                            PersonSplitCard(
                                contact: contact,
                                items: receipt.items(for: contact),
                                total: receipt.amountPerPerson()[contact] ?? 0,
                                formatAmount: formatAmount
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Bottom button
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    
                    AnimatedLoadingButton(
                        title: "Send Requests",
                        isLoadingBinding: $isButtonLoading
                    ) {
                        // Record split for each participant (except "You")
                        for contact in participants {
                            if contact.name != "You" {
                                let amount = receipt.amountPerPerson()[contact] ?? 0
                                activityService.recordSplitBill(
                                    merchantName: "Receipt Split",
                                    merchantAvatar: "receipt.fill",
                                    splitAmount: amount,
                                    withContactName: contact.name
                                )
                            }
                        }
                        
                        // Navigate to home tab
                        NotificationCenter.default.post(name: .navigateToHome, object: nil)
                        
                        onDismissAll()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .background(Color.white)
                }
            }
            
            // Centered success message (appears when loading)
            if isButtonLoading {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color(hex: "57CE43"))
                    
                    Text("Requests Sent!")
                        .font(.custom("Inter-Bold", size: 24))
                        .foregroundColor(themeService.textPrimaryColor)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
    }
}

// MARK: - Person Split Card

struct PersonSplitCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    let contact: Contact
    let items: [ReceiptItem]
    let total: Double
    let formatAmount: (Double) -> String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row (always visible)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Avatar
                    Image(contact.avatarName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    
                    // Name
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                    
                    Spacer()
                    
                    // Total
                    Text(formatAmount(total))
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeService.textTertiaryColor)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded items list
            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(hex: "EEEEEE"))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                    
                    ForEach(items) { item in
                        HStack {
                            Text(item.name)
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                            
                            Spacer()
                            
                            // Show split price if shared
                            if item.assignedTo.count > 1 {
                                let splitPrice = item.price / Double(item.assignedTo.count)
                                Text("\(formatAmount(splitPrice)) (÷\(item.assignedTo.count))")
                                    .font(.custom("Inter-Regular", size: 14))
                                    .foregroundColor(themeService.textSecondaryColor)
                            } else {
                                Text(item.formattedPrice)
                                    .font(.custom("Inter-Regular", size: 14))
                                    .foregroundColor(themeService.textSecondaryColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color(hex: "F8F8F8"))
        .cornerRadius(16)
    }
}

#Preview {
    let contacts = [
        Contact(name: "You", username: "@brendon", avatarName: "AvatarProfile"),
        Contact(name: "Ben Johnson", username: "@benj", avatarName: "AvatarBenJohnson")
    ]
    
    let receipt = ScannedReceipt(
        items: [
            ReceiptItem(name: "Burger", price: 12.99, assignedTo: [contacts[0]]),
            ReceiptItem(name: "Fries", price: 4.99, assignedTo: [contacts[0], contacts[1]]),
            ReceiptItem(name: "Coke", price: 2.99, assignedTo: [contacts[1]])
        ],
        tax: 1.67,
        tip: nil,
        total: 22.64
    )
    
    return ReceiptSplitSummaryView(
        isPresented: .constant(true),
        receipt: receipt,
        onDismissAll: {}
    )
}
