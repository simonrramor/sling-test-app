import SwiftUI

struct SwapAnimationTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrimaryOnTop = true
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "080808"))
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                
                Spacer()
                
                // The swap component
                AnimatedCurrencySwapView(
                    primaryDisplay: "£221.37",
                    secondaryDisplay: "€255",
                    showingPrimaryOnTop: showingPrimaryOnTop,
                    onSwap: {
                        showingPrimaryOnTop.toggle()
                    }
                )
                
                Spacer()
            }
        }
    }
}

#Preview {
    SwapAnimationTestView()
}
