import SwiftUI
import UIKit

/// Welcome screen for the signup flow
/// Shows an overview of the 3 signup steps before starting
struct SignUpWelcomeView: View {
    @Binding var isComplete: Bool
    @ObservedObject var signUpData: SignUpData
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCountryView = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .frame(width: 24, height: 24)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Title section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome to Sling, let's get you set up")
                                .h2Style()
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Signup is split into 3 easy steps.")
                                .bodyTextStyle()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                        
                        // Step cards
                        VStack(spacing: 32) {
                            SignUpStepCard(
                                icon: "IconSparkle",
                                title: "About you",
                                duration: "~1m",
                                description: "Answer some questions to help us tailor your experience.",
                                isAssetIcon: true
                            )
                            
                            SignUpStepCard(
                                icon: "IconVerified",
                                title: "Get verified",
                                duration: "~6m",
                                description: "Take a selfie and send a photo of your ID to finish creating your unique account identity.",
                                isAssetIcon: true
                            )
                            
                            SignUpStepCard(
                                icon: "IconWallet",
                                title: "Set up your account",
                                duration: "~1m",
                                description: "Customize your app settings and preferences to suit you.",
                                isAssetIcon: true
                            )
                        }
                        .padding(.horizontal, 16)
                        
                    }
                }
                
                // Footer text
                Text("Most people finish within 8 minutes")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color(hex: "7B7B7B"))
                    .padding(.bottom, 16)
                
                // Get started button
                SecondaryButton(
                    title: "Get started",
                    isEnabled: true,
                    action: {
                        showCountryView = true
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showCountryView) {
            SignUpCountryView(isComplete: $isComplete, signUpData: signUpData)
        }
    }
}

// MARK: - Step Card

struct SignUpStepCard: View {
    let icon: String
    let title: String
    let duration: String
    let description: String
    var isAssetIcon: Bool = false // true for asset catalog icons, false for SF Symbols
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon container - 44x44, light blue bg, cyan icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "E8F8FF"))
                    .frame(width: 44, height: 44)
                
                if isAssetIcon {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "2CC2FF"))
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                // Title row with duration
                HStack(alignment: .center, spacing: 4) {
                    Text(title)
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundColor(Color(hex: "080808"))
                        .tracking(-0.36) // -2% of 18px
                    
                    Spacer()
                    
                    // Duration with clock icon
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Text(duration)
                            .font(.custom("Inter-Bold", size: 10))
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .tracking(-0.2) // -2% of 10px
                    }
                }
                
                // Description - body/small/regular
                Text(description)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color(hex: "999999"))
                    .tracking(-0.28) // -2% of 14px
                    .lineSpacing(2) // ~1.43 line height
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignUpWelcomeView(isComplete: .constant(false), signUpData: SignUpData())
    }
}
