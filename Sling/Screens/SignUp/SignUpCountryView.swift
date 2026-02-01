import SwiftUI
import UIKit

/// Sign-up screen for selecting user's country of residence
struct SignUpCountryView: View {
    @Binding var isComplete: Bool
    @ObservedObject var signUpData: SignUpData
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showNameView = false
    
    // Progress: 60% (step 3 of 5)
    private let progress: CGFloat = 0.6
    
    /// Country matching the phone code from the previous screen
    private var suggestedCountry: Country? {
        Country.all.first { $0.dialCode == signUpData.countryCode }
    }
    
    /// All countries excluding the suggested one, filtered by search
    private var otherCountries: [Country] {
        let filtered = Country.search(searchText)
        guard let suggested = suggestedCountry else { return filtered }
        return filtered.filter { $0.code != suggested.code }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Spacer for header
                Color.clear.frame(height: 64)
                
                // Title section
                VStack(alignment: .leading, spacing: 8) {
                            Text("Where do you live?")
                                .h2Style()
                                .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Search field
                SearchField(text: $searchText, placeholder: "Search country")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Country list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // Suggested country based on phone code
                        if let suggested = suggestedCountry,
                           searchText.isEmpty || suggested.name.localizedCaseInsensitiveContains(searchText) {
                            CountryRow(
                                country: suggested,
                                isSelected: signUpData.country == suggested.name
                            ) {
                                selectCountry(suggested)
                            }
                            
                            Divider()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        
                        // Other countries alphabetically
                        ForEach(otherCountries) { country in
                            CountryRow(
                                country: country,
                                isSelected: signUpData.country == country.name
                            ) {
                                selectCountry(country)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 16)
                    .padding(.bottom, 80) // Space for button
                }
            }
            
            // Fixed header at top
            SignUpHeader(
                progress: progress,
                onBack: { dismiss() }
            )
            .background(Color.white)
            
            // Next button at bottom
            VStack {
                Spacer()
                
                SecondaryButton(
                    title: "Next",
                    isEnabled: !signUpData.country.isEmpty,
                    action: {
                        showNameView = true
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0), Color.white]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .allowsHitTesting(false)
                )
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showNameView) {
            SignUpNameView(isComplete: $isComplete, signUpData: signUpData)
        }
    }
    
    private func selectCountry(_ country: Country) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        signUpData.country = country.name
        signUpData.countryCode = country.dialCode
        signUpData.countryFlag = country.flagAsset
    }
}

// MARK: - Search Field

struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "7B7B7B"))
            
            TextField(placeholder, text: $text)
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(Color(hex: "080808"))
                .focused($isFocused)
                .tint(Color(hex: "FF5113"))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "999999"))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color(hex: "F7F7F7"))
        .cornerRadius(16)
    }
}

// MARK: - Country Row

struct CountryRow: View {
    let country: Country
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Flag
            Image(country.flagAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            // Country name
            Text(country.name)
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(Color(hex: "080808"))
            
            Spacer()
            
            // Checkmark if selected
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "FF5113"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color(hex: "F5F5F5") : (isSelected ? Color(hex: "FF5113").opacity(0.05) : Color.clear))
        )
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignUpCountryView(isComplete: .constant(false), signUpData: SignUpData())
    }
}
