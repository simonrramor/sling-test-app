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
    var cardColor: Color = Color(hex: "FF5113")  // Card color (default orange)
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
        frontMaterial.diffuse.contents = createCardFrontImage(color: UIColor(cardColor))
        frontMaterial.isDoubleSided = false
        frontMaterial.lightingModel = .constant  // No lighting effects
        
        let backMaterial = SCNMaterial()
        backMaterial.diffuse.contents = createCardBackImage(color: UIColor(cardColor))
        backMaterial.isDoubleSided = false
        backMaterial.lightingModel = .constant
        
        let sideMaterial = SCNMaterial()
        sideMaterial.diffuse.contents = UIColor(cardColor)  // Match card color
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
        
        // Update card texture based on lock state and color
        let uiCardColor = UIColor(cardColor)
        if let cardNode = uiView.scene?.rootNode.childNode(withName: "card", recursively: false),
           let box = cardNode.geometry as? SCNBox {
            
            let frontImage = isLocked ? createLockedCardImage(color: uiCardColor, blurRadius: contentBlur) : createCardFrontImage(color: uiCardColor)
            box.materials[0].diffuse.contents = frontImage
            
            // Update side material to match card color
            box.materials[1].diffuse.contents = uiCardColor
            box.materials[3].diffuse.contents = uiCardColor
            box.materials[4].diffuse.contents = uiCardColor
            box.materials[5].diffuse.contents = uiCardColor
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
            frontMaterial.diffuse.contents = isLocked ? createLockedCardImage(color: uiCardColor, blurRadius: contentBlur) : createCardFrontImage(color: uiCardColor)
            frontMaterial.isDoubleSided = false
            frontMaterial.lightingModel = .constant
            
            let backMaterial = SCNMaterial()
            backMaterial.diffuse.contents = createCardBackImage(color: uiCardColor)
            backMaterial.isDoubleSided = false
            backMaterial.lightingModel = .constant
            
            let sideMaterial = SCNMaterial()
            sideMaterial.diffuse.contents = uiCardColor
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
    
    private func createCardFrontImage(color: UIColor) -> UIImage {
        // Generate card front dynamically with the selected color
        let size = CGSize(width: 1035, height: 648)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Card background color
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Draw watermark logo (SlingLogoBg pattern)
            // Large concentric circles at 8% opacity
            let circleColor = UIColor.white.withAlphaComponent(0.08)
            circleColor.setFill()
            
            // Draw filled Sling logo watermark centered
            // The logo is about 218x218 on a 345x196 card, scale up proportionally
            let logoSize: CGFloat = 650
            let logoCenter = CGPoint(x: size.width / 2, y: size.height / 2)
            
            // Outer circle
            let outerPath = UIBezierPath(ovalIn: CGRect(
                x: logoCenter.x - logoSize / 2,
                y: logoCenter.y - logoSize / 2,
                width: logoSize,
                height: logoSize
            ))
            outerPath.fill()
            
            // Cut out the inner ring area (create the crescent effect)
            ctx.saveGState()
            let innerSize = logoSize * 0.667
            let innerPath = UIBezierPath(ovalIn: CGRect(
                x: logoCenter.x - innerSize / 2,
                y: logoCenter.y - innerSize / 2,
                width: innerSize,
                height: innerSize
            ))
            color.setFill()
            innerPath.fill()
            
            // Inner filled circle
            let coreSize = innerSize * 0.5
            let corePath = UIBezierPath(ovalIn: CGRect(
                x: logoCenter.x - logoSize * 0.35 - coreSize / 2,
                y: logoCenter.y - coreSize / 2,
                width: coreSize,
                height: coreSize
            ))
            circleColor.setFill()
            corePath.fill()
            ctx.restoreGState()
            
            // Draw Sling logo in top left
            if let logoImage = UIImage(named: "SlingLogo") {
                let logoRect = CGRect(x: 50, y: 50, width: 100, height: 100)
                logoImage.draw(in: logoRect)
            }
            
            // Draw card number dots and number at bottom left
            let dotColor = UIColor.white.withAlphaComponent(0.8)
            dotColor.setFill()
            let dotY: CGFloat = size.height - 80
            let dotSpacing: CGFloat = 12
            let dotSize: CGFloat = 8
            for i in 0..<4 {
                let dotX: CGFloat = 50 + CGFloat(i) * dotSpacing
                ctx.fillEllipse(in: CGRect(x: dotX, y: dotY, width: dotSize, height: dotSize))
            }
            
            let numberText = "9543"
            let numberAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            numberText.draw(at: CGPoint(x: 110, y: dotY - 12), withAttributes: numberAttrs)
            
            // Draw Visa logo at bottom right
            if let visaImage = UIImage(named: "VisaLogo")?.withRenderingMode(.alwaysTemplate) {
                let visaRect = CGRect(x: size.width - 220, y: size.height - 95, width: 170, height: 56)
                UIColor.white.withAlphaComponent(0.8).setFill()
                visaImage.draw(in: visaRect)
            }
        }
    }
    
    private func createLockedCardImage(color: UIColor, blurRadius: Double) -> UIImage {
        // Generate locked card image with blur
        let frontImage = createCardFrontImage(color: color)
        
        guard let ciImage = CIImage(image: frontImage) else { return frontImage }
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter?.outputImage else { return frontImage }
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return frontImage }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func createCardBackImage(color: UIColor) -> UIImage {
        // Match front image proportions: 1035x648
        let size = CGSize(width: 1035, height: 648)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Card background color
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Same background circles as front (mirrored)
            let circleColor = UIColor.white.withAlphaComponent(0.08)
            circleColor.setStroke()
            ctx.setLineWidth(18)
            
            let largeCircleSize: CGFloat = 654
            ctx.strokeEllipse(in: CGRect(x: size.width - 189 - largeCircleSize, y: -33, width: largeCircleSize, height: largeCircleSize))
            
            let smallCircleSize: CGFloat = 435
            ctx.strokeEllipse(in: CGRect(x: size.width - 300 - smallCircleSize, y: 78, width: smallCircleSize, height: smallCircleSize))
            
            // Magnetic stripe (darker version of the color)
            var hue: CGFloat = 0, sat: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            color.getHue(&hue, saturation: &sat, brightness: &brightness, alpha: &alpha)
            UIColor(hue: hue, saturation: sat, brightness: max(0, brightness - 0.1), alpha: alpha).setFill()
            ctx.fill(CGRect(x: 0, y: 90, width: size.width, height: 100))
            
            // Signature strip
            UIColor(hex: "F5E6D3")!.setFill()
            ctx.fill(CGRect(x: 60, y: 260, width: size.width - 120, height: 80))
            
            // CVV area
            UIColor.white.setFill()
            ctx.fill(CGRect(x: size.width - 200, y: 270, width: 130, height: 60))
            
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
