import SwiftUI
import UIKit

struct HeaderView: View {
    var onProfileTap: () -> Void = {}
    var onChatTap: () -> Void = {}
    var onQRCodeTap: () -> Void = {}
    var onSearchTap: () -> Void = {}
    var onInviteTap: () -> Void = {}
    
    var body: some View {
        HStack {
            // Profile Picture
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onProfileTap()
            }) {
                Image("AvatarProfile")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
            }
            .accessibilityLabel("Profile")
            
            Spacer()
            
            HStack(spacing: 8) {
                // Invite Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onInviteTap()
                }) {
                    Text("Invite")
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(Color(hex: "080808"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "EDEDED"))
                        .cornerRadius(12)
                }
                
                // QR Code Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onQRCodeTap()
                }) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "EDEDED"))
                        .cornerRadius(12)
                }
                .accessibilityLabel("QR Code")
                
                // Search Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onSearchTap()
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "EDEDED"))
                        .cornerRadius(12)
                }
                .accessibilityLabel("Search")
                
                // Chat/Help Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onChatTap()
                }) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "EDEDED"))
                        .cornerRadius(12)
                }
                .accessibilityLabel("Help")
            }
        }
        .padding(.vertical, 16)
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    HeaderView()
        .padding()
}
