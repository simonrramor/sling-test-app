import SwiftUI

/// Detail view showing debit card terms and agreements
struct DebitCardTermsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    // Terms URLs
    private let bridgeTermsURL = URL(string: "https://www.bridge.xyz/legal/terms-of-service")!
    private let bridgePrivacyURL = URL(string: "https://www.bridge.xyz/legal/privacy-policy")!
    private let leadCardholderURL = URL(string: "https://www.lead.bank/legal/cardholder-agreement")!
    private let leadPrivacyURL = URL(string: "https://www.lead.bank/privacy-policy")!
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hex: "080808"))
                            .frame(width: 24, height: 24)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Title and subtitle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debit card terms")
                                .h2Style()
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Sling debit card is issued in partnership with Bridge and Lead Bank.")
                                .bodyTextStyle()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                        
                        // Agreement rows
                        VStack(spacing: 0) {
                            TermsDocumentRow(title: "Bridge Terms of Service") {
                                openURL(bridgeTermsURL)
                            }
                            
                            TermsDocumentRow(title: "Bridge Privacy Policy") {
                                openURL(bridgePrivacyURL)
                            }
                            
                            TermsDocumentRow(title: "Lead Card Holder Agreement") {
                                openURL(leadCardholderURL)
                            }
                            
                            TermsDocumentRow(title: "Lead Privacy Policy") {
                                openURL(leadPrivacyURL)
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        Spacer().frame(height: 150)
                    }
                }
            }
            
            // Bottom button
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Gradient fade
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white, location: 0.32)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false)
                    
                    // Back button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        Text("Back")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "EDEDED"))
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 50)
                    .background(Color.white)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarHidden(true)
    }
}

/// Row showing a terms document with external link icon
struct TermsDocumentRow: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                // Document icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "F7F7F7"))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "888888"))
                }
                
                // Title
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // External link icon
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
}

#Preview {
    DebitCardTermsView()
}
