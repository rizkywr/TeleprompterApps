import Foundation
import AVFoundation
import Photos
import Combine

@MainActor
final class PermissionsManager: ObservableObject {
    @Published var cameraAuthorized: Bool = false
    @Published var microphoneAuthorized: Bool = false
    @Published var photosAuthorized: Bool = false
    
    init() {
        checkStatus()
    }
    
    func checkStatus() {
        cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        let photoStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        photosAuthorized = (photoStatus == .authorized || photoStatus == .limited)
    }
    
    func requestCamera() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraAuthorized = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraAuthorized = granted
            return granted
        default:
            cameraAuthorized = false
            return false
        }
    }
    
    func requestMicrophone() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            microphoneAuthorized = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            microphoneAuthorized = granted
            return granted
        default:
            microphoneAuthorized = false
            return false
        }
    }
    
    func requestPhotos() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            photosAuthorized = true
            return true
        case .notDetermined:
            let result = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            let granted = (result == .authorized || result == .limited)
            photosAuthorized = granted
            return granted
        default:
            photosAuthorized = false
            return false
        }
    }
}
