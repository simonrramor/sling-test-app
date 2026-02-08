import SwiftUI
import UIKit

// MARK: - Contact Model

struct Contact: Identifiable {
    let id = UUID()
    let name: String
    let username: String
    let avatarName: String
    var isVerified: Bool = true
}

// MARK: - Payment Mode

enum PaymentMode {
    case send
    case request
    
    var title: String {
        switch self {
        case .send: return "Send"
        case .request: return "Request"
        }
    }
    
    var headerPrefix: String {
        switch self {
        case .send: return "Send to"
        case .request: return "Request from"
        }
    }
    
    var buttonPrefix: String {
        switch self {
        case .send: return "Send"
        case .request: return "Request"
        }
    }
}

// MARK: - Send View

struct SendView: View {
    @Binding var isPresented: Bool
    var mode: PaymentMode = .send
    var preselectedContact: Contact? = nil
    @ObservedObject private var themeService = ThemeService.shared
    @State private var searchText = ""
    @State private var selectedContact: Contact? = nil
    @State private var showAmountInput = false
    
    // Sample contacts for recents
    let recentContacts = [
        Contact(name: "Noah", username: "@noah_lawson", avatarName: "AvatarBenJohnson", isVerified: false),
        Contact(name: "Julie", username: "@julie_r", avatarName: "AvatarEileenFarrell", isVerified: false),
        Contact(name: "Michael", username: "@michael_z", avatarName: "AvatarJamesRhode", isVerified: false),
        Contact(name: "Kwame", username: "@kwame_d", avatarName: "AvatarJoaoCardoso", isVerified: false),
        Contact(name: "Lisa", username: "@lisa_mc", avatarName: "AvatarImanniQuansah", isVerified: false)
    ]
    
    // Sample contacts for full list
    let allContacts = [
        Contact(name: "Agustin Alvarez", username: "@agustine", avatarName: "AvatarAgustinAlvarez", isVerified: false),
        Contact(name: "Barry Donbeck", username: "@barry123", avatarName: "AvatarBarryDonbeck", isVerified: false),
        Contact(name: "Ben Johnson", username: "@ben_j", avatarName: "AvatarBenJohnson", isVerified: false),
        Contact(name: "Brendon Arnold", username: "@brendon_a", avatarName: "AvatarBrendonArnold", isVerified: false),
        Contact(name: "Carl Pattersmith", username: "@carl_p", avatarName: "AvatarCarlPattersmith", isVerified: false),
        Contact(name: "Eileen Farrell", username: "@eileen_f", avatarName: "AvatarEileenFarrell", isVerified: false),
        Contact(name: "Iben Hvid Møller", username: "@iben_hm", avatarName: "AvatarIbenHvidMoller", isVerified: false),
        Contact(name: "Imanmi Quansah", username: "@imanmi_q", avatarName: "AvatarImanniQuansah", isVerified: false),
        Contact(name: "James Rhode", username: "@james_r", avatarName: "AvatarJamesRhode", isVerified: false),
        Contact(name: "João Cardoso", username: "@joao_c", avatarName: "AvatarJoaoCardoso", isVerified: false),
        Contact(name: "Joseph Perez", username: "@joseph_p", avatarName: "AvatarJosephPerez", isVerified: false)
    ]
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return allContacts
        }
        return allContacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                // Title
                Text(mode.title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                // Close button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeService.textSecondaryColor)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Close")
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(themeService.textSecondaryColor)
                
                TextField("Search for a name or username", text: $searchText)
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "F7F7F7"))
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Recents - horizontal scroll
                    if searchText.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(recentContacts) { contact in
                                    RecentContactBubble(contact: contact) {
                                        selectContact(contact)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        
                        // Send via link row - only in send mode
                        if mode == .send {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            // TODO: Open send via link flow
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "link")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "080808"))
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Send to anyone using a link")
                                        .font(.custom("Inter-Bold", size: 16))
                                        .tracking(-0.32)
                                        .foregroundColor(Color(hex: "080808"))
                                    
                                    Text("Even if they don't use Sling")
                                        .font(.custom("Inter-Regular", size: 14))
                                        .tracking(-0.28)
                                        .foregroundColor(Color(hex: "7B7B7B"))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeService.textTertiaryColor)
                            }
                            .padding(16)
                            .background(Color(hex: "F7F7F7"))
                            .cornerRadius(16)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        }
                    }
                    
                    // All contacts list
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredContacts) { contact in
                            ContactRow(contact: contact) {
                                selectContact(contact)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .overlay {
            if showAmountInput, let contact = selectedContact {
                SendAmountView(
                    contact: contact,
                    mode: mode,
                    isPresented: $showAmountInput,
                    onDismissAll: {
                        isPresented = false
                    }
                )
                .transition(.fluidConfirm)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showAmountInput)
        .onAppear {
            // If a contact was preselected, automatically show the amount input
            if let preselected = preselectedContact {
                selectedContact = preselected
                showAmountInput = true
            }
        }
    }
    
    private func selectContact(_ contact: Contact) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        selectedContact = contact
        showAmountInput = true
    }
}

// MARK: - Send Amount View

struct SendAmountView: View {
    @ObservedObject private var themeService = ThemeService.shared
    let contact: Contact
    let mode: PaymentMode
    @Binding var isPresented: Bool
    let onDismissAll: () -> Void
    
    @State private var amountString: String = ""
    @State private var showConfirmation = false
    @State private var selectedPaymentAccount: PaymentAccount = .slingBalance
    @State private var showAccountPicker = false
    
    private let portfolioService = PortfolioService.shared
    private let displayCurrencyService = DisplayCurrencyService.shared
    
    /// Whether the user is paying from a linked bank account (not Sling Balance)
    private var payFromBank: Bool {
        selectedPaymentAccount.id != PaymentAccount.slingBalance.id
    }
    
    /// Bank name for the confirm screen
    private var linkedBankName: String {
        selectedPaymentAccount.name
    }
    
    /// Bank icon asset name
    private var linkedBankIcon: String {
        switch selectedPaymentAccount.iconType {
        case .asset(let name): return name
        }
    }
    
    /// Bank currency
    private var linkedBankCurrency: String {
        selectedPaymentAccount.currency
    }
    
    var currencySymbol: String {
        ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
    }
    
    var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    var isOverBalance: Bool {
        mode == .send && !payFromBank && amountValue > portfolioService.cashBalance
    }
    
    /// Whether the bank currency differs from display currency
    private var bankCurrencyDiffers: Bool {
        payFromBank && linkedBankCurrency != displayCurrencyService.displayCurrency && !linkedBankCurrency.isEmpty
    }
    
    /// Converted amount in the bank's currency
    private var bankCurrencyAmount: Double {
        guard bankCurrencyDiffers, amountValue > 0 else { return 0 }
        if let rate = ExchangeRateService.shared.getCachedRate(from: displayCurrencyService.displayCurrency, to: linkedBankCurrency) {
            return amountValue * rate
        }
        let fallback: [String: [String: Double]] = [
            "EUR": ["GBP": 0.86, "USD": 1.09, "MXN": 18.5, "BRL": 5.5],
            "GBP": ["EUR": 1.16, "USD": 1.27],
            "USD": ["GBP": 0.79, "EUR": 0.92]
        ]
        if let rate = fallback[displayCurrencyService.displayCurrency]?[linkedBankCurrency] {
            return amountValue * rate
        }
        return amountValue
    }
    
    /// Formatted bank currency amount
    private var formattedBankAmount: String {
        let symbol = ExchangeRateService.symbol(for: linkedBankCurrency)
        return bankCurrencyAmount.asCurrency(symbol)
    }
    
    var formattedAmount: String {
        if amountString.isEmpty {
            return "\(currencySymbol)0"
        }
        let number = Double(amountString) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = amountString.contains(".") ? 2 : 0
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: number)) ?? amountString
        return "\(currencySymbol)\(formattedNumber)"
    }
    
    var formattedBalance: String {
        // Show remaining balance after the amount being typed (for send mode)
        let balance = mode == .send ? max(0, portfolioService.cashBalance - amountValue) : portfolioService.cashBalance
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: balance)) ?? NumberFormatService.shared.formatNumber(balance)
        return "\(currencySymbol)\(formattedNumber)"
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with contact info
                HStack(spacing: 16) {
                    // Back button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image("ArrowLeft")
                            .renderingMode(.template)
                            .foregroundColor(themeService.textSecondaryColor)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Go back")
                    
                    // Contact avatar
                    Image(contact.avatarName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    
                    // Title
                    VStack(alignment: .leading, spacing: 0) {
                        Text(mode.headerPrefix)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text(contact.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                Spacer()
                
                // Amount display
                VStack(spacing: 4) {
                    AnimatedAmountText(amount: formattedAmount)
                    
                    if isOverBalance {
                        Text("Insufficient balance")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(Color(hex: "E30000"))
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else if bankCurrencyDiffers && amountValue > 0 {
                        Text(formattedBankAmount)
                            .font(.custom("Inter-Medium", size: 18))
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .transition(.opacity)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOverBalance)
                .animation(.easeInOut(duration: 0.2), value: bankCurrencyDiffers)
                
                Spacer()
                
                // Payment source (tappable to open account picker)
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showAccountPicker = true
                }) {
                    PaymentInstrumentRow(
                        iconName: payFromBank ? linkedBankIcon : "SlingBalanceLogo",
                        title: payFromBank ? linkedBankName : "Sling balance",
                        subtitleParts: payFromBank ? [selectedPaymentAccount.accountNumber] : [formattedBalance],
                        showMenu: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Number pad
                NumberPadView(amountString: $amountString)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Next button
                SecondaryButton(
                    title: "Next",
                    isEnabled: amountValue > 0 && !isOverBalance
                ) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showConfirmation = true
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
            // Account picker overlay
            if showAccountPicker {
                SendAccountPickerOverlay(
                    selectedAccount: $selectedPaymentAccount,
                    isPresented: $showAccountPicker
                )
                .transition(.opacity)
            }
            
            // Confirmation overlay
            if showConfirmation {
                if payFromBank && mode == .send {
                    SendConfirmFromBankView(
                        contact: contact,
                        amount: amountValue,
                        bankName: linkedBankName,
                        bankIcon: linkedBankIcon,
                        bankCurrency: linkedBankCurrency,
                        isPresented: $showConfirmation,
                        onComplete: {
                            onDismissAll()
                        }
                    )
                    .transition(.fluidConfirm)
                } else {
                    SendConfirmView(
                        contact: contact,
                        amount: amountValue,
                        mode: mode,
                        isPresented: $showConfirmation,
                        onComplete: {
                            onDismissAll()
                        }
                    )
                    .transition(.fluidConfirm)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showConfirmation)
        .animation(.easeInOut(duration: 0.25), value: showAccountPicker)
    }
}

// MARK: - Send Account Picker Overlay

struct SendAccountPickerOverlay: View {
    @Binding var selectedAccount: PaymentAccount
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    
    @State private var sheetOffset: CGFloat = 500
    @State private var backgroundOpacity: Double = 0
    
    // Payment sources: Sling Balance first, then linked bank accounts
    private var paymentSources: [PaymentAccount] {
        [.slingBalance] + PaymentAccount.allAccounts.filter { !$0.isAddNew && $0.name != "Apple pay" }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissDrawer() }
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color(hex: "D9D9D9"))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                Text("Pay from")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(themeService.textPrimaryColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                VStack(spacing: 0) {
                    ForEach(paymentSources) { account in
                        AccountRow(
                            account: account,
                            isSelected: account.id == selectedAccount.id,
                            onTap: {
                                dismissDrawer()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    selectedAccount = account
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 40))
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
            .offset(y: sheetOffset)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.25)) {
                sheetOffset = 0
                backgroundOpacity = 0.4
            }
        }
    }
    
    private func dismissDrawer() {
        withAnimation(.easeInOut(duration: 0.25)) {
            sheetOffset = 500
            backgroundOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

// MARK: - Recent Contact Bubble

struct RecentContactBubble: View {
    @ObservedObject private var themeService = ThemeService.shared
    let contact: Contact
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Avatar
                Image(contact.avatarName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1.4)
                    )
                
                Text(contact.name)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(RecentContactButtonStyle())
    }
}

struct RecentContactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? DesignSystem.Animation.pressedScale : 1.0)
            .animation(.easeInOut(duration: DesignSystem.Animation.pressDuration), value: configuration.isPressed)
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let contact: Contact
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Image(contact.avatarName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                
                // Name and username
                VStack(alignment: .leading, spacing: 0) {
                    Text(contact.name)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text(contact.username)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textTertiaryColor)
                }
                
                Spacer()
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(ContactRowButtonStyle())
        .padding(.horizontal, 8)
    }
}

struct ContactRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(configuration.isPressed ? Color(hex: "EDEDED") : Color.clear)
            )
    }
}

#Preview {
    SendView(isPresented: .constant(true), mode: .send)
}
