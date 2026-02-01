import SwiftUI
import UIKit

/// Sign-up screen for entering user's phone number
struct SignUpPhoneView: View {
    @Binding var isComplete: Bool
    @ObservedObject var signUpData: SignUpData
    @Environment(\.dismiss) private var dismiss
    
    @State private var showVerificationView = false
    @State private var showCountryPicker = false
    @FocusState private var isPhoneFocused: Bool
    
    // Progress: 20% (step 1 of 5)
    private let progress: CGFloat = 0.2
    
    // Enable continue when phone number is at least 6 digits
    private var canContinue: Bool {
        signUpData.phoneNumber.filter { $0.isNumber }.count >= 6
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Spacer for header
                Color.clear.frame(height: 64)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Title section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's your phone number?")
                                .h2Style()
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("We'll send you a code to verify your number. Why do I need to add my phone number?")
                                .bodyTextStyle()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        
                        // Phone input with country code
                        PhoneInputField(
                            countryCode: signUpData.countryCode,
                            countryFlag: signUpData.countryFlag,
                            phoneNumber: $signUpData.phoneNumber,
                            isFocused: $isPhoneFocused,
                            onCountryTap: { showCountryPicker = true }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Next button - fixed at bottom
                SecondaryButton(
                    title: "Next",
                    isEnabled: canContinue,
                    action: {
                        showVerificationView = true
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
            // Fixed header at top
            SignUpHeader(
                progress: progress,
                onBack: { dismiss() }
            )
            .background(Color.white)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showVerificationView) {
            SignUpVerificationView(isComplete: $isComplete, signUpData: signUpData)
        }
        .sheet(isPresented: $showCountryPicker) {
            SignUpCountryPickerSheet(
                signUpData: signUpData,
                isPresented: $showCountryPicker
            )
        }
        .onAppear {
            // Auto-focus phone field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPhoneFocused = true
            }
        }
    }
}

// MARK: - Phone Input Field

struct PhoneInputField: View {
    let countryCode: String
    let countryFlag: String
    @Binding var phoneNumber: String
    var isFocused: FocusState<Bool>.Binding
    let onCountryTap: () -> Void
    
    /// Get currency code from dial code
    private var currencyCode: String {
        switch countryCode {
        case "+44": return "GBP"
        case "+1": return "USD"
        case "+33", "+49", "+39", "+34", "+31", "+353": return "EUR"
        case "+81": return "JPY"
        case "+86": return "CNY"
        case "+91": return "INR"
        case "+61": return "AUD"
        case "+64": return "NZD"
        case "+41": return "CHF"
        case "+65": return "SGD"
        case "+852": return "HKD"
        case "+254": return "KES"
        case "+234": return "NGN"
        case "+27": return "ZAR"
        case "+55": return "BRL"
        case "+52": return "MXN"
        case "+971": return "AED"
        default: return "USD"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side - Label and phone input
            VStack(alignment: .leading, spacing: 4) {
                Text("Phone number")
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundColor(Color(hex: "7B7B7B"))
                
                HStack(spacing: 0) {
                    Text(countryCode + " ")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                    
                    TextField("", text: $phoneNumber)
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                        .keyboardType(.phonePad)
                        .focused(isFocused)
                        .tint(Color(hex: "FF5113"))
                        .onChange(of: phoneNumber) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber || $0 == " " }
                            if filtered != newValue {
                                phoneNumber = filtered
                            }
                        }
                }
            }
            
            Spacer()
            
            // Right side - Country picker pill
            Button(action: onCountryTap) {
                HStack(spacing: 4) {
                    Image(countryFlag)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                    
                    Text(currencyCode)
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(Color(hex: "080808"))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "999999"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(hex: "FCFCFC"))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "F7F7F7"))
        .cornerRadius(16)
    }
}

// MARK: - Sign Up Country Picker Sheet

struct SignUpCountryPickerSheet: View {
    @ObservedObject var signUpData: SignUpData
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    private var filteredCountries: [Country] {
        Country.search(searchText)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                SearchField(text: $searchText, placeholder: "Search country")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                // Country list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredCountries) { country in
                            Button(action: {
                                signUpData.countryCode = country.dialCode
                                signUpData.countryFlag = country.flagAsset
                                isPresented = false
                            }) {
                                HStack(spacing: 16) {
                                    Image(country.flagAsset)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                    
                                    Text(country.name)
                                        .font(.custom("Inter-Medium", size: 16))
                                        .foregroundColor(Color(hex: "080808"))
                                    
                                    Spacer()
                                    
                                    Text(country.dialCode)
                                        .font(.custom("Inter-Regular", size: 14))
                                        .foregroundColor(Color(hex: "7B7B7B"))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Color(hex: "FF5113"))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignUpPhoneView(isComplete: .constant(false), signUpData: SignUpData())
    }
}
