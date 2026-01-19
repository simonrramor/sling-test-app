import SwiftUI
import UIKit

struct ComponentShowcaseView: View {
    @Binding var isPresented: Bool
    @State private var sampleAmount: String = "123"
    @State private var chartPeriod: String = "1D"
    @State private var chartIsDragging: Bool = false
    @State private var chartDragProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "080808"))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: "EDEDED"))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Text("Component Showcase")
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundColor(Color(hex: "080808"))
                    
                    Spacer()
                    
                    // Invisible spacer to balance
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Buttons
                        ComponentSection(title: "PrimaryButton (Orange)") {
                            PrimaryButton(title: "Primary Button", isEnabled: true) {}
                        }
                        
                        ComponentSection(title: "PrimaryButton (Disabled)") {
                            PrimaryButton(title: "Disabled Button", isEnabled: false) {}
                        }
                        
                        ComponentSection(title: "SecondaryButton (Black)") {
                            SecondaryButton(title: "Secondary Button", isEnabled: true) {}
                        }
                        
                        ComponentSection(title: "SecondaryButton (Disabled)") {
                            SecondaryButton(title: "Disabled Button", isEnabled: false) {}
                        }
                        
                        ComponentSection(title: "TertiaryButton (Grey)") {
                            TertiaryButton(title: "Tertiary Button", isEnabled: true) {}
                        }
                        
                        ComponentSection(title: "TertiaryButton (Disabled)") {
                            TertiaryButton(title: "Disabled Button", isEnabled: false) {}
                        }
                        
                        // MARK: - List Row
                        ComponentSection(title: "ListRow") {
                            ListRow(
                                iconName: "StockApple",
                                title: "Apple Inc.",
                                subtitle: "AAPL"
                            ) {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("$178.50")
                                        .font(.custom("Inter-Bold", size: 16))
                                        .foregroundColor(Color(hex: "080808"))
                                    Text("+2.34%")
                                        .font(.custom("Inter-Regular", size: 14))
                                        .foregroundColor(Color(hex: "00C853"))
                                }
                            }
                        }
                        
                        ComponentSection(title: "ListRow (Negative)") {
                            ListRow(
                                iconName: "StockGoogle",
                                title: "Alphabet Inc.",
                                subtitle: "GOOGL"
                            ) {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("$142.30")
                                        .font(.custom("Inter-Bold", size: 16))
                                        .foregroundColor(Color(hex: "080808"))
                                    Text("-1.25%")
                                        .font(.custom("Inter-Regular", size: 14))
                                        .foregroundColor(Color(hex: "E30000"))
                                }
                            }
                        }
                        
                        // MARK: - Number Pad
                        ComponentSection(title: "NumberPadView") {
                            NumberPadView(amountString: $sampleAmount)
                                .frame(height: 280)
                        }
                        
                        // MARK: - Sliding Number Text
                        ComponentSection(title: "SlidingNumberText") {
                            SlidingNumberText(
                                text: "$12,345.67",
                                font: .custom("Inter-Bold", size: 36),
                                color: Color(hex: "080808")
                            )
                        }
                        
                        // MARK: - Balance View
                        ComponentSection(title: "BalanceView") {
                            BalanceView()
                        }
                        
                        // MARK: - Chart View
                        ComponentSection(title: "ChartView") {
                            ChartView(
                                selectedPeriod: $chartPeriod,
                                isDragging: $chartIsDragging,
                                dragProgress: $chartDragProgress
                            )
                                .frame(height: 200)
                        }
                        
                        // MARK: - Header View
                        ComponentSection(title: "HeaderView") {
                            HeaderView(onProfileTap: {})
                        }
                        
                        // MARK: - Transaction Avatar
                        ComponentSection(title: "TransactionAvatarView") {
                            HStack(spacing: 16) {
                                VStack {
                                    TransactionAvatarView(identifier: "AvatarProfile")
                                    Text("Person")
                                        .font(.custom("Inter-Regular", size: 12))
                                        .foregroundColor(Color(hex: "7B7B7B"))
                                }
                                VStack {
                                    TransactionAvatarView(identifier: "netflix.com")
                                    Text("Business")
                                        .font(.custom("Inter-Regular", size: 12))
                                        .foregroundColor(Color(hex: "7B7B7B"))
                                }
                                VStack {
                                    TransactionAvatarView(identifier: "JD")
                                    Text("Initials")
                                        .font(.custom("Inter-Regular", size: 12))
                                        .foregroundColor(Color(hex: "7B7B7B"))
                                }
                            }
                        }
                        
                        // MARK: - Debit Card Widget
                        ComponentSection(title: "DebitCardWidget") {
                            DebitCardWidget()
                        }
                        
                        // MARK: - Bottom Nav
                        ComponentSection(title: "BottomNavView") {
                            BottomNavView(selectedTab: .constant(.home))
                        }
                        
                        // MARK: - Colors
                        ComponentSection(title: "Color Palette") {
                            VStack(spacing: 8) {
                                ColorSwatch(name: "Primary Orange", hex: "FF5113")
                                ColorSwatch(name: "Primary Dark", hex: "080808")
                                ColorSwatch(name: "Secondary Text", hex: "7B7B7B")
                                ColorSwatch(name: "Background", hex: "F7F7F7")
                                ColorSwatch(name: "Border", hex: "EDEDED")
                                ColorSwatch(name: "Green", hex: "00C853")
                                ColorSwatch(name: "Red", hex: "E30000")
                            }
                        }
                        
                        // MARK: - Typography
                        ComponentSection(title: "Typography") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Inter-Bold 36pt")
                                    .font(.custom("Inter-Bold", size: 36))
                                Text("Inter-Bold 24pt")
                                    .font(.custom("Inter-Bold", size: 24))
                                Text("Inter-Bold 18pt")
                                    .font(.custom("Inter-Bold", size: 18))
                                Text("Inter-Bold 16pt")
                                    .font(.custom("Inter-Bold", size: 16))
                                Text("Inter-Medium 16pt")
                                    .font(.custom("Inter-Medium", size: 16))
                                Text("Inter-Regular 16pt")
                                    .font(.custom("Inter-Regular", size: 16))
                                Text("Inter-Regular 14pt")
                                    .font(.custom("Inter-Regular", size: 14))
                            }
                            .foregroundColor(Color(hex: "080808"))
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}

// MARK: - Component Section
struct ComponentSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(Color(hex: "7B7B7B"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "F7F7F7"))
                )
            
            content
        }
    }
}

// MARK: - Color Swatch
struct ColorSwatch: View {
    let name: String
    let hex: String
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: hex))
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom("Inter-Medium", size: 14))
                    .foregroundColor(Color(hex: "080808"))
                Text("#\(hex)")
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundColor(Color(hex: "7B7B7B"))
            }
            
            Spacer()
        }
    }
}

#Preview {
    ComponentShowcaseView(isPresented: .constant(true))
}
