import SwiftUI

/// A text input field with animated floating label
/// Based on the input/text-form Figma component
struct TextFormInput: View {
    let label: String
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    // Design constants from Figma
    private enum Constants {
        static let backgroundColor = Color(hex: "F7F7F7")
        static let labelColor = Color(hex: "7B7B7B")
        static let inputColor = Color(hex: "080808")
        static let cursorColor = Color(hex: "FF5113")
        static let cornerRadius: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 14
        static let labelFontSizeSmall: CGFloat = 13
        static let labelFontSizeLarge: CGFloat = 16
        static let height: CGFloat = 72
    }
    
    private var isActive: Bool {
        isFocused || !text.isEmpty
    }
    
    // Scale factor for label animation
    private var labelScale: CGFloat {
        isActive ? Constants.labelFontSizeSmall / Constants.labelFontSizeLarge : 1.0
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background - tappable
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Constants.backgroundColor)
            
            // Content container
            VStack(alignment: .leading, spacing: 0) {
                // Animated floating label
                Text(label)
                    .font(.custom("Inter-Medium", size: Constants.labelFontSizeLarge))
                    .foregroundColor(Constants.labelColor)
                    .scaleEffect(labelScale, anchor: .topLeading)
                    .padding(.top, isActive ? Constants.verticalPadding : (Constants.height - 24) / 2)
                
                // TextField - always present, visibility controlled
                TextField("", text: $text)
                    .font(.custom("Inter-Medium", size: Constants.labelFontSizeLarge))
                    .foregroundColor(Constants.inputColor)
                    .focused($isFocused)
                    .tint(Constants.cursorColor)
                    .padding(.top, 4)
                    .opacity(isActive ? 1 : 0)
                    .frame(height: isActive ? nil : 0)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            
            // Invisible tap target that covers the whole area
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = true
                }
        }
        .frame(height: Constants.height)
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        // Empty state
        TextFormInput(label: "First Names", text: .constant(""))
        
        // Active state with text
        TextFormInput(label: "Last names", text: .constant("Smith"))
        
        // Interactive example
        StatefulPreviewWrapper("")
    }
    .padding(.horizontal, 24)
}

/// Helper for interactive preview
private struct StatefulPreviewWrapper: View {
    @State private var text: String
    
    init(_ initialText: String) {
        _text = State(initialValue: initialText)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Interactive:")
                .font(.caption)
                .foregroundColor(.gray)
            TextFormInput(label: "Email address", text: $text)
        }
    }
}
