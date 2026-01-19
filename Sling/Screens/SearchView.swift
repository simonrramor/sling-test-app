import SwiftUI
import UIKit

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var activityService = ActivityService.shared
    @StateObject private var stockService = StockService.shared
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Sample contacts for search
    let contacts = [
        (name: "Agustin Alvarez", username: "@agustine", avatar: "AvatarAgustinAlvarez"),
        (name: "Barry Donbeck", username: "@barry123", avatar: "AvatarBarryDonbeck"),
        (name: "Ben Johnson", username: "@ben_j", avatar: "AvatarBenJohnson"),
        (name: "Brendon Arnold", username: "@brendon_a", avatar: "AvatarBrendonArnold"),
        (name: "Carl Pattersmith", username: "@carl_p", avatar: "AvatarCarlPattersmith"),
        (name: "Eileen Farrell", username: "@eileen_f", avatar: "AvatarEileenFarrell"),
        (name: "Iben Hvid Møller", username: "@iben_hm", avatar: "AvatarIbenHvidMoller"),
        (name: "Imanmi Quansah", username: "@imanmi_q", avatar: "AvatarImanniQuansah"),
        (name: "James Rhode", username: "@james_r", avatar: "AvatarJamesRhode"),
        (name: "João Cardoso", username: "@joao_c", avatar: "AvatarJoaoCardoso"),
        (name: "Joseph Perez", username: "@joseph_p", avatar: "AvatarJosephPerez")
    ]
    
    // Stock definitions
    let stockDefinitions: [(name: String, symbol: String, iconName: String)] = [
        ("Amazon", "AMZN", "StockAmazon"),
        ("Apple Inc", "AAPL", "StockApple"),
        ("Bank of America", "BAC", "StockBankOfAmerica"),
        ("Circle", "CRCL", "StockCircle"),
        ("Coinbase", "COIN", "StockCoinbase"),
        ("Google Inc", "GOOGL", "StockGoogle"),
        ("McDonalds", "MCD", "StockMcDonalds"),
        ("Meta", "META", "StockMeta"),
        ("Microsoft", "MSFT", "StockMicrosoft"),
        ("Tesla Inc", "TSLA", "StockTesla"),
        ("Visa", "V", "StockVisa")
    ]
    
    // Filtered results
    var filteredContacts: [(name: String, username: String, avatar: String)] {
        guard !searchText.isEmpty else { return [] }
        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredTransactions: [ActivityItem] {
        guard !searchText.isEmpty else { return [] }
        return activityService.activities.filter {
            $0.titleLeft.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitleLeft.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredStocks: [(name: String, symbol: String, iconName: String)] {
        guard !searchText.isEmpty else { return [] }
        return stockDefinitions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var hasResults: Bool {
        !filteredContacts.isEmpty || !filteredTransactions.isEmpty || !filteredStocks.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search field
            HStack(spacing: 12) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(width: 36, height: 36)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "7B7B7B"))
                    
                    TextField("Search contacts, transactions, stocks...", text: $searchText)
                        .font(.custom("Inter-Regular", size: 16))
                        .focused($isSearchFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "7B7B7B"))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: "F7F7F7"))
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Results
            if searchText.isEmpty {
                // Empty state
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "CCCCCC"))
                    
                    Text("Search for anything")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
                
                Spacer()
            } else if !hasResults {
                // No results
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "CCCCCC"))
                    
                    Text("No results for \"\(searchText)\"")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
                
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Contacts section
                        if !filteredContacts.isEmpty {
                            SearchSectionHeader(title: "People")
                            
                            ForEach(filteredContacts, id: \.username) { contact in
                                SearchContactRow(
                                    name: contact.name,
                                    username: contact.username,
                                    avatar: contact.avatar
                                )
                            }
                        }
                        
                        // Stocks section
                        if !filteredStocks.isEmpty {
                            SearchSectionHeader(title: "Stocks")
                            
                            ForEach(filteredStocks, id: \.symbol) { stock in
                                SearchStockRow(
                                    name: stock.name,
                                    symbol: stock.symbol,
                                    iconName: stock.iconName,
                                    price: stockService.stockData[stock.iconName]?.formattedPrice ?? "—"
                                )
                            }
                        }
                        
                        // Transactions section
                        if !filteredTransactions.isEmpty {
                            SearchSectionHeader(title: "Transactions")
                            
                            ForEach(filteredTransactions.prefix(10)) { transaction in
                                SearchTransactionRow(activity: transaction)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .background(Color.white)
        .onAppear {
            isSearchFocused = true
        }
    }
}

// MARK: - Search Section Header

struct SearchSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.custom("Inter-Bold", size: 14))
            .foregroundColor(Color(hex: "7B7B7B"))
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
}

// MARK: - Search Contact Row

struct SearchContactRow: View {
    let name: String
    let username: String
    let avatar: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(avatar)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                Text(username)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Search Stock Row

struct SearchStockRow: View {
    let name: String
    let symbol: String
    let iconName: String
    let price: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                Text(symbol)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            
            Spacer()
            
            Text(price)
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(Color(hex: "080808"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Search Transaction Row

struct SearchTransactionRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar or initials
            if activity.avatar.count <= 2 {
                // Initials
                ZStack {
                    Circle()
                        .fill(Color(hex: "E5E5E5"))
                        .frame(width: 44, height: 44)
                    
                    Text(activity.avatar)
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(Color(hex: "080808"))
                }
            } else {
                // Image
                Image(activity.avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.titleLeft)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                if !activity.subtitleLeft.isEmpty {
                    Text(activity.subtitleLeft)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color(hex: "7B7B7B"))
                } else {
                    Text(activity.formattedDate)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(Color(hex: "7B7B7B"))
                }
            }
            
            Spacer()
            
            Text(activity.titleRight)
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(activity.titleRight.hasPrefix("+") ? Color(hex: "57CE43") : Color(hex: "080808"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    SearchView()
}
