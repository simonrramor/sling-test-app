import SwiftUI
import UIKit

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    @ObservedObject private var activityService = ActivityService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var savingsService = SavingsService.shared
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var showResetConfirmation = false
    @State private var showLogoutConfirmation = false
    @State private var showInviteSheet = false
    @State private var showDepositDetails = false
    @State private var showLinkedAccounts = false
    @State private var showProfile = false
    @State private var showPrivacy = false
    @State private var showPassport = false
    @State private var showParticleTest = false
    @State private var showBlobsTest = false
    @State private var showMorseBot = false
    @State private var showBotComparison = false
    @State private var showSwapTest = false
    @State private var showCardTest = false
    @State private var showCurrencyPicker = false
    @State private var showFees = false
    @State private var showInvestments = false
    @State private var showQRScanner = false
    @State private var showHelpChat = false
    @State private var showTransfer = false
    
    var body: some View {
        ZStack {
            themeService.backgroundColor
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
                
                // Settings List (everything scrolls)
                ScrollView {
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
                                .foregroundColor(themeService.textPrimaryColor)
                            
                            Text("@brendon")
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(themeService.textSecondaryColor)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
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
                                position: .middle,
                                onTap: { showLinkedAccounts = true }
                            )
                            
                            SettingsRow(
                                iconAsset: "IconMoney",
                                title: "Fees",
                                position: .middle,
                                onTap: { showFees = true }
                            )
                            
                            SettingsRow(
                                iconAsset: "NavInvest",
                                title: "Investments",
                                position: .middle,
                                onTap: { showInvestments = true }
                            )
                            
                            SettingsRow(
                                iconSystem: "arrow.left.arrow.right",
                                title: "Transfer between accounts",
                                position: .bottom,
                                onTap: { showTransfer = true }
                            )
                        }
                        
                        // Preferences section
                        VStack(spacing: 0) {
                            SettingsRow(
                                iconAsset: "IconMoney",
                                title: "Display currency",
                                rightText: displayCurrencyService.displayCurrency,
                                position: .top,
                                onTap: { showCurrencyPicker = true }
                            )
                            
                            SettingsRow(
                                iconSystem: themeService.currentTheme.iconName,
                                title: "Theme",
                                rightText: themeService.currentTheme.displayName,
                                position: .bottom,
                                onTap: { 
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    themeService.toggleTheme() 
                                }
                            )
                        }
                        
                        // Tools section
                        VStack(spacing: 0) {
                            SettingsRow(
                                iconSystem: "qrcode",
                                title: "QR Scanner",
                                position: .top,
                                onTap: { showQRScanner = true }
                            )
                            
                            SettingsRow(
                                iconSystem: "questionmark.circle",
                                title: "Help & Support",
                                position: .bottom,
                                onTap: { showHelpChat = true }
                            )
                        }
                        
                        // Profile section
                        VStack(spacing: 0) {
                            SettingsRow(
                                iconAsset: "IconUser",
                                title: "Your Profile",
                                position: .top,
                                onTap: { showProfile = true }
                            )
                            
                            SettingsRow(
                                iconAsset: "IconEye",
                                title: "Privacy",
                                position: .bottom,
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
                        
                        Spacer().frame(height: 24)
                        
                        // Test Area section header
                        Text("Test Area")
                            .font(.custom("Inter-Bold", size: 13))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        
                        // Developer section
                        VStack(spacing: 0) {
                            SettingsRow(
                                iconSystem: "creditcard.fill",
                                title: "Card Test",
                                position: .top,
                                onTap: { showCardTest = true }
                            )
                            
                            SettingsRow(
                                iconSystem: "arrow.up.arrow.down",
                                title: "Swap Animation",
                                position: .middle,
                                onTap: { showSwapTest = true }
                            )
                            
                            SettingsRow(
                                iconSystem: "book.closed.fill",
                                title: "Passport",
                                position: .middle,
                                onTap: { showPassport = true }
                            )
                            
                            SettingsRow(
                                iconSystem: "sparkles",
                                title: "Particle Burst Test",
                                position: .middle,
                                onTap: { showParticleTest = true }
                            )
                            
                            SettingsRow(
                                iconAsset: "IconMorseBot",
                                title: "Morse Bot",
                                position: .middle,
                                onTap: { showMorseBot = true }
                            )
                            
                            SettingsRow(
                                iconAsset: "IconMorseBot",
                                title: "Bot Comparison",
                                position: .middle,
                                onTap: { showBotComparison = true }
                            )
                            
                            SettingsRow(
                                iconSystem: "circle.grid.2x2",
                                title: "Blobs",
                                position: .bottom,
                                onTap: { showBlobsTest = true }
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
                            .background(themeService.cardBackgroundColor)
                            .cornerRadius(24)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .alert("Reset App Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAppData()
                isPresented = false
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
        .fullScreenCover(isPresented: $showPassport) {
            PassportView()
        }
        .fullScreenCover(isPresented: $showParticleTest) {
            ParticleTestView()
        }
        .fullScreenCover(isPresented: $showBlobsTest) {
            BlobsTestView()
        }
        .fullScreenCover(isPresented: $showMorseBot) {
            MorseBotView(isPresented: $showMorseBot)
        }
        .fullScreenCover(isPresented: $showBotComparison) {
            NavigationView {
                BotComparisonView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showBotComparison = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showSwapTest) {
            SwapAnimationTestView()
        }
        .fullScreenCover(isPresented: $showCardTest) {
            CardTestView(isPresented: $showCardTest)
        }
        .fullScreenCover(isPresented: $showFees) {
            FeesSettingsView(isPresented: $showFees)
        }
        .fullScreenCover(isPresented: $showCurrencyPicker) {
            CurrencySelectionView(isPresented: $showCurrencyPicker)
        }
        .fullScreenCover(isPresented: $showInvestments) {
            InvestView(isPresented: $showInvestments)
        }
        .fullScreenCover(isPresented: $showQRScanner) {
            QRScannerView()
        }
        .fullScreenCover(isPresented: $showHelpChat) {
            ChatView()
        }
        .fullScreenCover(isPresented: $showTransfer) {
            TransferBetweenAccountsView(isPresented: $showTransfer)
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
        
        // Reset savings
        savingsService.reset()
        
        // Reset activities
        activityService.clearLocalActivities()
        
        // Clear all persisted data
        PersistenceService.shared.clearAllData()
        
        // Clear Get Started flags
        UserDefaults.standard.removeObject(forKey: "hasAddedMoney")
        UserDefaults.standard.removeObject(forKey: "hasSentMoney")
        UserDefaults.standard.removeObject(forKey: "hasSetupAccount")
        UserDefaults.standard.removeObject(forKey: "hasCard")
        
        // Log out user - this will show the login screen
        isLoggedIn = false
        
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
                    .foregroundColor(themeService.textPrimaryColor)
                
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
                    .fill(themeService.textPrimaryColor.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.leading, 52)
            }
        }
        .background(isPressed ? (themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F7F7F7")) : themeService.cardBackgroundColor)
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
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(themeService.textPrimaryColor.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            Text("Deposit Account Details")
                .font(.custom("Inter-Bold", size: 20))
                .foregroundColor(themeService.textPrimaryColor)
                .padding(.bottom, 24)
            
            VStack(spacing: 16) {
                DepositDetailRow(label: "Account Name", value: "Brendon Arnold")
                DepositDetailRow(label: "Sort Code", value: "04-00-75")
                DepositDetailRow(label: "Account Number", value: "12345678")
                DepositDetailRow(label: "IBAN", value: "GB29 NWBK 6016 1331 9268 19")
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(themeService.backgroundColor)
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
                    .foregroundColor(copied ? Color.appPositiveGreen : themeService.textSecondaryColor)
            }
        }
        .padding(16)
        .background(themeService.currentTheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F7F7F7"))
        .cornerRadius(12)
    }
}

// MARK: - Linked Accounts Sheet

struct LinkedAccountsSheet: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.dismiss) private var dismiss
    
    let accounts = [
        (name: "Monzo Bank", icon: "AccountMonzo", lastFour: "•••• 4829"),
        (name: "EU Bank", icon: "AccountWise", lastFour: "•••• 1234"),
        (name: "Apple Pay", icon: "AccountApplePay", lastFour: "")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(themeService.textPrimaryColor.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            Text("Linked Accounts")
                .font(.custom("Inter-Bold", size: 20))
                .foregroundColor(themeService.textPrimaryColor)
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
                            .foregroundColor(Color.appPositiveGreen)
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
        .background(themeService.backgroundColor)
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
                .fill(themeService.textPrimaryColor.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            Text("Your Profile")
                .font(.custom("Inter-Bold", size: 20))
                .foregroundColor(themeService.textPrimaryColor)
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
                    .foregroundColor(Color.appPrimary)
            }
            .padding(.bottom, 24)
            
            VStack(spacing: 16) {
                ProfileField(label: "Full Name", value: "Brendon Arnold")
                ProfileField(label: "Username", value: "@brendon")
                ProfileField(label: "Email", value: "brendon@example.com")
                ProfileField(label: "Phone", value: "+44 7700 900123")
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(themeService.backgroundColor)
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
        .background(themeService.currentTheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F7F7F7"))
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
                .fill(themeService.textPrimaryColor.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            Text("Privacy")
                .font(.custom("Inter-Bold", size: 20))
                .foregroundColor(themeService.textPrimaryColor)
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
                .tint(Color.appPrimary)
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
                .tint(Color.appPrimary)
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
                .tint(Color.appPrimary)
                .padding(16)
            }
            .background(themeService.currentTheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F7F7F7"))
            .cornerRadius(24)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(themeService.backgroundColor)
        .presentationDetents([.medium])
    }
}

// MARK: - Passport View

struct PassportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var passportService = PassportService.shared
    @State private var selectedPassport: PassportInfo?
    @State private var showCountryPicker = false
    @State private var searchText = ""
    
    private var accentColor: Color {
        selectedPassport?.swiftUIColor ?? Color(hex: "1C3A6E")
    }
    
    private var filteredPassports: [PassportInfo] {
        if searchText.isEmpty {
            return passportService.passports
        }
        return passportService.passports.filter {
            $0.country.lowercased().contains(searchText.lowercased()) ||
            $0.code.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        ZStack {
            themeService.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Passport")
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Spacer()
                    
                    // Empty space to balance the close button
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                Spacer()
                
                // Passport Image
                VStack(spacing: 24) {
                    PassportCardView(passport: selectedPassport)
                        .onTapGesture {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showCountryPicker = true
                        }
                    
                    VStack(spacing: 8) {
                        Text(selectedPassport?.country ?? "Select a Country")
                            .font(.custom("Inter-Bold", size: 20))
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        if let passport = selectedPassport {
                            Text(passport.colorName)
                                .font(.custom("Inter-Medium", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                            
                            Text(passport.emblemDescription)
                                .font(.custom("Inter-Regular", size: 13))
                                .foregroundColor(themeService.textTertiaryColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        } else {
                            Text("Tap the passport to choose")
                                .font(.custom("Inter-Medium", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                        }
                    }
                }
                
                Spacer()
                
                // Country count
                Text("\(passportService.passports.count) countries available")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textTertiaryColor)
                    .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(
                passports: filteredPassports,
                searchText: $searchText,
                selectedPassport: $selectedPassport,
                isPresented: $showCountryPicker
            )
        }
    }
}

// MARK: - Passport Card View

struct PassportCardView: View {
    let passport: PassportInfo?
    
    private var passportColor: Color {
        passport?.swiftUIColor ?? Color(hex: "1C3A6E")
    }
    
    private var isLightColor: Bool {
        // Gold/Yellow passports need dark text
        passport?.colorName == "Gold"
    }
    
    private var textColor: Color {
        isLightColor ? Color.black.opacity(0.8) : Color(hex: "FFD700")
    }
    
    private var subtextColor: Color {
        isLightColor ? Color.black.opacity(0.5) : Color.white.opacity(0.7)
    }
    
    var body: some View {
        ZStack {
            // Passport background
            RoundedRectangle(cornerRadius: 24)
                .fill(passportColor)
                .frame(width: 280, height: 400)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 20) {
                // Top decoration
                HStack {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(textColor.opacity(0.8))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 24)
                
                Spacer()
                
                // Emblem/Logo
                ZStack {
                    Circle()
                        .fill(textColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: passport?.emblemIcon ?? "globe")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(textColor)
                }
                
                // Text
                VStack(spacing: 8) {
                    Text("PASSPORT")
                        .font(.custom("Inter-Bold", size: 24))
                        .tracking(4)
                        .foregroundColor(textColor)
                    
                    Text(passport?.country.uppercased() ?? "SELECT COUNTRY")
                        .font(.custom("Inter-Regular", size: 14))
                        .tracking(2)
                        .foregroundColor(subtextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                // Chip
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "FFD700"),
                            Color(hex: "FFA500")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 40)
                    .overlay(
                        VStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.2))
                                    .frame(height: 1)
                            }
                        }
                        .padding(4)
                    )
                    .padding(.bottom, 32)
            }
            .frame(width: 280, height: 400)
        }
        .animation(.easeInOut(duration: 0.3), value: passport?.code)
    }
}

// MARK: - Country Picker Sheet

struct CountryPickerSheet: View {
    let passports: [PassportInfo]
    @Binding var searchText: String
    @Binding var selectedPassport: PassportInfo?
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(passports) { passport in
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        selectedPassport = passport
                        isPresented = false
                    }) {
                        HStack(spacing: 12) {
                            // Color swatch with emblem icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(passport.swiftUIColor)
                                    .frame(width: 40, height: 28)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                                
                                Image(systemName: passport.emblemIcon)
                                    .font(.system(size: 12))
                                    .foregroundColor(passport.colorName == "Gold" ? .black.opacity(0.6) : Color(hex: "FFD700"))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(passport.country)
                                    .font(.custom("Inter-Bold", size: 16))
                                    .foregroundColor(themeService.textPrimaryColor)
                                
                                Text("\(passport.colorName) · \(passport.emblem)")
                                    .font(.custom("Inter-Regular", size: 13))
                                    .foregroundColor(themeService.textSecondaryColor)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text(passport.code)
                                .font(.custom("Inter-Medium", size: 14))
                                .foregroundColor(themeService.textTertiaryColor)
                            
                            if selectedPassport?.code == passport.code {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.appPrimary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color.appPrimary)
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
}

#Preview("Passport") {
    PassportView()
}
