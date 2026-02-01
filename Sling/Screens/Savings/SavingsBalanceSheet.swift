import SwiftUI

struct SavingsBalanceSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var portfolioService = PortfolioService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    
    @State private var selectedCurrency: String = "USD"
    @State private var showCurrencyPicker = false
    @State private var displayAmount: Double = 0
    @State private var exchangeRate: Double = 1.0
    @State private var sheetOffset: CGFloat = 500
    @State private var backgroundOpacity: Double = 0
    
    private let exchangeRateService = ExchangeRateService.shared
    
    // The underlying balance in USD (USDP)
    private var usdBalance: Double {
        portfolioService.cashBalance
    }
    
    // Formatted balance in the selected display currency
    private var formattedBalance: String {
        if selectedCurrency == "USD" {
            return String(format: "$%@", formatNumber(usdBalance))
        }
        let symbol = ExchangeRateService.symbol(for: selectedCurrency)
        return String(format: "%@%@", symbol, formatNumber(displayAmount))
    }
    
    // Formatted USDP amount
    private var formattedUSDPAmount: String {
        String(format: "%@ USDP", formatNumber(usdBalance))
    }
    
    // Exchange rate display string
    private var exchangeRateString: String {
        if selectedCurrency == "USD" {
            return "1 USDP = $1.00"
        }
        let symbol = ExchangeRateService.symbol(for: selectedCurrency)
        return String(format: "1 USDP = %@%.2f", symbol, exchangeRate)
    }
    
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
                
                // Content
                VStack(spacing: 24) {
                    // Balance row with icon
                    balanceRow
                    
                    // Description text
                    Text("Your Sling Balance is stored in digital dollars (USDP), but you can display your balance in any currency you like.")
                        .font(.custom("Inter-Regular", size: 16))
                        .tracking(-0.32)
                        .foregroundColor(Color(hex: "7B7B7B"))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Currency tab bar
                    currencyTabBar
                    
                    // Exchange rate row
                    exchangeRateRow
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 47))
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .offset(y: sheetOffset)
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showCurrencyPicker) {
            DisplayCurrencyPickerView(
                isPresented: $showCurrencyPicker,
                selectedCurrency: $selectedCurrency,
                onCurrencySelected: { currency in
                    selectedCurrency = currency
                    displayCurrencyService.displayCurrency = currency
                    fetchExchangeRate()
                }
            )
        }
        .onAppear {
            selectedCurrency = displayCurrencyService.displayCurrency
            fetchExchangeRate()
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
    
    // MARK: - Balance Row
    
    private var balanceRow: some View {
        HStack(spacing: 16) {
            // Sling app icon
            Image("SlingBalanceLogo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            
            // Balance amounts
            VStack(alignment: .leading, spacing: 0) {
                Text(formattedBalance)
                    .font(.custom("Inter-Bold", size: 32))
                    .tracking(-0.64)
                    .foregroundColor(Color(hex: "080808"))
                
                Text(formattedUSDPAmount)
                    .font(.custom("Inter-Medium", size: 16))
                    .tracking(-0.32)
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Currency Tab Bar
    
    private var currencyTabBar: some View {
        HStack(spacing: 4) {
            // USD tab (always shown)
            currencyTab(currency: displayCurrencyService.allCurrencies.first { $0.code == "USD" }!)
            
            // Current display currency tab (if not USD)
            if let currentCurrency = displayCurrencyService.currentCurrencyInfo, currentCurrency.code != "USD" {
                currencyTab(currency: currentCurrency)
            }
            
            // More tab
            moreTab
        }
        .padding(4)
        .background(Color(hex: "F7F7F7"))
        .cornerRadius(12)
    }
    
    private func currencyTab(currency: DisplayCurrencyInfo) -> some View {
        let isSelected = selectedCurrency == currency.code
        
        return Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCurrency = currency.code
                displayCurrencyService.displayCurrency = currency.code
                fetchExchangeRate()
            }
        }) {
            HStack(spacing: 4) {
                Image(currency.flagAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 16, height: 16)
                    .clipShape(Circle())
                
                Text(currency.code)
                    .font(.custom("Inter-Bold", size: 16))
                    .tracking(-0.32)
                    .foregroundColor(isSelected ? Color(hex: "080808") : Color(hex: "999999"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(isSelected ? Color.white : Color.clear)
            .cornerRadius(8)
            .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 4, x: 0, y: 2)
        }
    }
    
    private var moreTab: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            showCurrencyPicker = true
        }) {
            HStack(spacing: 4) {
                Text("More")
                    .font(.custom("Inter-Bold", size: 16))
                    .tracking(-0.32)
                    .foregroundColor(Color(hex: "999999"))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "999999"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(Color.clear)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Exchange Rate Row
    
    private var exchangeRateRow: some View {
        HStack(spacing: 4) {
            Text(exchangeRateString)
                .font(.custom("Inter-Bold", size: 18))
                .tracking(-0.36)
                .foregroundColor(Color.black.opacity(0.8))
            
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "7B7B7B"))
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
    
    private func fetchExchangeRate() {
        guard selectedCurrency != "USD" else {
            displayAmount = usdBalance
            exchangeRate = 1.0
            return
        }
        
        Task {
            if let rate = await exchangeRateService.getRate(from: "USD", to: selectedCurrency) {
                await MainActor.run {
                    exchangeRate = rate
                    displayAmount = usdBalance * rate
                }
            }
        }
    }
}

#Preview {
    SavingsBalanceSheet(isPresented: .constant(true))
}
