import SwiftUI
import UIKit
import LocalAuthentication

struct SpendCategory: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let iconName: String
    let iconColor: Color
}

struct SpendView: View {
    @Binding var showSubscriptionsOverlay: Bool
    
    @State private var isCardLocked = false
    @State private var showCardDetails = false
    @AppStorage("hasCard") private var hasCard = false
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject private var displayCurrencyService = DisplayCurrencyService.shared
    
    // Spending data in USD (base currency)
    private let spentThisMonthUSD: Double = 3430
    @State private var spentThisMonthDisplay: Double = 3430
    @State private var exchangeRate: Double = 1.0
    
    private let exchangeRateService = ExchangeRateService.shared
    
    // Shadow control sliders
    @State private var shadowOpacity: Double = 0.25
    @State private var shadowRadius: Double = 20
    @State private var shadowOffsetX: Double = 0
    @State private var shadowOffsetY: Double = 10
    @State private var showShadowControls = false
    
    // Category spending in USD
    private let categoriesUSD: [(name: String, amountUSD: Double, iconName: String, iconColor: Color)] = [
        ("Groceries", 1032, "cart.fill", Color(hex: "78D381")),
        ("Restaurants", 856, "fork.knife", Color(hex: "A78BFA")),
        ("Shopping", 1032, "bag.fill", Color(hex: "FFC774")),
        ("Transfers", 520, "arrow.left.arrow.right", Color(hex: "74CDFF")),
        ("Utilities", 245, "doc.text.fill", Color(hex: "6366F1")),
        ("Home", 380, "house.fill", Color(hex: "A5B4FC")),
        ("Entertainment", 290, "tv.fill", Color(hex: "5EEAD4")),
        ("Health", 175, "heart.fill", Color(hex: "FB7185")),
        ("Gift", 120, "gift.fill", Color(hex: "F472B6")),
        ("Finances", 95, "banknote.fill", Color(hex: "4ADE80")),
        ("Investments", 450, "chart.line.uptrend.xyaxis", Color(hex: "4ADE80")),
        ("Education", 200, "book.fill", Color(hex: "67E8F9")),
        ("General", 150, "slider.horizontal.3", Color(hex: "9CA3AF")),
        ("Transport", 320, "car.fill", Color(hex: "60A5FA")),
        ("Holidays", 680, "umbrella.fill", Color(hex: "FDBA74"))
    ]
    
    private var categories: [SpendCategory] {
        let symbol = ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
        return categoriesUSD.map { cat in
            let displayAmount = displayCurrencyService.displayCurrency == "USD" ? cat.amountUSD : cat.amountUSD * exchangeRate
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            let formattedNumber = formatter.string(from: NSNumber(value: displayAmount)) ?? String(format: "%.0f", displayAmount)
            return SpendCategory(name: cat.name, amount: "\(symbol)\(formattedNumber)", iconName: cat.iconName, iconColor: cat.iconColor)
        }
    }
    
    private var formattedSpentThisMonth: String {
        let symbol = ExchangeRateService.symbol(for: displayCurrencyService.displayCurrency)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        let formattedNumber = formatter.string(from: NSNumber(value: spentThisMonthDisplay)) ?? String(format: "%.0f", spentThisMonthDisplay)
        return "\(symbol)\(formattedNumber)"
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if hasCard {
                    // Card content
                    cardContent
                } else {
                    // Empty state
                    VStack(spacing: 0) {
                        // Card illustration from Figma
                        Image("CardEmptyIllustration")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                        
                        CardEmptyStateCard(onGetCard: {
                            withAnimation {
                                hasCard = true
                            }
                        })
                        .padding(.horizontal, 24)
                    }
                }
                
                // Bottom padding for scroll content to clear nav bar
                Spacer()
                    .frame(height: 120)
            }
        }
        .background(themeService.backgroundColor)
        .sheet(isPresented: $showCardDetails) {
            CardDetailsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.white)
        }
        .onAppear {
            fetchExchangeRate()
        }
        .onChange(of: displayCurrencyService.displayCurrency) { _, _ in
            fetchExchangeRate()
        }
    }
    
    private func fetchExchangeRate() {
        let currency = displayCurrencyService.displayCurrency
        guard currency != "USD" else {
            spentThisMonthDisplay = spentThisMonthUSD
            exchangeRate = 1.0
            return
        }
        
        Task {
            if let rate = await exchangeRateService.getRate(from: "USD", to: currency) {
                await MainActor.run {
                    exchangeRate = rate
                    spentThisMonthDisplay = spentThisMonthUSD * rate
                }
            }
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // 3D Interactive Card
            Card3DView(isLocked: $isCardLocked, cameraFOV: 40.1, backgroundColor: themeService.backgroundColor, onTap: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showShadowControls.toggle()
                }
            })
            .frame(height: 240)
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .overlay(
                Group {
                    if isCardLocked {
                        // Lock icon in center
                        Image("LockLockedIcon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                    }
                }
            )
            .padding(.top, 16)
            
            // Shadow Controls
            if showShadowControls {
                VStack(spacing: 12) {
                    HStack {
                        Text("Shadow Controls")
                            .font(.custom("Inter-Bold", size: 14))
                            .foregroundColor(themeService.textSecondaryColor)
                        Spacer()
                        Button(action: {
                            withAnimation { showShadowControls = false }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeService.textTertiaryColor)
                        }
                    }
                    
                    ShadowSlider(label: "Opacity", value: $shadowOpacity, range: 0...1, format: "%.2f")
                    ShadowSlider(label: "Radius", value: $shadowRadius, range: 0...50, format: "%.0f")
                    ShadowSlider(label: "Offset X", value: $shadowOffsetX, range: -30...30, format: "%.0f")
                    ShadowSlider(label: "Offset Y", value: $shadowOffsetY, range: -30...30, format: "%.0f")
                }
                .padding(16)
                .background(themeService.backgroundSecondaryColor)
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            
            HStack(spacing: 8) {
                TertiaryButton(title: "Show details") {
                    authenticateAndShowDetails()
                }
                
                TertiaryButton(title: isCardLocked ? "Unlock" : "Lock") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCardLocked.toggle()
                    }
                } icon: {
                    ZStack {
                        Image("LockIcon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .opacity(isCardLocked ? 0 : 1)
                            .scaleEffect(isCardLocked ? 0.8 : 1)
                        
                        Image("LockLockedIcon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .opacity(isCardLocked ? 1 : 0)
                            .scaleEffect(isCardLocked ? 1 : 0.8)
                    }
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isCardLocked)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Spent this month (1st Dec – 1st Jan)")
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(themeService.textSecondaryColor)
                
                Text(formattedSpentThisMonth)
                    .font(.custom("Inter-Bold", size: 33))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeService.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories) { category in
                        CategoryCard(category: category)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 8)
            
            // Subscriptions card - tappable
            Button(action: {
                showSubscriptionsOverlay = true
            }) {
                HStack(spacing: 16) {
                    // Single subscription avatar
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "F7F7F7"))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hex: "74CDFF"))
                    }
                    
                    Text("Track your subscriptions")
                        .font(.custom("Inter-Bold", size: 16))
                        .tracking(-0.32) // -2% of 16px
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Spacer()
                    
                    Text("12")
                        .font(.custom("Inter-Regular", size: 16))
                        .tracking(-0.32) // -2% of 16px
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeService.textTertiaryColor)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeService.cardBackgroundColor)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
        }
    }
    
    // MARK: - Biometric Authentication
    
    private func authenticateAndShowDetails() {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to view your card details"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        showCardDetails = true
                    } else {
                        // Biometric failed, try device passcode as fallback
                        authenticateWithPasscode()
                    }
                }
            }
        } else {
            // Biometrics not available, fall back to device passcode
            authenticateWithPasscode()
        }
    }
    
    private func authenticateWithPasscode() {
        let context = LAContext()
        let reason = "Authenticate to view your card details"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    showCardDetails = true
                }
                // If passcode also fails, just don't show details (user cancelled or failed)
            }
        }
    }
}

// MARK: - Card Empty State

struct CardEmptyStateCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    var onGetCard: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Text content
            VStack(spacing: 8) {
                Text("Create your Sling Card today")
                    .font(.custom("Inter-Bold", size: 32))
                    .tracking(-0.64)
                    .lineSpacing(1)
                    .foregroundColor(themeService.textPrimaryColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 313)
                
                Text("Get your new virtual debit card, and start spending digital dollars around the world, with no fees.")
                    .font(.custom("Inter-Regular", size: 16))
                    .tracking(-0.32)
                    .lineSpacing(8)
                    .foregroundColor(themeService.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }
            
            // Create card button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onGetCard()
            }) {
                Text("Create Sling Card")
                    .font(.custom("Inter-Bold", size: 16))
                    .tracking(-0.32)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "000000"))
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}

struct CategoryCard: View {
    @ObservedObject private var themeService = ThemeService.shared
    let category: SpendCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            RoundedRectangle(cornerRadius: 7)
                .fill(category.iconColor)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: category.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
                
                Text(category.amount)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeService.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
        )
    }
}


// MARK: - Card Details Sheet

struct CardDetailsSheet: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Mock card data
    let cardDetails = [
        CardDetailRow(title: "Name on card", value: "John Taylor"),
        CardDetailRow(title: "Card number", value: "4532 1234 5678 9012"),
        CardDetailRow(title: "Expiry date", value: "10/29"),
        CardDetailRow(title: "CVV", value: "123"),
        CardDetailRow(title: "Billing address", value: "1801 Main St.\nKansas City\nMO 64108")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Card detail rows
            VStack(spacing: 8) {
                ForEach(cardDetails) { detail in
                    CardDetailField(title: detail.title, value: detail.value)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 8)
            
            Spacer()
        }
        .background(Color.white)
    }
}

struct CardDetailRow: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct CardDetailField: View {
    @ObservedObject private var themeService = ThemeService.shared
    let title: String
    let value: String
    @State private var copied = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundColor(themeService.textTertiaryColor)
                
                Text(value)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            
            Spacer()
            
            // Copy button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                UIPasteboard.general.string = value.replacingOccurrences(of: "\n", with: ", ")
                copied = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    copied = false
                }
            }) {
                ZStack {
                    Image(systemName: copied ? "checkmark" : "square.on.square")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(copied ? Color(hex: "57CE43") : themeService.textPrimaryColor.opacity(0.8))
                }
                .frame(width: 24, height: 24)
            }
            .contentShape(Rectangle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "FCFCFC"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "F7F7F7"), lineWidth: 1)
        )
    }
}

// MARK: - Shadow Slider

struct ShadowSlider: View {
    @ObservedObject private var themeService = ThemeService.shared
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundColor(themeService.textSecondaryColor)
                Spacer()
                Text(String(format: format, value))
                    .font(.custom("Inter-Medium", size: 12))
                    .foregroundColor(themeService.textPrimaryColor)
                    .frame(width: 50, alignment: .trailing)
            }
            Slider(value: $value, in: range)
                .tint(Color(hex: "FF5113"))
        }
    }
}

// MARK: - Subscription Model

struct Subscription: Identifiable {
    let id = UUID()
    let name: String
    let dayOfMonth: Int
    let imageName: String? // Asset image name
    let fallbackColor: String // Fallback color if no image
}

// MARK: - Subscriptions Sheet

// MARK: - Custom Subscriptions Card Overlay

struct SubscriptionsCardOverlay: View {
    @Binding var isPresented: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var showCard = false
    @State private var selectedActivity: ActivityItem? = nil
    @State private var showingDetail = false
    @Namespace private var animation
    
    // Get actual device corner radius
    private var deviceCornerRadius: CGFloat {
        UIScreen.displayCornerRadius
    }
    
    // Calculate stretch scale when pulling up (negative dragOffset)
    private var stretchScale: CGFloat {
        guard dragOffset < 0 else { return 1.0 }
        let stretchAmount = abs(dragOffset) / 150.0 * 0.08
        return 1.0 + min(stretchAmount, 0.08)
    }
    
    /// iOS-style rubber band effect for pulling past limits
    private func rubberBandClamp(_ offset: CGFloat, limit: CGFloat, coefficient: CGFloat = 0.55) -> CGFloat {
        let absOffset = abs(offset)
        let sign: CGFloat = offset < 0 ? -1 : 1
        let clamped = (1.0 - (1.0 / ((absOffset * coefficient / limit) + 1.0))) * limit
        return clamped * sign
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background - fades in
            Color.black.opacity(showCard ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    if showingDetail {
                        // Go back to calendar
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showingDetail = false
                            selectedActivity = nil
                        }
                    } else {
                        dismissCard()
                    }
                }
                .animation(.easeOut(duration: 0.25), value: showCard)
            
            // Card that hugs content - slides up
            if showCard {
                VStack(spacing: 0) {
                    // Drag indicator
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(hex: "D9D9D9"))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, showingDetail ? 8 : 24)
                    
                    // Content - morphs between calendar and detail
                    if showingDetail, let activity = selectedActivity {
                        SubscriptionDetailContent(
                            activity: activity,
                            onBack: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showingDetail = false
                                    selectedActivity = nil
                                }
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                    } else {
                        SubscriptionCalendarView(
                            onSubscriptionTap: { activity in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedActivity = activity
                                    showingDetail = true
                                }
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                    }
                }
                .background(Color(hex: "F2F2F2"))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 40,
                        bottomLeadingRadius: deviceCornerRadius,
                        bottomTrailingRadius: deviceCornerRadius,
                        topTrailingRadius: 40,
                        style: .continuous
                    )
                )
                .compositingGroup()
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .scaleEffect(
                    x: 1.0,
                    y: stretchScale,
                    anchor: .bottom
                )
                .offset(y: dragOffset > 0 ? dragOffset : 0)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.height
                            
                            if translation > 0 {
                                // Dragging down - allow freely for dismiss
                                dragOffset = translation
                            } else {
                                // Dragging up - apply rubber band stretch effect
                                dragOffset = rubberBandClamp(translation, limit: 150)
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                dismissCard()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showCard = true
            }
        }
    }
    
    private func dismissCard() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            showCard = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Subscription Detail Content (inline in the card)

struct SubscriptionDetailContent: View {
    let activity: ActivityItem
    let onBack: () -> Void
    @ObservedObject private var themeService = ThemeService.shared
    
    private var isOutgoing: Bool {
        activity.titleRight.hasPrefix("-")
    }
    
    // Check if this is a subscription
    private var isSubscription: Bool {
        true // Always true since this is shown for subscriptions
    }
    
    // Generate next payment date
    private var nextPaymentDate: String {
        let calendar = Calendar.current
        let daysToAdd = Int.random(in: 7...28)
        let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: nextDate)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.custom("Inter-Medium", size: 16))
                    }
                    .foregroundColor(themeService.textSecondaryColor)
                }
                Spacer()
            }
            
            // Header with avatar and description
            VStack(alignment: .leading, spacing: 16) {
                // Avatar
                SubscriptionDetailAvatar(identifier: activity.avatar)
                
                // Description
                Text("You paid \(activity.titleRight.replacingOccurrences(of: "-", with: "")) to \(activity.titleLeft)")
                    .font(.custom("Inter-Bold", size: 32))
                    .tracking(-0.64)
                    .foregroundColor(themeService.textPrimaryColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            
            // Info cards
            VStack(spacing: 8) {
                // First card: Status, Date, Category, Next payment
                VStack(spacing: 0) {
                    InfoCardRow(label: "Status", value: "Completed")
                    InfoCardRow(label: "Date", value: activity.formattedDateLong)
                    InfoCardRow(
                        label: "Category",
                        value: "Subscriptions",
                        valueColor: Color(hex: "FF5113"),
                        icon: "repeat"
                    )
                    InfoCardRow(label: "Next payment", value: nextPaymentDate)
                }
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(16)
                
                // Second card: Fees, Total
                VStack(spacing: 0) {
                    InfoCardRow(label: "Fees", value: "No fee")
                    InfoCardRow(label: "Total", value: activity.titleRight, showPip: true)
                }
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(16)
            }
            
            // Help row
            Button(action: {
                // TODO: Open help
            }) {
                HStack(spacing: 16) {
                    Text("Need help with this payment?")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "999999"))
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Subscription Detail Avatar

struct SubscriptionDetailAvatar: View {
    let identifier: String
    
    var body: some View {
        if UIImage(named: identifier) != nil {
            Image(identifier)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "F5F5F5"))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(identifier.prefix(1)).uppercased())
                        .font(.custom("Inter-Bold", size: 24))
                        .foregroundColor(Color(hex: "7B7B7B"))
                )
        }
    }
}

struct SubscriptionsSheet: View {
    var body: some View {
        VStack(spacing: 0) {
            // Calendar
            SubscriptionCalendarView()
                .padding(.horizontal, 24)
                .padding(.top, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .presentationBackground(Color.white)
    }
}

// MARK: - Subscription Calendar View

struct SubscriptionCalendarView: View {
    var onSubscriptionTap: ((ActivityItem) -> Void)? = nil
    
    @ObservedObject private var themeService = ThemeService.shared
    @State private var selectedSubscription: Subscription? = nil
    @State private var showSubscriptionDetail = false
    @State private var selectedActivity: ActivityItem? = nil
    @State private var showTransactionDetail = false
    
    private let calendar = Calendar.current
    private let today = Date()
    
    // Sample subscriptions dotted throughout the month
    private let subscriptions: [Subscription] = [
        Subscription(name: "Spotify", dayOfMonth: 1, imageName: "SubscriptionSpotify", fallbackColor: "1DB954"),
        Subscription(name: "Netflix", dayOfMonth: 8, imageName: "SubscriptionNetflix", fallbackColor: "E50914"),
        Subscription(name: "Apple Music", dayOfMonth: 12, imageName: "SubscriptionAppleMusic", fallbackColor: "FC3C44"),
        Subscription(name: "Hulu", dayOfMonth: 15, imageName: "SubscriptionHulu", fallbackColor: "1CE783"),
        Subscription(name: "Disney+", dayOfMonth: 20, imageName: "SubscriptionDisney", fallbackColor: "113CCF"),
        Subscription(name: "Apple TV", dayOfMonth: 25, imageName: "SubscriptionAppleTV", fallbackColor: "000000")
    ]
    
    private func subscription(for day: Int) -> Subscription? {
        subscriptions.first { $0.dayOfMonth == day }
    }
    
    private var currentMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDay = currentMonth
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        // Adjust for Monday start (weekday 1 = Sunday, so Monday = 2)
        let offset = (firstWeekday + 5) % 7
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    // Sample monthly costs for each subscription
    private let monthlyCosts: [String: Double] = [
        "Spotify": 10.99,
        "Netflix": 15.99,
        "Apple Music": 10.99,
        "Hulu": 17.99,
        "Disney+": 13.99,
        "Apple TV": 9.99
    ]
    
    // Calculate total subscription cost
    private var totalSubsCost: String {
        let total = subscriptions.reduce(0.0) { sum, sub in
            sum + (monthlyCosts[sub.name] ?? 0)
        }
        return String(format: "$%.2f", total)
    }
    
    // Create an ActivityItem from a subscription for the transaction detail drawer
    private func activityItem(for subscription: Subscription) -> ActivityItem {
        let cost = monthlyCosts[subscription.name] ?? 0
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.day = subscription.dayOfMonth
        let date = calendar.date(from: components) ?? Date()
        
        return ActivityItem(
            avatar: subscription.imageName ?? subscription.name,
            titleLeft: subscription.name,
            subtitleLeft: "Subscription",
            titleRight: String(format: "-$%.2f", cost),
            subtitleRight: "",
            date: date
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Total spent on subs header
            VStack(alignment: .leading, spacing: 4) {
                Text("Total spent on subs")
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
                
                Text(totalSubsCost)
                    .font(.custom("Inter-Bold", size: 33))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 4)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.custom("Inter-Medium", size: 12))
                        .foregroundColor(themeService.textSecondaryColor)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid (use VStack/HStack instead of LazyVGrid for animation)
            let cellWidth: CGFloat = 44
            let cellHeight: CGFloat = 56
            let rows = daysInMonth.chunked(into: 7)
            VStack(spacing: 4) {
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 4) {
                        ForEach(Array(row.enumerated()), id: \.offset) { colIndex, date in
                    if let date = date {
                        let dayNumber = calendar.component(.day, from: date)
                        let isToday = calendar.isDateInToday(date)
                        let sub = subscription(for: dayNumber)
                        
                        VStack(spacing: 8) {
                            // Subscription indicator at top (or spacer if none)
                            if let sub = sub {
                                if let imageName = sub.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 16, height: 16)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.06), lineWidth: 0.67)
                                        )
                                } else {
                                    Circle()
                                        .fill(Color(hex: sub.fallbackColor))
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.06), lineWidth: 0.67)
                                        )
                                }
                            } else {
                                Spacer()
                                    .frame(height: 16)
                            }
                            
                            // Date number at bottom
                            Text("\(dayNumber)")
                                .font(.custom(isToday ? "Inter-Bold" : "Inter-Medium", size: 9))
                                .foregroundColor(isToday ? .white : themeService.textPrimaryColor)
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .frame(width: cellWidth, height: cellHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isToday ? Color(hex: "080808") : Color.white)
                        )
                        .onTapGesture {
                            if let sub = sub {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                let activity = activityItem(for: sub)
                                
                                if let callback = onSubscriptionTap {
                                    // Use callback for inline morph animation
                                    callback(activity)
                                } else {
                                    // Fallback to drawer
                                    selectedActivity = activity
                                    showTransactionDetail = true
                                }
                            }
                        }
                    } else {
                        Color.clear
                            .frame(width: cellWidth, height: cellHeight)
                    }
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .transactionDetailDrawer(
            isPresented: $showTransactionDetail,
            activity: selectedActivity
        )
    }
}

// MARK: - Subscription Detail Sheet

struct SubscriptionDetailSheet: View {
    let subscription: Subscription
    @ObservedObject private var themeService = ThemeService.shared
    
    // Sample monthly costs
    private let monthlyCosts: [String: Double] = [
        "Spotify": 10.99,
        "Netflix": 15.99,
        "Apple Music": 10.99,
        "Hulu": 17.99,
        "Disney+": 13.99,
        "Apple TV": 9.99
    ]
    
    private var cost: Double {
        monthlyCosts[subscription.name] ?? 0
    }
    
    private var paymentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.day = subscription.dayOfMonth
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(subscription.dayOfMonth) January 2026"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with subscription icon and name
            VStack(spacing: 16) {
                if let imageName = subscription.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: subscription.fallbackColor))
                        .frame(width: 64, height: 64)
                }
                
                Text(subscription.name)
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            // Transaction details
            VStack(spacing: 0) {
                SubscriptionDetailRow(label: "Amount", value: String(format: "-$%.2f", cost))
                SubscriptionDetailRow(label: "Date", value: paymentDate)
                SubscriptionDetailRow(label: "Category", value: "Subscriptions")
                SubscriptionDetailRow(label: "Payment method", value: "Sling Card ••••9543")
                SubscriptionDetailRow(label: "Status", value: "Completed", valueColor: Color(hex: "57CE43"))
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct SubscriptionDetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color(hex: "080808")
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(Color(hex: "7B7B7B"))
            
            Spacer()
            
            Text(value)
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Array Chunking Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    SpendView(showSubscriptionsOverlay: .constant(false))
}