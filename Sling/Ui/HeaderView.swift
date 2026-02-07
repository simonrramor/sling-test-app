import SwiftUI
import UIKit

struct HeaderView: View {
    var currentTab: Tab = .home
    var previousTab: Tab? = nil
    var onProfileTap: () -> Void = {}
    var onSearchTap: () -> Void = {}
    var onInviteTap: () -> Void = {}
    var onQRScannerTap: () -> Void = {}
    
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.selectedAppVariant) private var selectedAppVariant
    @AppStorage("cardAvailable") private var cardAvailable = true
    
    // Determine which buttons to show based on current tab
    private var showInvite: Bool {
        true // Always show invite
    }
    
    private var showSearch: Bool {
        currentTab == .home || currentTab == .invest
    }
    
    // Determine direction for animations
    private func tabIndex(_ tab: Tab) -> Int {
        switch tab {
        case .home: return 0
        case .card: return 1
        case .invest: return 2
        }
    }
    
    private var isMovingRight: Bool {
        guard let prev = previousTab else { return true }
        return tabIndex(currentTab) > tabIndex(prev)
    }
    
    // Custom transition with directional horizontal offset
    private var buttonTransition: AnyTransition {
        let offsetX: CGFloat = isMovingRight ? 15 : -15
        return AnyTransition.asymmetric(
            insertion: .scale(scale: 0.85)
                .combined(with: .opacity)
                .combined(with: .offset(x: offsetX)),
            removal: .scale(scale: 0.85)
                .combined(with: .opacity)
                .combined(with: .offset(x: -offsetX))
        )
    }
    
    var body: some View {
        HStack {
            // Profile Picture
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onProfileTap()
            }) {
                Image("AvatarProfile")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
            }
            .accessibilityLabel("Profile")
            
            Spacer()
            
            HStack(spacing: 8) {
                // Invite Button - always shown
                if showInvite {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onInviteTap()
                    }) {
                        Text("Invite")
                            .font(.custom("Inter-Bold", size: 14))
                            .foregroundColor(Color("TextPrimary"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .transition(buttonTransition)
                }
                
                // Search Button - Home, Invest
                if showSearch {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onSearchTap()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TextPrimary"))
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .accessibilityLabel("Search")
                    .transition(buttonTransition)
                }
                
                // QR Scanner Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onQRScannerTap()
                }) {
                    Image("QRCode")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("TextPrimary"))
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .accessibilityLabel("Scan QR Code")
                .transition(buttonTransition)
                
                // Card availability toggle button - only on card tab
                if currentTab == .card {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        cardAvailable.toggle()
                    }) {
                        ZStack {
                            Image(systemName: "creditcard")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))
                                .frame(width: 36, height: 36)
                                .background(Color.white)
                                .cornerRadius(12)
                            
                            // Status dot indicator
                            Circle()
                                .fill(cardAvailable ? Color(hex: "57CE43") : Color(hex: "E30000"))
                                .frame(width: 8, height: 8)
                                .offset(x: 12, y: -12)
                        }
                    }
                    .accessibilityLabel(cardAvailable ? "Card available" : "Card not available")
                    .transition(buttonTransition)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentTab)
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    HeaderView()
        .padding()
}
