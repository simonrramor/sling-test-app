import SwiftUI

struct SpendCategory: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let iconName: String
    let iconColor: Color
}

struct SpendView: View {
    let categories = [
        SpendCategory(name: "Groceries", amount: "$1,032", iconName: "cart.fill", iconColor: Color(hex: "78D381")),
        SpendCategory(name: "Transport", amount: "$1,032", iconName: "car.fill", iconColor: Color(hex: "74CDFF")),
        SpendCategory(name: "Shopping", amount: "$1,032", iconName: "bag.fill", iconColor: Color(hex: "FFC774"))
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                DebitCardWidget()
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Text("Show details")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(Color(hex: "080808"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "EDEDED"))
                            .cornerRadius(20)
                    }
                    
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                            Text("Lock")
                                .font(.custom("Inter-Bold", size: 16))
                        }
                        .foregroundColor(Color(hex: "080808"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "EDEDED"))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spent this month (1st Dec – 1st Jan)")
                        .font(.custom("Inter-Medium", size: 16))
                        .foregroundColor(Color(hex: "7B7B7B"))
                    
                    Text("$3,430")
                        .font(.custom("Inter-Bold", size: 33))
                        .foregroundColor(Color(hex: "080808"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories) { category in
                            CategoryCard(category: category)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 8)
                
                Spacer()
            }
        }
    }
}

struct DebitCardWidget: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "FF5113"))
            
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 80)
                .frame(width: 200, height: 200)
                .offset(x: 80, y: 0)
            
            VStack(alignment: .leading) {
                SlingLogoShape()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                
                Spacer()
                
                HStack {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 4, height: 4)
                            }
                        }
                        
                        Text("9543")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("VISA")
                        .font(.system(size: 24, weight: .bold))
                        .italic()
                        .foregroundColor(.white)
                }
            }
            .padding(16)
        }
        .frame(height: 196)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.25), radius: 22, x: 0, y: 24)
    }
}

struct SlingLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = size * 0.45
        let innerRadius = size * 0.25
        
        path.addArc(center: center, radius: radius, startAngle: .degrees(-45), endAngle: .degrees(225), clockwise: false)
        path.move(to: CGPoint(x: center.x + innerRadius, y: center.y))
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        
        return path.strokedPath(StrokeStyle(lineWidth: size * 0.12, lineCap: .round))
    }
}

struct CategoryCard: View {
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
                    .foregroundColor(Color(hex: "7B7B7B"))
                
                Text(category.amount)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(.black)
            }
        }
        .padding(16)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    SpendView()
}