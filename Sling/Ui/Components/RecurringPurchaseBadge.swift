import SwiftUI

/// A small badge that indicates a stock has a recurring purchase set up
struct RecurringPurchaseBadge: View {
    let recurringPurchase: RecurringPurchase?
    let compact: Bool
    
    init(for stockIconName: String, compact: Bool = false) {
        self.recurringPurchase = RecurringPurchaseService.shared.getRecurringPurchase(for: stockIconName)
        self.compact = compact
    }
    
    var body: some View {
        if let purchase = recurringPurchase {
            HStack(spacing: 4) {
                Image(systemName: "repeat")
                    .font(.system(size: compact ? 10 : 12, weight: .medium))
                
                if !compact {
                    Text(purchase.frequency.shortDisplayName)
                        .font(.custom("Inter-Medium", size: 10))
                }
            }
            .foregroundColor(Color(hex: DesignSystem.Colors.primary))
            .padding(.horizontal, compact ? 4 : 6)
            .padding(.vertical, 2)
            .background(Color(hex: "FFF5F0"))
            .cornerRadius(6)
        }
    }
}

/// Enhanced ListRow that includes recurring purchase badge
struct StockListRow: View {
    let stock: Stock
    let trailing: String
    let trailingColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Stock icon
                Image(stock.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(stock.name)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: DesignSystem.Colors.dark))
                        
                        RecurringPurchaseBadge(for: stock.iconName, compact: true)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(stock.symbol)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(Color(hex: DesignSystem.Colors.textSecondary))
                        
                        Spacer()
                        
                        Text(trailing)
                            .font(.custom("Inter-Medium", size: 14))
                            .foregroundColor(trailingColor)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct RecurringPurchaseBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Apple Inc")
                    .font(.custom("Inter-Bold", size: 16))
                
                RecurringPurchaseBadge(for: "StockApple")
                
                Spacer()
            }
            
            HStack {
                Text("Tesla Inc")
                    .font(.custom("Inter-Bold", size: 16))
                
                RecurringPurchaseBadge(for: "StockTesla", compact: true)
                
                Spacer()
            }
        }
        .padding()
    }
}