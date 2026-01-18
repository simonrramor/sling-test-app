import SwiftUI

struct DebitCardWidget: View {
    var isLocked: Bool = false
    
    var body: some View {
        ZStack {
            // Card content (blurred when locked)
            ZStack {
                // Background color
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "FF5113"))
                
                // Background Sling logo (large, centered)
                Image("SlingLogoBg")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 218, height: 218)
                
                // Card content
                VStack(alignment: .leading, spacing: 0) {
                    // Top left Sling logo
                    Image("SlingLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                    
                    Spacer()
                    
                    // Bottom row
                    HStack {
                        // Card number indicator
                        HStack(spacing: 8) {
                            // Dots
                            HStack(spacing: 4) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: 4, height: 4)
                                }
                            }
                            
                            // Card number
                            Text("9543")
                                .font(.custom("Inter-Medium", size: 16))
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Card icon
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Visa logo
                        Image("VisaLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 72, height: 24)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .blur(radius: isLocked ? 4 : 0)
            
            // Locked overlay
            if isLocked {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Image("LockOverlayIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    )
            }
        }
        .frame(height: 196)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .shadow(color: .init(white: 0.0, opacity: 1.0), radius: 10, x: 0, y: 0)
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 20)
                .padding(.bottom, 3)
        }
    }
}

#Preview {
    DebitCardWidget()
        .padding(24)
}
