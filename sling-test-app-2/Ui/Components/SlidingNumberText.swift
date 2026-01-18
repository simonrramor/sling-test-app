import SwiftUI

struct SlidingNumberText: View {
    let text: String
    let font: Font
    let color: Color
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .monospacedDigit()
            .animation(.easeInOut(duration: 0.15), value: text.count)
    }
}

#Preview {
    VStack {
        SlidingNumberText(
            text: "$8,800.10",
            font: .custom("Inter-Bold", size: 33),
            color: Color(hex: "080808")
        )
    }
}
