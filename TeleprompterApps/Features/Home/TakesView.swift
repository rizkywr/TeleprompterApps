import SwiftUI

struct TakesView: View {
    let scriptStore: ScriptStore
    let onStartRecord: () -> Void
    
    @State private var selectedTakeForReview: Recording? = nil
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Seamless background with smooth ambient glow that diffuses into canvas with ZERO harsh lines
                ZStack(alignment: .topLeading) {
                    AppTheme.canvas.ignoresSafeArea()
                    
                    RadialGradient(
                        colors: [
                            AppTheme.lightBlue.opacity(0.32),
                            AppTheme.lightBlue.opacity(0.14),
                            AppTheme.canvas.opacity(0)
                        ],
                        center: .topLeading,
                        startRadius: 20,
                        endRadius: 420
                    )
                    .ignoresSafeArea()
                }
                
                // Content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Hero Header
                        VStack(alignment: .leading, spacing: 8) {
                            EyebrowBadge(text: "RECORDING ARCHIVE")
                            
                            // HIG Large Title (34pt, Bold, SF Pro Rounded)
                            Text("Your Takes")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            // HIG Subheadline (15pt, Regular, SF Pro Rounded)
                            Text("Review your latest teleprompter takes and exports.")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        if scriptStore.recentRecordings.isEmpty {
                            emptyTakesView
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(scriptStore.recentRecordings) { recording in
                                    TakeCard(
                                        recording: recording,
                                        onPlay: {
                                            selectedTakeForReview = recording
                                        },
                                        onDelete: {
                                            scriptStore.deleteRecording(recording)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedTakeForReview) { recording in                VideoReviewView(
                    recording: recording,
                    onRetake: {
                        selectedTakeForReview = nil
                    },
                    onDismiss: {
                        selectedTakeForReview = nil
                    }
                )
            }
        }
    }
    
    private var emptyTakesView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentSoft)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "video.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.accent)
            }
            .padding(.top, 40)
            
            Text("No Recorded Takes Yet")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            Text("Select any script from your library and start recording to see your takes here.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            Button {
                onStartRecord()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "video.fill")
                    Text("Start Studio")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(AppTheme.accent)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
