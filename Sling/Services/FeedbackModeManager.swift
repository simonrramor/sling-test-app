import SwiftUI
import UIKit
import Combine

// MARK: - Feedback Team

enum FeedbackTeam: String, CaseIterable {
    case product = "product"
    case design = "design"
    case devFrontend = "dev_frontend"
    case devBackend = "dev_backend"
    
    var displayName: String {
        switch self {
        case .product: return "Product"
        case .design: return "Design"
        case .devFrontend: return "Front End"
        case .devBackend: return "Back End"
        }
    }
    
    var assigneeName: String {
        switch self {
        case .product: return "Greg"
        case .design: return "Simon"
        case .devFrontend: return "Marius"
        case .devBackend: return "Dom"
        }
    }
    
    /// Key used in LinearConfig.userIds
    var configKey: String {
        switch self {
        case .product: return "greg"
        case .design: return "simon"
        case .devFrontend: return "marius"
        case .devBackend: return "dom"
        }
    }
}

// MARK: - Feedback Data

struct FeedbackData {
    var screenshot: UIImage?
    var selectionRect: CGRect?
    var description: String = ""
    var team: FeedbackTeam?
}

// MARK: - Feedback Mode Manager

class FeedbackModeManager: ObservableObject {
    static let shared = FeedbackModeManager()
    
    /// Whether feedback mode is currently active (user can draw selection)
    @Published var isActive: Bool = false
    
    /// Whether we're currently capturing a selection
    @Published var isCapturing: Bool = false
    
    /// The current selection rectangle (in screen coordinates)
    @Published var selectionRect: CGRect = .zero
    
    /// The starting point of the selection
    @Published var selectionStart: CGPoint = .zero
    
    /// Whether to show the feedback popup
    @Published var showFeedbackPopup: Bool = false
    
    /// The current feedback data being collected
    @Published var currentFeedback: FeedbackData = FeedbackData()
    
    /// Whether feedback is being submitted
    @Published var isSubmitting: Bool = false
    
    private init() {}
    
    // MARK: - Public Methods
    
    func toggleFeedbackMode() {
        isActive.toggle()
        if !isActive {
            resetCapture()
        }
    }
    
    func startCapture(at point: CGPoint) {
        isCapturing = true
        selectionStart = point
        selectionRect = CGRect(origin: point, size: .zero)
    }
    
    func updateCapture(to point: CGPoint) {
        guard isCapturing else { return }
        
        let origin = CGPoint(
            x: min(selectionStart.x, point.x),
            y: min(selectionStart.y, point.y)
        )
        let size = CGSize(
            width: abs(point.x - selectionStart.x),
            height: abs(point.y - selectionStart.y)
        )
        selectionRect = CGRect(origin: origin, size: size)
    }
    
    func endCapture() {
        guard isCapturing else { return }
        isCapturing = false
        
        // Only proceed if we have a meaningful selection (at least 20x20)
        if selectionRect.width >= 20 && selectionRect.height >= 20 {
            captureScreenshot()
        } else {
            resetCapture()
        }
    }
    
    func cancelCapture() {
        resetCapture()
    }
    
    func resetCapture() {
        isCapturing = false
        selectionRect = .zero
        selectionStart = .zero
    }
    
    func resetFeedback() {
        currentFeedback = FeedbackData()
        showFeedbackPopup = false
        isActive = false
        resetCapture()
    }
    
    // MARK: - Screenshot Capture
    
    private func captureScreenshot() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            resetCapture()
            return
        }
        
        // Capture the entire screen first (clean, without overlays)
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let fullScreenshot = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        
        // Now draw just the rounded selection box on top
        let finalRenderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let screenshotWithSelection = finalRenderer.image { context in
            // Draw the original screenshot (clean, no overlay)
            fullScreenshot.draw(at: .zero)
            
            let ctx = context.cgContext
            
            // Draw rounded rectangle border
            let cornerRadius: CGFloat = 12
            let lineWidth: CGFloat = 4
            let borderRect = selectionRect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
            let roundedPath = UIBezierPath(roundedRect: borderRect, cornerRadius: cornerRadius)
            
            ctx.setStrokeColor(UIColor.systemBlue.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.addPath(roundedPath.cgPath)
            ctx.strokePath()
        }
        
        // Store the captured data
        currentFeedback.screenshot = screenshotWithSelection
        currentFeedback.selectionRect = selectionRect
        
        // Show the feedback popup
        showFeedbackPopup = true
        
        // Reset capture state but keep feedback mode active
        resetCapture()
    }
}
