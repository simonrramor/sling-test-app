import SwiftUI

// MARK: - Account Model

struct PaymentAccount: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let accountNumber: String
    let currency: String
    let iconType: AccountIconType
    let isAddNew: Bool
    
    init(name: String, accountNumber: String = "", currency: String, iconType: AccountIconType, isAddNew: Bool = false) {
        self.name = name
        self.accountNumber = accountNumber
        self.currency = currency
        self.iconType = iconType
        self.isAddNew = isAddNew
    }
    
    var subtitle: String {
        if isAddNew {
            return "Bank · Card · Mobile wallet"
        }
        if accountNumber.isEmpty {
            return currency
        }
        return "\(currency) · \(accountNumber)"
    }
    
    enum AccountIconType: Equatable {
        case asset(String) // Use an image asset name
    }
    
    static let slingWallet = PaymentAccount(
        name: "Sling Wallet",
        currency: "GBP",
        iconType: .asset("AccountSlingWallet")
    )
    
    static let applePay = PaymentAccount(
        name: "Apple pay",
        currency: "GBP",
        iconType: .asset("AccountApplePay")
    )
    
    static let monzoBankLimited = PaymentAccount(
        name: "Monzo Bank Limited",
        accountNumber: "•••• 4567",
        currency: "GBP",
        iconType: .asset("AccountMonzoCard")
    )
    
    static let bankOfAmerica = PaymentAccount(
        name: "Bank of America",
        accountNumber: "•••• 5678",
        currency: "USD",
        iconType: .asset("AccountBankDefault")
    )
    
    static let monzo = PaymentAccount(
        name: "Monzo",
        accountNumber: "•••• 5678",
        currency: "GBP",
        iconType: .asset("AccountMonzo")
    )
    
    static let wise = PaymentAccount(
        name: "Wise",
        accountNumber: "NL91 •••• 00",
        currency: "EUR",
        iconType: .asset("AccountWise")
    )
    
    static let coinbaseWallet = PaymentAccount(
        name: "Simon's Coinbase wallet",
        accountNumber: "Ae2l •••• b3Yl",
        currency: "USDC",
        iconType: .asset("AccountCoinbase")
    )
    
    static let addNewAccount = PaymentAccount(
        name: "Add a new account",
        currency: "",
        iconType: .asset("AccountAddNew"),
        isAddNew: true
    )
    
    static let allAccounts: [PaymentAccount] = [
        .slingWallet,
        .applePay,
        .monzoBankLimited,
        .bankOfAmerica,
        .monzo,
        .wise,
        .coinbaseWallet,
        .addNewAccount
    ]
}

// MARK: - Account Selector View

struct AccountSelectorView: View {
    @Binding var selectedAccount: PaymentAccount
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    
    // Calculate content height based on number of accounts
    private var contentHeight: CGFloat {
        let handleHeight: CGFloat = 30 // 8 top + 6 height + 16 bottom
        let titleHeight: CGFloat = 52 // title + padding
        let rowHeight: CGFloat = 68 // each account row
        let dividerHeight: CGFloat = 17 // divider before "Add new"
        let bottomSafeArea: CGFloat = 34 // home indicator area
        
        let accountCount = CGFloat(PaymentAccount.allAccounts.count)
        return handleHeight + titleHeight + (accountCount * rowHeight) + dividerHeight + bottomSafeArea
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // Drawer content
            VStack(spacing: 0) {
                // Drawer handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 32, height: 6)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Title
                Text("Select account")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(themeService.textPrimaryColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .accessibilityAddTraits(.isHeader)
                
                // Account list
                VStack(spacing: 0) {
                    ForEach(PaymentAccount.allAccounts) { account in
                        // Add divider before "Add a new account"
                        if account.isAddNew {
                            Rectangle()
                                .fill(Color.black.opacity(0.06))
                                .frame(height: 1)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                        }
                        
                        AccountRow(
                            account: account,
                            isSelected: account.id == selectedAccount.id,
                            onTap: {
                                if !account.isAddNew {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedAccount = account
                                        isPresented = false
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.bottom, 34) // Safe area for home indicator
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.white)
                    .ignoresSafeArea(edges: .bottom)
            )
            .transition(.move(edge: .bottom))
        }
    }
}

// MARK: - Account Selector Overlay Modifier

extension View {
    func accountSelectorOverlay(
        isPresented: Binding<Bool>,
        selectedAccount: Binding<PaymentAccount>
    ) -> some View {
        self.overlay {
            if isPresented.wrappedValue {
                AccountSelectorView(
                    selectedAccount: selectedAccount,
                    isPresented: isPresented
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented.wrappedValue)
    }
}

// MARK: - Account Row

struct AccountRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let account: PaymentAccount
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                accountIcon
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text(account.subtitle)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                Spacer()
                
                // Radio button (orange checkmark when selected)
                if !account.isAddNew {
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color(hex: "FF5113") : Color(hex: "CCCCCC"), lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                        
                        if isSelected {
                            Circle()
                                .fill(Color(hex: "FF5113"))
                                .frame(width: 22, height: 22)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(AccountRowButtonStyle())
    }
    
    @ViewBuilder
    private var accountIcon: some View {
        switch account.iconType {
        case .asset(let assetName):
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Button Style

struct AccountRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isPressed ? Color(hex: "F7F7F7") : Color.clear)
            )
    }
}

#Preview {
    AccountSelectorView(
        selectedAccount: .constant(.monzoBankLimited),
        isPresented: .constant(true)
    )
}
