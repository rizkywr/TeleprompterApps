import Foundation
import AVFoundation
import UIKit
import Combine

enum VideoResolutionFormat: String, CaseIterable, Identifiable {
    case hd720p30 = "720p HD at 30 fps"
    case hd1080p30 = "1080p HD at 30 fps"
    case hd1080p60 = "1080p HD at 60 fps"
    case uhd4K30 = "4K at 30 fps"
    case uhd4K60 = "4K at 60 fps"
    
    var id: String { rawValue }
    
    var shortTitle: String {
        switch self {
        case .hd720p30: return "720p · 30"
        case .hd1080p30: return "1080p · 30"
        case .hd1080p60: return "1080p · 60"
        case .uhd4K30: return "4K · 30"
        case .uhd4K60: return "4K · 60"
        }
    }
    
    var preset: AVCaptureSession.Preset {
        switch self {
        case .hd720p30: return .hd1280x720
        case .hd1080p30, .hd1080p60: return .hd1920x1080
        case .uhd4K30, .uhd4K60: return .hd4K3840x2160
        }
    }
    
    var targetFrameRate: Int32 {
        switch self {
        case .hd720p30, .hd1080p30, .uhd4K30: return 30
        case .hd1080p60, .uhd4K60: return 60
        }
    }
    
    var storageFootnote: String {
        switch self {
        case .hd720p30: return "60 MB with 720p HD at 30 fps (space saver)"
        case .hd1080p30: return "130 MB with 1080p HD at 30 fps (default)"
        case .hd1080p60: return "175 MB with 1080p HD at 60 fps (smoother video)"
        case .uhd4K30: return "190 MB with 4K at 30 fps (higher resolution)"
        case .uhd4K60: return "350 MB with 4K at 60 fps (high resolution & smooth)"
        }
    }
}

final class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning: Bool = false
    @Published var isRecording: Bool = false
    @Published var isRecordingPaused: Bool = false
    @Published var isFinishingRecording: Bool = false
    @Published var isFrontCamera: Bool = true
    @Published var recordingDuration: TimeInterval = 0
    @Published var latestRecording: Recording? = nil
    @Published var setupError: String? = nil
    @Published var currentOrientation: AVCaptureVideoOrientation = .portrait
    @Published var zoomFactor: CGFloat = 1.0
    @Published var selectedZoomLevel: Double = 1.0
    
    // Native iOS Camera Settings
    @Published var videoFormat: VideoResolutionFormat = .hd1080p60
    @Published var isStabilizationEnabled: Bool = true
    @Published var showGrid: Bool = false
    @Published var mirrorFrontCamera: Bool = true
    @Published var isTorchOn: Bool = false
    
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.speakframe.camera.sessionQueue")
    private let movieOutput = AVCaptureMovieFileOutput()
    
    private var currentVideoDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var recordingTimer: Timer?
    private var startTime: Date?
    private var recordedSegments: [URL] = []
    private var accumulatedDuration: TimeInterval = 0
    private var currentSegmentStartTime: Date?
    private var isPendingPause: Bool = false
    
    override init() {
        super.init()
        loadPersistedSettings()
    }
    
    private func loadPersistedSettings() {
        if let savedFormat = UserDefaults.standard.string(forKey: "default_video_format"),
           let format = VideoResolutionFormat(rawValue: savedFormat) {
            self.videoFormat = format
        }
        if UserDefaults.standard.object(forKey: "default_show_grid") != nil {
            self.showGrid = UserDefaults.standard.bool(forKey: "default_show_grid")
        }
        if UserDefaults.standard.object(forKey: "mirror_front_camera") != nil {
            self.mirrorFrontCamera = UserDefaults.standard.bool(forKey: "mirror_front_camera")
        }
        if UserDefaults.standard.object(forKey: "video_stabilization") != nil {
            self.isStabilizationEnabled = UserDefaults.standard.bool(forKey: "video_stabilization")
        }
    }
    
    func start() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureAudioSession()
            self.configureSession()
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                    self.isRecording = false
                    self.isRecordingPaused = false
                    self.stopDurationTimer()
                }
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session for recording: \(error)")
        }
    }
    
    private func configureSession() {
        guard session.inputs.isEmpty else { return }
        
        session.beginConfiguration()
        if session.canSetSessionPreset(videoFormat.preset) {
            session.sessionPreset = videoFormat.preset
        } else {
            session.sessionPreset = .high
        }
        
        // Video Input (Default: Front Camera)
        let cameraPosition: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        if let videoDevice = bestCamera(for: cameraPosition) {
            do {
                let videoIn = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoIn) {
                    session.addInput(videoIn)
                    self.videoInput = videoIn
                    self.currentVideoDevice = videoDevice
                    configureFrameRate(for: videoFormat, on: videoDevice)
                }
            } catch {
                DispatchQueue.main.async {
                    self.setupError = "Gagal memuat input kamera: \(error.localizedDescription)"
                }
            }
        }
        
        // Audio Input
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let audioIn = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioIn) {
                    session.addInput(audioIn)
                    self.audioInput = audioIn
                }
            } catch {
                print("Failed to add audio input: \(error)")
            }
        }
        
        // Movie Output
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            updateConnectionOrientation()
        }
        
        // Live Audio Data Output (for Speech Recognition & Follow)
        session.commitConfiguration()
    }
    
    func applyVideoFormat(_ format: VideoResolutionFormat) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            if self.session.canSetSessionPreset(format.preset) {
                self.session.sessionPreset = format.preset
            }
            if let device = self.currentVideoDevice {
                self.configureFrameRate(for: format, on: device)
            }
            self.session.commitConfiguration()
            self.updateConnectionOrientation()
            DispatchQueue.main.async {
                self.videoFormat = format
                UserDefaults.standard.set(format.rawValue, forKey: "default_video_format")
            }
        }
    }
    
    func setGrid(enabled: Bool) {
        showGrid = enabled
        UserDefaults.standard.set(enabled, forKey: "default_show_grid")
    }
    
    func setMirrorFrontCamera(enabled: Bool) {
        mirrorFrontCamera = enabled
        UserDefaults.standard.set(enabled, forKey: "mirror_front_camera")
        sessionQueue.async { [weak self] in
            self?.updateConnectionOrientation()
        }
    }
    
    func setStabilization(enabled: Bool) {
        isStabilizationEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "video_stabilization")
        sessionQueue.async { [weak self] in
            self?.updateConnectionOrientation()
        }
    }
    
    var hasTorch: Bool {
        guard let device = currentVideoDevice else { return false }
        return device.hasTorch && device.isTorchAvailable
    }
    
    func toggleTorch() {
        setTorch(on: !isTorchOn)
    }
    
    func setTorch(on: Bool) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if let device = self.currentVideoDevice, device.hasTorch && device.isTorchAvailable {
                do {
                    try device.lockForConfiguration()
                    device.torchMode = on ? .on : .off
                    device.unlockForConfiguration()
                } catch {
                    print("Failed to set torch: \(error)")
                }
            }
            DispatchQueue.main.async {
                self.isTorchOn = on
            }
        }
    }
    
    private func configureFrameRate(for format: VideoResolutionFormat, on device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            let targetFPS = Double(format.targetFrameRate)
            for range in device.activeFormat.videoSupportedFrameRateRanges {
                if targetFPS >= range.minFrameRate && targetFPS <= range.maxFrameRate {
                    device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: format.targetFrameRate)
                    device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: format.targetFrameRate)
                    break
                }
            }
            device.unlockForConfiguration()
        } catch {
            print("Failed to configure framerate: \(error)")
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let newPosition: AVCaptureDevice.Position = self.isFrontCamera ? .back : .front
            guard let newDevice = self.bestCamera(for: newPosition) else { return }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                self.session.beginConfiguration()
                if let currentInput = self.videoInput {
                    self.session.removeInput(currentInput)
                }
                
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.videoInput = newInput
                    self.currentVideoDevice = newDevice
                    self.configureFrameRate(for: self.videoFormat, on: newDevice)
                    DispatchQueue.main.async {
                        self.isFrontCamera = (newPosition == .front)
                        self.zoomFactor = 1.0
                        self.selectedZoomLevel = 1.0
                        self.isTorchOn = false
                    }
                    self.updateConnectionOrientation()
                } else {
                    if let current = self.videoInput {
                        self.session.addInput(current)
                    }
                }
                self.session.commitConfiguration()
            } catch {
                print("Error switching camera: \(error)")
            }
        }
    }
    
    func updateOrientation(_ orientation: AVCaptureVideoOrientation) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentOrientation = orientation
            }
            self.updateConnectionOrientation(with: orientation)
        }
    }
    
    private func updateConnectionOrientation(with orientation: AVCaptureVideoOrientation? = nil) {
        let activeOrientation = orientation ?? self.currentOrientation
        
        if let connection = movieOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = activeOrientation
            }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = self.isFrontCamera && self.mirrorFrontCamera
            }
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = self.isStabilizationEnabled ? .cinematic : .off
            }
        }
    }
    
    // Tap to focus & exposure (Native iOS Camera behavior)
    func focus(at devicePoint: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentVideoDevice else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            } catch {
                print("Failed to set focus/exposure: \(error)")
            }
        }
    }
    
    // Native Lens Zoom Selector (0.5x, 1x, 2x)
    func setZoomLevel(_ level: Double) {
        DispatchQueue.main.async {
            self.selectedZoomLevel = level
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if level == 0.5 {
                // If ultra-wide physical device is available, switch to it
                if let ultraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back),
                   self.currentVideoDevice?.uniqueID != ultraWide.uniqueID {
                    self.switchVideoDevice(to: ultraWide, targetZoom: 1.0)
                } else if let device = self.currentVideoDevice {
                    self.applyHardwareZoom(to: device, factor: device.minAvailableVideoZoomFactor)
                }
            } else if level == 1.0 {
                // Standard Wide-Angle camera at 1.0x
                if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                   self.currentVideoDevice?.uniqueID != wide.uniqueID {
                    self.switchVideoDevice(to: wide, targetZoom: 1.0)
                } else if let device = self.currentVideoDevice {
                    self.applyHardwareZoom(to: device, factor: 1.0)
                }
            } else if level == 2.0 {
                // Telephoto lens if available, otherwise 2.0x digital crop on Wide camera
                if let telephoto = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back),
                   self.currentVideoDevice?.uniqueID != telephoto.uniqueID {
                    self.switchVideoDevice(to: telephoto, targetZoom: 1.0)
                } else if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                          self.currentVideoDevice?.uniqueID != wide.uniqueID {
                    self.switchVideoDevice(to: wide, targetZoom: min(wide.maxAvailableVideoZoomFactor, 2.0))
                } else if let device = self.currentVideoDevice {
                    let target = min(device.maxAvailableVideoZoomFactor, 2.0)
                    self.applyHardwareZoom(to: device, factor: target)
                }
            }
        }
    }
    
    private func switchVideoDevice(to newDevice: AVCaptureDevice, targetZoom: CGFloat) {
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            session.beginConfiguration()
            if let current = videoInput {
                session.removeInput(current)
            }
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                self.videoInput = newInput
                self.currentVideoDevice = newDevice
                self.configureFrameRate(for: self.videoFormat, on: newDevice)
                self.updateConnectionOrientation()
            }
            session.commitConfiguration()
            
            applyHardwareZoom(to: newDevice, factor: targetZoom)
        } catch {
            print("Failed to switch camera device: \(error)")
        }
    }
    
    private func applyHardwareZoom(to device: AVCaptureDevice, factor: CGFloat) {
        do {
            try device.lockForConfiguration()
            let minZoom = device.minAvailableVideoZoomFactor
            let maxZoom = min(device.maxAvailableVideoZoomFactor, 10.0)
            let clamped = max(minZoom, min(factor, maxZoom))
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
            
            DispatchQueue.main.async {
                self.zoomFactor = clamped
            }
        } catch {
            print("Failed to apply zoom: \(error)")
        }
    }
    
    // Direct zoom setting (supports custom zoom factor)
    func setZoom(_ factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentVideoDevice else { return }
            self.applyHardwareZoom(to: device, factor: factor)
        }
    }
    
    // Incremental pinch-to-zoom
    func applyPinchZoom(scale: CGFloat) {
        let newZoom = self.zoomFactor * scale
        setZoom(newZoom)
        let nearest: Double
        if newZoom < 0.75 { nearest = 0.5 }
        else if newZoom < 1.5 { nearest = 1.0 }
        else { nearest = 2.0 }
        DispatchQueue.main.async {
            self.selectedZoomLevel = nearest
        }
    }
    
    private func bestCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if position == .back {
            if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                return wide
            }
            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInTripleCamera],
                mediaType: .video,
                position: .back
            )
            return discovery.devices.first
        } else {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }
    }
    
    // MARK: - Multi-Segment Recording & Pause/Resume
    
    func startRecording() {
        guard !isRecording && !isFinishingRecording else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Clean up any stale segments from previous takes
            for url in self.recordedSegments {
                try? FileManager.default.removeItem(at: url)
            }
            self.recordedSegments.removeAll()
            self.accumulatedDuration = 0
            self.isPendingPause = false
            
            let tempDir = FileManager.default.temporaryDirectory
            let segmentURL = tempDir.appendingPathComponent("segment_\(UUID().uuidString).mov")
            try? FileManager.default.removeItem(at: segmentURL)
            
            self.updateConnectionOrientation()
            self.movieOutput.startRecording(to: segmentURL, recordingDelegate: self)
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.isRecordingPaused = false
                self.isFinishingRecording = false
                self.recordingDuration = 0
                self.currentSegmentStartTime = Date()
                self.startDurationTimer()
            }
        }
    }
    
    func pauseRecording() {
        guard isRecording && !isRecordingPaused && !isFinishingRecording else { return }
        
        stopDurationTimer()
        if let start = currentSegmentStartTime {
            accumulatedDuration += Date().timeIntervalSince(start)
            recordingDuration = accumulatedDuration
        }
        currentSegmentStartTime = nil
        isPendingPause = true
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
        }
    }
    
    func resumeRecording() {
        guard isRecording && isRecordingPaused && !isFinishingRecording else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let tempDir = FileManager.default.temporaryDirectory
            let segmentURL = tempDir.appendingPathComponent("segment_\(UUID().uuidString).mov")
            try? FileManager.default.removeItem(at: segmentURL)
            
            self.updateConnectionOrientation()
            self.movieOutput.startRecording(to: segmentURL, recordingDelegate: self)
            
            DispatchQueue.main.async {
                self.isRecordingPaused = false
                self.isPendingPause = false
                self.currentSegmentStartTime = Date()
                self.startDurationTimer()
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        stopDurationTimer()
        if let start = currentSegmentStartTime {
            accumulatedDuration += Date().timeIntervalSince(start)
            recordingDuration = accumulatedDuration
        }
        currentSegmentStartTime = nil
        
        let wasPaused = isRecordingPaused
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.isRecordingPaused = false
            self.isFinishingRecording = true
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            } else if wasPaused {
                self.processFinishedSegments()
            }
        }
    }
    
    private func startDurationTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.currentSegmentStartTime else { return }
            self.recordingDuration = self.accumulatedDuration + Date().timeIntervalSince(start)
        }
    }
    
    private func stopDurationTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    func clearRecording() {
        if let current = latestRecording {
            try? FileManager.default.removeItem(at: current.fileURL)
            latestRecording = nil
        }
        for segment in recordedSegments {
            try? FileManager.default.removeItem(at: segment)
        }
        recordedSegments.removeAll()
    }
    
    private func processFinishedSegments() {
        guard !recordedSegments.isEmpty else {
            DispatchQueue.main.async {
                self.isFinishingRecording = false
                self.setupError = "Gagal menyimpan rekaman video. Durasi terlalu singkat."
            }
            return
        }
        
        if recordedSegments.count == 1 {
            let singleTake = recordedSegments[0]
            let duration = self.recordingDuration
            DispatchQueue.main.async {
                self.isFinishingRecording = false
                self.latestRecording = Recording(fileURL: singleTake, duration: duration)
            }
        } else {
            mergeSegments(recordedSegments) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isFinishingRecording = false
                    switch result {
                    case .success(let mergedURL):
                        self.latestRecording = Recording(fileURL: mergedURL, duration: self.recordingDuration)
                    case .failure(let error):
                        print("Failed to merge segments: \(error)")
                        if let first = self.recordedSegments.first {
                            self.latestRecording = Recording(fileURL: first, duration: self.recordingDuration)
                        } else {
                            self.setupError = "Gagal menggabungkan rekaman video: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
    
    private func mergeSegments(_ segments: [URL], completion: @escaping (Result<URL, Error>) -> Void) {
        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            completion(.failure(NSError(domain: "SpeakFrame", code: -1, userInfo: [NSLocalizedDescriptionKey: "Gagal membuat video track."])))
            return
        }
        
        let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        
        var currentTime = CMTime.zero
        var isFirstTrack = true
        
        for segmentURL in segments {
            let asset = AVURLAsset(url: segmentURL)
            let assetDuration = asset.duration
            let timeRange = CMTimeRange(start: .zero, duration: assetDuration)
            
            if let videoTrack = asset.tracks(withMediaType: .video).first {
                do {
                    try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: currentTime)
                    if isFirstTrack {
                        compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
                        isFirstTrack = false
                    }
                } catch {
                    print("Error inserting video segment: \(error)")
                }
            }
            
            if let audioTrack = asset.tracks(withMediaType: .audio).first, let compAudio = compositionAudioTrack {
                try? compAudio.insertTimeRange(timeRange, of: audioTrack, at: currentTime)
            }
            
            currentTime = CMTimeAdd(currentTime, assetDuration)
        }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("merged_\(UUID().uuidString).mov")
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            completion(.failure(NSError(domain: "SpeakFrame", code: -2, userInfo: [NSLocalizedDescriptionKey: "Gagal membuat export session."])))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                for segment in segments {
                    try? FileManager.default.removeItem(at: segment)
                }
                completion(.success(outputURL))
            case .failed, .cancelled:
                let err = exportSession.error ?? NSError(domain: "SpeakFrame", code: -3, userInfo: [NSLocalizedDescriptionKey: "Gagal mengekspor gabungan video."])
                completion(.failure(err))
            default:
                break
            }
        }
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        var success = true
        if let error = error as NSError? {
            success = (error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) ?? false
            if !success {
                print("Recording segment finished with failure: \(error)")
            }
        }
        
        if success {
            self.recordedSegments.append(outputFileURL)
        }
        
        if self.isPendingPause {
            DispatchQueue.main.async {
                self.isPendingPause = false
                self.isRecordingPaused = true
            }
        } else if !self.isRecording {
            self.processFinishedSegments()
        }
    }
}
