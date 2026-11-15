import SwiftUI
import AVFoundation

struct CameraStudioView: View {
    let script: Script
    var onTakeFinished: ((Recording) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var prompterViewModel = TeleprompterViewModel()
    @StateObject private var permissionsManager = PermissionsManager()
    
    @State private var showingSettings: Bool = false
    @State private var settingsInitialTab: TeleprompterSettingsView.SettingsTab = .prompter
    @State private var permissionsDenied: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 1. Live Camera Feed with Tap-to-Focus & Pinch-to-Zoom
                CameraPreviewView(
                    session: cameraManager.session,
                    isFrontCamera: cameraManager.isFrontCamera,
                    videoOrientation: cameraManager.currentOrientation,
                    onFocusTap: { devicePoint in
                        cameraManager.focus(at: devicePoint)
                    },
                    onPinchZoom: { scale in
                        cameraManager.applyPinchZoom(scale: scale)
                    }
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.25), value: cameraManager.currentOrientation)
                
                // 1b. Composition Grid Overlay (Native 3x3 Rule-of-Thirds)
                if cameraManager.showGrid {
                    CameraGridOverlay()
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
                
                // 2. Pure Floating Teleprompter Layer (Adapts padding to landscape/portrait)
                TeleprompterView(script: script, viewModel: prompterViewModel)
                    .padding(.top, isLandscape ? 36 : 56)
                    .padding(.bottom, isLandscape ? 12 : 92)
                    .padding(.horizontal, isLandscape ? 68 : 0)
                
                // 3. Countdown Overlay with Punchy White Pop-Up Animation
                if prompterViewModel.isCountingDown {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    
                    Text("\(prompterViewModel.countdownSeconds)")
                        .id(prompterViewModel.countdownSeconds)
                        .font(.system(size: 118, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.85), radius: 24, x: 0, y: 8)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.25).combined(with: .opacity),
                                removal: .scale(scale: 1.35).combined(with: .opacity)
                            )
                        )
                }
                
                // 4. Processing Video Overlay (Right after tapping stop)
                if cameraManager.isFinishingRecording {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Processing take...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                    .transition(.opacity)
                }
                
                // 5. Responsive Studio Controls (Portrait vs Landscape Native Layout)
                if isLandscape {
                    landscapeControlsView
                } else {
                    portraitControlsView
                }
            }
            .onAppear {
                updateOrientation(for: geo.size)
            }
            .onChange(of: geo.size) { newSize in
                withAnimation(.easeInOut(duration: 0.25)) {
                    updateOrientation(for: newSize)
                }
            }
        }
        .onAppear {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        .onDisappear {
            if !showingSettings && cameraManager.latestRecording == nil {
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
                cameraManager.stop()
                prompterViewModel.pauseScrolling()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                updateOrientation(for: windowScene.screen.bounds.size)
            }
        }
        .sheet(isPresented: $showingSettings) {
            TeleprompterSettingsView(viewModel: prompterViewModel, cameraManager: cameraManager, selectedTab: $settingsInitialTab)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $cameraManager.latestRecording) { recording in
            VideoReviewView(
                recording: recording,
                onRetake: {
                    cameraManager.clearRecording()
                    prompterViewModel.restartScript()
                    cameraManager.start()
                },
                onDismiss: {
                    onTakeFinished?(recording)
                    cameraManager.clearRecording()
                    cameraManager.stop()
                    dismiss()
                }
            )
            .onAppear {
                cameraManager.stop()
            }
        }
        .alert("Camera & Mic Permissions Needed", isPresented: $permissionsDenied) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("PromptCam requires camera and microphone permissions to record your studio video.")
        }
        .task {
            let cameraGranted = await permissionsManager.requestCamera()
            let micGranted = await permissionsManager.requestMicrophone()
            
            if cameraGranted && micGranted {
                cameraManager.start()
            } else {
                permissionsDenied = true
            }
        }
    }
    
    // MARK: - Subviews & Controls
    
    // Unified Floating Top Bar (Clean 3-Section Non-Colliding Layout)
    private var topBarView: some View {
        ZStack {
            // 1. Side Action Buttons (Far Left and Far Right with Spacer)
            HStack(alignment: .center) {
                // Left Buttons: Dismiss Studio [X] and Torch (Generous 48x48 pt hit targets)
                HStack(spacing: 8) {
                    // Dismiss Studio Button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        cameraManager.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .disabled(cameraManager.isRecording || cameraManager.isFinishingRecording)
                    .opacity((cameraManager.isRecording || cameraManager.isFinishingRecording) ? 0.3 : 1.0)
                    
                    // Native Flash ON / OFF Button (Only active when Back Camera)
                    if !cameraManager.isFrontCamera {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            cameraManager.toggleTorch()
                        } label: {
                            Image(systemName: cameraManager.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(cameraManager.isTorchOn ? .yellow : .white)
                                .frame(width: 42, height: 42)
                                .background(
                                    cameraManager.isTorchOn ? Color.yellow.opacity(0.28) : Color.black.opacity(0.4)
                                )
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(cameraManager.isTorchOn ? Color.yellow.opacity(0.85) : Color.clear, lineWidth: 1.5)
                                )
                        }
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                // Right Action Buttons (Settings & Resolution)
                HStack(spacing: 8) {
                    // Resolution Badge - Visible ONLY when idle or playing script (hidden during recording/pause to guarantee zero collision)
                    if !cameraManager.isRecording {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            settingsInitialTab = .camera
                            showingSettings = true
                        } label: {
                            Text(cameraManager.videoFormat.shortTitle)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Studio & Camera Settings Button - Always accessible anytime (including during pause or recording)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        settingsInitialTab = .prompter
                        showingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .disabled(cameraManager.isFinishingRecording)
                    .opacity(cameraManager.isFinishingRecording ? 0.35 : 1.0)
                }
            }
            
            // 2. Dead-Center Live REC / PAUSED Indicator (Layered in ZStack with zero possibility of collision)
            if cameraManager.isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(cameraManager.isRecordingPaused ? Color.yellow : Color.red)
                        .frame(width: 8, height: 8)
                    Text(cameraManager.isRecordingPaused ? "PAUSED" : "REC")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(cameraManager.isRecordingPaused ? .yellow : .red)
                    Text(formatDuration(cameraManager.recordingDuration))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.75))
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(cameraManager.isRecordingPaused ? Color.yellow.opacity(0.8) : Color.red.opacity(0.6), lineWidth: 1)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // Portrait Controls: Shutter at bottom center
    private var portraitControlsView: some View {
        VStack {
            topBarView
                .padding(.horizontal, 20)
                .padding(.top, 8)
            
            Spacer()
            
            // Floating Prompter Controls (Restart & Play/Pause) - Positioned ABOVE Speed & Font HUD
            HStack(spacing: 16) {
                // Prompter Restart / Undo Button
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    prompterViewModel.restartScript()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 34, height: 34)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
                .disabled(cameraManager.isFinishingRecording)
                
                // Prompter Play / Pause Button
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    prompterViewModel.toggleScrolling()
                } label: {
                    Image(systemName: prompterViewModel.isScrolling ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .disabled(cameraManager.isFinishingRecording)
            }
            .padding(.bottom, 8)
            
            // Direct Quick Adjust HUD: Speed & Font Size (Record View) - Can be hidden
            PrompterQuickAdjustBar(viewModel: prompterViewModel)
                .padding(.bottom, 10)
            
            // Native iPhone Camera Zoom Selector (0.5x, 1x, 2x) - Back Camera Only
            if !cameraManager.isFrontCamera {
                nativeZoomSelectorView
                    .padding(.bottom, 12)
            }
            
            // Camera Shutter + Switch Camera + Pause/Resume Centered Cluster (Tightly grouped around Shutter)
            HStack(alignment: .center, spacing: 26) {
                // Switch Camera Button (Active when idle or when paused to change angles)
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    cameraManager.switchCamera()
                } label: {
                    Image(systemName: "camera.rotate.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                }
                .disabled((cameraManager.isRecording && !cameraManager.isRecordingPaused) || cameraManager.isFinishingRecording)
                .opacity(((cameraManager.isRecording && !cameraManager.isRecordingPaused) || cameraManager.isFinishingRecording) ? 0.3 : 1.0)
                
                // Primary Shutter Button (Start Recording or Stop/Finish Take) - 76 pt Hero
                Button {
                    handleShutterTap()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 76, height: 76)
                        
                        if cameraManager.isRecording {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                                .frame(width: 32, height: 32)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 62, height: 62)
                        }
                    }
                }
                .disabled(cameraManager.isFinishingRecording)
                .opacity(cameraManager.isFinishingRecording ? 0.5 : 1.0)
                
                // Right Satellite: Pause / Resume Record Button or Symmetrical Anchor
                ZStack {
                    if cameraManager.isRecording {
                        Button {
                            handlePauseResumeTap()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(cameraManager.isRecordingPaused ? Color.yellow.opacity(0.25) : Color.black.opacity(0.45))
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Circle().stroke(cameraManager.isRecordingPaused ? Color.yellow : Color.white.opacity(0.25), lineWidth: 1.5)
                                    )
                                
                                Image(systemName: cameraManager.isRecordingPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(cameraManager.isRecordingPaused ? .yellow : .white)
                            }
                        }
                        .disabled(cameraManager.isFinishingRecording)
                        .transition(.scale.combined(with: .opacity))
                    } else if cameraManager.zoomFactor > 1.05 {
                        Text(String(format: "%.1fx", cameraManager.zoomFactor))
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.black.opacity(0.55))
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    } else {
                        // Invisible symmetrical spacer to keep shutter mathematically dead-center when idle
                        Color.clear
                            .frame(width: 48, height: 48)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 24)
        }
    }
    
    // Landscape Controls: Ergonomic native camera grip with shutter on right side
    private var landscapeControlsView: some View {
        ZStack {
            // Top Bar
            VStack {
                topBarView
                    .padding(.horizontal, 36)
                    .padding(.top, 10)
                Spacer()
            }
            
            // Left Column: Prompter Controls & Quick Adjust
            HStack {
                VStack(alignment: .leading, spacing: 14) {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Prompter Restart / Undo Button
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            prompterViewModel.restartScript()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 34, height: 34)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        }
                        .disabled(cameraManager.isFinishingRecording)
                        
                        // Prompter Play / Pause Button
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            prompterViewModel.toggleScrolling()
                        } label: {
                            Image(systemName: prompterViewModel.isScrolling ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .disabled(cameraManager.isFinishingRecording)
                    }
                    
                    PrompterQuickAdjustBar(viewModel: prompterViewModel)
                    
                    Spacer()
                }
                .padding(.leading, 28)
                
                Spacer()
                
                // Right Column: Native Camera Shutter & Controls
                VStack(spacing: 16) {
                    Spacer()
                    
                    // Switch Camera (Active when idle or paused)
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        cameraManager.switchCamera()
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .disabled((cameraManager.isRecording && !cameraManager.isRecordingPaused) || cameraManager.isFinishingRecording)
                    .opacity(((cameraManager.isRecording && !cameraManager.isRecordingPaused) || cameraManager.isFinishingRecording) ? 0.3 : 1.0)
                    
                    // Native Zoom Selector (0.5x, 1x, 2x) in Landscape
                    if !cameraManager.isFrontCamera {
                        nativeZoomSelectorView
                    }
                    
                    // Pause / Resume Record Button in Landscape (Visible while recording)
                    if cameraManager.isRecording {
                        Button {
                            handlePauseResumeTap()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(cameraManager.isRecordingPaused ? Color.yellow.opacity(0.25) : Color.black.opacity(0.45))
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .frame(width: 46, height: 46)
                                    .overlay(
                                        Circle().stroke(cameraManager.isRecordingPaused ? Color.yellow : Color.white.opacity(0.25), lineWidth: 1.5)
                                    )
                                
                                Image(systemName: cameraManager.isRecordingPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(cameraManager.isRecordingPaused ? .yellow : .white)
                            }
                        }
                        .disabled(cameraManager.isFinishingRecording)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Shutter Button
                    Button {
                        handleShutterTap()
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 72, height: 72)
                            
                            if cameraManager.isRecording {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red)
                                    .frame(width: 28, height: 28)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 58, height: 58)
                            }
                        }
                    }
                    .disabled(cameraManager.isFinishingRecording)
                    .opacity(cameraManager.isFinishingRecording ? 0.5 : 1.0)
                    
                    // Zoom indicator if active
                    if cameraManager.zoomFactor > 1.05 {
                        Text(String(format: "%.1fx", cameraManager.zoomFactor))
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                    } else {
                        Color.clear.frame(width: 46, height: 20)
                    }
                    
                    Spacer()
                }
                .padding(.trailing, 28)
            }
        }
    }
    
    // MARK: - Actions & Orientation Logic
    
    private func updateOrientation(for size: CGSize) {
        let isLandscape = size.width > size.height
        
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            switch windowScene.interfaceOrientation {
            case .landscapeLeft:
                cameraManager.updateOrientation(.landscapeLeft)
                return
            case .landscapeRight:
                cameraManager.updateOrientation(.landscapeRight)
                return
            case .portrait:
                cameraManager.updateOrientation(.portrait)
                return
            case .portraitUpsideDown:
                cameraManager.updateOrientation(.portraitUpsideDown)
                return
            default:
                break
            }
        }
        
        let deviceOrientation = UIDevice.current.orientation
        if deviceOrientation == .landscapeRight {
            cameraManager.updateOrientation(.landscapeLeft)
        } else if deviceOrientation == .landscapeLeft {
            cameraManager.updateOrientation(.landscapeRight)
        } else if isLandscape {
            cameraManager.updateOrientation(.landscapeRight)
        } else {
            cameraManager.updateOrientation(.portrait)
        }
    }
    
    private func handleShutterTap() {
        if cameraManager.isRecording {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            cameraManager.stopRecording()
            prompterViewModel.pauseScrolling()
        } else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            prompterViewModel.startCountdown {
                cameraManager.startRecording()
                prompterViewModel.resumeScrolling()
            }
        }
    }
    
    private func handlePauseResumeTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if cameraManager.isRecordingPaused {
            cameraManager.resumeRecording()
            prompterViewModel.resumeScrolling()
        } else {
            cameraManager.pauseRecording()
            prompterViewModel.pauseScrolling()
        }
    }
    

    // MARK: - Native iPhone Style Zoom Selector Pill (0.5x, 1x, 2x)
    private var nativeZoomSelectorView: some View {
        HStack(spacing: 4) {
            ForEach([0.5, 1.0, 2.0], id: \.self) { zoom in
                let isSelected = (cameraManager.selectedZoomLevel == zoom)
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        cameraManager.setZoomLevel(zoom)
                    }
                } label: {
                    Text(zoomLabel(for: zoom))
                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .rounded))
                        .foregroundColor(isSelected ? Color.yellow : Color.white)
                        .frame(width: zoom == 0.5 ? 44 : 36, height: 32)
                        .background(
                            isSelected ? Color.black.opacity(0.75) : Color.clear
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.55))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 2)
        .transition(.scale.combined(with: .opacity))
    }
    
    private func zoomLabel(for zoom: Double) -> String {
        if zoom == 0.5 {
            return "0.5x"
        } else if zoom == 1.0 {
            return "1x"
        } else {
            return "2x"
        }
    }

        private func formatDuration(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}


// MARK: - Native iOS 3x3 Composition Grid Overlay
struct CameraGridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                
                path.move(to: CGPoint(x: w / 3, y: 0))
                path.addLine(to: CGPoint(x: w / 3, y: h))
                path.move(to: CGPoint(x: 2 * w / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * w / 3, y: h))
                
                path.move(to: CGPoint(x: 0, y: h / 3))
                path.addLine(to: CGPoint(x: w, y: h / 3))
                path.move(to: CGPoint(x: 0, y: 2 * h / 3))
                path.addLine(to: CGPoint(x: w, y: 2 * h / 3))
            }
            .stroke(Color.white.opacity(0.32), lineWidth: 1)
        }
    }
}
