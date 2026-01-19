import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ScannerTab = .scan
    @State private var cachedQRCode: UIImage?
    
    enum ScannerTab {
        case scan
        case myCode
    }
    
    var body: some View {
        ZStack {
            // Camera always present (hidden when not needed for smooth switching)
            CameraPreviewView()
                .ignoresSafeArea()
                .opacity(selectedTab == .scan ? 1 : 0)
            
            // Dark background for My Code (always present, fades in/out)
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .opacity(selectedTab == .myCode ? 1 : 0)
            
            // Overlay content
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
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
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ZStack {
                    // Scan tab content
                    VStack {
                        Spacer()
                        
                        ScannerFrameView()
                            .frame(width: 250, height: 250)
                        
                        Text("Scan a QR Code")
                            .font(.custom("Inter-Bold", size: 20))
                            .foregroundColor(.white)
                            .padding(.top, 32)
                        
                        Spacer()
                    }
                    .opacity(selectedTab == .scan ? 1 : 0)
                    
                    // My Code tab content
                    VStack {
                        Spacer()
                        
                        // User name
                        VStack(spacing: 4) {
                            Text("Brendon Arnold")
                                .font(.custom("Inter-Bold", size: 24))
                                .foregroundColor(.white)
                            
                            Text("@brendon")
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.bottom, 24)
                        
                        // QR Code card
                        ZStack {
                            // White background
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .frame(width: 280, height: 280)
                            
                            // Cached QR Code
                            if let qrImage = cachedQRCode {
                                Image(uiImage: qrImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 240, height: 240)
                            }
                            
                            // User's profile photo in center
                            Image("AvatarProfile")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                )
                        }
                        
                        Spacer()
                    }
                    .opacity(selectedTab == .myCode ? 1 : 0)
                }
                
                // Tab switcher
                HStack(spacing: 0) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = .scan
                        }
                    }) {
                        Text("Scan")
                            .font(.custom("Inter-Bold", size: 14))
                            .foregroundColor(.white.opacity(selectedTab == .scan ? 1 : 0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedTab == .scan ? Color.white.opacity(0.25) : Color.clear)
                            .cornerRadius(24)
                    }
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = .myCode
                        }
                    }) {
                        Text("My Code")
                            .font(.custom("Inter-Bold", size: 14))
                            .foregroundColor(.white.opacity(selectedTab == .myCode ? 1 : 0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedTab == .myCode ? Color.white.opacity(0.25) : Color.clear)
                            .cornerRadius(24)
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.15))
                .cornerRadius(28)
                .padding(.horizontal, 80)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            // Pre-generate QR code on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                let qrImage = generateQRCode(from: "sling://pay/brendon")
                DispatchQueue.main.async {
                    cachedQRCode = qrImage
                }
            }
        }
    }
    
    // Generate QR code from string
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else {
            return nil
        }
        
        // Scale up the QR code for better quality
        let scale: CGFloat = 10
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Scanner Frame View

struct ScannerFrameView: View {
    var body: some View {
        ZStack {
            // Top left corner
            CornerShape(corner: .topLeft)
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 60, height: 60)
                .position(x: 30, y: 30)
            
            // Top right corner
            CornerShape(corner: .topRight)
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 60, height: 60)
                .position(x: 220, y: 30)
            
            // Bottom left corner
            CornerShape(corner: .bottomLeft)
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 60, height: 60)
                .position(x: 30, y: 220)
            
            // Bottom right corner
            CornerShape(corner: .bottomRight)
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 60, height: 60)
                .position(x: 220, y: 220)
        }
    }
}

// MARK: - Corner Shape

struct CornerShape: Shape {
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    let corner: Corner
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 16
        
        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: cornerRadius))
            path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(180),
                       endAngle: .degrees(270),
                       clockwise: false)
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            
        case .topRight:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
            path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(270),
                       endAngle: .degrees(0),
                       clockwise: false)
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            
        case .bottomLeft:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: rect.height - cornerRadius))
            path.addArc(center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(180),
                       endAngle: .degrees(90),
                       clockwise: true)
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            
        case .bottomRight:
            path.move(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
            path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(0),
                       endAngle: .degrees(90),
                       clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        }
        
        return path
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = CameraUIView()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class CameraUIView: UIView {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        checkPermissionAndSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        checkPermissionAndSetup()
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
        self.captureSession = session
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
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
        sessionQueue.async { [captureSession] in
            captureSession?.stopRunning()
        }
    }
}

#Preview {
    QRScannerView()
}
