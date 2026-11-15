import Foundation
import Photos

final class PhotosExporter {
    static let shared = PhotosExporter()
    
    private init() {}
    
    func saveVideoToPhotos(url: URL) async throws {
        // Ensure access first
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            let granted = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard granted == .authorized || granted == .limited else {
                throw PhotosError.notAuthorized
            }
        } else if status != .authorized && status != .limited {
            throw PhotosError.notAuthorized
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
}

enum PhotosError: LocalizedError {
    case notAuthorized
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Photos permission was denied. Please allow access in iOS Settings."
        case .saveFailed:
            return "Failed to save video to Photos."
        }
    }
}
