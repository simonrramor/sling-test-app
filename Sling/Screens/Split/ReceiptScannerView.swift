import SwiftUI
import AVFoundation
import UIKit

struct ReceiptScannerView: View {
    @Binding var isPresented: Bool
    @State private var capturedImage: UIImage?
    @State private var showReceiptItems = false
    @State private var scannedReceipt: ScannedReceipt?
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            // Camera preview
            ReceiptCameraPreviewView(capturedImage: $capturedImage)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(18)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Receipt frame guide
                ReceiptFrameGuide()
                    .frame(width: 280, height: 400)
                
                Text("Position the receipt within the frame")
                    .font(.custom("Inter-Medium", size: 16))
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                Spacer()
                
                // Capture button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    capturePhoto()
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.bottom, 48)
            }
            
            // Photo review overlay
            if let image = capturedImage {
                PhotoReviewView(
                    image: image,
                    isProcessing: isProcessing,
                    onRetake: {
                        capturedImage = nil
                    },
                    onUse: {
                        processReceipt(image: image)
                    }
                )
                .transition(.opacity)
            }
            
            // Receipt items view
            if showReceiptItems, let receipt = scannedReceipt {
                ReceiptItemsView(
                    isPresented: $showReceiptItems,
                    receipt: receipt,
                    onDismissAll: {
                        isPresented = false
                    }
                )
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: capturedImage != nil)
        .animation(.easeInOut(duration: 0.3), value: showReceiptItems)
    }
    
    private func capturePhoto() {
        // For now, we'll simulate a photo capture with a mock
        // In a real implementation, this would capture from the camera
        NotificationCenter.default.post(name: .captureReceiptPhoto, object: nil)
    }
    
    private func processReceipt(image: UIImage) {
        isProcessing = true
        
        // Process the image with Vision OCR
        ReceiptOCRService.shared.processImage(image) { receipt in
            isProcessing = false
            scannedReceipt = receipt
            showReceiptItems = true
        }
    }
}

// MARK: - Notification for capture

extension Notification.Name {
    static let captureReceiptPhoto = Notification.Name("captureReceiptPhoto")
}

// MARK: - Receipt Frame Guide

struct ReceiptFrameGuide: View {
    var body: some View {
        ZStack {
            // Semi-transparent overlay with cutout
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
            
            // Corner accents
            VStack {
                HStack {
                    ReceiptCorner(rotation: 0)
                    Spacer()
                    ReceiptCorner(rotation: 90)
                }
                Spacer()
                HStack {
                    ReceiptCorner(rotation: 270)
                    Spacer()
                    ReceiptCorner(rotation: 180)
                }
            }
            .padding(8)
        }
    }
}

struct ReceiptCorner: View {
    let rotation: Double
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 24))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 24, y: 0))
        }
        .stroke(Color.white, lineWidth: 3)
        .frame(width: 24, height: 24)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Photo Review View

struct PhotoReviewView: View {
    let image: UIImage
    var isProcessing: Bool = false
    let onRetake: () -> Void
    let onUse: () -> Void
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Captured image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
            
            // Processing overlay
            if isProcessing {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Scanning receipt...")
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundColor(.white)
                    
                    Text("Extracting items and prices")
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Controls overlay (hidden when processing)
            if !isProcessing {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // Retake button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onRetake()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Retake")
                                    .font(.custom("Inter-Medium", size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Use button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onUse()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Use Photo")
                                    .font(.custom("Inter-Medium", size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

// MARK: - Receipt Camera Preview

struct ReceiptCameraPreviewView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    
    func makeUIView(context: Context) -> ReceiptCameraUIView {
        let view = ReceiptCameraUIView()
        view.onImageCaptured = { image in
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: ReceiptCameraUIView, context: Context) {}
}

class ReceiptCameraUIView: UIView {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private let sessionQueue = DispatchQueue(label: "receipt.camera.session.queue")
    
    var onImageCaptured: ((UIImage) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        checkPermissionAndSetup()
        setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        checkPermissionAndSetup()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(capturePhoto),
            name: .captureReceiptPhoto,
            object: nil
        )
    }
    
    @objc private func capturePhoto() {
        guard let photoOutput = photoOutput else {
            // If no camera, generate mock image
            generateMockCapture()
            return
        }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func generateMockCapture() {
        // Generate a high-resolution mock receipt image for testing
        let scale: CGFloat = 3.0 // Higher resolution for better OCR
        let size = CGSize(width: 400, height: 700)
        
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        
        // White background
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // Use a clear, readable font
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let itemAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 20, weight: .regular),
            .foregroundColor: UIColor.black
        ]
        
        let lineHeight: CGFloat = 40
        var y: CGFloat = 40
        
        "THE PIZZA PLACE".draw(at: CGPoint(x: 100, y: y), withAttributes: titleAttrs)
        y += lineHeight * 1.5
        
        // Items with clear price format - draw as single lines for better OCR
        let items = [
            "Margherita Pizza     £14.99",
            "Pepperoni Pizza      £16.99",
            "Caesar Salad         £8.99",
            "Garlic Bread         £5.99",
            "Coca Cola            £2.99",
            "Sprite               £2.99",
            "Tiramisu             £7.99"
        ]
        
        for item in items {
            item.draw(at: CGPoint(x: 30, y: y), withAttributes: itemAttrs)
            y += lineHeight
        }
        
        y += lineHeight * 0.5
        
        // Divider
        let dividerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 20, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        "------------------------".draw(at: CGPoint(x: 30, y: y), withAttributes: dividerAttrs)
        y += lineHeight
        
        // Total
        "TOTAL                £60.91".draw(at: CGPoint(x: 30, y: y), withAttributes: titleAttrs)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let capturedImage = image {
            DispatchQueue.main.async { [weak self] in
                self?.onImageCaptured?(capturedImage)
            }
        }
    }
    
    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            sessionQueue.async { [weak self] in
                self?.setupCamera()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.sessionQueue.async {
                        self?.setupCamera()
                    }
                }
            }
        default:
            break
        }
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        self.captureSession = session
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            
            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.photoOutput = output
            }
            
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.previewLayer = preview
                self.layer.addSublayer(preview)
                preview.frame = self.bounds
            }
            
            session.startRunning()
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        sessionQueue.async { [captureSession] in
            captureSession?.stopRunning()
        }
    }
}

// MARK: - Photo Capture Delegate

extension ReceiptCameraUIView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.onImageCaptured?(image)
        }
    }
}

#Preview {
    ReceiptScannerView(isPresented: .constant(true))
}
