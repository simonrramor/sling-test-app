import SwiftUI
import UIKit

struct SpendCategory: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let iconName: String
    let iconColor: Color
}

struct SpendView: View {
    @State private var isCardLocked = false
    @State private var showCardDetails = false
    @AppStorage("hasCard") private var hasCard = false
    
    let categories = [
        SpendCategory(name: "Groceries", amount: "$1,032", iconName: "cart.fill", iconColor: Color(hex: "78D381")),
        SpendCategory(name: "Transport", amount: "$1,032", iconName: "car.fill", iconColor: Color(hex: "74CDFF")),
        SpendCategory(name: "Shopping", amount: "$1,032", iconName: "bag.fill", iconColor: Color(hex: "FFC774"))
    ]
    
    var body: some View {
        ScrollView {
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
            }
        }
        .sheet(isPresented: $showCardDetails) {
            CardDetailsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // 3D Interactive Card
            Card3DView(isLocked: $isCardLocked, cameraFOV: 40.1)
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
            
            HStack(spacing: 8) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showCardDetails = true
                }) {
                    Text("Show details")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(TertiaryButtonStyle())
                
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCardLocked.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
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
                        Text(isCardLocked ? "Unlock" : "Lock")
                            .font(.custom("Inter-Bold", size: 16))
                            .id(isCardLocked ? "unlock" : "lock")
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(x: 5, y: 0)).animation(.spring(response: 0.3, dampingFraction: 0.7)),
                                removal: .opacity.combined(with: .offset(x: -5, y: 0)).animation(.easeOut(duration: 0.2))
                            ))
                    }
                    .foregroundColor(Color(hex: "080808"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .clipped()
                }
                .buttonStyle(TertiaryButtonStyle())
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
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "F7F7F7"))
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
            
            Spacer()
        }
    }
}

// MARK: - Card Empty State

struct CardEmptyStateCard: View {
    var onGetCard: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Text content
            VStack(spacing: 8) {
                Text("Create your Sling Card today")
                    .font(.custom("Inter-Bold", size: 32))
                    .tracking(-0.64)
                    .lineSpacing(1)
                    .foregroundColor(Color(hex: "080808"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 313)
                
                Text("Get your new virtual debit card, and start spending digital dollars around the world, with no fees.")
                    .font(.custom("Inter-Regular", size: 16))
                    .tracking(-0.32)
                    .lineSpacing(8)
                    .foregroundColor(Color(hex: "7B7B7B"))
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "F7F7F7"))
        )
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(configuration.isPressed ? Color(hex: "DFDFDF") : Color(hex: "EDEDED"))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Card Details Sheet

struct CardDetailsSheet: View {
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
    let title: String
    let value: String
    @State private var copied = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundColor(Color(hex: "999999"))
                
                Text(value)
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(Color(hex: "000000"))
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
                        .foregroundColor(copied ? Color(hex: "57CE43") : Color(hex: "000000").opacity(0.8))
                }
                .frame(width: 24, height: 24)
            }
            .contentShape(Rectangle())
        }
        .padding(16)
        .background(Color(hex: "FCFCFC"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "F7F7F7"), lineWidth: 1)
        )
    }
}

#Preview {
    SpendView()
}