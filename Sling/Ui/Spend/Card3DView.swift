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
        // Use the actual Figma-exported card image and colorize it
        guard let originalImage = UIImage(named: "SlingCardFront") else { return UIImage() }
        
        // If color is orange (default), just return the original
        let orangeColor = UIColor(hex: "FF5113")!
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        orangeColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        if abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01 {
            return originalImage
        }
        
        // Calculate hue shift from orange to target color
        var orangeHue: CGFloat = 0, orangeSat: CGFloat = 0, orangeBri: CGFloat = 0
        var targetHue: CGFloat = 0, targetSat: CGFloat = 0, targetBri: CGFloat = 0
        orangeColor.getHue(&orangeHue, saturation: &orangeSat, brightness: &orangeBri, alpha: nil)
        color.getHue(&targetHue, saturation: &targetSat, brightness: &targetBri, alpha: nil)
        
        // Hue shift in radians (CIHueAdjust uses radians)
        let hueShift = (targetHue - orangeHue) * 2 * .pi
        
        guard let ciImage = CIImage(image: originalImage) else { return originalImage }
        
        // Apply hue rotation
        let hueFilter = CIFilter(name: "CIHueAdjust")
        hueFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        hueFilter?.setValue(hueShift, forKey: kCIInputAngleKey)
        
        guard let hueOutput = hueFilter?.outputImage else { return originalImage }
        
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(hueOutput, from: hueOutput.extent) else { return originalImage }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func createLockedCardImage(color: UIColor, blurRadius: Double) -> UIImage {
        // Use pre-made blurred asset if orange, otherwise blur the colorized version
        let orangeColor = UIColor(hex: "FF5113")!
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        orangeColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        if abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01 {
            return UIImage(named: "SlingCardFrontLocked") ?? UIImage(named: "SlingCardFront") ?? UIImage()
        }
        
        // For other colors, blur the colorized front image
        let frontImage = createCardFrontImage(color: color)
        
        guard let ciImage = CIImage(image: frontImage) else { return frontImage }
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter?.outputImage else { return frontImage }
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(outputImage, from: ciImage.extent) else { return frontImage }
        
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
            UIColor(hue: hue, saturation: sat, brightness: max(0, brightness - 0.15), alpha: alpha).setFill()
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
