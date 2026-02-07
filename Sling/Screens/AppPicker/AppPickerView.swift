import SwiftUI

// MARK: - App Variant Definitions

enum AppVariant: String, CaseIterable, Identifiable {
    case newNavMVP = "new_nav_mvp"
    case investmentsMVP = "investments_mvp"
    case future = "future"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .newNavMVP: return "New nav MVP"
        case .investmentsMVP: return "Investments MVP"
        case .future: return "future"
        }
    }
    
    var subtitle: String {
        switch self {
        case .newNavMVP: return "Refreshed navigation & home experience"
        case .investmentsMVP: return "Stock trading & portfolio management"
        case .future: return "Coming soon..."
        }
    }
    
    var iconName: String {
        switch self {
        case .newNavMVP: return "rectangle.3.group"
        case .investmentsMVP: return "chart.line.uptrend.xyaxis"
        case .future: return "sparkles"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .newNavMVP:
            return [Color(hex: "FF5113"), Color(hex: "FF8A5C")]
        case .investmentsMVP:
            return [Color(hex: "0887DC"), Color(hex: "5AC8FA")]
        case .future:
            return [Color(hex: "8E8E93"), Color(hex: "BBBBC0")]
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .newNavMVP, .investmentsMVP: return true
        case .future: return false
        }
    }
}

// MARK: - App Picker View

struct AppPickerView: View {
    let onSelectVariant: (AppVariant) -> Void
    
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header area
                VStack(spacing: 8) {
                    Text("sling")
                        .font(.custom("Inter-Bold", size: 20))
                        .foregroundColor(Color(hex: "080808").opacity(0.3))
                        .tracking(-0.4)
                        .padding(.top, 16)
                    
                    Text("Prototypes")
                        .font(.custom("Inter-Bold", size: 40))
                        .foregroundColor(Color(hex: "080808"))
                        .tracking(-0.8)
                    
                    Text("Choose a version to explore")
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .tracking(-0.32)
                }
                .padding(.top, 40)
                .padding(.bottom, 40)
                
                // Cards
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(Array(AppVariant.allCases.enumerated()), id: \.element.id) { index, variant in
                            AppVariantCard(
                                variant: variant,
                                index: index,
                                appeared: appeared,
                                onTap: {
                                    if variant.isAvailable {
                                        onSelectVariant(variant)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - App Variant Card

struct AppVariantCard: View {
    let variant: AppVariant
    let index: Int
    let appeared: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(variant.title)
                        .font(.custom("Inter-Bold", size: 22))
                        .foregroundColor(Color(hex: "080808"))
                        .tracking(-0.44)
                    
                    Spacer()
                    
                    if variant.isAvailable {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "080808").opacity(0.35))
                    } else {
                        Text("Soon")
                            .font(.custom("Inter-Medium", size: 13))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "080808").opacity(0.05))
                            )
                    }
                }
                
                Text(variant.subtitle)
                    .font(.custom("Inter-Regular", size: 15))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .tracking(-0.3)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            .opacity(variant.isAvailable ? 1.0 : 0.6)
        }
        .buttonStyle(CardPressStyle())
        .disabled(!variant.isAvailable)
        .offset(y: appeared ? 0 : 40)
        .opacity(appeared ? 1 : 0)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.8)
                .delay(Double(index) * 0.1),
            value: appeared
        )
    }
}

// MARK: - Card Press Button Style

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Environment Key for Selected Variant

private struct SelectedAppVariantKey: EnvironmentKey {
    static let defaultValue: AppVariant? = nil
}

extension EnvironmentValues {
    var selectedAppVariant: AppVariant? {
        get { self[SelectedAppVariantKey.self] }
        set { self[SelectedAppVariantKey.self] = newValue }
    }
}

// MARK: - Preview

#Preview {
    AppPickerView(onSelectVariant: { variant in
        print("Selected: \(variant.title)")
    })
}
