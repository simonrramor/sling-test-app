import SwiftUI
import UIKit
import Combine

// MARK: - Stock Ticker Helper

/// Adds "x" suffix to stock tickers that don't already have it
private func fixStockTicker(_ text: String) -> String {
    let tickers = ["AAPL", "AMZN", "GOOGL", "META", "MSFT", "TSLA", "BAC", "MCD", "V", "COIN", "CRCL"]
    var result = text
    for ticker in tickers {
        if result.hasSuffix(ticker) && !result.hasSuffix(ticker + "x") {
            result = result.replacingOccurrences(of: ticker, with: ticker + "x")
        }
    }
    return result
}

// MARK: - Transaction List View

struct TransactionListView: View {
    @ObservedObject private var activityService = ActivityService.shared
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        ScrollView {
            TransactionListContent()
        }
        .scrollIndicators(.hidden)
        .onAppear {
            Task {
                await activityService.fetchActivities()
            }
        }
        .refreshable {
            await activityService.fetchActivities(force: true)
        }
    }
}

// MARK: - Transaction List Content (without ScrollView, for embedding)

struct TransactionListContent: View {
    @ObservedObject private var activityService = ActivityService.shared
    @ObservedObject private var themeService = ThemeService.shared
    
    /// Maximum number of transactions to show (nil = show all)
    var limit: Int? = nil
    /// Callback when "See more" is tapped
    var onSeeMore: (() -> Void)? = nil
    /// Callback when a transaction is selected (for external drawer handling)
    var onTransactionSelected: ((ActivityItem) -> Void)? = nil
    
    @State private var selectedActivity: ActivityItem?
    @State private var showDetail = false
    
    /// Whether to handle drawer internally (legacy behavior) or externally
    private var handlesDrawerInternally: Bool {
        onTransactionSelected == nil
    }
    
    private var displayedActivities: [ActivityItem] {
        if let limit = limit {
            return Array(activityService.activities.prefix(limit))
        }
        return activityService.activities
    }
    
    private var hasMoreActivities: Bool {
        if let limit = limit {
            return activityService.activities.count > limit
        }
        return false
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            if activityService.isLoading {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if activityService.activities.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    Text("No recent activity")
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Activity Rows (flat list, no section headers)
                ForEach(displayedActivities) { activity in
                    if let onTransactionSelected = onTransactionSelected {
                        // External handling - just call the callback
                        ActivityRowView(
                            activity: activity,
                            onTap: { onTransactionSelected(activity) }
                        )
                    } else {
                        // Internal handling - use bindings
                        ActivityRowView(
                            activity: activity,
                            selectedActivity: $selectedActivity,
                            showDetail: $showDetail
                        )
                    }
                }
                .padding(.top, 4)
                
                // "See more" row if there are more activities
                if hasMoreActivities, let onSeeMore = onSeeMore {
                    Divider()
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    Button(action: onSeeMore) {
                        HStack {
                            Text("See more")
                                .font(.custom("Inter-SemiBold", size: 16))
                                .foregroundColor(Color(hex: "FF5113"))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "FF5113"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await activityService.fetchActivities()
            }
        }
        .modifier(ConditionalDrawerModifier(
            isPresented: $showDetail,
            activity: selectedActivity,
            enabled: handlesDrawerInternally
        ))
    }
    
    // Group activities by date (e.g., "Today", "Yesterday", "16 January 2026")
    private var groupedActivities: [(title: String, activities: [ActivityItem])] {
        var groups: [String: [ActivityItem]] = [:]
        var orderedKeys: [String] = []
        
        for activity in activityService.activities {
            let section = activity.sectionTitle
            if groups[section] == nil {
                orderedKeys.append(section)
                groups[section] = []
            }
            groups[section]?.append(activity)
        }
        
        return orderedKeys.map { (title: $0, activities: groups[$0] ?? []) }
    }
}

// MARK: - Conditional Drawer Modifier

struct ConditionalDrawerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let activity: ActivityItem?
    let enabled: Bool
    
    func body(content: Content) -> some View {
        if enabled {
            content.transactionDetailDrawer(isPresented: $isPresented, activity: activity)
        } else {
            content
        }
    }
}

// MARK: - Activity Row View

struct ActivityRowView: View {
    @ObservedObject private var themeService = ThemeService.shared
    let activity: ActivityItem
    
    // Option 1: Binding-based (internal drawer handling)
    var selectedActivity: Binding<ActivityItem?>?
    var showDetail: Binding<Bool>?
    
    // Option 2: Callback-based (external drawer handling)
    var onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    // Convenience init for binding-based usage
    init(activity: ActivityItem, selectedActivity: Binding<ActivityItem?>, showDetail: Binding<Bool>) {
        self.activity = activity
        self.selectedActivity = selectedActivity
        self.showDetail = showDetail
        self.onTap = nil
    }
    
    // Convenience init for callback-based usage
    init(activity: ActivityItem, onTap: @escaping () -> Void) {
        self.activity = activity
        self.selectedActivity = nil
        self.showDetail = nil
        self.onTap = onTap
    }
    
    // Check if this is a savings activity (Home feed shows from main balance perspective)
    private var isSavingsActivity: Bool {
        activity.avatar == "IconSavings" || activity.avatar.contains("Savings")
    }
    
    // For Home feed: invert savings amounts (deposits leave main balance, withdrawals return to it)
    private var displayAmount: String {
        guard isSavingsActivity else { return activity.titleRight }
        
        // Invert the sign for savings transactions on Home feed
        let amount = activity.titleRight
        if amount.hasPrefix("+") {
            // Deposit to savings = negative for main balance
            return "-" + amount.dropFirst()
        } else if amount.hasPrefix("-") {
            // Withdrawal from savings = positive for main balance
            return "+" + amount.dropFirst()
        }
        return amount
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar - pass subtitle for context (e.g., to differentiate deposit/withdrawal)
            TransactionAvatarView(identifier: activity.avatar, subtitleLeft: activity.subtitleLeft)
            
            // Name and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.titleLeft)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                    .lineLimit(1)
                
                if !activity.subtitleLeft.isEmpty {
                    Text(activity.subtitleLeft)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Amount and subtitle
            VStack(alignment: .trailing, spacing: 2) {
                Text(displayAmount)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(amountColor)
                
                if !activity.subtitleRight.isEmpty {
                    Text(fixStockTicker(activity.subtitleRight))
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(.gray)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isPressed ? (themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F7F7F7")) : Color.clear)
        )
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            if let onTap = onTap {
                // External handling via callback
                onTap()
            } else {
                // Internal handling via bindings
                selectedActivity?.wrappedValue = activity
                showDetail?.wrappedValue = true
            }
        }
    }
    
    private var amountColor: Color {
        if displayAmount.hasPrefix("+") {
            return Color(hex: "57CE43")
        } else {
            return themeService.textPrimaryColor
        }
    }
}

// MARK: - App Icon Fetcher

class AppIconFetcher: ObservableObject {
    @Published var iconURL: URL?
    @Published var isLoading = false
    
    func fetchAppIcon(for companyName: String) {
        let searchTerm = companyName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? companyName
        let urlString = "https://itunes.apple.com/search?term=\(searchTerm)&entity=software&limit=1"
        
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let results = json["results"] as? [[String: Any]],
                      let firstResult = results.first,
                      let artworkUrl = firstResult["artworkUrl512"] as? String ?? firstResult["artworkUrl100"] as? String,
                      let iconURL = URL(string: artworkUrl) else {
                    return
                }
                
                self?.iconURL = iconURL
            }
        }.resume()
    }
}

// MARK: - Transaction Avatar View

struct TransactionAvatarView: View {
    @ObservedObject private var themeService = ThemeService.shared
    let identifier: String
    var subtitleLeft: String = ""  // Optional subtitle for context (e.g., "Deposit" or "Withdrawal")
    @StateObject private var iconFetcher = AppIconFetcher()
    
    private var isInitials: Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        // Must be 1-2 characters AND not contain emojis (emojis have unicode scalars > 255)
        let isLikelyEmoji = trimmed.unicodeScalars.contains { $0.value > 255 }
        return trimmed.count <= 2 && !isLikelyEmoji
    }
    
    private var isSFSymbol: Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        // SF Symbols typically have specific patterns like "person.fill", "cart.fill"
        return trimmed.contains(".") && !trimmed.contains(" ") && !trimmed.hasPrefix("http") && UIImage(systemName: trimmed) != nil
    }
    
    private var isLocalAsset: Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        // Check if it's a local asset (starts with "Avatar", "Account", "Stock", or exists in bundle)
        return trimmed.hasPrefix("Avatar") || trimmed.hasPrefix("Account") || trimmed.hasPrefix("Stock") || UIImage(named: trimmed) != nil
    }
    
    // Check if this is a savings activity
    private var isSavingsActivity: Bool {
        identifier == "IconSavings" || identifier.contains("Savings")
    }
    
    // Determine if this is a deposit or withdrawal based on subtitle
    private var isSavingsDeposit: Bool {
        subtitleLeft.lowercased().contains("deposit")
    }
    
    // For Home feed: badges should reflect main balance perspective (inverted from savings)
    // Deposit to savings = money leaving main balance = purple arrow down
    // Withdrawal from savings = money returning = green plus
    private var badgeColorForHome: Color {
        isSavingsDeposit ? Color(hex: "9874FF") : Color(hex: "78D381")
    }
    
    private var badgeIconForHome: String {
        isSavingsDeposit ? "arrow.down" : "plus"
    }
    
    // People have rounded avatars, businesses have square
    private var isPerson: Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        // Person if: starts with "Avatar", is initials (1-2 chars, not emoji), or is a person's name (contains space and no dots)
        let isLikelyEmoji = trimmed.unicodeScalars.contains { $0.value > 255 }
        return trimmed.hasPrefix("Avatar") || 
               (trimmed.count <= 2 && !isLikelyEmoji) || 
               (trimmed.contains(" ") && !trimmed.contains(".") && !trimmed.hasPrefix("http"))
    }
    
    private var cornerRadius: CGFloat {
        isPerson ? 22 : 10  // 22 = half of 44 for full circle, 10 for rounded square
    }
    
    var body: some View {
        if isSavingsActivity {
            // Savings activity - show black square with plant icon and badge
            ZStack(alignment: .bottomTrailing) {
                // Black square background with savings icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "000000"))
                        .frame(width: 44, height: 44)
                    
                    Image("NavSavings")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                }
                
                // Badge - reflects main balance perspective (inverted from savings)
                // Deposit to savings = money leaving = purple arrow down
                // Withdrawal from savings = money returning = green plus
                ZStack {
                    Circle()
                        .fill(badgeColorForHome)
                        .frame(width: 14, height: 14)
                    
                    Image(systemName: badgeIconForHome)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(themeService.cardBackgroundColor, lineWidth: 2)
                )
                .offset(x: 4, y: 4)
            }
        } else if isInitials {
            // Initials (1-2 characters) - always person, so rounded
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                
                Text(identifier.uppercased())
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundColor(themeService.textPrimaryColor)
            }
        } else if isLocalAsset {
            // Local asset image - person avatars are rounded
            Image(identifier)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        } else if isSFSymbol {
            // SF Symbol - business style (square)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                
                Image(systemName: identifier)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(themeService.textPrimaryColor)
            }
        } else if let url = iconFetcher.iconURL {
            // App icon from iTunes - always square with rounded corners
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                case .failure:
                    // Fallback to initials on failure
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                        
                        Text(String(identifier.prefix(1)).uppercased())
                            .font(.custom("Inter-Bold", size: 18))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                @unknown default:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                }
            }
        } else if iconFetcher.isLoading {
            // Loading state while fetching app icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                ProgressView()
                    .scaleEffect(0.6)
            }
        } else if !isPerson && !isInitials && !isLocalAsset && !isSFSymbol {
            // Business - show initials while loading or as fallback
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                
                Text(String(identifier.prefix(1)).uppercased())
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundColor(themeService.textPrimaryColor)
            }
            .onAppear {
                iconFetcher.fetchAppIcon(for: identifier)
            }
        } else {
            // Fallback to initials
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                
                Text(String(identifier.prefix(1)).uppercased())
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundColor(themeService.textPrimaryColor)
            }
        }
    }
    
    // Generate a consistent color based on text
    private func generateColor(for text: String) -> Color {
        let colors: [Color] = [
            Color(hex: "78D381"), // Green
            Color(hex: "FF6B6B"), // Red
            Color(hex: "4ECDC4"), // Teal
            Color(hex: "45B7D1"), // Blue
            Color(hex: "96CEB4"), // Sage
            Color(hex: "FFEAA7"), // Yellow
            Color(hex: "DDA0DD"), // Plum
            Color(hex: "98D8C8"), // Mint
            Color(hex: "F7DC6F"), // Gold
            Color(hex: "BB8FCE")  // Purple
        ]
        
        let hash = text.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[hash % colors.count]
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    @ObservedObject private var themeService = ThemeService.shared
    let title: String
    
    var body: some View {
        Text(title)
            .font(.custom("Inter-Bold", size: 16))
            .foregroundColor(themeService.textPrimaryColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    TransactionListView()
}
