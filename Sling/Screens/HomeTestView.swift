import SwiftUI
import UIKit

struct HomeTestView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var themeService = ThemeService.shared
    
    private let tabs = ["activity", "wallet", "invest", "settings"]
    @State private var selectedTab = "wallet"
    
    var formattedBalance: String {
        let balance = portfolioService.totalBalance
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: balance)) ?? "$0.00"
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeService.textSecondaryColor)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                
                // Tab Navigation
                HStack(spacing: 8) {
                    ForEach(tabs, id: \.self) { tab in
                        Text(tab)
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(tab == selectedTab ? Color(hex: "080808") : Color(hex: "AAAAAA"))
                            .onTapGesture {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                selectedTab = tab
                            }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Balance Section - matches Figma specs
                VStack(alignment: .leading, spacing: 4) {
                    // Label: Inter Medium 16pt, -2% tracking, #7B7B7B
                    Text("Cash balance")
                        .font(.custom("Inter-Medium", size: 16))
                        .tracking(-0.32) // -2% at 16pt
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    // Balance: Inter Bold 48pt, line height 1.25em, -2% tracking, #080808
                    Text(formattedBalance)
                        .font(.custom("Inter-Bold", size: 48))
                        .tracking(-0.96) // -2% at 48pt
                        .foregroundColor(themeService.textPrimaryColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Top row: Add, Send
                    HStack(spacing: 16) {
                        CircleActionButton(icon: "plus", action: {})
                        CircleActionButton(icon: "arrow.up.right", action: {})
                    }
                    
                    // Bottom row: QR, Exchange, Menu
                    HStack(spacing: 16) {
                        CircleActionButton(icon: "qrcode", action: {})
                        CircleActionButton(icon: "arrow.left.arrow.right", action: {})
                        CircleActionButton(icon: "line.3.horizontal", action: {})
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Circle Action Button

struct CircleActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color(hex: "080808"))
                .clipShape(Circle())
        }
        .buttonStyle(CircleButtonStyle())
    }
}

struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DesignSystem.Animation.pressedScale : 1.0)
            .animation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping), value: configuration.isPressed)
    }
}

#Preview {
    HomeTestView()
}
