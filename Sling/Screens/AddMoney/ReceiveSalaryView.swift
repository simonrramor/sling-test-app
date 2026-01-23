import SwiftUI

struct ReceiveSalaryView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @AppStorage("hasSetupAccount") private var hasSetupAccount = false
    @State private var showAccountDetails = false
    @State private var showLetterToEmployer = false
    @State private var showProofOfOwnership = false
    
    // Mock account details - in production these would come from a service
    private let accountNumber = "12345678"
    private let sortCode = "04-00-04"
    private let iban = "GB82 WEST 1234 5698 7654 32"
    private let accountName = "Sling Money Ltd"
    private let userName = "John Smith"
    
    var body: some View {
        ZStack {
            themeService.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(themeService.currentTheme == .white ? .white : themeService.textPrimaryColor)
                            .frame(width: 32, height: 32)
                            .background(themeService.buttonSecondaryColor)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Receive Salary")
                        .font(.custom("Inter-Bold", size: 17))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Description
                        Text("Share your account details with your employer to receive your salary directly into Sling.")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                        
                        // Account Details Card
                        SalaryOptionCard(
                            icon: "building.columns.fill",
                            iconColor: Color(hex: "007AFF"),
                            title: "Account Details",
                            subtitle: "Your account number, sort code and IBAN",
                            onTap: { showAccountDetails = true }
                        )
                        
                        // Letter to Employer Card
                        SalaryOptionCard(
                            icon: "envelope.fill",
                            iconColor: Color(hex: "34C759"),
                            title: "Letter to Employer",
                            subtitle: "A pre-written letter to share with HR",
                            onTap: { showLetterToEmployer = true }
                        )
                        
                        // Proof of Ownership Card
                        SalaryOptionCard(
                            icon: "checkmark.seal.fill",
                            iconColor: Color(hex: "FF9500"),
                            title: "Proof of Ownership",
                            subtitle: "Official document proving account ownership",
                            onTap: { showProofOfOwnership = true }
                        )
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .sheet(isPresented: $showAccountDetails) {
            AccountDetailsSheet(
                accountNumber: accountNumber,
                sortCode: sortCode,
                iban: iban,
                accountName: accountName
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showLetterToEmployer) {
            LetterToEmployerSheet(
                userName: userName,
                accountNumber: accountNumber,
                sortCode: sortCode,
                accountName: accountName
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showProofOfOwnership) {
            ProofOfOwnershipSheet(
                userName: userName,
                accountNumber: accountNumber,
                sortCode: sortCode,
                iban: iban
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .onAppear {
            // Mark as completed for Get Started cards when user views account details
            hasSetupAccount = true
        }
    }
}

// MARK: - Salary Option Card

struct SalaryOptionCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text(subtitle)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeService.textTertiaryColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeService.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PressedButtonStyle())
    }
}

// MARK: - Account Details Sheet

struct AccountDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeService = ThemeService.shared
    let accountNumber: String
    let sortCode: String
    let iban: String
    let accountName: String
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Account Details")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
            }
            .padding(.top, 8)
            
            // Details
            VStack(spacing: 16) {
                AccountDetailRow(label: "Account Name", value: accountName)
                AccountDetailRow(label: "Account Number", value: accountNumber, copyable: true)
                AccountDetailRow(label: "Sort Code", value: sortCode, copyable: true)
                AccountDetailRow(label: "IBAN", value: iban, copyable: true)
            }
            
            Spacer()
            
            // Share button
            SecondaryButton(title: "Share Details") {
                shareAccountDetails()
            }
        }
        .padding(24)
        .background(themeService.backgroundColor)
    }
    
    private func shareAccountDetails() {
        let details = """
        Account Details for Salary Payment
        
        Account Name: \(accountName)
        Account Number: \(accountNumber)
        Sort Code: \(sortCode)
        IBAN: \(iban)
        """
        
        let activityVC = UIActivityViewController(activityItems: [details], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct AccountDetailRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let label: String
    let value: String
    var copyable: Bool = false
    @State private var copied = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundColor(themeService.textSecondaryColor)
                
                Text(value)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            
            Spacer()
            
            if copyable {
                Button(action: {
                    UIPasteboard.general.string = value
                    copied = true
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                }) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(copied ? Color(hex: "57CE43") : themeService.textSecondaryColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeService.cardBackgroundColor)
        )
    }
}

// MARK: - Letter to Employer Sheet

struct LetterToEmployerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeService = ThemeService.shared
    let userName: String
    let accountNumber: String
    let sortCode: String
    let accountName: String
    
    private var letterContent: String {
        """
        Dear HR / Payroll Team,

        I am writing to request that my salary payments be directed to my new bank account. Please find the updated banking details below:

        Account Holder: \(userName)
        Bank Name: \(accountName)
        Account Number: \(accountNumber)
        Sort Code: \(sortCode)

        Please update your records accordingly and ensure that all future salary payments are deposited into this account.

        If you require any additional documentation or verification, please do not hesitate to contact me.

        Thank you for your assistance.

        Kind regards,
        \(userName)
        """
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Letter to Employer")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
            }
            .padding(.top, 8)
            
            // Letter content
            ScrollView {
                Text(letterContent)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textPrimaryColor)
                    .lineSpacing(6)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeService.cardBackgroundColor)
                    )
            }
            
            // Share button
            SecondaryButton(title: "Share Letter") {
                shareLetter()
            }
        }
        .padding(24)
        .background(themeService.backgroundColor)
    }
    
    private func shareLetter() {
        let activityVC = UIActivityViewController(activityItems: [letterContent], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Proof of Ownership Sheet

struct ProofOfOwnershipSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeService = ThemeService.shared
    let userName: String
    let accountNumber: String
    let sortCode: String
    let iban: String
    
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Proof of Ownership")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
            }
            .padding(.top, 8)
            
            // Certificate
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    Image("SlingLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)
                    
                    // Title
                    Text("Account Ownership Certificate")
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    // Divider
                    Rectangle()
                        .fill(themeService.textTertiaryColor.opacity(0.3))
                        .frame(height: 1)
                    
                    // Certificate content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("This is to certify that:")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        CertificateRow(label: "Account Holder", value: userName)
                        CertificateRow(label: "Account Number", value: accountNumber)
                        CertificateRow(label: "Sort Code", value: sortCode)
                        CertificateRow(label: "IBAN", value: iban)
                        
                        Text("is the registered owner of the above-mentioned account held with Sling Money Ltd.")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                            .padding(.top, 8)
                        
                        Text("Date of Issue: \(currentDate)")
                            .font(.custom("Inter-Regular", size: 12))
                            .foregroundColor(themeService.textTertiaryColor)
                            .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Seal
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FF5113").opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "FF5113"))
                    }
                    .padding(.top, 16)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeService.cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
                )
            }
            
            // Share button
            SecondaryButton(title: "Share Certificate") {
                shareCertificate()
            }
        }
        .padding(24)
        .background(themeService.backgroundColor)
    }
    
    private func shareCertificate() {
        let certificate = """
        ACCOUNT OWNERSHIP CERTIFICATE
        
        Issued by: Sling Money Ltd
        Date: \(currentDate)
        
        This is to certify that:
        
        Account Holder: \(userName)
        Account Number: \(accountNumber)
        Sort Code: \(sortCode)
        IBAN: \(iban)
        
        is the registered owner of the above-mentioned account held with Sling Money Ltd.
        
        This certificate is issued for official purposes.
        """
        
        let activityVC = UIActivityViewController(activityItems: [certificate], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct CertificateRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(themeService.textSecondaryColor)
            
            Text(value)
                .font(.custom("Inter-Bold", size: 14))
                .foregroundColor(themeService.textPrimaryColor)
        }
    }
}

#Preview {
    ReceiveSalaryView(isPresented: .constant(true))
}
