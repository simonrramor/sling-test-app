import SwiftUI

struct CurrencySelectionView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    
    @State private var showAdvanced = false
    @State private var selectedBaseCurrency: SelectedCurrency? = nil
    
    // Wrapper to make the selected currency identifiable for fullScreenCover
    struct SelectedCurrency: Identifiable {
        let id = UUID()
        let code: String
    }
    
    // Main fiat currencies (EUR and USD)
    private let mainCurrencies: [(code: String, name: String, subtitle: String, imageAsset: String)] = [
        ("EUR", "Euro", "EURC", "CurrencyEUR"),
        ("USD", "US Dollar", "USDG", "CurrencyUSD")
    ]
    
    // Advanced crypto options (USDG is now shown under USD, so removed from here)
    private let advancedCurrencies: [(code: String, name: String, imageAsset: String)] = [
        ("USDC", "USDC", "CurrencyUSDC"),
        ("USDP", "USDP", "CurrencyUSDP"),
        ("USDT", "USDT", "CurrencyUSDT")
    ]
    
    var body: some View {
        ZStack {
            themeService.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select storage currency")
                        .font(.custom("Inter-Bold", size: 28))
                        .tracking(-0.56)
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text("Your Sling balance will be stored in this digital currency but you can display this balance in any currency you like.")
                        .font(.custom("Inter-Regular", size: 16))
                        .tracking(-0.32)
                        .foregroundColor(themeService.textSecondaryColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Main currency list
                VStack(spacing: 0) {
                    ForEach(mainCurrencies, id: \.code) { currency in
                        CurrencyRow(
                            name: currency.name,
                            subtitle: currency.subtitle,
                            imageAsset: currency.imageAsset,
                            isSelected: displayCurrencyService.displayCurrency == currency.code,
                            onTap: {
                                selectedBaseCurrency = SelectedCurrency(code: currency.code)
                            }
                        )
                        
                        if currency.code != mainCurrencies.last?.code {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(themeService.cardBackgroundColor)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // Advanced options header
                HStack {
                    Text("Advanced options")
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showAdvanced.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(showAdvanced ? "Hide" : "Show")
                                .font(.custom("Inter-Medium", size: 14))
                                .foregroundColor(Color(hex: "FF5113"))
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "FF5113"))
                                .rotationEffect(.degrees(showAdvanced ? 180 : 0))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 12)
                
                // Advanced currency list
                if showAdvanced {
                    VStack(spacing: 0) {
                        ForEach(Array(advancedCurrencies.enumerated()), id: \.element.code) { index, currency in
                            CurrencyRow(
                                name: currency.name,
                                imageAsset: currency.imageAsset,
                                isSelected: displayCurrencyService.displayCurrency == currency.code,
                                isRound: true,
                                onTap: {
                                    selectedBaseCurrency = SelectedCurrency(code: currency.code)
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .opacity
                                    .combined(with: .offset(y: -10))
                                    .animation(.spring(response: 0.35, dampingFraction: 0.8).delay(Double(index) * 0.04)),
                                removal: .opacity.animation(.easeOut(duration: 0.15))
                            ))
                            
                            if currency.code != advancedCurrencies.last?.code {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(themeService.cardBackgroundColor)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .transition(.asymmetric(
                        insertion: .opacity
                            .combined(with: .scale(scale: 0.95, anchor: .top))
                            .combined(with: .offset(y: -8)),
                        removal: .opacity.animation(.easeOut(duration: 0.15))
                    ))
                }
                
                Spacer()
            }
        }
        .fullScreenCover(item: $selectedBaseCurrency) { selected in
            DisplayCurrencyStepView(
                isPresented: Binding(
                    get: { selectedBaseCurrency != nil },
                    set: { if !$0 { selectedBaseCurrency = nil } }
                ),
                baseCurrency: selected.code,
                onComplete: {
                    selectedBaseCurrency = nil
                    isPresented = false
                }
            )
        }
    }
}

// MARK: - Display Currency Step View (Step 2 of flow)

struct DisplayCurrencyStepView: View {
    @Binding var isPresented: Bool
    let baseCurrency: String
    let onComplete: () -> Void
    
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    
    @State private var searchText = ""
    @State private var selectedCurrency: String = ""
    
    // All display currency options
    private let displayCurrencies: [(code: String, name: String, imageAsset: String)] = [
        ("USD", "US Dollar", "CurrencyUSD"),
        ("EUR", "Euro", "CurrencyEUR"),
        ("GBP", "British Pound", "FlagGB"),
        ("CHF", "Swiss Franc", "FlagCH"),
        ("CAD", "Canadian Dollar", "FlagCA"),
        ("AUD", "Australian Dollar", "FlagAU"),
        ("JPY", "Japanese Yen", "FlagJP"),
        ("CNY", "Chinese Yuan", "FlagCN"),
        ("INR", "Indian Rupee", "FlagIN"),
        ("BRL", "Brazilian Real", "FlagBR"),
        ("MXN", "Mexican Peso", "FlagMX"),
        ("SGD", "Singapore Dollar", "FlagSG")
    ]
    
    private var filteredCurrencies: [(code: String, name: String, imageAsset: String)] {
        if searchText.isEmpty {
            return displayCurrencies
        }
        return displayCurrencies.filter { currency in
            currency.name.localizedCaseInsensitiveContains(searchText) ||
            currency.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Convert 1 unit of base currency to display currency
    private var convertedAmount: String {
        guard !selectedCurrency.isEmpty else {
            return ExchangeRateService.format(amount: 1, currency: baseCurrency)
        }
        
        // If same currency, just return 1
        if baseCurrency == selectedCurrency {
            return ExchangeRateService.format(amount: 1, currency: selectedCurrency)
        }
        
        // Try to get cached rate from base to display currency
        if let rate = ExchangeRateService.shared.getCachedRate(from: baseCurrency, to: selectedCurrency) {
            return ExchangeRateService.format(amount: rate, currency: selectedCurrency)
        }
        
        // If no cached rate, show placeholder and fetch asynchronously
        return ExchangeRateService.format(amount: 1, currency: selectedCurrency)
    }
    
    var body: some View {
        ZStack {
            themeService.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // Balance preview card - sticky at top
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 0) {
                        Text("Balance")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Text("・")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        Text(ExchangeRateService.format(amount: 1, currency: baseCurrency))
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                    
                    AnimatedCurrencyText(
                        text: convertedAmount,
                        font: .custom("Inter-Bold", size: 48),
                        textColor: themeService.textPrimaryColor
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(themeService.cardBackgroundColor)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Title and subtitle
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pick a Display Currency")
                                .font(.custom("Inter-Bold", size: 28))
                                .tracking(-0.56)
                                .foregroundColor(themeService.textPrimaryColor)
                            
                            Text("Your balance will be stored in digital dollars, but you can display your balance and transactions in any currency you want.")
                                .font(.custom("Inter-Regular", size: 16))
                                .tracking(-0.32)
                                .foregroundColor(themeService.textSecondaryColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        
                        // Search bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(themeService.textSecondaryColor)
                            
                            TextField("Search currency", text: $searchText)
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(themeService.textPrimaryColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(themeService.cardBackgroundColor)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        
                        // Currency list with checkboxes
                        VStack(spacing: 0) {
                            ForEach(filteredCurrencies, id: \.code) { currency in
                                DisplayCurrencyCheckboxRow(
                                    name: currency.name,
                                    code: currency.code,
                                    imageAsset: currency.imageAsset,
                                    isSelected: selectedCurrency == currency.code,
                                    onTap: {
                                        // Fetch rate if not cached
                                        Task {
                                            _ = await ExchangeRateService.shared.getRate(from: baseCurrency, to: currency.code)
                                            await MainActor.run {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    selectedCurrency = currency.code
                                                }
                                            }
                                        }
                                        displayCurrencyService.displayCurrency = currency.code
                                    }
                                )
                                
                                if currency.code != filteredCurrencies.last?.code {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(themeService.cardBackgroundColor)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                
                // Continue button
                Button(action: {
                    // Save both storage and display currencies
                    displayCurrencyService.storageCurrency = baseCurrency
                    displayCurrencyService.displayCurrency = selectedCurrency
                    onComplete()
                }) {
                    Text("Continue")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "080808"))
                        .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .opacity(selectedCurrency.isEmpty ? 0.5 : 1.0)
                .disabled(selectedCurrency.isEmpty)
            }
        }
        .onAppear {
            selectedCurrency = displayCurrencyService.displayCurrency
            // Prefetch exchange rates for the base currency
            Task {
                await ExchangeRateService.shared.getRate(from: baseCurrency, to: "USD")
            }
        }
    }
}

// MARK: - Display Currency Checkbox Row

struct DisplayCurrencyCheckboxRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let name: String
    let code: String
    let imageAsset: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Flag/Currency image
            Image(imageAsset)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            
            // Currency info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Text(code)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
            }
            
            Spacer()
            
            // Checkbox
            ZStack {
                Circle()
                    .stroke(isSelected ? Color(hex: "080808") : Color(hex: "D1D1D6"), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Circle()
                        .fill(Color(hex: "080808"))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color(hex: "F5F5F5") : Color.clear)
        )
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }
    }
}

// MARK: - Currency Row

struct CurrencyRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let name: String
    var subtitle: String? = nil
    let imageAsset: String
    let isSelected: Bool
    var isRound: Bool = false
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Currency image from assets
            Image(imageAsset)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(isRound ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 10)))
                .overlay(
                    Group {
                        if isRound {
                            Circle()
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        }
                    }
                )
            
            // Currency name and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? themeService.textPrimaryColor : themeService.textSecondaryColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? (themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F5F5F5")) : Color.clear)
        )
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }
    }
}

// MARK: - Animated Currency Text with Rolling Characters

struct AnimatedCurrencyText: View {
    let text: String
    let font: Font
    let textColor: Color
    
    @State private var displayedChars: [(id: String, char: Character, offset: CGFloat, opacity: Double)] = []
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(displayedChars, id: \.id) { item in
                Text(String(item.char))
                    .font(font)
                    .tracking(-0.64)
                    .foregroundColor(textColor)
                    .offset(y: item.offset)
                    .opacity(item.opacity)
            }
        }
        .onAppear {
            initializeChars()
        }
        .onChange(of: text) { oldValue, newValue in
            animateToNewText(newValue)
        }
    }
    
    private func initializeChars() {
        displayedChars = text.enumerated().map { index, char in
            (id: "\(index)-\(char)-\(UUID())", char: char, offset: 0, opacity: 1)
        }
    }
    
    private func animateToNewText(_ newText: String) {
        let oldCount = displayedChars.count
        
        // Phase 1: Roll out old characters from left to right
        for i in 0..<oldCount {
            let delay = Double(i) * 0.025
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: 0.15)) {
                    if i < displayedChars.count {
                        displayedChars[i].offset = -25
                        displayedChars[i].opacity = 0
                    }
                }
            }
        }
        
        // Phase 2: After old chars are gone, set up new chars and roll them in
        let rollOutDuration = Double(oldCount) * 0.025 + 0.15
        
        DispatchQueue.main.asyncAfter(deadline: .now() + rollOutDuration) {
            // Set up new characters in starting position
            displayedChars = newText.enumerated().map { index, char in
                (id: "\(index)-\(char)-\(UUID())", char: char, offset: 25, opacity: 0)
            }
            
            // Roll in new characters from left to right
            for i in 0..<newText.count {
                let delay = Double(i) * 0.025
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        if i < displayedChars.count {
                            displayedChars[i].offset = 0
                            displayedChars[i].opacity = 1
                        }
                    }
                }
            }
        }
    }
}

// Helper for type-erased shapes
struct AnyShape: Shape, @unchecked Sendable {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

#Preview {
    CurrencySelectionView(isPresented: .constant(true))
}
