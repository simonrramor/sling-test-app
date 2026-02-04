import SwiftUI
import UIKit

/// Sign-up screen for SMS verification code entry
struct SignUpVerificationView: View {
    @Binding var isComplete: Bool
    @ObservedObject var signUpData: SignUpData
    @Environment(\.dismiss) private var dismiss
    
    @State private var verificationCode = ""
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @State private var showWelcomeView = false
    @FocusState private var isCodeFocused: Bool
    
    // Progress: 40% (step 2 of 5)
    private let progress: CGFloat = 0.4
    
    // Code length
    private let codeLength = 6
    
    // Enable continue when code is complete
    private var canContinue: Bool {
        verificationCode.count == codeLength && !isVerifying
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
                            Text("Enter your verification code")
                                .h2Style()
                                .fixedSize(horizontal: false, vertical: true)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("We sent your code to \(signUpData.formattedPhoneNumber) via SMS.")
                                    .bodyTextStyle()
                                
                                HStack(spacing: 0) {
                                    Text("Didn't receive a code? ")
                                        .font(.custom("Inter-Regular", size: 16))
                                        .foregroundColor(Color(hex: "7B7B7B"))
                                    
                                    Button(action: {
                                        // TODO: Resend code
                                    }) {
                                        Text("Request again.")
                                            .font(.custom("Inter-Medium", size: 16))
                                            .foregroundColor(Color(hex: "FF5113"))
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        
                        // Code input
                        VerificationCodeInput(
                            code: $verificationCode,
                            length: codeLength,
                            isFocused: $isCodeFocused
                        )
                        .padding(.horizontal, 16)
                        
                        // Error message
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 14))
                                Text(error)
                                    .font(.custom("Inter-Regular", size: 14))
                            }
                            .foregroundColor(Color(hex: "E53935"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Next button - fixed at bottom
                Button(action: {
                    verifyCode()
                }) {
                    HStack(spacing: 8) {
                        if isVerifying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isVerifying ? "Verifying..." : "Next")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(canContinue ? .white : .white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canContinue ? Color(hex: "080808") : Color("ButtonDisabled"))
                    .cornerRadius(20)
                }
                .buttonStyle(PressedButtonStyle())
                .disabled(!canContinue)
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
        .navigationDestination(isPresented: $showWelcomeView) {
            SignUpWelcomeView(isComplete: $isComplete, signUpData: signUpData)
        }
        .onAppear {
            // Auto-focus code field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCodeFocused = true
            }
        }
        .onChange(of: verificationCode) { _, newValue in
            // Clear error when user types
            if errorMessage != nil {
                errorMessage = nil
            }
            
            // Auto-submit when code is complete
            if newValue.count == codeLength {
                verifyCode()
            }
        }
    }
    
    private func verifyCode() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        isVerifying = true
        errorMessage = nil
        
        // Simulate verification delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isVerifying = false
            
            // For demo, accept any 6-digit code
            // In production, this would call an API
            if verificationCode.count == codeLength {
                // Success - proceed to welcome screen
                showWelcomeView = true
            } else {
                errorMessage = "Invalid verification code. Please try again."
            }
        }
    }
}

// MARK: - Verification Code Input

struct VerificationCodeInput: View {
    @Binding var code: String
    let length: Int
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        ZStack {
            // Hidden text field for input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused(isFocused)
                .opacity(0)
                .onChange(of: code) { _, newValue in
                    // Limit to digits only and max length
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > length {
                        code = String(filtered.prefix(length))
                    } else if filtered != newValue {
                        code = filtered
                    }
                }
            
            // Visual code boxes
            HStack(spacing: 8) {
                ForEach(0..<length, id: \.self) { index in
                    CodeDigitBox(
                        digit: getDigit(at: index),
                        isActive: index == code.count && isFocused.wrappedValue
                    )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused.wrappedValue = true
            }
        }
    }
    
    private func getDigit(at index: Int) -> String {
        guard index < code.count else { return "" }
        let stringIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[stringIndex])
    }
}

// MARK: - Code Digit Box

struct CodeDigitBox: View {
    let digit: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "F7F7F7"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isActive ? Color(hex: "FF5113") : Color.clear, lineWidth: 2)
                )
            
            if digit.isEmpty && isActive {
                // Cursor
                Rectangle()
                    .fill(Color(hex: "FF5113"))
                    .frame(width: 2, height: 24)
                    .opacity(1)
            } else {
                Text(digit)
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundColor(Color(hex: "080808"))
            }
        }
        .frame(height: 72)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignUpVerificationView(isComplete: .constant(false), signUpData: SignUpData())
    }
}
