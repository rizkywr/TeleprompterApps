import SwiftUI

struct TakeCard: View {
    let recording: Recording
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Video Thumbnail / Icon Box
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.accentSoft)
                    .frame(width: 68, height: 68)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.accent)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text("Take \(recording.id.uuidString.prefix(4).uppercased())")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(recording.createdAt, style: .date)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
                
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 11))
                    Text(formatDuration(recording.duration))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(AppTheme.accentDeep)
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Play Button
            Button {
                onPlay()
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
    
    private func formatDuration(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
