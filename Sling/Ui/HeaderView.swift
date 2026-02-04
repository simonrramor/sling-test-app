import SwiftUI
import UIKit

struct HeaderView: View {
    var currentTab: Tab = .home
    var previousTab: Tab? = nil
    var onProfileTap: () -> Void = {}
    var onChatTap: () -> Void = {}
    var onQRCodeTap: () -> Void = {}
    var onSearchTap: () -> Void = {}
    var onInviteTap: () -> Void = {}
    
    @ObservedObject private var themeService = ThemeService.shared
    
    // Determine which buttons to show based on current tab
    // Home: Invite, QR, Help
    // Card: Invite, Help
    // Transfer: Invite, QR, Help
    // Invest: Search, Invite, Help
    
    private var showInvite: Bool {
        true // Always show invite
    }
    
    private var showQR: Bool {
        currentTab == .home
    }
    
    private var showSearch: Bool {
        currentTab == .home || currentTab == .invest
    }
    
    private var showHelp: Bool {
        true // Always show help
    }
    
    // Determine direction for animations
    private func tabIndex(_ tab: Tab) -> Int {
        switch tab {
        case .home: return 0
        case .card: return 1
        case .invest: return 2
        case .savings: return 3
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
                            .background(Color("BackgroundTertiary"))
                            .cornerRadius(12)
                    }
                    .transition(buttonTransition)
                }
                
                // QR Code Button - Home, Transfer
                if showQR {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onQRCodeTap()
                    }) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TextPrimary"))
                            .frame(width: 36, height: 36)
                            .background(Color("BackgroundTertiary"))
                            .cornerRadius(12)
                    }
                    .accessibilityLabel("QR Code")
                    .transition(buttonTransition)
                }
                
                // Search Button - Invest, Activity
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
                            .background(Color("BackgroundTertiary"))
                            .cornerRadius(12)
                    }
                    .accessibilityLabel("Search")
                    .transition(buttonTransition)
                }
                
                // Chat/Help Button - always shown
                if showHelp {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onChatTap()
                    }) {
                        Image(systemName: "questionmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TextPrimary"))
                            .frame(width: 36, height: 36)
                            .background(Color("BackgroundTertiary"))
                            .cornerRadius(12)
                    }
                    .accessibilityLabel("Help")
                    .transition(buttonTransition)
                }
                
                // Theme Switcher Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    themeService.toggleTheme()
                }) {
                    Image(systemName: themeService.currentTheme.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                        .frame(width: 36, height: 36)
                        .background(Color("BackgroundTertiary"))
                        .cornerRadius(12)
                }
                .accessibilityLabel("Theme: \(themeService.currentTheme.displayName)")
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentTab)
            .animation(.easeInOut(duration: 0.2), value: themeService.currentTheme)
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    HeaderView()
        .padding()
}
