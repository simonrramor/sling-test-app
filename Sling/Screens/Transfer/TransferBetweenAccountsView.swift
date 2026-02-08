import SwiftUI
import UIKit

// MARK: - Transfer Step

private enum TransferStep {
    case selectTo
    case selectFrom
    case amount
}

// MARK: - Transfer Between Accounts View

struct TransferBetweenAccountsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    
    @State private var step: TransferStep = .selectFrom
    @State private var toAccount: PaymentAccount?
    @State private var fromAccount: PaymentAccount?
    @State private var amountString = ""
    @State private var showConfirm = false
    
    // Currency conversion state (matching AddMoney/Withdraw pattern)
    @State private var showingSourceCurrency = true // true = source (from) currency is primary
    @State private var sourceAmount: Double = 0     // Amount in source (from) currency
    @State private var destinationAmount: Double = 0 // Amount in destination (to) currency
    @State private var exchangeRate: Double = 1.0
    
    private let exchangeService = ExchangeRateService.shared
    
    // Accounts for "Transfer to" (exclude Sling Balance and Apple Pay)
    private var toAccounts: [PaymentAccount] {
        PaymentAccount.allAccounts.filter { $0.name != "Apple pay" }
    }
    
    // Accounts for "Transfer from" (Sling Balance first, then the rest)
    private var fromAccounts: [PaymentAccount] {
        [PaymentAccount.slingBalance] + PaymentAccount.allAccounts
    }
    
    var amountValue: Double {
        Double(amountString) ?? 0
    }
    
    // MARK: - Currency helpers
    
    private var fromCurrency: String {
        fromAccount?.currency.isEmpty == false ? fromAccount!.currency : "USD"
    }
    
    private var toCurrency: String {
        toAccount?.currency.isEmpty == false ? toAccount!.currency : "USD"
    }
    
    private var fromSymbol: String {
        ExchangeRateService.symbol(for: fromCurrency)
    }
    
    private var toSymbol: String {
        ExchangeRateService.symbol(for: toCurrency)
    }
    
    private var needsCurrencyConversion: Bool {
        fromCurrency != toCurrency
    }
    
    // MARK: - Fee helpers for input screen
    
    private var hasTransferInputFee: Bool {
        !FeeService.shared.calculateFee(for: .withdrawal, paymentInstrumentCurrency: fromCurrency).isFree
    }
    
    private var transferInputFeeInSource: Double {
        if !hasTransferInputFee { return 0 }
        let feeUSD = 0.50
        if fromCurrency == "USD" { return feeUSD }
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: fromCurrency) {
            return feeUSD * rate
        }
        let fallback: [String: Double] = ["EUR": 0.92, "GBP": 0.79]
        return feeUSD * (fallback[fromCurrency] ?? 1.0)
    }
    
    // MARK: - Formatted amounts
    
    private var formattedSourceAmount: String {
        let symbol = fromSymbol
        let value = showingSourceCurrency ? amountValue : sourceAmount
        if amountString.isEmpty || value == 0 {
            return "\(symbol)0"
        }
        // Always show with fee when applicable (source pays the fee)
        return value.asCurrency(symbol)
    }
    
    /// Fee converted to destination currency
    private var transferInputFeeInDest: Double {
        if !hasTransferInputFee { return 0 }
        let feeUSD = 0.50
        if toCurrency == "USD" { return feeUSD }
        if let rate = ExchangeRateService.shared.getCachedRate(from: "USD", to: toCurrency) {
            return feeUSD * rate
        }
        let fallback: [String: Double] = ["EUR": 0.92, "GBP": 0.79, "MXN": 17.15, "BRL": 5.12]
        return feeUSD * (fallback[toCurrency] ?? 1.0)
    }
    
    private var formattedDestinationAmount: String {
        let symbol = toSymbol
        let value = showingSourceCurrency ? destinationAmount : amountValue
        if amountString.isEmpty || value == 0 {
            return "\(symbol)0"
        }
        return value.asCurrency(symbol)
    }
    
    /// Simple formatted amount when no conversion needed
    private var formattedSimpleAmount: String {
        let symbol = fromSymbol
        if amountString.isEmpty {
            return "\(symbol)0"
        }
        let value = amountValue
        if value == 0 { return "\(symbol)0" }
        return value.asCurrency(symbol)
    }
    
    private var toIconName: String {
        switch toAccount?.iconType {
        case .asset(let name): return name
        case .none: return "AccountBankDefault"
        }
    }
    
    private var fromIconName: String {
        switch fromAccount?.iconType {
        case .asset(let name): return name
        case .none: return "AccountBankDefault"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            switch step {
            case .selectFrom:
                TransferAccountPickerView(
                    title: "Transfer from",
                    accounts: fromAccounts,
                    onBack: { isPresented = false },
                    onSelect: { account in
                        fromAccount = account
                        withAnimation(.easeInOut(duration: 0.25)) {
                            step = .selectTo
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .selectTo:
                TransferAccountPickerView(
                    title: "Transfer to",
                    accounts: toAccounts,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            step = .selectFrom
                        }
                    },
                    onSelect: { account in
                        toAccount = account
                        withAnimation(.easeInOut(duration: 0.25)) {
                            step = .amount
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .amount:
                transferAmountView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step == .selectTo)
        .animation(.easeInOut(duration: 0.25), value: step == .selectFrom)
        .animation(.easeInOut(duration: 0.25), value: step == .amount)
        .fullScreenCover(isPresented: $showConfirm) {
            TransferConfirmView(
                sourceAmount: showingSourceCurrency ? amountValue : sourceAmount,
                destinationAmount: showingSourceCurrency ? destinationAmount : amountValue,
                sourceCurrency: fromCurrency,
                destinationCurrency: toCurrency,
                sourceAccount: fromAccount ?? .slingBalance,
                destinationAccount: toAccount ?? .usBank,
                exchangeRate: exchangeRate,
                isPresented: $showConfirm,
                onComplete: {
                    isPresented = false
                }
            )
        }
        .onChange(of: amountString) { _, _ in
            updateAmounts()
        }
        .onAppear {
            updateAmounts()
        }
    }
    
    // MARK: - Amount Input Step
    
    private var transferAmountView: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - standard pattern: back arrow, destination icon, "Send to" / name, currency tag
                HStack(spacing: 16) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            step = .selectTo
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeService.textSecondaryColor)
                            .frame(width: 24, height: 24)
                    }
                    
                    Image(toIconName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Send to")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Text(toAccount?.name ?? "")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                    
                    Spacer()
                    
                    // Currency tag
                    Text(toCurrency)
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "F7F7F7"))
                        )
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                Spacer()
                
                // Amount display with currency swap
                if needsCurrencyConversion {
                    AnimatedCurrencySwapView(
                        primaryDisplay: formattedSourceAmount,
                        secondaryDisplay: formattedDestinationAmount,
                        showingPrimaryOnTop: showingSourceCurrency,
                        onSwap: {
                            // Convert current amount before swapping
                            if showingSourceCurrency {
                                amountString = destinationAmount > 0 ? formatForInput(destinationAmount) : ""
                            } else {
                                amountString = sourceAmount > 0 ? formatForInput(sourceAmount) : ""
                            }
                            showingSourceCurrency.toggle()
                        }
                    )
                } else {
                    Text(formattedSimpleAmount)
                        .font(.custom("Inter-Bold", size: 56))
                        .foregroundColor(themeService.textPrimaryColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Source account - standard TappablePaymentInstrumentRow
                TappablePaymentInstrumentRow(
                    iconName: fromIconName,
                    title: fromAccount?.name ?? "",
                    subtitleParts: (fromAccount?.accountNumber.isEmpty ?? true) ? [] : [fromAccount!.accountNumber],
                    trailingText: fromAccount?.currency,
                    onTap: {
                        // Could open account switcher in future
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Number pad - standard shared component
                NumberPadView(amountString: $amountString)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Next button - standard SecondaryButton
                SecondaryButton(
                    title: "Next",
                    isEnabled: amountValue > 0
                ) {
                    showConfirm = true
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Currency Conversion
    
    private func formatForInput(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    private func updateAmounts() {
        guard needsCurrencyConversion else {
            sourceAmount = amountValue
            destinationAmount = amountValue
            exchangeRate = 1.0
            return
        }
        
        let inputAmount = amountValue
        
        if showingSourceCurrency {
            // User is entering source (from) currency, convert to destination (to) currency
            sourceAmount = inputAmount
            Task {
                if let rate = await exchangeService.getRate(from: fromCurrency, to: toCurrency) {
                    await MainActor.run {
                        exchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: fromCurrency,
                    to: toCurrency
                ) {
                    await MainActor.run {
                        destinationAmount = converted
                    }
                }
            }
        } else {
            // User is entering destination (to) currency, convert to source (from) currency
            destinationAmount = inputAmount
            Task {
                if let rate = await exchangeService.getRate(from: fromCurrency, to: toCurrency) {
                    await MainActor.run {
                        exchangeRate = rate
                    }
                }
                if let converted = await exchangeService.convert(
                    amount: inputAmount,
                    from: toCurrency,
                    to: fromCurrency
                ) {
                    await MainActor.run {
                        sourceAmount = converted
                    }
                }
            }
        }
    }
}

// MARK: - Transfer Confirm View

struct TransferConfirmView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var feeService = FeeService.shared
    
    let sourceAmount: Double
    let destinationAmount: Double
    let sourceCurrency: String
    let destinationCurrency: String
    let sourceAccount: PaymentAccount
    let destinationAccount: PaymentAccount
    let exchangeRate: Double
    @Binding var isPresented: Bool
    var onComplete: () -> Void = {}
    
    @State private var isButtonLoading = false
    @State private var showFeesSheet = false
    
    private let portfolioService = PortfolioService.shared
    private let activityService = ActivityService.shared
    
    private var sourceSymbol: String {
        ExchangeRateService.symbol(for: sourceCurrency)
    }
    
    private var destinationSymbol: String {
        ExchangeRateService.symbol(for: destinationCurrency)
    }
    
    /// Calculate fee for this transfer (uses withdrawal fee logic)
    private var transferFee: FeeResult {
        feeService.calculateFee(
            for: .withdrawal,
            paymentInstrumentCurrency: sourceCurrency
        )
    }
    
    /// Formatted amounts
    private var formattedSourceAmount: String {
        sourceAmount.asCurrency(sourceSymbol)
    }
    
    private var formattedDestinationAmount: String {
        destinationAmount.asCurrency(destinationSymbol)
    }
    
    private var formattedExchangeRate: String {
        if sourceCurrency == destinationCurrency { return "" }
        let rate = exchangeRate
        return "1 \(sourceCurrency) = \(String(format: "%.4f", rate)) \(destinationCurrency)"
    }
    
    private var destinationIconName: String {
        switch destinationAccount.iconType {
        case .asset(let name): return name
        }
    }
    
    private var sourceIconName: String {
        switch sourceAccount.iconType {
        case .asset(let name): return name
        }
    }
    
    /// Attributed title with green amount
    private var transferTitle: AttributedString {
        var result = AttributedString("Move ")
        result.foregroundColor = UIColor(Color(hex: "080808"))
        var amount = AttributedString(shortDestAmount)
        amount.foregroundColor = UIColor(Color(hex: "57CE43"))
        var suffix = AttributedString(" from \(sourceAccount.name) to \(destinationAccount.name)")
        suffix.foregroundColor = UIColor(Color(hex: "080808"))
        return result + amount + suffix
    }
    
    /// Short formatted amount for title
    private var shortDestAmount: String {
        if destinationAmount.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(destinationSymbol)\(Int(destinationAmount))"
        }
        return formattedDestinationAmount
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - back arrow only
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeService.textSecondaryColor)
                            .frame(width: 24, height: 24)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 48)
                .opacity(isButtonLoading ? 0 : 1)
                
                Spacer()
                
                // Main content - icon and title
                VStack(alignment: .leading, spacing: 24) {
                    // Destination account icon
                    AccountIconView(iconType: destinationAccount.iconType)
                    
                    // Title: "Move €100 from Wise to Monzo bank Limited"
                    Text(transferTitle)
                        .font(.custom("Inter-Bold", size: 32))
                        .tracking(-0.64)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.bottom, isButtonLoading ? 0 : 16)
                
                Spacer()
                    .frame(maxHeight: isButtonLoading ? .infinity : 0)
                
                // Details section - fades out when loading
                if !isButtonLoading {
                    VStack(spacing: 4) {
                        // Transfer speed
                        InfoListItem(label: "Transfer speed", detail: "Instant")
                        
                        // Divider
                        Rectangle()
                            .fill(Color.black.opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        // Total withdrawn
                        InfoListItem(label: "Total withdrawn", detail: formattedSourceAmount)
                        
                        // Fees
                        FeeRow(fee: transferFee, paymentInstrumentCurrency: sourceCurrency, onTap: { showFeesSheet = true })
                        
                        // Amount exchanged
                        if !transferFee.isFree {
                            InfoListItem(label: "Amount exchanged", detail: formattedSourceAmount)
                        }
                        
                        // Exchange rate (source currency on left - money flows from source to destination)
                        if sourceCurrency != destinationCurrency {
                            HStack {
                                Text("Exchange rate")
                                    .font(.custom("Inter-Regular", size: 16))
                                    .foregroundColor(themeService.textSecondaryColor)
                                
                                Spacer()
                                
                                Text("\(sourceSymbol)1 = \(destinationSymbol)\(String(format: "%.2f", exchangeRate))")
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(Color(hex: "FF5113"))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 16)
                        }
                        
                        // Recipient gets
                        InfoListItem(label: "Recipient gets", detail: formattedDestinationAmount)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }
                
                Spacer()
                    .frame(height: 16)
                
                // Orange CTA button
                LoadingButton(
                    title: "Move \(shortDestAmount)",
                    isLoadingBinding: $isButtonLoading,
                    showLoader: true
                ) {
                    activityService.addActivity(
                        avatar: destinationIconName,
                        titleLeft: destinationAccount.name,
                        subtitleLeft: "Transfer",
                        titleRight: "-\(formattedSourceAmount)",
                        subtitleRight: sourceCurrency != destinationCurrency ? formattedDestinationAmount : ""
                    )
                    activityService.addActivity(
                        avatar: sourceIconName,
                        titleLeft: sourceAccount.name,
                        subtitleLeft: "Transfer",
                        titleRight: "+\(formattedDestinationAmount)",
                        subtitleRight: sourceCurrency != destinationCurrency ? formattedSourceAmount : ""
                    )
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    onComplete()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isButtonLoading)
        .fullScreenCover(isPresented: $showFeesSheet) {
            FeesSettingsView(isPresented: $showFeesSheet)
        }
    }
}

// MARK: - Transfer Account Picker View

private struct TransferAccountPickerView: View {
    let title: String
    let accounts: [PaymentAccount]
    let onBack: () -> Void
    let onSelect: (PaymentAccount) -> Void
    
    @State private var searchText = ""
    @ObservedObject private var themeService = ThemeService.shared
    
    private var filteredAccounts: [PaymentAccount] {
        if searchText.isEmpty {
            return accounts
        }
        return accounts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.currency.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back arrow and title
            HStack {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                Spacer()
                
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 4)
            
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "7B7B7B"))
                
                TextField("Search your accounts", text: $searchText)
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color(hex: "F7F7F7"))
            .cornerRadius(24)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Account list
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(filteredAccounts) { account in
                        if account.isAddNew {
                            // Divider before "Add a new account"
                            Rectangle()
                                .fill(Color.black.opacity(0.06))
                                .frame(height: 1)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                        }
                        
                        TransferAccountRow(account: account) {
                            if !account.isAddNew {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                onSelect(account)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
        }
        .background(Color.white)
    }
}

// MARK: - Transfer Account Row

private struct TransferAccountRow: View {
    let account: PaymentAccount
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                AccountIconView(iconType: account.iconType)
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                    
                    if !account.subtitle.isEmpty {
                        Text(account.subtitle)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(Color(hex: "7B7B7B"))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(TransferAccountRowButtonStyle())
    }
}

// MARK: - Button Style

private struct TransferAccountRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isPressed ? Color(hex: "EDEDED") : Color.clear)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Helper view for account icons

struct AccountIconView: View {
    let iconType: PaymentAccount.AccountIconType
    
    var body: some View {
        switch iconType {
        case .asset(let assetName):
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    TransferBetweenAccountsView(isPresented: .constant(true))
}
