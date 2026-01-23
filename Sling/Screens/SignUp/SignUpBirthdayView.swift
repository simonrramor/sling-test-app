import SwiftUI
import UIKit

/// Sign-up screen for entering user's birthday
struct SignUpBirthdayView: View {
    @Binding var isComplete: Bool
    @ObservedObject var signUpData: SignUpData
    @Environment(\.dismiss) private var dismiss
    
    @State private var showMonthPicker = false
    @State private var selectedMonthIndex: Int = 0
    
    // Progress: 100% (step 5 of 5)
    private let progress: CGFloat = 1.0
    
    // Enable continue when all fields are filled
    private var canContinue: Bool {
        !signUpData.birthDay.isEmpty &&
        !signUpData.birthMonth.isEmpty &&
        !signUpData.birthYear.isEmpty &&
        isValidDate
    }
    
    // Validate that the date is reasonable
    private var isValidDate: Bool {
        guard let day = Int(signUpData.birthDay),
              let year = Int(signUpData.birthYear) else {
            return false
        }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        return day >= 1 && day <= 31 && year >= 1900 && year <= currentYear - 13
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
                            Text("When's your birthday?")
                                .h2Style()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        
                        // Date input fields
                        HStack(spacing: 8) {
                            // Day
                            DateFieldInput(
                                label: "Day",
                                text: $signUpData.birthDay,
                                placeholder: "DD",
                                keyboardType: .numberPad,
                                maxLength: 2
                            )
                            .frame(maxWidth: .infinity)
                            
                            // Month
                            MonthFieldInput(
                                label: "Month",
                                selectedMonth: signUpData.birthMonth,
                                onTap: { showMonthPicker = true }
                            )
                            .frame(maxWidth: .infinity)
                            
                            // Year
                            DateFieldInput(
                                label: "Year",
                                text: $signUpData.birthYear,
                                placeholder: "YYYY",
                                keyboardType: .numberPad,
                                maxLength: 4
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Next button - fixed at bottom
                SecondaryButton(
                    title: "Next",
                    isEnabled: canContinue,
                    action: {
                        // Complete signup
                        withAnimation {
                            isComplete = true
                        }
                    }
                )
                .padding(.horizontal, 24)
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
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerSheet(
                selectedMonth: $signUpData.birthMonth,
                isPresented: $showMonthPicker
            )
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Date Field Input

struct DateFieldInput: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let maxLength: Int
    
    @FocusState private var isFocused: Bool
    
    private var isActive: Bool {
        isFocused || !text.isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "F7F7F7"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundColor(Color(hex: "7B7B7B"))
                    .padding(.top, 14)
                
                TextField(placeholder, text: $text)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                    .keyboardType(keyboardType)
                    .focused($isFocused)
                    .tint(Color(hex: "FF5113"))
                    .onChange(of: text) { _, newValue in
                        // Limit to max length and digits only
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > maxLength {
                            text = String(filtered.prefix(maxLength))
                        } else {
                            text = filtered
                        }
                    }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 72)
        .onTapGesture {
            isFocused = true
        }
    }
}

// MARK: - Month Field Input

struct MonthFieldInput: View {
    let label: String
    let selectedMonth: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "F7F7F7"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.custom("Inter-Medium", size: 13))
                        .foregroundColor(Color(hex: "7B7B7B"))
                        .padding(.top, 14)
                    
                    Text(selectedMonth.isEmpty ? "Month" : selectedMonth)
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(selectedMonth.isEmpty ? Color(hex: "999999") : Color(hex: "080808"))
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 72)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Month Picker Sheet

struct MonthPickerSheet: View {
    @Binding var selectedMonth: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Month")
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundColor(Color(hex: "080808"))
                
                Spacer()
                
                Button("Done") {
                    isPresented = false
                }
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(Color(hex: "FF5113"))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
            
            // Month list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Month.all) { month in
                        Button(action: {
                            selectedMonth = month.name
                            isPresented = false
                        }) {
                            HStack {
                                Text(month.name)
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(Color(hex: "080808"))
                                
                                Spacer()
                                
                                if selectedMonth == month.name {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "FF5113"))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        
                        if month.id < 12 {
                            Divider()
                                .padding(.leading, 24)
                        }
                    }
                }
            }
        }
        .background(Color.white)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignUpBirthdayView(isComplete: .constant(false), signUpData: SignUpData())
    }
}
