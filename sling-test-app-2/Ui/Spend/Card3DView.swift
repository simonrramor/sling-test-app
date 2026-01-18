import SwiftUI
import SceneKit

struct Card3DView: UIViewRepresentable {
    @Binding var isLocked: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling4X
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Create the card geometry - match downloaded image ratio 1035:648 = 1.597:1
        let cardWidth: CGFloat = 3.45
        let cardHeight: CGFloat = 2.16  // 3.45 / 1.597
        let cardDepth: CGFloat = 0.005  // Very thin to minimize visible edges
        
        let cardGeometry = SCNBox(width: cardWidth, height: cardHeight, length: cardDepth, chamferRadius: 0)
        
        // Create materials for the card
        let frontMaterial = SCNMaterial()
        frontMaterial.diffuse.contents = createCardFrontImage()
        frontMaterial.isDoubleSided = false
        
        let backMaterial = SCNMaterial()
        backMaterial.diffuse.contents = createCardBackImage()
        backMaterial.isDoubleSided = false
        
        let sideMaterial = SCNMaterial()
        sideMaterial.diffuse.contents = UIColor.clear
        sideMaterial.transparency = 0
        
        // Box has 6 faces: front, right, back, left, top, bottom
        cardGeometry.materials = [frontMaterial, sideMaterial, backMaterial, sideMaterial, sideMaterial, sideMaterial]
        
        let cardNode = SCNNode(geometry: cardGeometry)
        cardNode.name = "card"
        scene.rootNode.addChildNode(cardNode)
        
        // Add camera - position closer for larger card view
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 4.5)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)
        
        // Add directional light for shine effect
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.light?.color = UIColor.white
        directionalLight.position = SCNVector3(x: 2, y: 2, z: 5)
        directionalLight.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(directionalLight)
        
        // Add pan gesture for rotation
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        // Add tap gesture for flip
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        context.coordinator.sceneView = sceneView
        context.coordinator.cardNode = cardNode
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update card appearance based on lock state if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: Card3DView
        var sceneView: SCNView?
        var cardNode: SCNNode?
        var lastPanLocation: CGPoint = .zero
        var currentRotationX: Float = 0
        var currentRotationY: Float = 0
        
        init(_ parent: Card3DView) {
            self.parent = parent
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let cardNode = cardNode else { return }
            
            let translation = gesture.translation(in: sceneView)
            
            if gesture.state == .began {
                lastPanLocation = translation
            }
            
            let deltaX = Float(translation.x - lastPanLocation.x) * 0.01
            let deltaY = Float(translation.y - lastPanLocation.y) * 0.01
            
            currentRotationY += deltaX
            currentRotationX += deltaY
            
            // Limit X rotation to prevent flipping too far
            currentRotationX = max(-0.5, min(0.5, currentRotationX))
            
            cardNode.eulerAngles = SCNVector3(currentRotationX, currentRotationY, 0)
            
            lastPanLocation = translation
            
            if gesture.state == .ended {
                // Animate back to center with spring effect
                let springBack = SCNAction.rotateTo(x: 0, y: CGFloat(currentRotationY), z: 0, duration: 0.3)
                springBack.timingMode = .easeOut
                cardNode.runAction(springBack)
                currentRotationX = 0
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let cardNode = cardNode else { return }
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // Flip the card 180 degrees
            let currentY = currentRotationY
            let targetY = currentY + Float.pi
            
            let flipAction = SCNAction.rotateTo(x: 0, y: CGFloat(targetY), z: 0, duration: 0.5)
            flipAction.timingMode = .easeInEaseOut
            cardNode.runAction(flipAction)
            
            currentRotationY = targetY
        }
    }
    
    private func createCardFrontImage() -> UIImage {
        // Use the actual Figma-exported card image
        return UIImage(named: "SlingCardFront") ?? UIImage()
    }
    
    private func createCardBackImage() -> UIImage {
        // Match front image proportions: 1035x648
        let size = CGSize(width: 1035, height: 648)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Orange background to match front
            UIColor(hex: "FF5113")!.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Same background circles as front (mirrored)
            let circleColor = UIColor.white.withAlphaComponent(0.08)
            circleColor.setStroke()
            ctx.setLineWidth(18)
            
            let largeCircleSize: CGFloat = 654
            ctx.strokeEllipse(in: CGRect(x: size.width - 189 - largeCircleSize, y: -33, width: largeCircleSize, height: largeCircleSize))
            
            let smallCircleSize: CGFloat = 435
            ctx.strokeEllipse(in: CGRect(x: size.width - 300 - smallCircleSize, y: 78, width: smallCircleSize, height: smallCircleSize))
            
            // Magnetic stripe (darker)
            UIColor(hex: "E04510")!.setFill()
            context.fill(CGRect(x: 0, y: 90, width: size.width, height: 100))
            
            // Signature strip
            UIColor(hex: "F5E6D3")!.setFill()
            context.fill(CGRect(x: 60, y: 260, width: size.width - 120, height: 80))
            
            // CVV area
            UIColor.white.setFill()
            context.fill(CGRect(x: size.width - 200, y: 270, width: 130, height: 60))
            
            let cvvText = "123"
            let cvvAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 36, weight: .medium),
                .foregroundColor: UIColor.black
            ]
            cvvText.draw(at: CGPoint(x: size.width - 175, y: 282), withAttributes: cvvAttrs)
            
            // Legal text
            let legalText = "Issued by Sling Money Ltd."
            let legalAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            legalText.draw(at: CGPoint(x: 60, y: size.height - 80), withAttributes: legalAttrs)
        }
    }
}

// Helper extension for UIColor hex
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

#Preview {
    Card3DView(isLocked: .constant(false))
        .frame(height: 250)
        .background(Color.white)
}
