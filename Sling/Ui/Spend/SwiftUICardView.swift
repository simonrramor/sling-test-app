import SwiftUI

struct SwiftUICardView: View {
    @Binding var isLocked: Bool
    var cardColor: Color = Color(hex: "FF5113")
    var cardStyle: String = "orange"
    var showCardNumber: Bool = true
    var onTap: (() -> Void)? = nil
    
    // 3D rotation state
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var isDragging = false
    
    // Card dimensions (690x432 ratio = 1.597:1)
    private let cardAspectRatio: CGFloat = 690.0 / 432.0
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = min(geometry.size.width - 48, 345)
            let cardHeight = cardWidth / cardAspectRatio
            
            ZStack {
                // Card content
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 24)
                        .fill(cardColor)
                        .frame(width: cardWidth, height: cardHeight)
                    
                    // Sling logo watermark - centered
                    Image("SlingLogo")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: cardWidth * 0.73)
                        .foregroundColor(Color.white.opacity(0.08))
                    
                    // Small Sling logo - top left, 16px from edges
                    VStack {
                        HStack {
                            Image("SlingLogo")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundColor(.white)
                                .padding(.leading, 16)
                                .padding(.top, 16)
                            Spacer()
                        }
                        Spacer()
                    }
                    
                    // Bottom row: card number (left) and VISA logo (right)
                    VStack {
                        Spacer()
                        HStack {
                            // Card number - bottom left (optional)
                            if showCardNumber {
                                Text("•••• 9543")
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.leading, 16)
                                    .padding(.bottom, 16)
                            }
                            
                            Spacer()
                            
                            // VISA logo - bottom right
                            Image("VisaLogo")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 72, height: 24)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.trailing, 16)
                                .padding(.bottom, 16)
                        }
                    }
                }
                .blur(radius: isLocked ? 4 : 0)
                .overlay(
                    // Dark tint overlay when locked
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(isLocked ? 0.05 : 0))
                )
                .animation(.easeInOut(duration: 0.2), value: isLocked)
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(
                    color: Color.black.opacity(0.12),
                    radius: 24,
                    x: 0,
                    y: 8
                )
                .rotation3DEffect(
                    .degrees(rotationX),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )
                .rotation3DEffect(
                    .degrees(rotationY),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let sensitivity: Double = 0.15
                            rotationY = value.translation.width * sensitivity
                            rotationX = -value.translation.height * sensitivity
                            rotationX = max(-12, min(12, rotationX))
                            rotationY = max(-12, min(12, rotationY))
                        }
                        .onEnded { _ in
                            isDragging = false
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                rotationX = 0
                                rotationY = 0
                            }
                        }
                )
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onTap?()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SwiftUICardView(isLocked: .constant(false))
        .frame(height: 250)
        .background(Color.white)
}
