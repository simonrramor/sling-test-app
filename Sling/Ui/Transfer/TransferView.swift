import SwiftUI
import UIKit

struct TransferAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    var iconBackgroundColor: Color? = nil
    var iconColor: Color? = nil
    var isComingSoon: Bool = false
}

struct TransferView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @State private var showSendView = false
    @State private var showRequestView = false
    @State private var showSplitBillView = false
    @State private var showTransferView = false
    @State private var showSalaryView = false
    
    let actions = [
        TransferAction(
            title: "Send",
            subtitle: "Pay anyone on Sling in seconds",
            iconName: "TransferSend"
        ),
        TransferAction(
            title: "Request",
            subtitle: "Ask someone to pay you back",
            iconName: "TransferRequest"
        ),
        TransferAction(
            title: "Transfer",
            subtitle: "Move money between your accounts",
            iconName: "TransferTransfer"
        ),
        TransferAction(
            title: "Receive your salary",
            subtitle: "Get paid into Sling",
            iconName: "TransferSalary"
        )
    ]
    
    let socialActions = [
        TransferAction(
            title: "Split a bill",
            subtitle: "Share the cost of a payment",
            iconName: "TransferSplit",
            iconBackgroundColor: Color(hex: "CAE3FF"),
            iconColor: Color(hex: "3167FC")
        ),
        TransferAction(
            title: "Start a pool",
            subtitle: "Group money and spend with friends",
            iconName: "TransferPool",
            iconBackgroundColor: Color(hex: "FFFECA"),
            isComingSoon: true
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Main transfer actions
                ForEach(actions) { action in
                    if action.isComingSoon {
                        ComingSoonListRow(
                            iconName: action.iconName,
                            title: action.title,
                            subtitle: action.subtitle
                        )
                    } else {
                        ListRow(
                            iconName: action.iconName,
                            title: action.title,
                            subtitle: action.subtitle,
                            iconStyle: .plain,
                            isButton: true,
                            onTap: {
                                switch action.title {
                                case "Send":
                                    showSendView = true
                                case "Request":
                                    showRequestView = true
                                case "Transfer":
                                    showTransferView = true
                                case "Receive your salary":
                                    showSalaryView = true
                                default:
                                    break
                                }
                            }
                        )
                    }
                }
                
                // Social section header
                HStack {
                    Text("Social")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 16)
                
                // Social actions
                ForEach(socialActions) { action in
                    SocialListRow(
                        iconName: action.iconName,
                        title: action.title,
                        subtitle: action.subtitle,
                        backgroundColor: action.iconBackgroundColor ?? .clear,
                        iconColor: action.iconColor,
                        isComingSoon: action.isComingSoon,
                        onTap: {
                            if action.title == "Split a bill" {
                                showSplitBillView = true
                            }
                        }
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .fullScreenCover(isPresented: $showSendView) {
            SendView(isPresented: $showSendView, mode: .send)
        }
        .fullScreenCover(isPresented: $showRequestView) {
            SendView(isPresented: $showRequestView, mode: .request)
        }
        .fullScreenCover(isPresented: $showSplitBillView) {
            SplitBillView(isPresented: $showSplitBillView)
        }
        .fullScreenCover(isPresented: $showTransferView) {
            TransferBetweenAccountsView(isPresented: $showTransferView)
        }
        .sheet(isPresented: $showSalaryView) {
            ReceiveSalarySheet()
        }
    }
}

// MARK: - Receive Salary Sheet

struct ReceiveSalarySheet: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 24)
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "FF5113").opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "FF5113"))
            }
            .padding(.bottom, 16)
            
            Text("Receive Your Salary")
                .font(.custom("Inter-Bold", size: 24))
                .foregroundColor(themeService.textPrimaryColor)
                .padding(.bottom, 8)
            
            Text("Get your salary paid directly into Sling and start spending instantly.")
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(themeService.textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            
            // Account details
            VStack(alignment: .leading, spacing: 16) {
                Text("Share these details with your employer")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
                
                SalaryDetailRow(label: "Account Name", value: "Brendon Arnold")
                SalaryDetailRow(label: "Sort Code", value: "04-00-75")
                SalaryDetailRow(label: "Account Number", value: "12345678")
            }
            .padding(16)
            .background(Color(hex: "F7F7F7"))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                // Copy all details
                let details = """
                Account Name: Brendon Arnold
                Sort Code: 04-00-75
                Account Number: 12345678
                """
                UIPasteboard.general.string = details
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }) {
                Text("Copy Details")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "080808"))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .presentationDetents([.large])
    }
}

struct SalaryDetailRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundColor(themeService.textSecondaryColor)
                
                Text(value)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            
            Spacer()
        }
    }
}

struct SocialListRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let iconName: String
    let title: String
    let subtitle: String
    let backgroundColor: Color
    var iconColor: Color? = nil
    var isComingSoon: Bool = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if !isComingSoon {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onTap?()
            }
        }) {
            HStack(spacing: 16) {
                // Icon with white background
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                    
                    Image(iconName)
                        .resizable()
                        .renderingMode(iconColor != nil ? .template : .original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text(subtitle)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                Spacer()
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(SocialListRowButtonStyle(isComingSoon: isComingSoon))
        .disabled(isComingSoon)
    }
}

struct SocialListRowButtonStyle: ButtonStyle {
    let isComingSoon: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isPressed && !isComingSoon ? Color(hex: "F5F5F5") : Color.clear)
            )
    }
}

// MARK: - Coming Soon List Row

struct ComingSoonListRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let iconName: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Text(subtitle)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
            }
            
            Spacer()
        }
        .padding(16)
    }
}

#Preview {
    TransferView()
}
