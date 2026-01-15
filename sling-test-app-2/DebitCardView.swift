import SwiftUI

struct DebitCardView: View {
    @State private var showCardNumber = false
    
    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.55, blue: 0.35),
                            Color(red: 1.0, green: 0.45, blue: 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Decorative circles
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 40)
                .frame(width: 200, height: 200)
                .offset(x: 50, y: 0)
            
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 30)
                .frame(width: 280, height: 280)
                .offset(x: 80, y: 20)
            
            // Card Content
            VStack(alignment: .leading, spacing: 8) {
                // Balance
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("€1,000.00")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white.opacity(0.8))
                                .rotationEffect(.degrees(90))
                                .accessibilityHidden(true)
                        }
                        
                        Text("114.90 USDP")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Card Number & Visa
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 12) {
                        // Card number with show/hide
                        HStack(spacing: 6) {
                            Text(showCardNumber ? "4532 1234 5678 9543" : "•••• 9543")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .accessibilityLabel(showCardNumber ? "Card number: 4532 1234 5678 9543" : "Card number hidden, ending in 9543")
                            
                            Button(action: {
                                withAnimation {
                                    showCardNumber.toggle()
                                }
                            }) {
                                Image(systemName: showCardNumber ? "eye.slash" : "eye")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .accessibilityLabel(showCardNumber ? "Hide card number" : "Show card number")
                        }
                        
                        // VISA logo
                        Text("VISA")
                            .font(.system(size: 28, weight: .bold))
                            .italic()
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(24)
        }
        .frame(height: 200)
        .shadow(color: Color.orange.opacity(0.4), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    DebitCardView()
        .padding()
}
