import SwiftUI
import UIKit

// Custom button style with no visual feedback
struct NoFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

enum Tab: String, CaseIterable {
    case home = "Home"
    case card = "Card"
    case invest = "Invest"
    
    // Tabs that appear in the left pill (no transfer - it's a sheet now)
    static var pillTabs: [Tab] {
        [.home, .card, .invest]
    }
}

enum TransferSheetOption: String, CaseIterable, Identifiable {
    case send = "Send"
    case request = "Request"
    case transfer = "Transfer"
    case receiveSalary = "Receive your salary"
    
    var id: String { rawValue }
    
    var subtitle: String {
        switch self {
        case .send: return "Pay anyone on Sling in seconds"
        case .request: return "Ask someone to pay you back"
        case .transfer: return "Move money between your accounts"
        case .receiveSalary: return "Get paid into Sling"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .send: return Color(hex: "007AFF")
        case .request: return Color(hex: "34C759")
        case .transfer: return Color(hex: "FF2D92")
        case .receiveSalary: return Color(hex: "080808")
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .send: return Color(hex: "007AFF").opacity(0.12)
        case .request: return Color(hex: "34C759").opacity(0.12)
        case .transfer: return Color(hex: "FF2D92").opacity(0.12)
        case .receiveSalary: return Color(hex: "F5F5F5")
        }
    }
    
    var iconImageName: String {
        switch self {
        case .send: return "TransferSend"
        case .request: return "TransferRequest"
        case .transfer: return "TransferTransfer"
        case .receiveSalary: return "TransferSalary"
        }
    }
}

struct BottomNavView: View {
    @Binding var selectedTab: Tab
    var onTabChange: ((Tab) -> Void)? = nil
    var onTransferTap: (() -> Void)? = nil
    @ObservedObject private var themeService = ThemeService.shared
    @Namespace private var animation
    @State private var showTransferSheet = false
    
    var body: some View {
        HStack {
            // Left pill container with 3 tabs
            HStack(spacing: 8) {
                ForEach(Tab.pillTabs, id: \.self) { tab in
                    PillTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        onTap: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onTabChange?(tab)
                            selectedTab = tab
                        }
                    )
                }
            }
            .padding(8)
            .background(
                Capsule()
                    .fill(themeService.currentTheme == .dark ? Color(hex: "1C1C1E") : Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            
            Spacer()
            
            // Right circular transfer button
            Button(action: {
                // #region agent log
                let logPath = "/Users/simonamor/Desktop/sling-test-app-2/.cursor/debug.log"
                let ts = Date().timeIntervalSince1970 * 1000
                let logEntry = "{\"hypothesisId\":\"H1-H4\",\"location\":\"transferButton:action\",\"message\":\"Button tapped\",\"data\":{\"showTransferSheetBefore\":\(showTransferSheet)},\"timestamp\":\(ts)}\n"
                if let handle = FileHandle(forWritingAtPath: logPath) { handle.seekToEndOfFile(); handle.write(logEntry.data(using: .utf8)!); handle.closeFile() } else { FileManager.default.createFile(atPath: logPath, contents: logEntry.data(using: .utf8), attributes: nil) }
                // #endregion
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showTransferSheet = true
                // #region agent log
                let logEntry2 = "{\"hypothesisId\":\"H1-H4\",\"location\":\"transferButton:afterSet\",\"message\":\"State set to true\",\"data\":{\"showTransferSheetAfter\":\(showTransferSheet)},\"timestamp\":\(Date().timeIntervalSince1970 * 1000)}\n"
                if let handle2 = FileHandle(forWritingAtPath: logPath) { handle2.seekToEndOfFile(); handle2.write(logEntry2.data(using: .utf8)!); handle2.closeFile() }
                // #endregion
            }) {
                Image("NavTransfer")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(hex: "080808"))
            }
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(themeService.currentTheme == .dark ? Color(hex: "1C1C1E") : Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .buttonStyle(NoFeedbackButtonStyle())
            .matchedTransitionSource(id: "TransferSheet", in: animation)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 0)
        .background(Color.clear)
        .sheet(isPresented: $showTransferSheet, onDismiss: {
            // #region agent log
            let logPath = "/Users/simonamor/Desktop/sling-test-app-2/.cursor/debug.log"
            let ts = Date().timeIntervalSince1970 * 1000
            let logEntry = "{\"hypothesisId\":\"H2\",\"location\":\"sheet:onDismiss\",\"message\":\"Sheet dismissed\",\"data\":{\"showTransferSheetValue\":\(showTransferSheet)},\"timestamp\":\(ts)}\n"
            if let handle = FileHandle(forWritingAtPath: logPath) { handle.seekToEndOfFile(); handle.write(logEntry.data(using: .utf8)!); handle.closeFile() } else { FileManager.default.createFile(atPath: logPath, contents: logEntry.data(using: .utf8), attributes: nil) }
            // #endregion
        }) {
            TransferOptionsSheet(onAction: { action in
                // #region agent log
                let logPath = "/Users/simonamor/Desktop/sling-test-app-2/.cursor/debug.log"
                let ts = Date().timeIntervalSince1970 * 1000
                let logEntry = "{\"hypothesisId\":\"H2\",\"location\":\"sheet:onAction\",\"message\":\"Action selected\",\"data\":{\"action\":\"\(action.rawValue)\"},\"timestamp\":\(ts)}\n"
                if let handle = FileHandle(forWritingAtPath: logPath) { handle.seekToEndOfFile(); handle.write(logEntry.data(using: .utf8)!); handle.closeFile() } else { FileManager.default.createFile(atPath: logPath, contents: logEntry.data(using: .utf8), attributes: nil) }
                // #endregion
                showTransferSheet = false
            })
            .presentationDetents([.height(298)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(44)
            .presentationBackground(themeService.currentTheme == .dark ? Color(hex: "1C1C1E") : Color.white)
            .navigationTransition(.zoom(sourceID: "TransferSheet", in: animation))
        }
    }
}

// MARK: - Transfer Options Sheet

struct TransferOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeService = ThemeService.shared
    var onAction: ((TransferSheetOption) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(TransferSheetOption.allCases) { action in
                TransferOptionRow(action: action) {
                    onAction?(action)
                }
                
                if action != .receiveSalary {
                    Divider()
                        .padding(.leading, 76)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(themeService.currentTheme == .dark ? Color(hex: "1C1C1E") : Color.white)
    }
}

struct TransferOptionRow: View {
    let action: TransferSheetOption
    let onTap: () -> Void
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(action.iconImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.rawValue)
                        .font(.custom("Inter-Bold", size: 17))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text(action.subtitle)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
        }
    }
}

struct PillTabButton: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var themeService = ThemeService.shared
    
    var iconName: String {
        switch tab {
        case .home: return "NavHomeFilled"
        case .card: return "NavCardFilled"
        case .invest: return "NavInvest"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(Color(hex: "080808"))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: "F5F5F5") : Color.clear)
                )
        }
        .buttonStyle(NoFeedbackButtonStyle())
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        Color(hex: "F5F5F5")
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            BottomNavView(selectedTab: .constant(.home))
        }
    }
}
