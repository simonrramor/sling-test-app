import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack {
            // Profile Picture with Verified Badge
            ZStack(alignment: .topTrailing) {
                Image("ProfilePhoto")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                
                // Verified Badge
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "2CC2FF"))
                }
                .offset(x: 2, y: -1)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                // Invite Button
                Button(action: {}) {
                    Text("Invite")
                        .font(.custom("Inter-Bold", size: 14))
                        .foregroundColor(Color(hex: "080808"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "EDEDED"))
                        .cornerRadius(12)
                }
                
                // Search Button
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "080808"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "EDEDED"))
                        .cornerRadius(12)
                }
            }
        }
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
