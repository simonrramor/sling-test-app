import SwiftUI
import UIKit

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            icon: "arrow.left.arrow.right",
            title: "Send Money Instantly",
            description: "Pay friends and family anywhere in the world with zero fees. It's as simple as sending a message.",
            color: "FF5113"
        ),
        OnboardingPage(
            icon: "creditcard.fill",
            title: "Spend Anywhere",
            description: "Get a virtual or physical card to spend your balance anywhere Visa is accepted.",
            color: "3167FC"
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Invest & Grow",
            description: "Buy fractional shares of your favorite companies and watch your portfolio grow.",
            color: "57CE43"
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Safe & Secure",
            description: "Your money is protected with bank-level security and biometric authentication.",
            color: "080808"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("Skip")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color(hex: "7B7B7B"))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .frame(height: 44)
            
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color(hex: "080808") : Color(hex: "E5E5E5"))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.bottom, 32)
            
            // Continue button
            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            }) {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "080808"))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white)
    }
    
    private func completeOnboarding() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation {
            isComplete = true
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: page.color).opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: page.color))
            }
            
            // Title
            Text(page.title)
                .font(.custom("Inter-Bold", size: 28))
                .foregroundColor(Color(hex: "080808"))
                .multilineTextAlignment(.center)
            
            // Description
            Text(page.description)
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(Color(hex: "7B7B7B"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
}
