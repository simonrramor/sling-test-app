import SwiftUI
import UIKit

/// Sign-up screen for entering user's legal name
/// Shown after Apple Sign In authentication
struct SignUpNameView: View {
    @Binding var isComplete: Bool
    @ObservedObject var signUpData: SignUpData
    @Environment(\.dismiss) private var dismiss
    
    // Name validation service
    @StateObject private var nameValidationService = NameValidationService()
    
    // Navigation state
    @State private var showBirthdayView = false
    
    // Validation state
    @State private var validationError: String?
    @State private var isValidating = false
    
    // Progress: 80% (step 4 of 5)
    private let progress: CGFloat = 0.8
    
    // Enable continue when required fields are filled and not validating
    private var canContinue: Bool {
        !signUpData.firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !signUpData.lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isValidating
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            VStack(spacing: 0) {
                // Spacer for header
                Color.clear.frame(height: 64)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Title section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's your full, legal name?")
                                .h2Style()
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("This must match the name on your ID. You can add a preferred name if you like.")
                                .bodyTextStyle()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                        
                        // Form fields
                        VStack(spacing: 8) {
                            TextFormInput(label: "First Names", text: $signUpData.firstName)
                            TextFormInput(label: "Last names", text: $signUpData.lastName)
                            TextFormInput(label: "Preferred name (optional)", text: $signUpData.preferredName)
                                .onChange(of: signUpData.preferredName) { _, _ in
                                    // Clear validation error when user edits preferred name
                                    validationError = nil
                                }
                            
                            // Validation error message
                            if let error = validationError {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text(error)
                                        .font(.custom("Inter-Regular", size: 14))
                                }
                                .foregroundColor(Color(hex: "E53935"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Next button - fixed at bottom
                Button(action: {
                    // Validate preferred name before proceeding
                    Task {
                        await validateAndContinue()
                    }
                }) {
                    HStack(spacing: 8) {
                        if isValidating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isValidating ? "Checking..." : "Next")
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
        .background(Color.white)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showBirthdayView) {
            SignUpBirthdayView(isComplete: $isComplete, signUpData: signUpData)
        }
    }
    
    // MARK: - Validation
    
    /// Validates the preferred name against the legal name using AI
    /// If validation passes (or no preferred name), proceeds to next step
    private func validateAndContinue() async {
        // If no preferred name, skip validation and proceed
        let trimmedPreferred = signUpData.preferredName.trimmingCharacters(in: .whitespaces)
        if trimmedPreferred.isEmpty {
            await MainActor.run {
                showBirthdayView = true
            }
            return
        }
        
        // Start validation
        await MainActor.run {
            isValidating = true
            validationError = nil
        }
        
        // Call validation service
        let result = await nameValidationService.validatePreferredName(
            legalFirstName: signUpData.firstName,
            legalLastName: signUpData.lastName,
            preferredName: signUpData.preferredName
        )
        
        await MainActor.run {
            isValidating = false
            
            switch result {
            case .success(let validation):
                if validation.approved {
                    // Validation passed, proceed to next step
                    showBirthdayView = true
                } else {
                    // Validation failed, show error
                    validationError = validation.reason
                }
                
            case .failure(let error):
                // Network or API error - show generic message
                validationError = "Unable to verify name. Please try again."
                print("Name validation error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Sign Up Header

/// Reusable header component for sign-up screens
/// Contains back button and progress indicator
struct SignUpHeader: View {
    let progress: CGFloat // 0.0 to 1.0
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // Centered progress bar
            ProgressBarView(progress: progress)
            
            // Back button on left
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "7B7B7B"))
                        .frame(width: 24, height: 24)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 64)
    }
}

// MARK: - Progress Bar

/// Three-segment progress bar for sign-up flow
struct ProgressBarView: View {
    let progress: CGFloat // 0.0 to 1.0
    
    // Design constants from Figma
    private let totalWidth: CGFloat = 142
    private let segmentHeight: CGFloat = 4
    private let segmentSpacing: CGFloat = 4
    
    var body: some View {
        HStack(spacing: segmentSpacing) {
            // Segment 1: filled if progress > 0
            progressSegment(isFilled: progress > 0)
            // Segment 2: filled if progress > 33%
            progressSegment(isFilled: progress > 0.33)
            // Segment 3: filled if progress > 66%
            progressSegment(isFilled: progress > 0.66)
        }
        .frame(width: totalWidth, height: segmentHeight)
    }
    
    @ViewBuilder
    private func progressSegment(isFilled: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isFilled ? Color(hex: "FF5113") : Color(hex: "F7F7F7"))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignUpNameView(isComplete: .constant(false), signUpData: SignUpData())
    }
}
