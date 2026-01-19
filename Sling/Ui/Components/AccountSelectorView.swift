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
    
    var body: some View {
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
                .foregroundColor(Color(hex: "080808"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .accessibilityAddTraits(.isHeader)
            
            // Account list (scrollable)
            ScrollView {
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
                                    selectedAccount = account
                                    isPresented = false
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .background(Color.white)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Account Row

struct AccountRow: View {
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
                        .foregroundColor(Color(hex: "080808"))
                    
                    Text(account.subtitle)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color(hex: "7B7B7B"))
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
