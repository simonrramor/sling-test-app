import SwiftUI

struct DisplayCurrencyPickerView: View {
    @Binding var isPresented: Bool
    @Binding var selectedCurrency: String
    var onCurrencySelected: (String) -> Void
    
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    
    @State private var searchText = ""
    
    private var filteredCurrencies: [DisplayCurrencyInfo] {
        if searchText.isEmpty {
            return displayCurrencyService.allCurrencies
        }
        let lowercasedSearch = searchText.lowercased()
        return displayCurrencyService.allCurrencies.filter { currency in
            currency.name.lowercased().contains(lowercasedSearch) ||
            currency.code.lowercased().contains(lowercasedSearch)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drawer handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.2))
                .frame(width: 32, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Header with back button
            HStack {
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
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(height: 56)
            
            // Title
            HStack {
                Text("Display currency")
                    .font(.custom("Inter-Bold", size: 24))
                    .tracking(-0.48)
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "999999"))
                
                TextField("Currency, code, country", text: $searchText)
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "999999"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color(hex: "F7F7F7"))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Currency list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredCurrencies) { currency in
                        currencyRow(currency: currency)
                        
                        // Divider (except for last item)
                        if currency.id != filteredCurrencies.last?.id {
                            Rectangle()
                                .fill(Color.black.opacity(0.06))
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(.keyboard)
    }
    
    private func currencyRow(currency: DisplayCurrencyInfo) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            selectedCurrency = currency.code
            onCurrencySelected(currency.code)
            isPresented = false
        }) {
            HStack(spacing: 16) {
                // Flag avatar
                Image(currency.flagAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                
                // Currency name and code
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.name)
                        .font(.custom("Inter-Bold", size: 16))
                        .tracking(-0.32)
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text(currency.code)
                        .font(.custom("Inter-Regular", size: 14))
                        .tracking(-0.28)
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
                
                Spacer()
                
                // Checkmark if selected
                if selectedCurrency == currency.code {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "080808"))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
}

#Preview {
    DisplayCurrencyPickerView(
        isPresented: .constant(true),
        selectedCurrency: .constant("USD"),
        onCurrencySelected: { _ in }
    )
}
