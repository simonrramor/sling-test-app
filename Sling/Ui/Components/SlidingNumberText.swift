import SwiftUI

struct SlidingNumberText: View {
    let text: String
    let font: Font
    let color: Color
    
    var body: some View {
        if #available(iOS 17.0, *) {
            // Use the native numeric text transition for iOS 17+
            Text(text)
                .font(font)
                .foregroundColor(color)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: false))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text)
        } else {
            // Fallback to custom character animation for older iOS
            AnimatedDigitsView(text: text, font: font, color: color)
        }
    }
}

// MARK: - Fallback for iOS < 17

private struct AnimatedDigitsView: View {
    let text: String
    let font: Font
    let color: Color
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(font)
                    .foregroundColor(color)
                    .monospacedDigit()
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5).combined(with: .opacity).combined(with: .offset(y: -10)),
                        removal: .scale(scale: 0.5).combined(with: .opacity).combined(with: .offset(y: 10))
                    ))
                    .id("\(index)-\(character)")
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: text)
    }
}

// MARK: - Animated Amount Text (for larger displays)

struct AnimatedAmountText: View {
    let amount: String
    let fontSize: CGFloat
    let color: Color
    
    init(amount: String, fontSize: CGFloat = 56, color: Color = Color(hex: "080808")) {
        self.amount = amount
        self.fontSize = fontSize
        self.color = color
    }
    
    var body: some View {
        if #available(iOS 17.0, *) {
            Text(amount)
                .font(.custom("Inter-Bold", size: fontSize))
                .foregroundColor(color)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: false))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: amount)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        } else {
            HStack(spacing: 0) {
                ForEach(Array(amount.enumerated()), id: \.offset) { index, character in
                    SingleDigitView(
                        character: character,
                        fontSize: fontSize,
                        color: color,
                        index: index
                    )
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: amount)
            .minimumScaleFactor(0.5)
        }
    }
}

private struct SingleDigitView: View {
    let character: Character
    let fontSize: CGFloat
    let color: Color
    let index: Int
    
    var body: some View {
        Text(String(character))
            .font(.custom("Inter-Bold", size: fontSize))
            .foregroundColor(color)
            .monospacedDigit()
            .transition(.asymmetric(
                insertion: .scale(scale: 0.6).combined(with: .opacity).combined(with: .offset(y: -8)),
                removal: .scale(scale: 0.6).combined(with: .opacity).combined(with: .offset(y: 8))
            ))
            .id("\(index)-\(character)")
    }
}

#Preview {
    VStack(spacing: 40) {
        SlidingNumberText(
            text: "$8,800.10",
            font: .custom("Inter-Bold", size: 32),
            color: Color(hex: "080808")
        )
        
        AnimatedAmountText(amount: "£1,234.56")
    }
}
