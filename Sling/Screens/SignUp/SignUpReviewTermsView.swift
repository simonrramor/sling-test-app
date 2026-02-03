import SwiftUI

/// Review terms content - agreements list and e-signature toggle
struct SignUpReviewTermsContent: View {
    @ObservedObject var signUpData: SignUpData
    
    @State private var showDebitCardTerms = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review terms")
                        .h2Style()
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("To verify your identity and activate your card and account, please review and accept these agreements.")
                        .bodyTextStyle()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Agreement rows   
                VStack(spacing: 0) {
                    TermsAgreementRow(
                        icon: "IconIDVerify",
                        title: "Secure ID verification",
                        subtitle: "Verify your identity with Persona",
                        isAssetIcon: true
                    )
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showDebitCardTerms = true
                    }) {
                        TermsAgreementRow(
                            icon: "IconDebitCard",
                            title: "Debit card",
                            subtitle: "Issued by Bridge and Lead Bank",
                            isAssetIcon: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    TermsAgreementRow(
                        icon: "IconBank",
                        title: "Account details",
                        subtitle: "Issued by Bridge",
                        isAssetIcon: true
                    )
                }
                .padding(.horizontal, 8)
                
                Spacer().frame(height: 150)
            }
        }
        .fullScreenCover(isPresented: $showDebitCardTerms) {
            DebitCardTermsView()
        }
        
        // Bottom section - positioned absolutely
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // E-signature toggle
                ESignatureRow(isEnabled: $signUpData.useESignature)
                    .padding(.vertical, 16)
                
                // Disclaimer text
                Text("Tap 'I agree' to confirm that you have reviewed and accepted the terms above.")
                    .font(.custom("Inter-Regular", size: 13))
                    .foregroundColor(Color(hex: "7B7B7B"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Terms Components

/// Row showing an agreement item with icon, title/subtitle, and chevron
struct TermsAgreementRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isAssetIcon: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container (44x44 with 10px inset for 24px icon)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "F7F7F7"))
                    .frame(width: 44, height: 44)
                
                if isAssetIcon {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "888888"))
                }
            }
            
            // Text content - title bold, subtitle regular
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                Text(subtitle)
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "7B7B7B"))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
    }
}

/// E-signature toggle row
struct ESignatureRow: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            isEnabled.toggle()
        }) {
            HStack(spacing: 16) {
                // Text
                Text("Sign with e-signature")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                Spacer()
                
                // Checkbox - rounded square
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isEnabled ? Color(hex: "FF5113") : Color(hex: "7B7B7B"), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isEnabled {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "FF5113"))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(Color(hex: "FCFCFC"))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(hex: "F7F7F7"), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    SignUpReviewTermsContent(signUpData: SignUpData())
}
