import SwiftUI
import UIKit
import MapKit

/// Transaction detail drawer with the new card-based design
struct TransactionDetailDrawer: View {
    let activity: ActivityItem
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @State private var showSplitBill = false
    @State private var showSendView = false
    @State private var showRequestView = false
    @State private var backgroundOpacity: Double = 0
    @State private var dragOffset: CGFloat = 0
    @State private var currentDetent: DrawerDetent = .half
    @State private var showCard = false
    
    enum DrawerDetent {
        case half
        case full
    }
    
    // Get actual device corner radius
    private var deviceCornerRadius: CGFloat {
        UIScreen.displayCornerRadius
    }
    
    // Screen height for calculations
    private var screenHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 800 // Fallback
        }
        return window.bounds.height
    }
    
    // Height for half detent (50% of screen)
    private var halfHeight: CGFloat {
        screenHeight * 0.5
    }
    
    // Height for full detent (full screen minus safe area)
    private var fullHeight: CGFloat {
        screenHeight - 60 // Leave some space at top
    }
    
    // Current drawer height based on detent
    private var drawerHeight: CGFloat {
        switch currentDetent {
        case .half: return halfHeight
        case .full: return fullHeight
        }
    }
    
    // Calculate stretch scale when pulling up past full (positive dragOffset when at full and pulling up)
    private var stretchScale: CGFloat {
        guard currentDetent == .full && dragOffset > 0 else { return 1.0 }
        let stretchAmount = dragOffset / 80.0 * 0.05
        return 1.0 + min(stretchAmount, 0.05)
    }
    
    private var isOutgoing: Bool {
        activity.titleRight.hasPrefix("-")
    }
    
    // Transaction type detection
    private var transactionType: TransactionType {
        let avatar = activity.avatar
        let subtitle = activity.subtitleLeft.lowercased()
        let title = activity.titleLeft.lowercased()
        
        // Explicit card payment check first (subtitle says "card payment")
        if subtitle.contains("card payment") {
            return .cardPayment
        }
        
        // Check for add money / deposits
        if subtitle.contains("top up") || subtitle.contains("added") || 
           title.contains("top up") || title.contains("added money") ||
           (subtitle.isEmpty && !isOutgoing && (avatar.hasPrefix("Account") || avatar.contains("monzo") || avatar.contains("wise") || avatar.contains("bank"))) {
            return .addMoney
        }
        
        // Check for withdrawals
        if subtitle.contains("withdrawal") || subtitle.contains("withdrew") || 
           title.contains("withdrawal") || title.contains("atm") {
            return .withdrawal
        }
        
        // Check for transfers between accounts
        if subtitle.contains("transfer") || subtitle.contains("moved") {
            return .transferBetweenAccounts
        }
        
        // Check for savings transactions
        if subtitle.contains("saving") || subtitle.contains("interest") || title.contains("saving") {
            return .transferBetweenAccounts
        }
        
        // Check for investment/stock transactions
        if avatar.hasPrefix("Stock") || 
           subtitle.contains("stock") || subtitle.contains("invest") || 
           subtitle.contains("dividend") {
            // Check if buy or sell based on amount direction
            if isOutgoing {
                return .stockBuy
            } else {
                return .stockSell
            }
        }
        
        // P2P: person avatars or initials (but not emojis)
        // Emojis typically have unicode scalars > 255, letters/numbers don't
        let isLikelyEmoji = avatar.unicodeScalars.contains { $0.value > 255 }
        let isPersonAvatar = (!isLikelyEmoji && avatar.count <= 2) || avatar.hasPrefix("Avatar")
        
        if isPersonAvatar {
            // Check if received or sent
            if subtitle.contains("received") || !isOutgoing {
                return .p2pReceived
            } else {
                return .p2pSent
            }
        }
        
        // Card payment: merchant with domain or company name
        if isOutgoing {
            return .cardPayment
        }
        
        return .other
    }
    
    enum TransactionType {
        case cardPayment
        case p2pSent
        case p2pReceived
        case addMoney
        case withdrawal
        case transferBetweenAccounts
        case stockBuy
        case stockSell
        case other
    }
    
    // Contextual header text based on transaction type
    private var headerDescription: (prefix: String, amount: String, suffix: String) {
        // Extract amount without sign
        let amountText = activity.titleRight.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "-", with: "")
        let name = activity.titleLeft
        
        switch transactionType {
        case .p2pSent:
            return ("You sent", amountText, "to \(name)")
        case .p2pReceived:
            return ("You received", amountText, "from \(name)")
        case .cardPayment:
            return ("You spent", amountText, "at \(name)")
        case .addMoney:
            return ("You added", amountText, "from \(name)")
        case .withdrawal:
            // Savings withdrawal = taking money out of savings, so "from"
            let isSavings = activity.avatar.contains("Savings") || name.lowercased().contains("savings")
            return ("You withdrew", amountText, isSavings ? "from \(name)" : "to \(name)")
        case .transferBetweenAccounts:
            // Check for savings transactions
            let isSavings = activity.avatar.contains("Savings") || name.lowercased().contains("savings")
            if isSavings {
                // Deposits go TO savings, withdrawals come FROM savings
                let isDeposit = activity.subtitleLeft.lowercased().contains("deposit")
                return (isDeposit ? "You added" : "You withdrew", amountText, isDeposit ? "to \(name)" : "from \(name)")
            }
            // Try to parse "from X to Y" from subtitle or title
            if activity.subtitleLeft.lowercased().contains("to") {
                return ("You moved", amountText, activity.subtitleLeft)
            }
            return ("You moved", amountText, "from \(name)")
        case .stockBuy:
            // Extract ticker from subtitleRight (e.g., "+0.50 AMZN") or use stock name
            let ticker = extractTicker(from: activity.subtitleRight) ?? extractTicker(from: activity.subtitleLeft) ?? stockTickerFromName(name)
            return ("You bought", amountText, "of \(ticker)")
        case .stockSell:
            // Extract ticker from subtitleLeft (e.g., "Sold 0.50 AMZN") or subtitleRight
            let ticker = extractTicker(from: activity.subtitleLeft) ?? extractTicker(from: activity.subtitleRight) ?? stockTickerFromName(name)
            return ("You sold", amountText, "of \(ticker)")
        case .other:
            if isOutgoing {
                return ("You paid", amountText, "to \(name)")
            } else {
                return ("You received", amountText, "from \(name)")
            }
        }
    }
    
    // Extract ticker symbol from subtitle like "+0.50 AMZN", "Sold 0.50 AMZN", or "0.50 AMZNx"
    private func extractTicker(from text: String) -> String? {
        guard !text.isEmpty else { return nil }
        
        let components = text.components(separatedBy: " ")
        // Ticker is usually the last component and mostly uppercase letters
        if let lastComponent = components.last {
            // Remove trailing "x" if present (added by fixStockTicker helper)
            var ticker = lastComponent
            if ticker.hasSuffix("x") && ticker.count > 2 {
                ticker = String(ticker.dropLast())
            }
            
            // Check if it looks like a ticker (2-5 uppercase letters)
            if ticker.count >= 2 && ticker.count <= 5 && ticker == ticker.uppercased() && ticker.allSatisfy({ $0.isLetter }) {
                return ticker
            }
        }
        return nil
    }
    
    // Map stock name to ticker symbol
    private func stockTickerFromName(_ name: String) -> String {
        let nameToTicker: [String: String] = [
            "Apple": "AAPL",
            "Apple Inc": "AAPL",
            "Amazon": "AMZN",
            "Amazon.com": "AMZN",
            "Google": "GOOGL",
            "Alphabet": "GOOGL",
            "Microsoft": "MSFT",
            "Tesla": "TSLA",
            "Meta": "META",
            "Meta Platforms": "META",
            "Facebook": "META",
            "Netflix": "NFLX",
            "Nvidia": "NVDA",
            "US Bank": "USB",
            "McDonald's": "MCD",
            "Visa": "V",
            "Coinbase": "COIN",
            "Circle": "CRCL"
        ]
        
        // Try exact match first
        if let ticker = nameToTicker[name] {
            return ticker
        }
        
        // Try case-insensitive match
        let lowercasedName = name.lowercased()
        for (stockName, ticker) in nameToTicker {
            if stockName.lowercased() == lowercasedName {
                return ticker
            }
        }
        
        // Fallback to name
        return name
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissDrawer()
                }
            
            // Drawer content with dynamic height
            if showCard {
                VStack(spacing: 0) {
                    // Drawer handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Contextual header with avatar and description
                            TransactionContextHeader(
                                avatar: activity.avatar,
                                subtitleLeft: activity.subtitleLeft,
                                prefix: headerDescription.prefix,
                                amount: headerDescription.amount,
                                suffix: headerDescription.suffix,
                                isPositive: !isOutgoing
                            )
                            
                            // Action rows based on transaction type
                            actionRows
                            
                            // Info cards
                            infoCards
                            
                            // Help row
                            TransactionActionRow(
                                title: "Need help with this payment?",
                                onTap: {
                                    // TODO: Open help/support flow
                                }
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .scrollIndicators(.hidden)
                }
                .frame(maxWidth: .infinity)
                .frame(height: max(200, drawerHeight + dragOffset))
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
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .scaleEffect(
                    x: 1.0,
                    y: stretchScale,
                    anchor: .bottom
                )
                .transition(.move(edge: .bottom))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.height
                            
                            if currentDetent == .half {
                                if translation < 0 {
                                    // Dragging up from half - expand toward full
                                    // translation is negative, we want positive dragOffset
                                    let maxExpand = fullHeight - halfHeight
                                    dragOffset = min(-translation, maxExpand)
                                } else {
                                    // Dragging down from half - shrink to dismiss
                                    dragOffset = -translation
                                    let progress = min(translation / 300, 1.0)
                                    backgroundOpacity = 0.4 * (1 - progress)
                                }
                            } else {
                                // At full detent
                                if translation > 0 {
                                    // Dragging down from full - shrink toward half
                                    dragOffset = -translation
                                } else {
                                    // Dragging up past full - rubber band
                                    dragOffset = rubberBandClamp(-translation, limit: 60)
                                }
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.height
                            
                            if currentDetent == .half {
                                if translation < -100 {
                                    // Dragged up significantly - go to full
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        currentDetent = .full
                                        dragOffset = 0
                                    }
                                } else if translation > 100 {
                                    // Dragged down significantly - dismiss
                                    dismissDrawer()
                                } else {
                                    // Snap back
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                        backgroundOpacity = 0.4
                                    }
                                }
                            } else {
                                // At full detent
                                if translation > 150 {
                                    // Dragged down a lot - go to half
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        currentDetent = .half
                                        dragOffset = 0
                                    }
                                } else {
                                    // Snap back to full
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                        }
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Fade in background separately
            withAnimation(.easeOut(duration: 0.25)) {
                backgroundOpacity = 0.4
            }
            // Slide in card with spring
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showCard = true
            }
        }
        .fullScreenCover(isPresented: $showSplitBill) {
            SplitBillFromTransactionView(
                isPresented: $showSplitBill,
                payment: activity
            )
        }
        .fullScreenCover(isPresented: $showSendView) {
            SendView(
                isPresented: $showSendView,
                mode: .send,
                preselectedContact: Contact(
                    name: activity.titleLeft,
                    username: "@\(activity.titleLeft.lowercased().replacingOccurrences(of: " ", with: "_"))",
                    avatarName: activity.avatar
                )
            )
        }
        .fullScreenCover(isPresented: $showRequestView) {
            SendView(
                isPresented: $showRequestView,
                mode: .request,
                preselectedContact: Contact(
                    name: activity.titleLeft,
                    username: "@\(activity.titleLeft.lowercased().replacingOccurrences(of: " ", with: "_"))",
                    avatarName: activity.avatar
                )
            )
        }
    }
    
    // MARK: - Action Rows
    
    @ViewBuilder
    private var actionRows: some View {
        switch transactionType {
        case .cardPayment:
            TransactionActionRow(
                iconName: "TransferSplit",
                iconColor: Color(hex: "2CC2FF"),
                title: "Split the cost",
                onTap: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showSplitBill = true
                }
            )
            
        case .p2pSent:
            // Two buttons side by side
            HStack(spacing: 8) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showSendView = true
                }) {
                    Text("Send again")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showRequestView = true
                }) {
                    Text("Request")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
        case .p2pReceived:
            // Two buttons side by side
            HStack(spacing: 8) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showSendView = true
                }) {
                    Text("Send")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showRequestView = true
                }) {
                    Text("Request")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
        case .addMoney, .withdrawal, .transferBetweenAccounts, .stockBuy, .stockSell, .other:
            EmptyView()
        }
    }
    
    // MARK: - Info Cards
    
    // Check if this is a subscription transaction
    private var isSubscription: Bool {
        let merchant = activity.titleLeft.lowercased()
        let subtitle = activity.subtitleLeft.lowercased()
        
        let subscriptionKeywords = ["spotify", "netflix", "disney", "hulu", "apple music", "apple tv", 
                                     "youtube", "amazon prime", "hbo", "paramount", "peacock",
                                     "adobe", "microsoft 365", "dropbox", "icloud", "google one",
                                     "gym", "fitness", "membership", "subscription", "monthly",
                                     "audible", "kindle", "notion", "slack", "zoom", "canva"]
        
        for keyword in subscriptionKeywords {
            if merchant.contains(keyword) || subtitle.contains(keyword) {
                return true
            }
        }
        return false
    }
    
    // Generate a random next payment date (1-28 days from now)
    private var nextPaymentDate: String {
        let calendar = Calendar.current
        let daysToAdd = Int.random(in: 7...28)
        let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: nextDate)
    }
    
    // Sample locations for card payments
    private var transactionLocation: String {
        let locations = [
            "Godalming, GB",
            "London, GB",
            "Manchester, GB",
            "Bristol, GB",
            "Edinburgh, GB",
            "Birmingham, GB",
            "Liverpool, GB",
            "Oxford, GB"
        ]
        // Use merchant name hash to get consistent location
        let hash = activity.titleLeft.hashValue
        return locations[abs(hash) % locations.count]
    }
    
    // Coordinates for map (sample based on location)
    private var mapCoordinates: (lat: Double, lon: Double) {
        let location = transactionLocation
        if location.contains("Godalming") { return (51.1859, -0.6161) }
        if location.contains("London") { return (51.5074, -0.1278) }
        if location.contains("Manchester") { return (53.4808, -2.2426) }
        if location.contains("Bristol") { return (51.4545, -2.5879) }
        if location.contains("Edinburgh") { return (55.9533, -3.1883) }
        if location.contains("Birmingham") { return (52.4862, -1.8904) }
        if location.contains("Liverpool") { return (53.4084, -2.9916) }
        if location.contains("Oxford") { return (51.7520, -1.2577) }
        return (51.5074, -0.1278) // Default to London
    }
    
    private var infoCards: some View {
        VStack(spacing: 8) {
            // Map card for card payments (not subscriptions)
            if transactionType == .cardPayment && !isSubscription {
                TransactionMapCard(
                    location: transactionLocation,
                    coordinates: mapCoordinates
                )
            }
            
            // First card: Status, Date, Category, and Next Payment (for subscriptions)
            InfoCardSection {
                InfoCardRow(label: "Status", value: "Completed")
                InfoCardRow(label: "Date", value: activity.formattedDateLong)
                InfoCardRow(
                    label: "Category",
                    value: categoryInfo.name,
                    valueColor: Color(hex: "FF5113"),
                    icon: categoryInfo.icon
                )
                if isSubscription {
                    InfoCardRow(label: "Next payment", value: nextPaymentDate)
                }
            }
            
            // Second card: Fees, Total
            InfoCardSection {
                InfoCardRow(label: "Fees", value: "No fee")
                InfoCardRow(label: "Total", value: activity.titleRight, showPip: true)
            }
        }
    }
    
    private var categoryInfo: (name: String, icon: String) {
        // Savings transactions
        let title = activity.titleLeft.lowercased()
        if title.contains("savings deposit") || title.contains("savings withdrawal") {
            return ("Savings", "IconSavings")
        }
        
        // P2P transactions should be categorized as Transfers
        if transactionType == .p2pSent || transactionType == .p2pReceived {
            return ("Transfers", "arrow.up.right")
        }
        
        // Withdrawals
        if transactionType == .withdrawal {
            return ("Withdrawal", "arrow.down.circle")
        }
        
        // Add money
        if transactionType == .addMoney {
            return ("Deposit", "arrow.up.circle")
        }
        
        // Transfer between accounts
        if transactionType == .transferBetweenAccounts {
            return ("Transfer", "arrow.left.arrow.right")
        }
        
        let merchant = activity.titleLeft.lowercased()
        let subtitle = activity.subtitleLeft.lowercased()
        
        // Subscriptions - streaming services, apps, recurring payments
        let subscriptionKeywords = ["spotify", "netflix", "disney", "hulu", "apple music", "apple tv", 
                                     "youtube", "amazon prime", "hbo", "paramount", "peacock",
                                     "adobe", "microsoft 365", "dropbox", "icloud", "google one",
                                     "gym", "fitness", "membership", "subscription", "monthly",
                                     "audible", "kindle", "notion", "slack", "zoom", "canva"]
        for keyword in subscriptionKeywords {
            if merchant.contains(keyword) || subtitle.contains(keyword) {
                return ("Subscriptions", "repeat")
            }
        }
        
        // Shopping
        if merchant.contains("boot") || merchant.contains("shop") || merchant.contains("store") ||
           merchant.contains("amazon") || merchant.contains("walmart") || merchant.contains("target") {
            return ("Shopping", "bag.fill")
        }
        
        // Transport
        if merchant.contains("uber") || merchant.contains("lyft") || merchant.contains("transport") ||
           merchant.contains("taxi") || merchant.contains("train") || merchant.contains("bus") {
            return ("Transport", "car.fill")
        }
        
        // Food & Drink
        if merchant.contains("restaurant") || merchant.contains("cafe") || merchant.contains("food") ||
           merchant.contains("starbucks") || merchant.contains("mcdonald") || merchant.contains("coffee") {
            return ("Food & Drink", "fork.knife")
        }
        
        // Entertainment
        if merchant.contains("cinema") || merchant.contains("movie") || merchant.contains("theater") ||
           merchant.contains("concert") || merchant.contains("ticket") {
            return ("Entertainment", "ticket.fill")
        }
        
        return ("General", "bag.fill")
    }
    
    private func dismissDrawer() {
        // Fade out background
        withAnimation(.easeOut(duration: 0.25)) {
            backgroundOpacity = 0
        }
        // Slide out card
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            showCard = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    /// iOS-style rubber band effect for pulling past limits
    private func rubberBandClamp(_ offset: CGFloat, limit: CGFloat, coefficient: CGFloat = 0.55) -> CGFloat {
        let absOffset = abs(offset)
        let sign: CGFloat = offset < 0 ? -1 : 1
        let clamped = (1.0 - (1.0 / ((absOffset * coefficient / limit) + 1.0))) * limit
        return clamped * sign
    }
}

// MARK: - View Modifier for Transaction Detail

extension View {
    func transactionDetailDrawer(
        isPresented: Binding<Bool>,
        activity: ActivityItem?
    ) -> some View {
        self.overlay {
            if isPresented.wrappedValue, let activity = activity {
                TransactionDetailDrawer(
                    activity: activity,
                    isPresented: isPresented
                )
                .ignoresSafeArea()
            }
        }
    }
}


// MARK: - Split Bill From Transaction

struct SplitBillFromTransactionView: View {
    @Binding var isPresented: Bool
    let payment: ActivityItem
    
    var body: some View {
        SplitUserSelectionView(
            isPresented: $isPresented,
            payment: payment,
            onDismissAll: { isPresented = false }
        )
    }
}

// MARK: - Transaction Context Header

struct TransactionContextHeader: View {
    let avatar: String
    var subtitleLeft: String = ""
    let prefix: String
    let amount: String
    let suffix: String
    var isPositive: Bool = false
    
    private var styledText: AttributedString {
        var result = AttributedString()
        
        // Prefix
        var prefixPart = AttributedString(prefix + " ")
        prefixPart.foregroundColor = Color(hex: "080808")
        result.append(prefixPart)
        
        // Amount (colored)
        var amountPart = AttributedString(amount)
        amountPart.foregroundColor = isPositive ? Color(hex: "57CE43") : Color(hex: "080808")
        result.append(amountPart)
        
        // Suffix
        var suffixPart = AttributedString(" " + suffix)
        suffixPart.foregroundColor = Color(hex: "080808")
        result.append(suffixPart)
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Avatar
            TransactionAvatarLarge(identifier: avatar, subtitleLeft: subtitleLeft)
            
            // Contextual description - H2 style from Figma with colored amount
            Text(styledText)
                .font(.custom("Inter-Bold", size: 32))
                .tracking(-0.64) // -2% letter spacing
                .lineSpacing(0)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
    }
}

// MARK: - New Transaction Header (Legacy - kept for reference)

struct TransactionHeaderNew: View {
    let activity: ActivityItem
    
    private var isPositive: Bool {
        activity.titleRight.hasPrefix("+")
    }
    
    private var amountColor: Color {
        isPositive ? Color(hex: "57CE43") : Color(hex: "080808")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Large avatar (left-aligned)
            TransactionAvatarLarge(identifier: activity.avatar, subtitleLeft: activity.subtitleLeft)
            
            // Name + subtitle on left, amount on right
            HStack(alignment: .center) {
                // Left side: Name and subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.titleLeft)
                        .font(.custom("Inter-Bold", size: 28))
                        .foregroundColor(Color(hex: "080808"))
                        .lineLimit(1)
                    
                    // Subtitle (note or category)
                    if !activity.subtitleLeft.isEmpty {
                        Text(activity.subtitleLeft)
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(Color(hex: "7B7B7B"))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Right side: Amount
                Text(activity.titleRight)
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(amountColor)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}

// MARK: - Large Transaction Avatar

struct TransactionAvatarLarge: View {
    let identifier: String
    var subtitleLeft: String = ""  // Optional context for savings deposit/withdrawal
    
    private var logoURL: URL? {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if trimmed.isEmpty { return nil }
        
        if trimmed.hasPrefix("http") {
            if let url = URL(string: identifier), let host = url.host {
                return URL(string: "https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://\(host)&size=128")
            }
            return nil
        }
        
        if trimmed.contains(".") {
            return URL(string: "https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://\(trimmed)&size=128")
        }
        
        let domain = trimmed.replacingOccurrences(of: " ", with: "") + ".com"
        return URL(string: "https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://\(domain)&size=128")
    }
    
    private var isLocalAsset: Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("Avatar") || UIImage(named: trimmed) != nil
    }
    
    private var isSavingsActivity: Bool {
        identifier == "IconSavings" || identifier.contains("Savings")
    }
    
    private var isSavingsDeposit: Bool {
        subtitleLeft.lowercased().contains("deposit")
    }
    
    private var isSavingsWithdrawal: Bool {
        subtitleLeft.lowercased().contains("withdrawal")
    }
    
    // Badge colors and icons for savings transactions
    // Deposit to savings = green plus (money coming in)
    // Withdrawal from savings = purple arrow down (money going out)
    private var badgeColor: Color {
        isSavingsDeposit ? Color(hex: "78D381") : Color(hex: "9874FF")
    }
    
    private var badgeIcon: String {
        isSavingsDeposit ? "plus" : "arrow.down"
    }
    
    private var isPerson: Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("Avatar") || 
               trimmed.count <= 2 || 
               (trimmed.contains(" ") && !trimmed.contains(".") && !trimmed.hasPrefix("http"))
    }
    
    private var cornerRadius: CGFloat {
        isPerson ? 28 : 14
    }
    
    var body: some View {
        if isSavingsActivity {
            // Savings activity - show black square with plant icon (larger version)
            ZStack(alignment: .bottomTrailing) {
                // Black square background with savings icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "000000"))
                        .frame(width: 56, height: 56)
                    
                    Image("NavSavings")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                }
                
                // Badge for savings transactions
                // Deposit to savings = green plus (money coming in)
                // Withdrawal from savings = purple arrow down (money going out)
                ZStack {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: badgeIcon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(Color(hex: "F2F2F2"), lineWidth: 2.5)
                )
                .offset(x: 4, y: 4)
            }
        } else if isLocalAsset {
            Image(identifier)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        } else if let url = logoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white)
                            .frame(width: 56, height: 56)
                        
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(generateColor(for: identifier))
                            .frame(width: 56, height: 56)
                        
                        Text(String(identifier.prefix(1)).uppercased())
                            .font(.custom("Inter-Bold", size: 24))
                            .foregroundColor(.white)
                    }
                }
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(generateColor(for: identifier))
                    .frame(width: 56, height: 56)
                
                Text(String(identifier.prefix(1)).uppercased())
                    .font(.custom("Inter-Bold", size: 24))
                    .foregroundColor(.white)
            }
        }
    }
    
    private func generateColor(for text: String) -> Color {
        let colors: [Color] = [
            Color(hex: "78D381"), Color(hex: "FF6B6B"), Color(hex: "4ECDC4"),
            Color(hex: "45B7D1"), Color(hex: "96CEB4"), Color(hex: "FFEAA7"),
            Color(hex: "DDA0DD"), Color(hex: "98D8C8"), Color(hex: "F7DC6F"),
            Color(hex: "BB8FCE")
        ]
        let hash = text.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[hash % colors.count]
    }
}

// MARK: - Transaction Action Row

struct TransactionActionRow: View {
    var iconName: String? = nil
    var iconColor: Color = Color(hex: "080808")
    let title: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon container (if icon provided)
                if let iconName = iconName {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "F7F7F7"))
                            .frame(width: 44, height: 44)
                        
                        Image(iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(iconColor)
                    }
                }
                
                // Title
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "999999"))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(24)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Info Card Section

struct InfoCardSection<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(24)
    }
}

// MARK: - Transaction Map Card

struct TransactionMapCard: View {
    let location: String
    let coordinates: (lat: Double, lon: Double)
    
    @State private var mapSnapshot: UIImage? = nil
    
    var body: some View {
        VStack(spacing: 2) {
            // Map image
            GeometryReader { geometry in
                ZStack {
                    // Map background
                    if let snapshot = mapSnapshot {
                        Image(uiImage: snapshot)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: 177)
                    } else {
                        MapPlaceholderView()
                    }
                    
                    // Location pin
                    Circle()
                        .fill(Color(hex: "FF5113"))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "FF5113").opacity(0.2), lineWidth: 7)
                        )
                }
                .frame(width: geometry.size.width, height: 177)
                .clipped()
            }
            .frame(height: 177)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white, lineWidth: 6)
            )
            
            // Location row
            HStack {
                Image("IconLocationPin")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 19, height: 19)
                    .foregroundColor(Color(hex: "7B7B7B"))
                
                Spacer()
                
                Text(location)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(Color(hex: "080808"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .onAppear {
            generateMapSnapshot()
        }
    }
    
    private func generateMapSnapshot() {
        let coordinate = CLLocationCoordinate2D(latitude: coordinates.lat, longitude: coordinates.lon)
        
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        options.size = CGSize(width: 400, height: 200)
        options.scale = 3.0 // Retina scale
        options.mapType = .mutedStandard
        options.pointOfInterestFilter = .excludingAll
        options.showsBuildings = false
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot, error == nil else { return }
            
            DispatchQueue.main.async {
                self.mapSnapshot = snapshot.image
            }
        }
    }
}

// MARK: - Map Placeholder View

struct MapPlaceholderView: View {
    var body: some View {
        ZStack {
            // Gradient background that looks like a map
            LinearGradient(
                colors: [
                    Color(hex: "E8F4E8"),
                    Color(hex: "F5F5DC"),
                    Color(hex: "E8F0E8")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Road-like lines
            VStack(spacing: 30) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(height: 3)
                        .rotationEffect(.degrees(Double.random(in: -15...15)))
                }
            }
            .padding(.horizontal, 20)
            
            // Some "blocks"
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "D4D4D4").opacity(0.5))
                        .frame(width: CGFloat.random(in: 40...80), height: CGFloat.random(in: 30...60))
                }
            }
        }
        .frame(height: 177)
    }
}

// MARK: - Info Card Row

struct InfoCardRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color(hex: "080808")
    var icon: String? = nil
    var showPip: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(Color(hex: "7B7B7B"))
            
            Spacer()
            
            HStack(spacing: 6) {
                if showPip {
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 4, height: 4)
                }
                
                if let icon = icon {
                    // Check if it's a custom asset (starts with "Icon") or SF Symbol
                    if icon.hasPrefix("Icon") {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(valueColor)
                    }
                }
                
                Text(value)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(valueColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - TransactionDetailView (for screenshot mode compatibility)

struct TransactionDetailView: View {
    let activity: ActivityItem
    @State private var isPresented = true
    
    var body: some View {
        ZStack {
            Color.gray.ignoresSafeArea()
            
            TransactionDetailDrawer(
                activity: activity,
                isPresented: $isPresented
            )
        }
    }
}

#Preview("Card Payment") {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        TransactionDetailDrawer(
            activity: ActivityItem(
                avatar: "boots.com",
                titleLeft: "Boots",
                subtitleLeft: "Card payment",
                titleRight: "-£100.00",
                subtitleRight: "",
                date: Date()
            ),
            isPresented: .constant(true)
        )
    }
}

#Preview("P2P Sent") {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        TransactionDetailDrawer(
            activity: ActivityItem(
                avatar: "Avatar1",
                titleLeft: "Agustin Alvarez",
                subtitleLeft: "",
                titleRight: "-£100.00",
                subtitleRight: "",
                date: Date()
            ),
            isPresented: .constant(true)
        )
    }
}

#Preview("P2P Received") {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        TransactionDetailDrawer(
            activity: ActivityItem(
                avatar: "Avatar2",
                titleLeft: "Agustin Alvarez",
                subtitleLeft: "Received",
                titleRight: "+£100.00",
                subtitleRight: "",
                date: Date()
            ),
            isPresented: .constant(true)
        )
    }
}

#Preview("Add Money") {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        TransactionDetailDrawer(
            activity: ActivityItem(
                avatar: "AccountMonzo",
                titleLeft: "UK Bank",
                subtitleLeft: "",
                titleRight: "+£100.00",
                subtitleRight: "",
                date: Date()
            ),
            isPresented: .constant(true)
        )
    }
}

#Preview("Withdrawal") {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        TransactionDetailDrawer(
            activity: ActivityItem(
                avatar: "AccountMonzo",
                titleLeft: "UK Bank",
                subtitleLeft: "Withdrawal",
                titleRight: "-£100.00",
                subtitleRight: "",
                date: Date()
            ),
            isPresented: .constant(true)
        )
    }
}

#Preview("Transfer Between Accounts") {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        TransactionDetailDrawer(
            activity: ActivityItem(
                avatar: "AccountWise",
                titleLeft: "UK Bank",
                subtitleLeft: "from UK Bank to EU Bank",
                titleRight: "-£100.00",
                subtitleRight: "",
                date: Date()
            ),
            isPresented: .constant(true)
        )
    }
}
