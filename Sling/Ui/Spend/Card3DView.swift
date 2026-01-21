import SwiftUI
import SceneKit

struct Card3DView: UIViewRepresentable {
    @Binding var isLocked: Bool
    var maxRotation: Float = 0.07  // Default ~4 degrees
    var cameraFOV: Double = 42.0
    var cameraZ: Double = 3.23
    var cardDepth: Double = 0.057
    var contentBlur: Double = 8.0  // Blur radius for locked state
    var backgroundColor: Color = Color(red: 0.949, green: 0.949, blue: 0.949)  // Default to grey theme
    var onTap: (() -> Void)? = nil  // Callback for tap events
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        // Use background color from theme
        sceneView.backgroundColor = UIColor(backgroundColor)
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode = .none  // Disable AA to test hypothesis G
        
        // Set layer background to match theme
        sceneView.layer.isOpaque = false
        sceneView.layer.backgroundColor = UIColor(backgroundColor).cgColor
        sceneView.layer.shadowOpacity = 0
        sceneView.layer.shadowRadius = 0
        sceneView.layer.masksToBounds = true
        
        let scene = SCNScene()
        // Use background color from theme
        scene.background.contents = UIColor(backgroundColor)
        sceneView.scene = scene
        
        // Disable any floor/shadow rendering
        scene.rootNode.castsShadow = false
        
        // Create the card geometry - match downloaded image ratio 1035:648 = 1.597:1
        let cardWidth: CGFloat = 3.45
        let cardHeight: CGFloat = 2.16  // 3.45 / 1.597
        
        let cardGeometry = SCNBox(width: cardWidth, height: cardHeight, length: CGFloat(cardDepth), chamferRadius: 0)
        
        // Create materials for the card
        let frontMaterial = SCNMaterial()
        frontMaterial.diffuse.contents = createCardFrontImage()
        frontMaterial.isDoubleSided = false
        frontMaterial.lightingModel = .constant  // No lighting effects
        
        let backMaterial = SCNMaterial()
        backMaterial.diffuse.contents = createCardBackImage()
        backMaterial.isDoubleSided = false
        backMaterial.lightingModel = .constant
        
        let sideMaterial = SCNMaterial()
        sideMaterial.diffuse.contents = UIColor(hex: "FF5113")  // Match card orange
        sideMaterial.lightingModel = .constant
        
        // Box has 6 faces: front, right, back, left, top, bottom
        cardGeometry.materials = [frontMaterial, sideMaterial, backMaterial, sideMaterial, sideMaterial, sideMaterial]
        
        let cardNode = SCNNode(geometry: cardGeometry)
        cardNode.name = "card"
        scene.rootNode.addChildNode(cardNode)
        
        // Add camera - perspective projection for 3D depth effect
        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = CGFloat(cameraFOV)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: Float(cameraZ))
        scene.rootNode.addChildNode(cameraNode)
        
        // No lights needed - using constant lighting model on materials
        
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
        // Update max rotation when slider changes
        context.coordinator.maxRotation = maxRotation
        
        // Update background color when theme changes
        uiView.backgroundColor = UIColor(backgroundColor)
        uiView.layer.backgroundColor = UIColor(backgroundColor).cgColor
        uiView.scene?.background.contents = UIColor(backgroundColor)
        
        // Update camera settings
        if let cameraNode = uiView.scene?.rootNode.childNode(withName: "camera", recursively: false) {
            cameraNode.camera?.fieldOfView = CGFloat(cameraFOV)
            cameraNode.position = SCNVector3(x: 0, y: 0, z: Float(cameraZ))
        }
        
        // Update card texture based on lock state
        if let cardNode = uiView.scene?.rootNode.childNode(withName: "card", recursively: false),
           let box = cardNode.geometry as? SCNBox {
            
            let frontImage = isLocked ? createLockedCardImage(blurRadius: contentBlur) : createCardFrontImage()
            box.materials[0].diffuse.contents = frontImage
            
            // Keep side material orange (no grayscale)
            let sideColor = UIColor(hex: "FF5113")
            box.materials[1].diffuse.contents = sideColor
            box.materials[3].diffuse.contents = sideColor
            box.materials[4].diffuse.contents = sideColor
            box.materials[5].diffuse.contents = sideColor
        }
        
        // Update card depth if changed
        if let cardNode = uiView.scene?.rootNode.childNode(withName: "card", recursively: false),
           let oldBox = cardNode.geometry as? SCNBox,
           abs(oldBox.length - CGFloat(cardDepth)) > 0.001 {
            
            let cardWidth: CGFloat = 3.45
            let cardHeight: CGFloat = 2.16
            
            let newBox = SCNBox(width: cardWidth, height: cardHeight, length: CGFloat(cardDepth), chamferRadius: 0)
            
            // Recreate materials
            let frontMaterial = SCNMaterial()
            frontMaterial.diffuse.contents = isLocked ? createLockedCardImage(blurRadius: contentBlur) : createCardFrontImage()
            frontMaterial.isDoubleSided = false
            frontMaterial.lightingModel = .constant
            
            let backMaterial = SCNMaterial()
            backMaterial.diffuse.contents = createCardBackImage()
            backMaterial.isDoubleSided = false
            backMaterial.lightingModel = .constant
            
            let sideMaterial = SCNMaterial()
            sideMaterial.diffuse.contents = UIColor(hex: "FF5113")
            sideMaterial.lightingModel = .constant
            
            newBox.materials = [frontMaterial, sideMaterial, backMaterial, sideMaterial, sideMaterial, sideMaterial]
            cardNode.geometry = newBox
        }
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
        var maxRotation: Float = 0.087
        
        init(_ parent: Card3DView) {
            self.parent = parent
            self.maxRotation = parent.maxRotation
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let cardNode = cardNode else { return }
            
            let translation = gesture.translation(in: sceneView)
            
            if gesture.state == .began {
                lastPanLocation = translation
                cardNode.removeAllActions()
            }
            
            let deltaX = Float(translation.x - lastPanLocation.x) * 0.004
            let deltaY = Float(translation.y - lastPanLocation.y) * 0.004
            
            currentRotationX += deltaY
            currentRotationY += deltaX
            
            // Simple clamp - no rubber band, just limits
            currentRotationX = max(-maxRotation, min(maxRotation, currentRotationX))
            currentRotationY = max(-maxRotation, min(maxRotation, currentRotationY))
            
            cardNode.eulerAngles = SCNVector3(currentRotationX, currentRotationY, 0)
            
            lastPanLocation = translation
            
            if gesture.state == .ended {
                // Simple smooth return to center
                let returnAction = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.25)
                returnAction.timingMode = .easeOut
                
                cardNode.runAction(returnAction) { [weak self] in
                    self?.currentRotationX = 0
                    self?.currentRotationY = 0
                }
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let cardNode = cardNode else { return }
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // Subtle bounce effect on tap instead of flip
            let tiltForward = SCNAction.rotateBy(x: -0.05, y: 0, z: 0, duration: 0.1)
            let tiltBack = SCNAction.rotateBy(x: 0.05, y: 0, z: 0, duration: 0.15)
            tiltBack.timingMode = .easeOut
            let sequence = SCNAction.sequence([tiltForward, tiltBack])
            cardNode.runAction(sequence)
            
            // Call the tap callback
            parent.onTap?()
        }
    }
    
    private func createCardFrontImage() -> UIImage {
        // Use the actual Figma-exported card image
        return UIImage(named: "SlingCardFront") ?? UIImage()
    }
    
    private func createLockedCardImage(blurRadius: Double) -> UIImage {
        // Use pre-made blurred asset from Figma
        return UIImage(named: "SlingCardFrontLocked") ?? UIImage(named: "SlingCardFront") ?? UIImage()
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
