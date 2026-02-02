import SwiftUI
import UIKit

struct ListRow<TrailingContent: View>: View {
    @ObservedObject private var themeService = ThemeService.shared
    let iconName: String
    let title: String
    let subtitle: String
    let iconStyle: IconStyle
    var iconColor: Color? = nil
    let isButton: Bool
    let onTap: (() -> Void)?
    let trailingContent: () -> TrailingContent
    
    enum IconStyle {
        case rounded   // Rounded corners with border (for stocks)
        case plain     // No modifications (for transfer actions)
    }
    
    init(
        iconName: String,
        title: String,
        subtitle: String,
        iconStyle: IconStyle = .rounded,
        iconColor: Color? = nil,
        isButton: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.iconStyle = iconStyle
        self.iconColor = iconColor
        self.isButton = isButton
        self.onTap = onTap
        self.trailingContent = trailingContent
    }
    
    var body: some View {
        if isButton {
            PressableRow(onTap: onTap) {
                rowContent
            }
        } else {
            rowContent
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: 16) {
            // Icon
            iconView
            
            // Title and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Text(subtitle)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
            }
            
            Spacer()
            
            // Trailing content
            trailingContent()
        }
        .padding(16)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var iconView: some View {
        switch iconStyle {
        case .rounded:
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(themeService.textPrimaryColor.opacity(0.06), lineWidth: 1)
                )
                .accessibilityHidden(true)
        case .plain:
            if let color = iconColor {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .foregroundColor(color)
                    .accessibilityHidden(true)
            } else {
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
        }
    }
}

// Extension for rows without trailing content
extension ListRow where TrailingContent == EmptyView {
    init(
        iconName: String,
        title: String,
        subtitle: String,
        iconStyle: IconStyle = .rounded,
        iconColor: Color? = nil,
        isButton: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.iconStyle = iconStyle
        self.iconColor = iconColor
        self.isButton = isButton
        self.onTap = onTap
        self.trailingContent = { EmptyView() }
    }
}

// MARK: - Pressable Row (instant press detection)

struct PressableRow<Content: View>: View {
    @ObservedObject private var themeService = ThemeService.shared
    let onTap: (() -> Void)?
    let content: () -> Content
    
    @State private var isPressed = false
    
    init(onTap: (() -> Void)?, @ViewBuilder content: @escaping () -> Content) {
        self.onTap = onTap
        self.content = content
    }
    
    var body: some View {
        content()
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isPressed ? (themeService.currentTheme == .dark ? Color(hex: "3A3A3C") : Color(hex: "F5F5F5")) : Color.clear)
            )
            .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .onTapGesture {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onTap?()
            }
    }
}

#Preview {
    VStack {
        ListRow(
            iconName: "StockApple",
            title: "Apple Inc",
            subtitle: "AAPL",
            iconStyle: .rounded
        ) {
            Text("$150.00")
                .font(.custom("Inter-Bold", size: 16))
        }
        
        ListRow(
            iconName: "TransferSend",
            title: "Send",
            subtitle: "Pay anyone on Sling",
            iconStyle: .plain,
            isButton: true
        )
    }
}
