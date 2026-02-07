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
                                currencyIcon: "FlagBR",
                                position: .top,
                                onTap: { showBRLDetails = true }
                            )
                            
                            // US Dollar
                            CurrencyAccountRow(
                                currencyName: "US dollar",
                                transferType: "ACH or Wire transfer",
                                currencyIcon: "FlagUS",
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
                            
                            // Euro
                            CurrencyAccountRow(
                                currencyName: "Euro",
                                transferType: "IBAN",
                                secondaryText: "SEPA transfer",
                                currencyIcon: "FlagEUR",
                                position: .middle,
                                onTap: { showEURDetails = true }
                            )
                            
                            // British Pound
                            CurrencyAccountRow(
                                currencyName: "British pound",
                                transferType: "Sort code & Account number",
                                currencyIcon: "FlagGB",
                                position: .bottom,
                                onTap: { showGBPDetails = true }
                            )
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showBRLDetails) {
            CurrencyAccountDetailsSheet(
                isPresented: $showBRLDetails,
                title: "BRL account details",
                subtitle: "Money sent to these details will be converted to digital dollars and added to your Sling Wallet.",
                infoBadges: [("percent", "0% fee"), ("arrow.down", "R$10 min"), ("clock", "Instant")],
                details: [
                    ("Pix Key", "12345678900", false),
                    ("Bank", "Sling", false),
                    ("Account Holder", "Brendon Arnold", false)
                ]
            )
        }
        .fullScreenCover(isPresented: $showUSDDetails) {
            CurrencyAccountDetailsSheet(
                isPresented: $showUSDDetails,
                title: "US account details",
                subtitle: "Money sent to these details will be converted to digital dollars and added to your Sling Wallet.",
                infoBadges: [("percent", "0.25% fee"), ("arrow.down", "$2 min"), ("clock", "1-3 business days")],
                details: [
                    ("Routing number", "123456789", false),
                    ("Account number", "123456789123", true),
                    ("Bank name", "Lead Bank", false),
                    ("Beneficiary name", "Brendon Arnold", false),
                    ("Bank address", "1801 Main St.\nKansas City\nMO 64108", true)
                ]
            )
        }
        .fullScreenCover(isPresented: $showEURDetails) {
            CurrencyAccountDetailsSheet(
                isPresented: $showEURDetails,
                title: "EUR account details",
                subtitle: "Money sent to these details will be converted to digital dollars and added to your Sling Wallet.",
                infoBadges: [("percent", "0.25% fee"), ("arrow.down", "€2 min"), ("clock", "1-2 business days")],
                details: [
                    ("IBAN", "DE89 3704 0044 0532 0130 00", true),
                    ("BIC/SWIFT", "COBADEFFXXX", true),
                    ("Account Holder", "Brendon Arnold", false),
                    ("Bank name", "Sling EU", false),
                    ("Bank address", "Finanzplatz 1\n60311 Frankfurt\nGermany", true)
                ]
            )
        }
        .fullScreenCover(isPresented: $showGBPDetails) {
            CurrencyAccountDetailsSheet(
                isPresented: $showGBPDetails,
                title: "GBP account details",
                subtitle: "Money sent to these details will be converted to digital dollars and added to your Sling Wallet.",
                infoBadges: [("percent", "0.25% fee"), ("arrow.down", "£2 min"), ("clock", "Same day")],
                details: [
                    ("Account number", "12345678", true),
                    ("Sort code", "04-00-75", true),
                    ("IBAN", "GB29 NWBK 6016 1331 9268 19", true),
                    ("Account Holder", "Brendon Arnold", false),
                    ("Bank name", "Sling UK", false),
                    ("Bank address", "1 Bank Street\nLondon E14 5JP", true)
                ]
            )
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
                        
                        Image("IconBankCurrency")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
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
            .cornerRadius(24)
        }
        .buttonStyle(CurrencyRowButtonStyle())
    }
}

// MARK: - Currency Account Details Sheet

struct CurrencyAccountDetailsSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    let title: String
    let subtitle: String
    let infoBadges: [(icon: String, text: String)]
    let details: [(label: String, value: String, copyable: Bool)]
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back arrow and info icon
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "080808"))
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Color(hex: "080808"))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 0)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Title, subtitle, and info badges
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(title)
                                    .font(.custom("Inter-Bold", size: 24))
                                    .tracking(-0.48)
                                    .foregroundColor(Color(hex: "080808"))
                                
                                Text(subtitle)
                                    .font(.custom("Inter-Regular", size: 16))
                                    .tracking(-0.32)
                                    .lineSpacing(4)
                                    .foregroundColor(Color.black.opacity(0.4))
                            }
                            
                            // Info badges
                            HStack(spacing: 8) {
                                ForEach(infoBadges, id: \.text) { badge in
                                    InfoBadge(icon: badge.icon, text: badge.text)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Detail cards
                        VStack(spacing: 8) {
                            ForEach(Array(details.enumerated()), id: \.offset) { _, detail in
                                AccountDetailCard(
                                    label: detail.label,
                                    value: detail.value,
                                    copyable: detail.copyable
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                copyAllDetails()
                            }) {
                                Text("Copy all")
                                    .font(.custom("Inter-Bold", size: 16))
                                    .tracking(-0.32)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "000000"))
                                    .cornerRadius(20)
                            }
                            .buttonStyle(PressedButtonStyle())
                            
                            Button(action: {
                                shareDetails()
                            }) {
                                Text("Share")
                                    .font(.custom("Inter-Bold", size: 16))
                                    .tracking(-0.32)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "000000"))
                                    .cornerRadius(20)
                            }
                            .buttonStyle(PressedButtonStyle())
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func copyAllDetails() {
        var text = ""
        for detail in details {
            let cleanValue = detail.value.replacingOccurrences(of: "\n", with: ", ")
            text += "\(detail.label): \(cleanValue)\n"
        }
        UIPasteboard.general.string = text
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func shareDetails() {
        var shareText = "\(title)\n\n"
        for detail in details {
            let cleanValue = detail.value.replacingOccurrences(of: "\n", with: ", ")
            shareText += "\(detail.label): \(cleanValue)\n"
        }
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Info Badge

struct InfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "7B7B7B"))
                .frame(width: 12, height: 12)
            
            Text(text)
                .font(.custom("Inter-Regular", size: 14))
                .tracking(-0.28)
                .foregroundColor(Color(hex: "7B7B7B"))
        }
        .padding(.leading, 6)
        .padding(.trailing, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "F7F7F7"))
        .cornerRadius(8)
    }
}

// MARK: - Account Detail Card

struct AccountDetailCard: View {
    let label: String
    let value: String
    var copyable: Bool = false
    @State private var copied = false
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundColor(Color.black.opacity(0.4))
                
                Text(value)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(Color(hex: "080808"))
            }
            
            Spacer()
            
            if copyable {
                Button(action: {
                    UIPasteboard.general.string = value.replacingOccurrences(of: "\n", with: ", ")
                    copied = true
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                }) {
                    if copied {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "57CE43"))
                    } else {
                        Image("IconCopy")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color.black.opacity(0.4))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(hex: "FCFCFC"))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "F7F7F7"), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

// MARK: - Currency Row Button Style

struct CurrencyRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(configuration.isPressed ? Color(hex: "EDEDED") : Color.clear)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ReceiveSalaryView(isPresented: .constant(true))
}
