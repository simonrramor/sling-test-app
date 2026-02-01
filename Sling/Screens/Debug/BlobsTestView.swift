import SwiftUI

struct BlobsTestView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Circle positions
    @State private var circle1Position = CGPoint(x: 120, y: 300)
    @State private var circle2Position = CGPoint(x: 280, y: 300)
    
    // Circle radius
    private let circleRadius: CGFloat = 80
    
    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()
            
            // Metaball layer using Canvas with proper filters
            Canvas { context, size in
                // Add filters in REVERSE order of application
                // alphaThreshold is applied AFTER blur
                context.addFilter(.alphaThreshold(min: 0.5, color: .black))
                context.addFilter(.blur(radius: 15))
                
                // Draw layer applies the filters to everything inside
                context.drawLayer { ctx in
                    let circle1 = Path(ellipseIn: CGRect(
                        x: circle1Position.x - circleRadius,
                        y: circle1Position.y - circleRadius,
                        width: circleRadius * 2,
                        height: circleRadius * 2
                    ))
                    let circle2 = Path(ellipseIn: CGRect(
                        x: circle2Position.x - circleRadius,
                        y: circle2Position.y - circleRadius,
                        width: circleRadius * 2,
                        height: circleRadius * 2
                    ))
                    
                    ctx.fill(circle1, with: .color(.black))
                    ctx.fill(circle2, with: .color(.black))
                }
            }
            
            // Invisible drag handles
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: circleRadius * 2, height: circleRadius * 2)
                .contentShape(Circle())
                .position(circle1Position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            circle1Position = value.location
                        }
                )
            
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: circleRadius * 2, height: circleRadius * 2)
                .contentShape(Circle())
                .position(circle2Position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            circle2Position = value.location
                        }
                )
            
            // Close button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.gray, Color(hex: "E8E8E8"))
                    }
                    .padding(16)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Instructions
                Text("Drag the circles to move them.\nThey merge when close together.")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    BlobsTestView()
}
