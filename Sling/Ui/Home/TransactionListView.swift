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
    @StateObject private var activityService = ActivityService.shared
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
    @StateObject private var activityService = ActivityService.shared
    @ObservedObject private var themeService = ThemeService.shared
    
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
                ForEach(activityService.activities) { activity in
                    ActivityRowView(activity: activity)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
        }
        .onAppear {
            Task {
                await activityService.fetchActivities()
            }
        }
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

// MARK: - Activity Row View

struct ActivityRowView: View {
    @ObservedObject private var themeService = ThemeService.shared
    let activity: ActivityItem
    @State private var showDetail = false
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            TransactionAvatarView(identifier: activity.avatar)
            
            // Name and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.titleLeft)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                if !activity.subtitleLeft.isEmpty {
                    Text(activity.subtitleLeft)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Amount and subtitle
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.titleRight)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(amountColor)
                
                if !activity.subtitleRight.isEmpty {
                    Text(fixStockTicker(activity.subtitleRight))
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color(hex: "F7F7F7") : Color.clear)
        )
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            TransactionDetailView(activity: activity)
        }
    }
    
    private var amountColor: Color {
        if activity.titleRight.hasPrefix("+") {
            return Color(hex: "57CE43")
        } else if activity.titleRight.hasPrefix("-") {
            return Color(hex: "080808")
        } else {
            return Color(hex: "080808")
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
    @StateObject private var iconFetcher = AppIconFetcher()
    
    private var isInitials: Bool {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines).count <= 2
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
    
    // People have rounded avatars, businesses have square
    private var isPerson: Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        // Person if: starts with "Avatar", is initials (1-2 chars), or is a person's name (contains space and no dots)
        return trimmed.hasPrefix("Avatar") || 
               trimmed.count <= 2 || 
               (trimmed.contains(" ") && !trimmed.contains(".") && !trimmed.hasPrefix("http"))
    }
    
    private var cornerRadius: CGFloat {
        isPerson ? 22 : 10  // 22 = half of 44 for full circle, 10 for rounded square
    }
    
    var body: some View {
        if isInitials {
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
