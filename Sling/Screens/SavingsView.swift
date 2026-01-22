import SwiftUI

struct SavingsView: View {
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Balance card
                savingsBalanceCard
                
                // Empty state / Getting started
                savingsEmptyState
            }
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
    }
    
    // MARK: - Savings Balance Card
    
    private var savingsBalanceCard: some View {
        VStack(spacing: 8) {
            Text("Total savings")
                .font(.custom("Inter-Medium", size: 16))
                .foregroundColor(themeService.textSecondaryColor)
            
            Text("$0.00")
                .font(.custom("Inter-Bold", size: 42))
                .foregroundColor(themeService.textPrimaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Empty State
    
    private var savingsEmptyState: some View {
        VStack(spacing: 24) {
            // Plant icons floating
            ZStack {
                // Background circles
                Circle()
                    .fill(Color(hex: "E8F5E9"))
                    .frame(width: 120, height: 120)
                
                // Plant icon
                Image("NavSavings")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .foregroundColor(Color(hex: "4CAF50"))
            }
            .padding(.bottom, 8)
            
            // Text content
            VStack(spacing: 8) {
                Text("Start growing your savings")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(themeService.textPrimaryColor)
                    .multilineTextAlignment(.center)
                
                Text("Set money aside automatically and watch your savings grow over time.")
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(themeService.textSecondaryColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Create savings button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                // TODO: Create savings goal action
            }) {
                Text("Create savings goal")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "4CAF50"))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeService.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(themeService.cardBorderColor ?? Color.clear, lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }
}

#Preview {
    SavingsView()
}
