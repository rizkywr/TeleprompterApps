import SwiftUI
import AVKit

struct VideoReviewView: View {
    let recording: Recording
    let onRetake: () -> Void
    let onDismiss: () -> Void
    
    @State private var player: AVPlayer
    @State private var isPlaying: Bool = true
    @State private var currentTime: Double = 0
    @State private var totalDuration: Double = 0
    @State private var isScrubbing: Bool = false
    @State private var scrubTime: Double = 0
    @State private var isSaving: Bool = false
    @State private var isSaved: Bool = false
    @State private var saveSuccess: Bool = false
    @State private var errorMessage: String? = nil
    
    @State private var timeObserver: Any?
    
    init(recording: Recording, onRetake: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.recording = recording
        self.onRetake = onRetake
        self.onDismiss = onDismiss
        _player = State(initialValue: AVPlayer(url: recording.fileURL))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Video Player
                VideoPlayer(player: player)
                    .ignoresSafeArea(edges: .bottom)
                    .onTapGesture {
                        togglePlayPause()
                    }
                
                // Center play button overlay when paused
                if !isPlaying && !saveSuccess {
                    Button {
                        togglePlayPause()
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.white.opacity(0.85))
                            .shadow(radius: 8)
                    }
                }
                
                // Bottom control overlay bar
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Interactive Video Scrubber Bar
                        let effectiveDuration = max(0.1, totalDuration > 0 ? totalDuration : recording.duration)
                        let activeDisplayTime = isScrubbing ? scrubTime : currentTime
                        let progress = max(0.0, min(1.0, activeDisplayTime / effectiveDuration))
                        
                        GeometryReader { geo in
                            let width = geo.size.width
                            let currentPos = width * CGFloat(progress)
                            
                            ZStack(alignment: .leading) {
                                // Background track
                                Capsule()
                                    .fill(Color.white.opacity(0.28))
                                    .frame(height: isScrubbing ? 6 : 4)
                                
                                // Played progress
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: max(0, min(width, currentPos)), height: isScrubbing ? 6 : 4)
                                
                                // Scrubber Thumb Indicator
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: isScrubbing ? 18 : 14, height: isScrubbing ? 18 : 14)
                                    .shadow(color: Color.black.opacity(0.45), radius: 4, x: 0, y: 1)
                                    .offset(x: max(0, min(width - (isScrubbing ? 18 : 14), currentPos - (isScrubbing ? 9 : 7))))
                            }
                            .frame(height: 36)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let clampedX = max(0, min(width, value.location.x))
                                        let pct = Double(clampedX / width)
                                        let targetSec = pct * effectiveDuration
                                        
                                        if !isScrubbing {
                                            isScrubbing = true
                                            player.pause()
                                        }
                                        scrubTime = targetSec
                                        player.seek(
                                            to: CMTime(seconds: targetSec, preferredTimescale: 600),
                                            toleranceBefore: .zero,
                                            toleranceAfter: .zero
                                        )
                                    }
                                    .onEnded { value in
                                        let clampedX = max(0, min(width, value.location.x))
                                        let pct = Double(clampedX / width)
                                        let targetSec = pct * effectiveDuration
                                        
                                        player.seek(
                                            to: CMTime(seconds: targetSec, preferredTimescale: 600),
                                            toleranceBefore: .zero,
                                            toleranceAfter: .zero
                                        ) { _ in
                                            self.isScrubbing = false
                                            if self.isPlaying {
                                                self.player.play()
                                            }
                                        }
                                    }
                            )
                        }
                        .frame(height: 36)
                        
                        // Time & Control buttons
                        HStack(alignment: .center) {
                            Text(formatTime(activeDisplayTime))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            HStack(spacing: 24) {
                                // Replay / Restart to beginning button (Clear bold icon)
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    restartVideo()
                                } label: {
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))
                                }
                                
                                // Play / Pause button
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    togglePlayPause()
                                } label: {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Spacer()
                            
                            Text(formatTime(effectiveDuration))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Pure Floating Save Notice (No box)
                if saveSuccess {
                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 68, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.9), radius: 14, x: 0, y: 4)
                        
                        Text("Saved cleanly to Gallery!")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.9), radius: 14, x: 0, y: 4)
                    }
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        cleanUpAndRetake()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Retake")
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Review")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isSaved {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            tearDownPlayback()
                            onDismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                Text("Done")
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        }
                    } else {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            saveVideo()
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                    Text("Save")
                                }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                            }
                        }
                        .disabled(isSaving)
                    }
                }
            }
            .alert("Error Saving Video", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                setupPlayback()
            }
            .onDisappear {
                tearDownPlayback()
            }
        }
    }
    
    private func setupPlayback() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to set audio session for playback: \(error)")
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            self.restartVideo()
        }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            self.currentTime = time.seconds
            if let duration = self.player.currentItem?.duration.seconds, !duration.isNaN && duration > 0 {
                self.totalDuration = duration
            }
        }
        
        player.play()
        isPlaying = true
    }
    
    private func tearDownPlayback() {
        player.pause()
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
    
    private func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    private func restartVideo() {
        player.seek(to: .zero)
        player.play()
        isPlaying = true
    }
    
    private func cleanUpAndRetake() {
        tearDownPlayback()
        onRetake()
    }
    
    private func saveVideo() {
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                try await PhotosExporter.shared.saveVideoToPhotos(url: recording.fileURL)
                await MainActor.run {
                    self.isSaving = false
                    self.isSaved = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        self.saveSuccess = true
                    }
                    
                    // Stay on this screen; fade out floating center message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.35)) {
                            self.saveSuccess = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
