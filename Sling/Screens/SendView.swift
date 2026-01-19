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
                    .foregroundColor(Color(hex: "080808"))
                
                // Close button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Close")
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 56)
            
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "7B7B7B"))
                
                TextField("Search for a name or username", text: $searchText)
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "7B7B7B"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "F7F7F7"))
            )
            .padding(.horizontal, 24)
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
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 16)
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
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showAmountInput)
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
    let contact: Contact
    let mode: PaymentMode
    @Binding var isPresented: Bool
    let onDismissAll: () -> Void
    
    @State private var amountString: String = ""
    @State private var showConfirmation = false
    
    var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    var isOverBalance: Bool {
        mode == .send && amountValue > PortfolioService.shared.cashBalance
    }
    
    var formattedAmount: String {
        if amountString.isEmpty {
            return "£0"
        }
        let number = Double(amountString) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = amountString.contains(".") ? 2 : 0
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: number)) ?? amountString
        return "£\(formattedNumber)"
    }
    
    var formattedBalance: String {
        let balance = PortfolioService.shared.cashBalance
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: balance)) ?? String(format: "%.2f", balance)
        return "£\(formattedNumber)"
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
                            .foregroundColor(Color(hex: "7B7B7B"))
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
                            .foregroundColor(Color(hex: "7B7B7B"))
                        Text(contact.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                
                Spacer()
                
                // Amount display
                VStack(spacing: 4) {
                    Text(formattedAmount)
                        .font(.custom("Inter-Bold", size: 56))
                        .foregroundColor(Color(hex: "080808"))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    if isOverBalance {
                        Text("Insufficient balance")
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(Color(hex: "E30000"))
                    }
                }
                
                Spacer()
                
                // Payment source (Sling balance)
                PaymentInstrumentRow(
                    iconName: "SlingBalanceLogo",
                    title: "Sling balance",
                    subtitleParts: [formattedBalance],
                    showMenu: false
                )
                .padding(.horizontal, 24)
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
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            // Confirmation overlay
            if showConfirmation {
                SendConfirmView(
                    contact: contact,
                    amount: amountValue,
                    mode: mode,
                    isPresented: $showConfirmation,
                    onComplete: {
                        onDismissAll()
                    }
                )
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showConfirmation)
    }
}

// MARK: - Send Confirm View

struct SendConfirmView: View {
    let contact: Contact
    let amount: Double
    let mode: PaymentMode
    @Binding var isPresented: Bool
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    
    private let portfolioService = PortfolioService.shared
    private let activityService = ActivityService.shared
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "£\(formattedNumber)"
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
                            .foregroundColor(Color(hex: "7B7B7B"))
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
                            .foregroundColor(Color(hex: "7B7B7B"))
                        Text(contact.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Amount display
                Text(formattedAmount)
                    .font(.custom("Inter-Bold", size: 56))
                    .foregroundColor(Color(hex: "080808"))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .opacity(isButtonLoading ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
                
                // Details section
                VStack(spacing: 0) {
                    // From/To row (depends on mode)
                    HStack {
                        Text(mode == .send ? "From" : "To")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image("SlingBalanceLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 18, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            
                            Text("Sling balance")
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(Color(hex: "080808"))
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    
                    // Divider
                    Rectangle()
                        .fill(Color(hex: "EDEDED"))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    // Amount row
                    HStack {
                        Text(mode == .send ? "Total" : "Amount requested")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Spacer()
                        
                        Text(formattedAmount)
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    
                    // Fees row
                    HStack {
                        Text("Fees")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Spacer()
                        
                        Text("No fee")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color(hex: "FF5113"))
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    
                    // Result row
                    HStack {
                        Text(mode == .send ? "Recipient receives" : "You receive")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: "080808").opacity(0.1))
                                .frame(width: 4, height: 4)
                            
                            Text(formattedAmount)
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(Color(hex: "080808"))
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Action button with animation
                AnimatedLoadingButton(
                    title: "\(mode.buttonPrefix) \(formattedAmount)",
                    isLoadingBinding: $isButtonLoading
                ) {
                    if mode == .send {
                        // Deduct from balance
                        portfolioService.deductCash(amount)
                        
                        // Record the transaction
                        activityService.recordSendMoney(
                            toContactName: contact.name,
                            toContactAvatar: contact.avatarName,
                            amount: amount
                        )
                    } else {
                        // Record the request
                        activityService.recordRequestMoney(
                            fromContactName: contact.name,
                            fromContactAvatar: contact.avatarName,
                            amount: amount
                        )
                    }
                    
                    // Navigate to home tab
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    
                    onComplete()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            // Centered amount overlay (appears when loading)
            if isButtonLoading {
                Text(formattedAmount)
                    .font(.custom("Inter-Bold", size: 56))
                    .foregroundColor(Color(hex: "080808"))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
    }
}

// MARK: - Recent Contact Bubble

struct RecentContactBubble: View {
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
                    .foregroundColor(Color(hex: "080808"))
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
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Contact Row

struct ContactRow: View {
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
                        .foregroundColor(Color(hex: "080808"))
                    
                    Text(contact.username)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color(hex: "999999"))
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isPressed ? Color(hex: "EDEDED") : Color.clear)
            )
    }
}

#Preview {
    SendView(isPresented: .constant(true), mode: .send)
}
