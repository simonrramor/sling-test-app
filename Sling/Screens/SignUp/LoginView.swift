import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @State private var showSignUpFlow = false
    @State private var showStagePicker = false
    @State private var selectedStartStep: SignUpStep = .phone
    @State private var animateFeatures = false
    
    private let features: [(icon: String, title: String)] = [
        ("bolt.fill", "Send money in seconds"),
        ("chart.line.uptrend.xyaxis", "Trade stocks 24/7"),
        ("dollarsign.circle.fill", "Earn savings on your USD"),
        ("building.columns.fill", "EUR and USD accounts"),
        ("clock.fill", "Sign up in minutes")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Large heading
                    Text("The global account for global people")
                        .h1Style()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    
                    // Feature list with staggered animation
                    VStack(spacing: 24) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            FeatureRow(
                                icon: feature.icon,
                                title: feature.title,
                                isAnimated: animateFeatures,
                                delay: Double(index) * 0.12
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .onAppear {
                        // Trigger animation after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            animateFeatures = true
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom section
                    VStack(spacing: 0) {
                        // Terms and Privacy
                        Text("Read our Privacy Policy. Continue to accept the Terms of service.")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(Color(hex: "999999"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                        
                        // Buttons
                        HStack(spacing: 8) {
                            // More options button (dev: tap to skip, long press for stage picker)
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "080808"))
                                .frame(width: 56, height: 56)
                                .background(Color(hex: "EDEDED"))
                                .cornerRadius(20)
                                .onTapGesture {
                                    // Skip sign-up entirely
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    isLoggedIn = true
                                }
                                .onLongPressGesture(minimumDuration: 0.5) {
                                    // Show stage picker
                                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                                    generator.impactOccurred()
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        showStagePicker = true
                                    }
                                }
                            
                            // Continue with Apple button
                            Button(action: {
                                // Navigate to sign-up flow
                                showSignUpFlow = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 20, weight: .medium))
                                    Text("Continue with Apple")
                                        .font(.custom("Inter-Bold", size: 16))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(hex: "080808"))
                                .cornerRadius(20)
                            }
                            .buttonStyle(PressedButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 50)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showSignUpFlow) {
            SignUpFlowView(isComplete: $isLoggedIn, startStep: selectedStartStep)
                .transition(.opacity)
        }
        .overlay {
            if showStagePicker {
                SignUpStagePicker(
                    currentStep: .phone,
                    onSelectStep: { step in
                        // Set step and show flow FIRST, then hide picker
                        selectedStartStep = step
                        showSignUpFlow = true
                        showStagePicker = false
                    },
                    onDismiss: {
                        showStagePicker = false
                    },
                    onSkipToHome: {
                        // Skip directly to logged in state
                        showStagePicker = false
                        isLoggedIn = true
                    },
                    isFromWelcome: true
                )
                .transition(.opacity)
            }
        }
        .transaction { transaction in
            // Disable the default fullScreenCover animation
            if showSignUpFlow {
                transaction.disablesAnimations = true
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    var isAnimated: Bool = true
    var delay: Double = 0
    
    @State private var appeared = false
    @State private var iconBounce = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container with bounce animation
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "FF5113").opacity(0.05))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "FF5113"))
                    .scaleEffect(iconBounce ? 1.0 : 0.6)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0)
                            .delay(delay + 0.15),
                        value: iconBounce
                    )
            }
            
            // Title
            Text(title)
                .font(.custom("Inter-Bold", size: 18))
                .foregroundColor(Color(hex: "080808"))
            
            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
                .delay(delay),
            value: appeared
        )
        .onChange(of: isAnimated) { _, newValue in
            if newValue {
                appeared = true
                iconBounce = true
            }
        }
        .onAppear {
            // If not using external animation control, animate immediately
            if isAnimated && !appeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    appeared = true
                    iconBounce = true
                }
            }
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}
