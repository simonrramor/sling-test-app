import SwiftUI
import UIKit

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var activityService = ActivityService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @State private var showResetConfirmation = false
    @State private var showLogoutConfirmation = false
    @State private var showInviteSheet = false
    @State private var showDepositDetails = false
    @State private var showLinkedAccounts = false
    @State private var showProfile = false
    @State private var showPrivacy = false
    @State private var showParticleTest = false
    @State private var showHomeTest = false
    @State private var showCurrencyPicker = false
    
    private let availableCurrencies = ["GBP", "USD", "EUR", "JPY", "CHF", "CAD", "AUD"]
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // Profile Section
                VStack(spacing: 24) {
                    // Profile Image with verified badge
                    ZStack(alignment: .topTrailing) {
                        Image("AvatarProfile")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                        
                        // Verified badge
                        Image("BadgeVerified")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .offset(x: 5, y: -5)
                    }
                    
                    // Name and username
                    VStack(spacing: 4) {
                        Text("Brendon Arnold")
                            .font(.custom("Inter-Bold", size: 32))
                            .tracking(-0.64)
                            .foregroundColor(.black)
                        
                        Text("@brendon")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color.black.opacity(0.6))
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Settings List
                ScrollView {
                    VStack(spacing: 0) {
                        // Invite Friends Row (standalone top)
                        SettingsRow(
                            iconAsset: "IconUserAdd",
                            title: "Invite friends to Sling",
                            position: .standalone,
                            onTap: { showInviteSheet = true }
                        )
                        
                        Spacer().frame(height: 16)
                        
                        // Account section
                        VStack(spacing: 0) {
                            SettingsRow(
                                iconAsset: "IconList",
                                title: "Deposit account details",
                                position: .top,
                                onTap: { showDepositDetails = true }
                            )
                            
                            SettingsRow(
                                iconAsset: "IconBank",
                                title: "Linked payment accounts",
                                position: .bottom,
                                onTap: { showLinkedAccounts = true }
                            )
                        }
                        
                        // Preferences section
                        VStack(spacing: 0) {
                            SettingsRow(
                                iconAsset: "IconMoney",
                                title: "Display currency",
                                rightText: portfolioService.displayCurrency,
                                position: .standalone,
                                onTap: { showCurrencyPicker = true }
                            )
                            
                            SettingsRow(
                                iconAsset: "IconUser",
                                title: "Your Profile",
                                position: .standalone,
                                onTap: { showProfile = true }
                            )
                            
                            SettingsRow(
                                iconAsset: "IconEye",
                                title: "Privacy",
                                position: .standalone,
                                onTap: { showPrivacy = true }
                            )
                        }
                        
                        // Log out row
                        SettingsRow(
                            iconAsset: "IconLogout",
                            title: "Log out",
                            position: .standalone,
                            onTap: { showLogoutConfirmation = true }
                        )
                        
                        Spacer().frame(height: 16)
                        
                        // Developer section
                        VStack(spacing: 0) {
                            SettingsRow(
                                iconSystem: "sparkles",
                                title: "Particle Burst Test",
                                position: .top,
                                onTap: { showParticleTest = true }
                            )
                            
                            SettingsRow(
                                iconSystem: "house",
                                title: "Home test",
                                position: .bottom,
                                onTap: { showHomeTest = true }
                            )
                        }
                        
                        Spacer().frame(height: 16)
                        
                        // Reset button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            showResetConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Reset App Data")
                                    .font(.custom("Inter-Bold", size: 16))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(16)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .alert("Reset App Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAppData()
            }
        } message: {
            Text("This will clear all your portfolio holdings, cash balance, and activity history. This cannot be undone.")
        }
        .alert("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                logOut()
            }
        } message: {
            Text("Are you sure you want to log out of your account?")
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteShareSheet()
        }
        .sheet(isPresented: $showDepositDetails) {
            DepositDetailsSheet()
        }
        .sheet(isPresented: $showLinkedAccounts) {
            LinkedAccountsSheet()
        }
        .sheet(isPresented: $showProfile) {
            ProfileSheet()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacySheet()
        }
        .fullScreenCover(isPresented: $showParticleTest) {
            ParticleTestView()
        }
        .fullScreenCover(isPresented: $showHomeTest) {
            HomeTestView()
        }
        .confirmationDialog("Display Currency", isPresented: $showCurrencyPicker, titleVisibility: .visible) {
            ForEach(availableCurrencies, id: \.self) { currency in
                Button(action: {
                    portfolioService.displayCurrency = currency
                }) {
                    HStack {
                        Text("\(ExchangeRateService.symbol(for: currency)) \(currency)")
                        if currency == portfolioService.displayCurrency {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func logOut() {
        // Reset app data and close settings
        resetAppData()
        isPresented = false
    }
    
    private func resetAppData() {
        // Reset portfolio
        portfolioService.reset()
        
        // Reset activities
        activityService.clearLocalActivities()
        
        // Clear all persisted data
        PersistenceService.shared.clearAllData()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Settings Row Component

enum RowPosition {
    case top
    case middle
    case bottom
    case standalone
}

struct SettingsRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    var iconAsset: String? = nil
    var iconSystem: String? = nil
    let title: String
    var rightText: String? = nil
    var position: RowPosition = .middle
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    
    private var cornerRadius: CGFloat {
        switch position {
        case .top: return 16
        case .middle: return 0
        case .bottom: return 16
        case .standalone: return 16
        }
    }
    
    private var corners: UIRectCorner {
        switch position {
        case .top: return [.topLeft, .topRight]
        case .middle: return []
        case .bottom: return [.bottomLeft, .bottomRight]
        case .standalone: return .allCorners
        }
    }
    
    private var showDivider: Bool {
        switch position {
        case .top, .middle: return true
        case .bottom, .standalone: return false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Left icon
                if let iconAsset = iconAsset {
                    Image(iconAsset)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(themeService.textSecondaryColor)
                } else if let iconSystem = iconSystem {
                    Image(systemName: iconSystem)
                        .font(.system(size: 20))
                        .foregroundColor(themeService.textSecondaryColor)
                        .frame(width: 24, height: 24)
                }
                
                // Title
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .tracking(-0.32)
                    .foregroundColor(.black)
                
                Spacer()
                
                // Right text (optional)
                if let rightText = rightText {
                    Text(rightText)
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(themeService.textTertiaryColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            // Divider
            if showDivider {
                Rectangle()
                    .fill(Color.black.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.leading, 52)
            }
        }
        .background(isPressed ? Color(hex: "F7F7F7") : Color.white)
        .clipShape(RoundedCornerShape(corners: corners, radius: cornerRadius))
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap?()
        }
    }
}

// MARK: - Custom Corner Shape

struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Deposit Details Sheet

struct DepositDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            Text("Deposit Account Details")
                .font(.custom("Inter-Bold", size: 20))
                .padding(.bottom, 24)
            
            VStack(spacing: 16) {
                DepositDetailRow(label: "Account Name", value: "Brendon Arnold")
                DepositDetailRow(label: "Sort Code", value: "04-00-75")
                DepositDetailRow(label: "Account Number", value: "12345678")
                DepositDetailRow(label: "IBAN", value: "GB29 NWBK 6016 1331 9268 19")
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.white)
        .presentationDetents([.medium])
    }
}

struct DepositDetailRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let label: String
    let value: String
    @State private var copied = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
                
                Text(value)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            
            Spacer()
            
            Button(action: {
                UIPasteboard.general.string = value
                copied = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    copied = false
                }
            }) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 16))
                    .foregroundColor(copied ? Color(hex: "57CE43") : Color(hex: "7B7B7B"))
            }
        }
        .padding(16)
        .background(Color(hex: "F7F7F7"))
        .cornerRadius(12)
    }
}

// MARK: - Linked Accounts Sheet

struct LinkedAccountsSheet: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.dismiss) private var dismiss
    
    let accounts = [
        (name: "Monzo Bank", icon: "AccountMonzo", lastFour: "•••• 4829"),
        (name: "Wise", icon: "AccountWise", lastFour: "•••• 1234"),
        (name: "Apple Pay", icon: "AccountApplePay", lastFour: "")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            Text("Linked Accounts")
                .font(.custom("Inter-Bold", size: 20))
                .padding(.bottom, 24)
            
            VStack(spacing: 0) {
                ForEach(accounts, id: \.name) { account in
                    HStack(spacing: 12) {
                        Image(account.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .font(.custom("Inter-Bold", size: 16))
                                .foregroundColor(themeService.textPrimaryColor)
                            
                            if !account.lastFour.isEmpty {
                                Text(account.lastFour)
                                    .font(.custom("Inter-Regular", size: 14))
                                    .foregroundColor(themeService.textSecondaryColor)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "57CE43"))
                    }
                    .padding(16)
                }
                
                // Add new account
                Button(action: {}) {
                    HStack(spacing: 12) {
                        Image("AccountAddNew")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                        
                        Text("Add new account")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .background(Color.white)
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Profile Sheet

struct ProfileSheet: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            Text("Your Profile")
                .font(.custom("Inter-Bold", size: 20))
                .padding(.bottom, 24)
            
            // Profile image
            Image("AvatarProfile")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .padding(.bottom, 16)
            
            Button(action: {}) {
                Text("Change Photo")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(Color(hex: "FF5113"))
            }
            .padding(.bottom, 24)
            
            VStack(spacing: 16) {
                ProfileField(label: "Full Name", value: "Brendon Arnold")
                ProfileField(label: "Username", value: "@brendon")
                ProfileField(label: "Email", value: "brendon@example.com")
                ProfileField(label: "Phone", value: "+44 7700 900123")
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.white)
        .presentationDetents([.large])
    }
}

struct ProfileField: View {
    @ObservedObject private var themeService = ThemeService.shared
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(themeService.textSecondaryColor)
            
            HStack {
                Text(value)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeService.textTertiaryColor)
            }
        }
        .padding(16)
        .background(Color(hex: "F7F7F7"))
        .cornerRadius(12)
    }
}

// MARK: - Privacy Sheet

struct PrivacySheet: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showBalance = true
    @State private var showActivity = true
    @State private var allowSearchByUsername = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            Text("Privacy")
                .font(.custom("Inter-Bold", size: 20))
                .padding(.bottom, 24)
            
            VStack(spacing: 0) {
                Toggle(isOn: $showBalance) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Balance")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        Text("Display your balance on the home screen")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                }
                .tint(Color(hex: "FF5113"))
                .padding(16)
                
                Divider()
                
                Toggle(isOn: $showActivity) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Activity")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        Text("Display recent transactions")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                }
                .tint(Color(hex: "FF5113"))
                .padding(16)
                
                Divider()
                
                Toggle(isOn: $allowSearchByUsername) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Discoverable by Username")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        Text("Allow others to find you by @brendon")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                }
                .tint(Color(hex: "FF5113"))
                .padding(16)
            }
            .background(Color(hex: "F7F7F7"))
            .cornerRadius(16)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(Color.white)
        .presentationDetents([.medium])
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
}
