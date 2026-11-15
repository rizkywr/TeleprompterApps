import SwiftUI

struct ScriptCard: View {
    let script: Script
    var folderName: String? = nil
    var folders: [ScriptFolder] = []
    let onRecord: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    var onMoveToFolder: ((UUID?) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Title, folder badge, reading time badge, and action button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(script.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(script.updatedAt, style: .date)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(AppTheme.textTertiary)
                        
                        if let folderName = folderName, !folderName.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 10))
                                Text(folderName)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(AppTheme.accent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(AppTheme.accentSoft)
                            .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                // One-tap Record Studio pill button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onRecord()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 11))
                        Text("Record")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            // Content preview (HIG Subheadline)
            Text(script.content)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(2)
                .lineSpacing(4)
            
            Divider()
                .background(AppTheme.separator)
            
            // Bottom metadata & context menu (HIG Caption 1)
            HStack {
                HStack(spacing: 12) {
                    Label("\(script.wordCount) words", systemImage: "doc.text")
                    Label(script.formattedDuration, systemImage: "clock")
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                // More options menu
                Menu {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onRecord()
                    } label: {
                        Label("Record in Studio", systemImage: "video")
                    }
                    
                    if !folders.isEmpty, let onMoveToFolder = onMoveToFolder {
                        Menu {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onMoveToFolder(nil)
                            } label: {
                                if script.folderId == nil {
                                    Label("Unfiled (No Folder)", systemImage: "checkmark")
                                } else {
                                    Text("Unfiled (No Folder)")
                                }
                            }
                            
                            ForEach(folders) { folder in
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    onMoveToFolder(folder.id)
                                } label: {
                                    if script.folderId == folder.id {
                                        Label(folder.name, systemImage: "checkmark")
                                    } else {
                                        Label(folder.name, systemImage: "folder")
                                    }
                                }
                            }
                        } label: {
                            Label("Move to Folder", systemImage: "folder")
                        }
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onDuplicate()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    
                    Button(role: .destructive) {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.surfaceSecondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(AppTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}
