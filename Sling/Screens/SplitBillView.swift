import SwiftUI
import UIKit

struct SplitBillView: View {
    @Binding var isPresented: Bool
    @StateObject private var activityService = ActivityService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @State private var selectedPayment: ActivityItem? = nil
    @State private var showUserSelection = false
    @State private var showReceiptScanner = false
    
    // Filter to only show card payments (negative amounts that aren't P2P transfers)
    var cardPayments: [ActivityItem] {
        activityService.activities.filter { activity in
            // Card payments have negative amounts (start with "-")
            let isNegative = activity.titleRight.hasPrefix("-")
            
            // Exclude P2P transfers (those with person avatars/initials)
            // Card payments typically have business names/logos
            let isProbablyBusiness = !isPersonAvatar(activity.avatar)
            
            return isNegative && isProbablyBusiness
        }
    }
    
    // Check if avatar looks like a person (initials or person image asset)
    private func isPersonAvatar(_ avatar: String) -> Bool {
        // If it's 1-2 characters, it's initials (could be person or business)
        if avatar.count <= 2 {
            return true
        }
        
        // If it starts with "Avatar", it's a person
        if avatar.hasPrefix("Avatar") {
            return true
        }
        
        return false
    }
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "F5F5F5"))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close")
                    
                    Spacer()
                    
                    Text("Split a bill")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                
                // Scan Receipt Card
                ScanReceiptCard(onTap: {
                    showReceiptScanner = true
                })
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Section header
                HStack {
                    Text("Or select a payment")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
                // Payment list
                if cardPayments.isEmpty {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 48))
                            .foregroundColor(themeService.textTertiaryColor)
                        
                        Text("No card payments yet")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Text("Your card purchases will appear here")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(Color(hex: "AAAAAA"))
                    }
                    
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(cardPayments) { payment in
                                PaymentRow(payment: payment) {
                                    selectedPayment = payment
                                    showUserSelection = true
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .background(Color.white)
            
            // User selection overlay
            if showUserSelection, let payment = selectedPayment {
                SplitUserSelectionView(
                    isPresented: $showUserSelection,
                    payment: payment,
                    onDismissAll: { isPresented = false }
                )
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showUserSelection)
        .fullScreenCover(isPresented: $showReceiptScanner) {
            ReceiptScannerView(isPresented: $showReceiptScanner)
        }
    }
}

// MARK: - Scan Receipt Card

struct ScanReceiptCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Camera icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "FF5113").opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "FF5113"))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan a receipt")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text("Take a photo and assign items to people")
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeService.textTertiaryColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "FFF8F5"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "FF5113").opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Payment Row

struct PaymentRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let payment: ActivityItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Avatar
                TransactionAvatarView(identifier: payment.avatar)
                
                // Payment name
                Text(payment.titleLeft)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                    .lineLimit(1)
                
                Spacer()
                
                // Amount
                Text(payment.titleRight)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PaymentRowButtonStyle())
        .padding(.horizontal, 8)
    }
}

struct PaymentRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isPressed ? Color(hex: "F7F7F7") : Color.clear)
            )
    }
}

// MARK: - User Selection View

struct SplitUserSelectionView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Binding var isPresented: Bool
    let payment: ActivityItem
    let onDismissAll: () -> Void
    
    @State private var searchText = ""
    @State private var selectedUsers: Set<UUID> = []
    @State private var showSplitAmount = false
    
    // Sample contacts - reusing the same contacts from SendView
    let contacts: [Contact] = [
        Contact(name: "Agustin Alvarez", username: "@Agustine", avatarName: "AvatarAgustinAlvarez"),
        Contact(name: "Barry Donbeck", username: "@barry123", avatarName: "AvatarBarryDonbeck"),
        Contact(name: "Ben Johnson", username: "@benj", avatarName: "AvatarBenJohnson"),
        Contact(name: "Brendon Arnold", username: "@brendon", avatarName: "AvatarBrendonArnold"),
        Contact(name: "Carl Pattersmith", username: "@carlp", avatarName: "AvatarCarlPattersmith"),
        Contact(name: "Eileen Farrell", username: "@eileenf", avatarName: "AvatarEileenFarrell"),
        Contact(name: "Iben Hvid Moller", username: "@ibenm", avatarName: "AvatarIbenHvidMoller"),
        Contact(name: "Imanni Quansah", username: "@imanni", avatarName: "AvatarImanniQuansah"),
        Contact(name: "James Rhode", username: "@jamesrh", avatarName: "AvatarJamesRhode"),
        Contact(name: "Joao Cardoso", username: "@joaoc", avatarName: "AvatarJoaoCardoso"),
        Contact(name: "Joseph Perez", username: "@josephp", avatarName: "AvatarJosephPerez")
    ]
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var hasSelection: Bool {
        !selectedUsers.isEmpty
    }
    
    var selectedContacts: [Contact] {
        contacts.filter { selectedUsers.contains($0.id) }
    }
    
    var body: some View {
        ZStack {
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
                
                Text("Split a bill")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                // Invisible spacer for centering
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 24)
            .frame(height: 64)
            
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(themeService.textSecondaryColor)
                
                TextField("Search your contacts on Sling", text: $searchText)
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // User list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredContacts) { contact in
                        SelectableUserRow(
                            contact: contact,
                            isSelected: selectedUsers.contains(contact.id),
                            onTap: {
                                if selectedUsers.contains(contact.id) {
                                    selectedUsers.remove(contact.id)
                                } else {
                                    selectedUsers.insert(contact.id)
                                }
                            }
                        )
                    }
                }
            }
            .scrollIndicators(.hidden)
            
            Spacer()
            
            // Bottom button with gradient background
            VStack(spacing: 0) {
                // Gradient fade
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
                
                // Button container
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showSplitAmount = true
                }) {
                    Text("Next")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(hasSelection ? .white : Color.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(hasSelection ? Color(hex: "080808") : Color(hex: "C8C8C8"))
                        )
                }
                .buttonStyle(PressedButtonStyle())
                .disabled(!hasSelection)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .background(Color.white)
            }
        }
        .background(Color.white)
            
            // Split amount overlay
            if showSplitAmount {
                SplitAmountView(
                    isPresented: $showSplitAmount,
                    payment: payment,
                    selectedContacts: selectedContacts,
                    onDismissAll: onDismissAll
                )
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplitAmount)
    }
}

// MARK: - Selectable User Row

struct SelectableUserRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let contact: Contact
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Avatar
                Image(contact.avatarName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text(contact.username)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                Spacer()
                
                // Checkbox
                ZStack {
                    if isSelected {
                        // Filled orange circle with checkmark
                        Circle()
                            .fill(Color(hex: "FF5113"))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        // Empty circle with border
                        Circle()
                            .stroke(Color(hex: "CCCCCC"), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(SelectableRowButtonStyle())
        .padding(.horizontal, 8)
    }
}

struct SelectableRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isPressed ? Color(hex: "F7F7F7") : Color.clear)
            )
    }
}

// MARK: - Split Amount View

struct SplitAmountView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Binding var isPresented: Bool
    let payment: ActivityItem
    let selectedContacts: [Contact]
    let onDismissAll: () -> Void
    
    @State private var isButtonLoading = false
    private let activityService = ActivityService.shared
    
    // Parse the amount from the payment's titleRight (e.g., "-£45.80" -> 45.80)
    var totalAmount: Double {
        let amountString = payment.titleRight
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(amountString) ?? 0
    }
    
    // Split equally between selected contacts + yourself
    var splitAmount: Double {
        let numberOfPeople = selectedContacts.count + 1 // +1 for "You"
        return totalAmount / Double(numberOfPeople)
    }
    
    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        let formatted = formatter.string(from: NSNumber(value: totalAmount)) ?? String(format: "%.2f", totalAmount)
        return "£\(formatted)"
    }
    
    var formattedSplit: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        let formatted = formatter.string(from: NSNumber(value: splitAmount)) ?? String(format: "%.2f", splitAmount)
        return "£\(formatted)"
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
                    
                    Text("Split a bill")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear
                        .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 24)
                .frame(height: 64)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Transaction being split
                HStack(spacing: 12) {
                    // Payment logo
                    TransactionAvatarView(identifier: payment.avatar)
                    
                    // Transaction details
                    VStack(alignment: .leading, spacing: 2) {
                        Text(payment.titleLeft)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        if payment.date != nil {
                            Text(payment.formattedDate)
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Total amount
                    Text(formattedTotal)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Divider
                Rectangle()
                    .fill(Color(hex: "EEEEEE"))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(isButtonLoading ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                // Friends section
                VStack(spacing: 0) {
                    // "You" row
                    SplitUserRow(
                        name: "You",
                        avatarName: "AvatarProfile",
                        amount: formattedSplit
                    )
                    
                    // Selected contacts
                    ForEach(selectedContacts) { contact in
                        SplitUserRow(
                            name: contact.name,
                            avatarName: contact.avatarName,
                            amount: formattedSplit
                        )
                    }
                }
                .padding(.horizontal, 24)
                .opacity(isButtonLoading ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: isButtonLoading)
                
                Spacer()
            
            // Bottom button with gradient
            VStack(spacing: 0) {
                // Gradient fade
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
                
                // Animated button
                AnimatedLoadingButton(
                    title: "Split bill",
                    isLoadingBinding: $isButtonLoading
                ) {
                    // Record split for each selected contact
                    for contact in selectedContacts {
                        activityService.recordSplitBill(
                            merchantName: payment.titleLeft,
                            merchantAvatar: payment.avatar,
                            splitAmount: splitAmount,
                            withContactName: contact.name
                        )
                    }
                    
                    // Navigate to home tab
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    
                    onDismissAll()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .background(Color.white)
            }
            }
            
            // Centered amount overlay (appears when loading)
            if isButtonLoading {
                Text(formattedSplit)
                    .font(.custom("Inter-Bold", size: 56))
                    .foregroundColor(themeService.textPrimaryColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isButtonLoading)
    }
}

// MARK: - Split User Row

struct SplitUserRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let name: String
    let avatarName: String
    let amount: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Image(avatarName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            
            // Name
            Text(name)
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(themeService.textPrimaryColor)
            
            Spacer()
            
            // Amount pill with grey background
            Text(amount)
                .font(.custom("Inter-Bold", size: 14))
                .foregroundColor(themeService.textPrimaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 17)
                        .fill(Color(hex: "F7F7F7"))
                )
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    SplitBillView(isPresented: .constant(true))
}
