import SwiftUI

struct ReceiveSalaryView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @AppStorage("hasSetupAccount") private var hasSetupAccount = false
    @State private var showBRLDetails = false
    @State private var showUSDDetails = false
    @State private var showEURDetails = false
    @State private var showGBPDetails = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with X close button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 32, height: 32)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title and subtitle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your account details")
                                .font(.custom("Inter-Bold", size: 28))
                                .tracking(-0.56)
                                .foregroundColor(themeService.textPrimaryColor)
                            
                            Text("Send money to these details, or share them to get paid. Funds arrive as digital dollars in your Sling Balance.")
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(themeService.textSecondaryColor)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        
                        // Currency options
                        VStack(spacing: 0) {
                            // Brazilian Real
                            CurrencyAccountRow(
                                currencyName: "Brazilian real",
                                transferType: "Pix transfer",
                                currencyIcon: "CurrencyBRL",
                                position: .top,
                                onTap: { showBRLDetails = true }
                            )
                            
                            // US Dollar
                            CurrencyAccountRow(
                                currencyName: "US dollar",
                                transferType: "ACH or Wire transfer",
                                currencyIcon: "CurrencyUSD",
                                position: .middle,
                                onTap: { showUSDDetails = true }
                            )
                            
                            // Section header
                            HStack {
                                Text("Get new account details")
                                    .font(.custom("Inter-Bold", size: 14))
                                    .foregroundColor(themeService.textSecondaryColor)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(themeService.cardBackgroundColor)
                            
                            // Euro
                            CurrencyAccountRow(
                                currencyName: "Euro",
                                transferType: "IBAN",
                                secondaryText: "SEPA transfer",
                                currencyIcon: "CurrencyEUR",
                                position: .middle,
                                onTap: { showEURDetails = true }
                            )
                            
                            // British Pound
                            CurrencyAccountRow(
                                currencyName: "British pound",
                                transferType: "Sort code & Account number",
                                currencyIcon: "CurrencyGBP",
                                position: .bottom,
                                onTap: { showGBPDetails = true }
                            )
                        }
                        .background(themeService.cardBackgroundColor)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showBRLDetails) {
            CurrencyAccountDetailsSheet(
                currencyName: "Brazilian real",
                currencyIcon: "CurrencyBRL",
                details: [
                    ("Pix Key", "12345678900"),
                    ("Bank", "Sling"),
                    ("Account Holder", "Brendon Arnold")
                ]
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showUSDDetails) {
            CurrencyAccountDetailsSheet(
                currencyName: "US dollar",
                currencyIcon: "CurrencyUSD",
                details: [
                    ("Account Number", "123456789"),
                    ("Routing Number (ACH)", "021000021"),
                    ("Routing Number (Wire)", "026009593"),
                    ("Account Holder", "Brendon Arnold"),
                    ("Bank Name", "Sling Bank"),
                    ("Bank Address", "123 Finance St, New York, NY 10001")
                ]
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showEURDetails) {
            CurrencyAccountDetailsSheet(
                currencyName: "Euro",
                currencyIcon: "CurrencyEUR",
                details: [
                    ("IBAN", "DE89 3704 0044 0532 0130 00"),
                    ("BIC/SWIFT", "COBADEFFXXX"),
                    ("Account Holder", "Brendon Arnold"),
                    ("Bank Name", "Sling EU"),
                    ("Bank Address", "Finanzplatz 1, 60311 Frankfurt, Germany")
                ]
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showGBPDetails) {
            CurrencyAccountDetailsSheet(
                currencyName: "British pound",
                currencyIcon: "CurrencyGBP",
                details: [
                    ("Account Number", "12345678"),
                    ("Sort Code", "04-00-75"),
                    ("IBAN", "GB29 NWBK 6016 1331 9268 19"),
                    ("Account Holder", "Brendon Arnold"),
                    ("Bank Name", "Sling UK"),
                    ("Bank Address", "1 Bank Street, London E14 5JP")
                ]
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .onAppear {
            hasSetupAccount = true
        }
    }
}

// MARK: - Currency Account Row

struct CurrencyAccountRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let currencyName: String
    let transferType: String
    var secondaryText: String? = nil
    let currencyIcon: String
    let position: RowPosition
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Black square with bank icon and currency badge (44x44 avatar)
                ZStack(alignment: .topLeading) {
                    // Black rounded square with bank icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "000000"))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                    }
                    
                    // Currency flag badge (14x14, positioned at 32,32 from top-left)
                    Image(currencyIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 14, height: 14)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2.5)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 0, x: 0, y: 0)
                        .offset(x: 32, y: 32)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(currencyName)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    HStack(spacing: 4) {
                        Text(transferType)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        
                        if let secondary = secondaryText {
                            Text("・")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                            Text(secondary)
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeService.textTertiaryColor)
            }
            .padding(16)
            .background(themeService.cardBackgroundColor)
        }
        .buttonStyle(PressedButtonStyle())
        
        // Divider (except for bottom)
        if position != .bottom {
            Rectangle()
                .fill(themeService.cardBorderColor ?? Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.leading, 72)
        }
    }
}

// MARK: - Currency Account Details Sheet

struct CurrencyAccountDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeService = ThemeService.shared
    let currencyName: String
    let currencyIcon: String
    let details: [(label: String, value: String)]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack(spacing: 12) {
                Image(currencyIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                
                Text("\(currencyName) account")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
            }
            .padding(.top, 8)
            
            // Details
            VStack(spacing: 0) {
                ForEach(Array(details.enumerated()), id: \.offset) { index, detail in
                    VStack(spacing: 0) {
                        AccountDetailRow(
                            label: detail.label,
                            value: detail.value,
                            copyable: true
                        )
                        
                        if index < details.count - 1 {
                            Rectangle()
                                .fill(themeService.cardBorderColor ?? Color.gray.opacity(0.2))
                                .frame(height: 1)
                        }
                    }
                }
            }
            .background(themeService.cardBackgroundColor)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
            )
            
            Spacer()
            
            // Share button
            SecondaryButton(title: "Share Details") {
                shareDetails()
            }
        }
        .padding(24)
        .background(Color.white)
    }
    
    private func shareDetails() {
        var shareText = "\(currencyName) Account Details\n\n"
        for detail in details {
            shareText += "\(detail.label): \(detail.value)\n"
        }
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Account Detail Row (reused from before)

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
    }
}

#Preview {
    ReceiveSalaryView(isPresented: .constant(true))
}
