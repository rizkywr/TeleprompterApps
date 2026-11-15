import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let isFrontCamera: Bool
    let videoOrientation: AVCaptureVideoOrientation
    let onFocusTap: ((CGPoint) -> Void)?
    let onPinchZoom: ((CGFloat) -> Void)?
    
    init(
        session: AVCaptureSession,
        isFrontCamera: Bool = true,
        videoOrientation: AVCaptureVideoOrientation = .portrait,
        onFocusTap: ((CGPoint) -> Void)? = nil,
        onPinchZoom: ((CGFloat) -> Void)? = nil
    ) {
        self.session = session
        self.isFrontCamera = isFrontCamera
        self.videoOrientation = videoOrientation
        self.onFocusTap = onFocusTap
        self.onPinchZoom = onPinchZoom
    }
    
    class VideoPreviewUIView: UIView, UIGestureRecognizerDelegate {
        var onFocusTap: ((CGPoint) -> Void)?
        var onPinchZoom: ((CGFloat) -> Void)?
        
        private var focusBox: UIView?
        
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupGestures()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupGestures()
        }
        
        private func setupGestures() {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.delegate = self
            addGestureRecognizer(tap)
            
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            addGestureRecognizer(pinch)
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard gestureRecognizer is UITapGestureRecognizer else { return true }
            let point = touch.location(in: self)
            
            // Protect UI control regions: Top bar (~110 pt) and Bottom controls (~140 pt)
            // Taps in these areas are reserved for buttons (Dismiss X, Flash, Settings, Shutter, Prompter),
            // and should never be captured as camera autofocus/exposure taps.
            let topProtectionZone: CGFloat = max(safeAreaInsets.top, 44) + 60
            let bottomProtectionZone: CGFloat = bounds.height - (max(safeAreaInsets.bottom, 20) + 140)
            
            return point.y >= topProtectionZone && point.y <= bottomProtectionZone
        }
        
        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: self)
            let topProtectionZone: CGFloat = max(safeAreaInsets.top, 44) + 60
            let bottomProtectionZone: CGFloat = bounds.height - (max(safeAreaInsets.bottom, 20) + 140)
            
            guard point.y >= topProtectionZone && point.y <= bottomProtectionZone else {
                return
            }
            
            showFocusBox(at: point)
            
            let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
            onFocusTap?(devicePoint)
        }
        
        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            onPinchZoom?(gesture.scale)
            gesture.scale = 1.0
        }
        
        private func showFocusBox(at point: CGPoint) {
            focusBox?.removeFromSuperview()
            
            let boxSize: CGFloat = 68
            let box = UIView(frame: CGRect(x: point.x - boxSize / 2, y: point.y - boxSize / 2, width: boxSize, height: boxSize))
            box.layer.borderColor = UIColor.systemYellow.cgColor
            box.layer.borderWidth = 1.5
            box.layer.cornerRadius = 6
            box.alpha = 0
            box.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            
            addSubview(box)
            focusBox = box
            
            UIView.animate(withDuration: 0.2, animations: {
                box.alpha = 1.0
                box.transform = .identity
            }) { _ in
                UIView.animate(withDuration: 0.4, delay: 0.8, options: .curveEaseOut, animations: {
                    box.alpha = 0
                }) { _ in
                    box.removeFromSuperview()
                }
            }
        }
        
        func applyConfiguration(session: AVCaptureSession, isFront: Bool, orientation: AVCaptureVideoOrientation) {
            if previewLayer.session != session {
                previewLayer.session = session
            }
            if let connection = previewLayer.connection {
                if connection.isVideoOrientationSupported && connection.videoOrientation != orientation {
                    connection.videoOrientation = orientation
                }
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = isFront
                }
            }
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewUIView {
        let view = VideoPreviewUIView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onFocusTap = onFocusTap
        view.onPinchZoom = onPinchZoom
        view.applyConfiguration(session: session, isFront: isFrontCamera, orientation: videoOrientation)
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {
        uiView.onFocusTap = onFocusTap
        uiView.onPinchZoom = onPinchZoom
        uiView.applyConfiguration(session: session, isFront: isFrontCamera, orientation: videoOrientation)
    }
}
