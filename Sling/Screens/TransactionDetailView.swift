import SwiftUI
import UIKit

struct TransactionDetailView: View {
    let activity: ActivityItem
    @Environment(\.dismiss) private var dismiss
    @State private var showSplitBill = false
    
    private var isOutgoing: Bool {
        activity.titleRight.hasPrefix("-")
    }
    
    // Check if this is a card payment (can be split)
    private var isCardPayment: Bool {
        guard isOutgoing else { return false }
        
        // Exclude P2P transfers (person avatars)
        let avatar = activity.avatar
        if avatar.count <= 2 { return false }  // Initials
        if avatar.hasPrefix("Avatar") { return false }  // Person avatar
        
        return true
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drawer handle
            DrawerHandle()
            
            // Transaction header
            TransactionHeader(activity: activity)
            
            // Divider
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            // Detail rows
            VStack(spacing: 0) {
                TransactionDetailRow(label: isOutgoing ? "To" : "From", value: activity.titleLeft)
                TransactionDetailRow(label: "Date", value: activity.formattedDateLong)
                TransactionDetailRow(label: "Status", value: "Completed", valueColor: Color(hex: "57CE43"))
                
                if !activity.subtitleLeft.isEmpty {
                    TransactionDetailRow(label: "Note", value: activity.subtitleLeft)
                }
            }
            .padding(.top, 16)
            
            Spacer()
            
            // Split bill button for card payments
            if isCardPayment {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showSplitBill = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Split bill")
                            .font(.custom("Inter-Bold", size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "080808"))
                    .cornerRadius(20)
                }
                .buttonStyle(PressedButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color.white)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $showSplitBill) {
            SplitBillFromTransactionView(
                isPresented: $showSplitBill,
                payment: activity
            )
        }
    }
}

// MARK: - Split Bill From Transaction (skips transaction selector)

struct SplitBillFromTransactionView: View {
    @Binding var isPresented: Bool
    let payment: ActivityItem
    
    var body: some View {
        SplitUserSelectionView(
            isPresented: $isPresented,
            payment: payment,
            onDismissAll: { isPresented = false }
        )
    }
}

// MARK: - Drawer Handle

struct DrawerHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.black.opacity(0.2))
            .frame(width: 32, height: 6)
            .padding(.top, 8)
            .padding(.bottom, 16)
    }
}

// MARK: - Transaction Header

struct TransactionHeader: View {
    let activity: ActivityItem
    
    private var isPositive: Bool {
        activity.titleRight.hasPrefix("+")
    }
    
    private var amountColor: Color {
        isPositive ? Color(hex: "57CE43") : Color(hex: "080808")
    }
    
    private var prefix: String {
        isPositive ? "From" : "To"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Large avatar
            TransactionAvatarLarge(identifier: activity.avatar)
            
            // Transaction info
            VStack(spacing: 4) {
                // To/From label
                HStack(spacing: 4) {
                    Text(prefix)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color(hex: "7B7B7B"))
                    Text(activity.titleLeft)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
                
                // Amount
                Text(activity.titleRight)
                    .font(.custom("Inter-Bold", size: 32))
                    .foregroundColor(amountColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Large Transaction Avatar

struct TransactionAvatarLarge: View {
    let identifier: String
    
    private var logoURL: URL? {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if trimmed.isEmpty { return nil }
        
        if trimmed.hasPrefix("http") {
            if let url = URL(string: identifier), let host = url.host {
                return URL(string: "https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://\(host)&size=128")
            }
            return nil
        }
        
        if trimmed.contains(".") {
            return URL(string: "https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://\(trimmed)&size=128")
        }
        
        let domain = trimmed.replacingOccurrences(of: " ", with: "") + ".com"
        return URL(string: "https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://\(domain)&size=128")
    }
    
    private var isLocalAsset: Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("Avatar") || UIImage(named: trimmed) != nil
    }
    
    private var isPerson: Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("Avatar") || 
               trimmed.count <= 2 || 
               (trimmed.contains(" ") && !trimmed.contains(".") && !trimmed.hasPrefix("http"))
    }
    
    private var cornerRadius: CGFloat {
        isPerson ? 28 : 14
    }
    
    var body: some View {
        if isLocalAsset {
            Image(identifier)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        } else if let url = logoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white)
                            .frame(width: 56, height: 56)
                        
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(generateColor(for: identifier))
                            .frame(width: 56, height: 56)
                        
                        Text(String(identifier.prefix(1)).uppercased())
                            .font(.custom("Inter-Bold", size: 24))
                            .foregroundColor(.white)
                    }
                }
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(generateColor(for: identifier))
                    .frame(width: 56, height: 56)
                
                Text(String(identifier.prefix(1)).uppercased())
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundColor(.white)
            }
        }
    }
    
    private func generateColor(for text: String) -> Color {
        let colors: [Color] = [
            Color(hex: "78D381"), Color(hex: "FF6B6B"), Color(hex: "4ECDC4"),
            Color(hex: "45B7D1"), Color(hex: "96CEB4"), Color(hex: "FFEAA7"),
            Color(hex: "DDA0DD"), Color(hex: "98D8C8"), Color(hex: "F7DC6F"),
            Color(hex: "BB8FCE")
        ]
        let hash = text.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[hash % colors.count]
    }
}

// MARK: - Transaction Detail Row

struct TransactionDetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color(hex: "080808")
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(Color(hex: "7B7B7B"))
            
            Spacer()
            
            Text(value)
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    TransactionDetailView(
        activity: ActivityItem(
            avatar: "monzo.com",
            titleLeft: "Monzo",
            subtitleLeft: "Bank transfer",
            titleRight: "-£10.00",
            subtitleRight: "",
            date: Date()
        )
    )
}
