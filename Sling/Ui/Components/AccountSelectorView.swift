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
    
    static let slingBalance = PaymentAccount(
        name: "Sling Balance",
        currency: "USD",
        iconType: .asset("AccountSlingWallet")
    )
    
    static let applePay = PaymentAccount(
        name: "Apple pay",
        currency: "GBP",
        iconType: .asset("AccountApplePay")
    )
    
    static let ukBank = PaymentAccount(
        name: "UK debit card",
        accountNumber: "•••• 4567",
        currency: "GBP",
        iconType: .asset("AccountMonzoCard")
    )
    
    static let usBank = PaymentAccount(
        name: "US Bank",
        accountNumber: "•••• 5678",
        currency: "USD",
        iconType: .asset("AccountBankDefault")
    )
    
    static let euBank = PaymentAccount(
        name: "EU Bank",
        accountNumber: "NL91 •••• 00",
        currency: "EUR",
        iconType: .asset("AccountWise")
    )
    
    static let cryptoWallet = PaymentAccount(
        name: "Crypto wallet",
        accountNumber: "Ae2l •••• b3Yl",
        currency: "USDC",
        iconType: .asset("AccountCoinbase")
    )
    
    static let mexicanBank = PaymentAccount(
        name: "Mexican Bank",
        accountNumber: "•••• 7832",
        currency: "MXN",
        iconType: .asset("AccountBBVA")
    )
    
    static let brazilianBank = PaymentAccount(
        name: "Brazilian Bank",
        accountNumber: "•••• 4521",
        currency: "BRL",
        iconType: .asset("AccountNubank")
    )
    
    static let kenyanMobileMoney = PaymentAccount(
        name: "Kenyan Mobile Money",
        accountNumber: "+254 •••• 89",
        currency: "KES",
        iconType: .asset("AccountMPesa")
    )
    
    static let addNewAccount = PaymentAccount(
        name: "Add a new account",
        currency: "",
        iconType: .asset("AccountAddNew"),
        isAddNew: true
    )
    
    static let allAccounts: [PaymentAccount] = [
        .applePay,
        .ukBank,
        .usBank,
        .euBank,
        .mexicanBank,
        .brazilianBank,
        .kenyanMobileMoney,
        .cryptoWallet,
        .addNewAccount
    ]
}

// MARK: - Account Selector View

struct AccountSelectorView: View {
    @Binding var selectedAccount: PaymentAccount
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    
    @State private var sheetOffset: CGFloat = 500
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background - fades in/out
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissDrawer()
                }
            
            // Drawer content with device-matching corner radius
            VStack(spacing: 0) {
                // Drawer handle
                DrawerHandle()
                
                // Title
                Text("Select account")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(themeService.textPrimaryColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
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
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        
                        AccountRow(
                            account: account,
                            isSelected: account.id == selectedAccount.id,
                            onTap: {
                                if !account.isAddNew {
                                    dismissDrawer()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        selectedAccount = account
                                    }
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
            .padding(.top, 8)
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
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPresented.wrappedValue)
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
        selectedAccount: .constant(.ukBank),
        isPresented: .constant(true)
    )
}
