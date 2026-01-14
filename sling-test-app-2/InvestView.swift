import SwiftUI

struct Stock: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let price: String
    let change: String
    let isPositive: Bool
    let iconName: String
}

struct InvestView: View {
    @State private var selectedPeriod = "1D"
    let periods = ["1H", "1D", "1W", "1M", "1Y", "All"]
    
    let stocks = [
        Stock(name: "Apple Inc", symbol: "APPLx", price: "$277.59", change: "0.42%", isPositive: false, iconName: "apple.logo"),
        Stock(name: "Circle", symbol: "CRCLx", price: "$277.59", change: "0.42%", isPositive: false, iconName: "circle.fill"),
        Stock(name: "Meta", symbol: "METAx", price: "$650.47", change: "0.42%", isPositive: false, iconName: "m.circle.fill")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Portfolio Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Your portfolio")
                            .font(.custom("Inter28pt-Medium", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "57CE43"))
                        
                        Text("$0.13")
                            .font(.custom("Inter28pt-Medium", size: 16))
                            .foregroundColor(Color(hex: "57CE43"))
                    }
                    
                    Text("$2,541.01")
                        .font(.custom("Inter18pt-Bold", size: 33))
                        .foregroundColor(Color(hex: "080808"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                // Chart Area
                ChartView()
                    .frame(height: 140)
                    .padding(.vertical, 16)
                
                // Time Period Selector
                HStack {
                    ForEach(periods, id: \.self) { period in
                        Button(action: {
                            selectedPeriod = period
                        }) {
                            Text(period)
                                .font(.custom(selectedPeriod == period ? "Inter28pt-Medium" : "Inter18pt-Regular", size: 14))
                                .foregroundColor(selectedPeriod == period ? Color(hex: "080808") : Color(hex: "7B7B7B"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(selectedPeriod == period ? Color(hex: "F7F7F7") : Color.clear)
                                .cornerRadius(8)
                        }
                        
                        if period != periods.last {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
                
                // Your Stocks Section
                VStack(alignment: .leading, spacing: 0) {
                    Text("Your stocks")
                        .font(.custom("Inter18pt-Bold", size: 16))
                        .foregroundColor(Color(hex: "7B7B7B"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    ForEach(stocks) { stock in
                        StockRow(stock: stock)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 16)
                
                Spacer()
            }
        }
    }
}

struct ChartView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Sample chart data points
            let points: [CGFloat] = [0.5, 0.4, 0.6, 0.3, 0.7, 0.5, 0.8, 0.6, 0.65, 0.55]
            
            Path { path in
                for (index, point) in points.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(points.count - 1)
                    let y = height * (1 - point)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color(hex: "080808"), lineWidth: 2)
            
            // End dot
            let lastX = width
            let lastY = height * (1 - points.last!)
            Circle()
                .fill(Color(hex: "080808"))
                .frame(width: 9, height: 9)
                .position(x: lastX, y: lastY)
        }
        .padding(.horizontal, 24)
    }
}

struct StockRow: View {
    let stock: Stock
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: stock.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                )
            
            // Name and Symbol
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name)
                    .font(.custom("Inter18pt-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                Text(stock.symbol)
                    .font(.custom("Inter18pt-Regular", size: 14))
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            
            Spacer()
            
            // Price and Change
            VStack(alignment: .trailing, spacing: 2) {
                Text(stock.price)
                    .font(.custom("Inter18pt-Bold", size: 16))
                    .foregroundColor(Color(hex: "080808"))
                
                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    Text(stock.change)
                        .font(.custom("Inter18pt-Regular", size: 14))
                }
                .foregroundColor(stock.isPositive ? Color(hex: "57CE43") : Color(hex: "E30000"))
            }
        }
        .padding(16)
    }
}

#Preview {
    InvestView()
}