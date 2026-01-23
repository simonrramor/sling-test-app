import SwiftUI

struct BrowseStocksView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var ondoService = OndoService.shared
    @ObservedObject private var themeService = ThemeService.shared
    @State private var selectedStock: Stock? = nil
    
    // Stock definitions - available Ondo tokenized stocks to buy
    private let stockDefinitions: [(name: String, iconName: String, description: String)] = [
        ("Amazon", "StockAmazon", "Amazon is a global technology company and one of the world's largest e-commerce and cloud computing platforms."),
        ("Apple Inc", "StockApple", "Apple Inc. designs, manufactures, and markets consumer electronics, software, and services."),
        ("Coinbase", "StockCoinbase", "Coinbase is the largest cryptocurrency exchange in the United States."),
        ("Google Inc", "StockGoogle", "Alphabet Inc., Google's parent company, is a multinational technology conglomerate."),
        ("McDonalds", "StockMcDonalds", "McDonald's Corporation is the world's largest restaurant chain by revenue."),
        ("Meta", "StockMeta", "Meta Platforms, formerly Facebook, is a social technology company."),
        ("Microsoft", "StockMicrosoft", "Microsoft Corporation is a global technology leader known for Windows and Azure."),
        ("Tesla Inc", "StockTesla", "Tesla, Inc. is an electric vehicle and clean energy company."),
        ("Visa", "StockVisa", "Visa Inc. is a global payments technology company.")
    ]
    
    // Build stocks from Ondo service data
    private var allStocks: [Stock] {
        stockDefinitions.compactMap { definition in
            // Only include stocks that have Ondo tokens available
            guard ondoService.hasOndoToken(for: definition.iconName) else { return nil }
            
            if let data = ondoService.tokenData[definition.iconName] {
                return Stock(
                    name: definition.name,
                    symbol: data.symbol,
                    price: data.formattedPrice,
                    change: data.formattedChange,
                    isPositive: data.isPositive,
                    iconName: definition.iconName,
                    description: definition.description,
                    isOndo: true,
                    ondoSymbol: data.symbol
                )
            } else {
                let ondoSymbol = ondoService.ondoSymbol(for: definition.iconName) ?? "---"
                return Stock(
                    name: definition.name,
                    symbol: ondoSymbol,
                    price: "---",
                    change: "---",
                    isPositive: true,
                    iconName: definition.iconName,
                    description: definition.description,
                    isOndo: true,
                    ondoSymbol: ondoSymbol
                )
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeService.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Stocks list
                        ForEach(allStocks) { stock in
                            StockRowView(stock: stock) {
                                selectedStock = stock
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Stocks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeService.textPrimaryColor)
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedStock) { stock in
            StockDetailView(stock: stock)
        }
        .onAppear {
            Task {
                await ondoService.fetchAllTokens()
            }
        }
    }
}

// MARK: - Stock Row View

struct StockRowView: View {
    @ObservedObject private var themeService = ThemeService.shared
    let stock: Stock
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Stock icon
                Image(stock.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                
                // Name and symbol
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.name)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text(stock.symbol)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                Spacer()
                
                // Price and change
                VStack(alignment: .trailing, spacing: 2) {
                    Text(stock.price)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    HStack(spacing: 4) {
                        Image(systemName: stock.isPositive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                        Text(stock.change)
                            .font(.custom("Inter-Regular", size: 14))
                    }
                    .foregroundColor(stock.isPositive ? Color(hex: "57CE43") : Color(hex: "E30000"))
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BrowseStocksView(isPresented: .constant(true))
}
