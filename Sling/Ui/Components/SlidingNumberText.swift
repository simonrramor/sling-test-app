import SwiftUI

// MARK: - NumberFlow-style Sliding Number Text

struct SlidingNumberText: View {
    let text: String
    let font: Font
    let color: Color
    var trend: NumberTrend = .auto
    
    var body: some View {
        NumberFlowView(
            text: text,
            font: font,
            color: color,
            trend: trend
        )
    }
}

// MARK: - Number Trend Direction

enum NumberTrend {
    case up      // Digits always spin upward
    case down    // Digits always spin downward
    case auto    // Each digit spins based on whether it increased or decreased
}

// MARK: - NumberFlow View (Main Component)

struct NumberFlowView: View {
    let text: String
    let font: Font
    let color: Color
    var trend: NumberTrend = .auto
    
    // Parse the text into characters
    private var characters: [NumberFlowCharacter] {
        text.enumerated().map { index, char in
            NumberFlowCharacter(
                id: index,
                character: char,
                isDigit: char.isNumber
            )
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(characters) { char in
                if char.isDigit {
                    SpinningDigitView(
                        digit: char.character,
                        font: font,
                        color: color,
                        trend: trend
                    )
                    .id(char.id)
                } else {
                    // Non-digit characters (currency symbols, commas, periods)
                    Text(String(char.character))
                        .font(font)
                        .foregroundColor(color)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: text)
    }
}

// MARK: - Character Model

private struct NumberFlowCharacter: Identifiable {
    let id: Int
    let character: Character
    let isDigit: Bool
}

// MARK: - Spinning Digit View

struct SpinningDigitView: View {
    let digit: Character
    let font: Font
    let color: Color
    var trend: NumberTrend = .auto
    
    @State private var previousDigit: Character = "0"
    @State private var animationOffset: CGFloat = 0
    
    private let digitHeight: CGFloat = 1.2 // em units
    private let allDigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    private var currentValue: Int {
        Int(String(digit)) ?? 0
    }
    
    private var previousValue: Int {
        Int(String(previousDigit)) ?? 0
    }
    
    // Calculate which direction to spin
    private var spinDirection: Int {
        switch trend {
        case .up:
            return 1
        case .down:
            return -1
        case .auto:
            let diff = currentValue - previousValue
            if diff == 0 { return 0 }
            return diff > 0 ? 1 : -1
        }
    }
    
    // Calculate the digits to show during animation
    private var digitSequence: [String] {
        guard spinDirection != 0 else { return [String(digit)] }
        
        var sequence: [String] = []
        var current = previousValue
        let target = currentValue
        
        if spinDirection > 0 {
            // Spinning up
            while current != target {
                sequence.append(allDigits[current])
                current = (current + 1) % 10
            }
            sequence.append(allDigits[target])
        } else {
            // Spinning down
            while current != target {
                sequence.append(allDigits[current])
                current = (current - 1 + 10) % 10
            }
            sequence.append(allDigits[target])
        }
        
        return sequence
    }
    
    var body: some View {
        Text(String(digit))
            .font(font)
            .foregroundColor(color)
            .monospacedDigit()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.15),
                        .init(color: .black, location: 0.85),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .contentTransition(.numericText(countsDown: spinDirection < 0))
            .transaction { transaction in
                transaction.animation = .spring(response: 0.35, dampingFraction: 0.75)
            }
            .onChange(of: digit) { oldValue, newValue in
                previousDigit = oldValue
            }
    }
}

// MARK: - Animated Amount Text (Enhanced)

struct AnimatedAmountText: View {
    let amount: String
    let fontSize: CGFloat
    let color: Color
    var trend: NumberTrend = .auto
    
    init(amount: String, fontSize: CGFloat = 56, color: Color = Color(hex: "080808"), trend: NumberTrend = .auto) {
        self.amount = amount
        self.fontSize = fontSize
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        NumberFlowView(
            text: amount,
            font: .custom("Inter-Bold", size: fontSize),
            color: color,
            trend: trend
        )
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}

// MARK: - Large Balance Display (for home screen)

struct AnimatedBalanceText: View {
    let amount: String
    var fontSize: CGFloat = 48
    var fontWeight: String = "Inter-Bold"
    var color: Color = Color(hex: "080808")
    var trend: NumberTrend = .auto
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(amount.enumerated()), id: \.offset) { index, character in
                if character.isNumber {
                    Text(String(character))
                        .font(.custom(fontWeight, size: fontSize))
                        .foregroundColor(color)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: trend == .down))
                        .transition(
                            .asymmetric(
                                insertion: .push(from: trend == .down ? .top : .bottom),
                                removal: .push(from: trend == .down ? .bottom : .top)
                            )
                            .combined(with: .opacity)
                        )
                        .id("\(index)-\(character)")
                } else {
                    Text(String(character))
                        .font(.custom(fontWeight, size: fontSize))
                        .foregroundColor(color)
                        .transition(.opacity)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: amount)
    }
}

// MARK: - Number Flow Style Input Display

struct NumberFlowInputDisplay: View {
    let amount: String
    var fontSize: CGFloat = 56
    var color: Color = Color(hex: "080808")
    var secondaryColor: Color = Color(hex: "7B7B7B")
    
    // Split into currency symbol and number parts
    private var currencySymbol: String {
        let symbols = ["$", "£", "€", "¥", "₹", "₿"]
        for symbol in symbols {
            if amount.hasPrefix(symbol) {
                return symbol
            }
        }
        return ""
    }
    
    private var numberPart: String {
        var result = amount
        let symbols = ["$", "£", "€", "¥", "₹", "₿"]
        for symbol in symbols {
            result = result.replacingOccurrences(of: symbol, with: "")
        }
        return result
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Currency symbol (static)
            if !currencySymbol.isEmpty {
                Text(currencySymbol)
                    .font(.custom("Inter-Bold", size: fontSize))
                    .foregroundColor(color)
            }
            
            // Animated number
            ForEach(Array(numberPart.enumerated()), id: \.offset) { index, character in
                if character.isNumber {
                    Text(String(character))
                        .font(.custom("Inter-Bold", size: fontSize))
                        .foregroundColor(color)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity).combined(with: .offset(y: 20)),
                                removal: .scale(scale: 0.5).combined(with: .opacity).combined(with: .offset(y: -20))
                            )
                        )
                        .id("digit-\(index)-\(character)")
                } else {
                    // Comma, period, etc.
                    Text(String(character))
                        .font(.custom("Inter-Bold", size: fontSize))
                        .foregroundColor(color)
                        .transition(.opacity)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: amount)
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var value: Double = 1234.56
        @State private var isPositive = true
        
        var formattedValue: String {
            String(format: "$%.2f", value)
        }
        
        var body: some View {
            VStack(spacing: 40) {
                Text("NumberFlow-style Animation")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                // Standard sliding number
                SlidingNumberText(
                    text: formattedValue,
                    font: .custom("Inter-Bold", size: 48),
                    color: Color(hex: "080808")
                )
                
                // Animated amount
                AnimatedAmountText(amount: formattedValue)
                
                // Balance display
                AnimatedBalanceText(amount: formattedValue)
                
                // Input display
                NumberFlowInputDisplay(amount: formattedValue)
                
                HStack(spacing: 20) {
                    Button("+ Random") {
                        withAnimation {
                            value += Double.random(in: 10...500)
                        }
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("- Random") {
                        withAnimation {
                            value = max(0, value - Double.random(in: 10...500))
                        }
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
