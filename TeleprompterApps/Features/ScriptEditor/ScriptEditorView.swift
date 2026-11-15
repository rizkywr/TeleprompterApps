import SwiftUI

struct ScriptEditorView: View {
    @ObservedObject var scriptStore: ScriptStore
    @Environment(\.dismiss) private var dismiss
    
    @State var script: Script
    var isNew: Bool
    var onStartRecord: ((Script) -> Void)?
    
    @State private var showingStudio: Bool = false
    @State private var showingFileImporter: Bool = false
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var undoStack: [ScriptSnapshot] = []
    @State private var showingUndoToast: Bool = false
    @State private var undoToastMessage: String = ""
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isBodyFocused: Bool
    
    init(scriptStore: ScriptStore, script: Script? = nil, onStartRecord: ((Script) -> Void)? = nil) {
        self.scriptStore = scriptStore
        self.onStartRecord = onStartRecord
        if let script = script {
            _script = State(initialValue: script)
            self.isNew = false
        } else {
            _script = State(initialValue: Script(title: "", content: "", folderId: scriptStore.selectedFolderId))
            self.isNew = true
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Seamless uniform canvas background
            AppTheme.canvas
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    // Rounded-square back/dismiss control
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        hideKeyboard()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.separator, lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    EyebrowBadge(text: "SCRIPT EDITOR")
                    
                    Spacer()
                    
                    // Undo button
                    if !undoStack.isEmpty {
                        Button {
                            handleUndo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppTheme.accent)
                                .frame(width: 38, height: 38)
                                .background(AppTheme.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Save button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        hideKeyboard()
                        saveChanges()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.boldBlue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(AppTheme.accentSoft)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(AppTheme.canvas)
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
                
                // Editor Body & Stats - dynamically bounded to viewport height
                GeometryReader { geo in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            // Title Row
                            HStack {
                                ZStack(alignment: .leading) {
                                    if script.title.isEmpty {
                                        Text("Script Title")
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                                    
                                    TextField("", text: $script.title)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .focused($isTitleFocused)
                                }
                                
                                Spacer(minLength: 16)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        hideKeyboard()
                                    }
                            }
                            
                            // Folder Selector Pill & Import Button
                            HStack {
                                Menu {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        script.folderId = nil
                                    } label: {
                                        if script.folderId == nil {
                                            Label("Unfiled (No Folder)", systemImage: "checkmark")
                                        } else {
                                            Text("Unfiled (No Folder)")
                                        }
                                    }
                                    
                                    ForEach(scriptStore.folders) { folder in
                                        Button {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            script.folderId = folder.id
                                        } label: {
                                            if script.folderId == folder.id {
                                                Label(folder.name, systemImage: "checkmark")
                                            } else {
                                                Label(folder.name, systemImage: "folder")
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 12))
                                        Text(scriptStore.folder(for: script.folderId)?.name ?? "Folder: Unfiled")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                    .foregroundColor(script.folderId == nil ? AppTheme.textSecondary : AppTheme.accent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(script.folderId == nil ? AppTheme.surfaceSecondary : AppTheme.accentSoft)
                                    .clipShape(Capsule())
                                }
                                
                                Spacer()
                                
                                // Import Menu - Enlarged, Prominent & Noticeable
                                Menu {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        showingFileImporter = true
                                    } label: {
                                        Label("Import from Files (.txt, .md, .rtf)", systemImage: "folder")
                                    }
                                    
                                    Button {
                                        handlePasteFromClipboard()
                                    } label: {
                                        Label("Paste from Notes / Clipboard", systemImage: "doc.on.clipboard")
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.down.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text("Import")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(AppTheme.accent)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(AppTheme.accentSoft)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.top, 2)
                            
                            Divider()
                                .background(AppTheme.separator.opacity(0.6))
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    hideKeyboard()
                                }
                            
                            // Seamless Script Text Input
                            ZStack(alignment: .topLeading) {
                                if script.content.isEmpty {
                                    Text("Write or paste your teleprompter script here...\n\nKeep sentences natural and conversational.")
                                        .font(.system(size: 17, weight: .regular, design: .rounded))
                                        .foregroundColor(AppTheme.textTertiary)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $script.content)
                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .lineSpacing(6)
                                    .focused($isBodyFocused)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .frame(minHeight: 140)
                            }
                            
                            // HIG Footnote Stats Badges
                            HStack(spacing: 12) {
                                statBadge(icon: "doc.text", title: "\(script.wordCount) words")
                                statBadge(icon: "character", title: "\(script.characterCount) chars")
                                Spacer()
                                statBadge(icon: "clock.fill", title: script.formattedDuration, isHighlight: true)
                            }
                            .padding(.top, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                hideKeyboard()
                            }
                            
                            // Flexible spacer that fills the rest of the visible screen without overflowing
                            Spacer(minLength: 10)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    hideKeyboard()
                                }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                        .frame(minHeight: geo.size.height - 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hideKeyboard()
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                hideKeyboard()
                            }
                    )
                }
            }
            
            // Floating Undo Banner above bottom action bar
            if showingUndoToast {
                HStack(spacing: 12) {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.accent)
                    
                    Text(undoToastMessage)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        handleUndo()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12, weight: .bold))
                            Text("Undo")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.separator, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 24)
                .padding(.bottom, 88)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(20)
            }
            
            // Sticky Bottom Action Bar: Continue to Record
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    Divider().background(AppTheme.separator)
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        hideKeyboard()
                        saveChanges()
                        if let onStartRecord = onStartRecord {
                            dismiss()
                            onStartRecord(script)
                        } else {
                            showingStudio = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 15))
                            Text("Continue to Record")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(script.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.4) : AppTheme.accent)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.accent.opacity(script.content.isEmpty ? 0 : 0.35), radius: 8, x: 0, y: 4)
                    }
                    .disabled(script.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .background(AppTheme.canvas.opacity(0.95))
                .background(.ultraThinMaterial)
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if !undoStack.isEmpty {
                    Button {
                        handleUndo()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.accent)
                    }
                }
                
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    hideKeyboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "keyboard.chevron.compact.down")
                        Text("Done")
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.boldBlue)
                }
            }
        }
        .fullScreenCover(isPresented: $showingStudio) {
            CameraStudioView(script: script)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: ScriptImporter.supportedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else { return }
                do {
                    let (importedTitle, importedContent) = try ScriptImporter.extractScript(from: selectedURL)
                    undoStack.append(ScriptSnapshot(title: script.title, content: script.content))
                    if script.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        script.title = importedTitle
                    }
                    if script.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        script.content = importedContent
                    } else {
                        script.content += "\n\n" + importedContent
                    }
                    showUndoBanner(message: "File Imported")
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } catch {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
        .alert("Import Notice", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func statBadge(icon: String, title: String, isHighlight: Bool = false) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(isHighlight ? AppTheme.accentSoft : AppTheme.surfaceSecondary)
        .foregroundColor(isHighlight ? AppTheme.accent : AppTheme.textSecondary)
        .clipShape(Capsule())
    }
    
    private func hideKeyboard() {
        isTitleFocused = false
        isBodyFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveChanges() {
        var cleanTitle = script.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.isEmpty {
            let firstLine = script.content.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            cleanTitle = firstLine.isEmpty ? "Untitled Script" : String(firstLine.prefix(40))
        }
        
        script.title = cleanTitle
        if isNew {
            scriptStore.add(script)
        } else {
            scriptStore.update(script)
        }
    }

    private func handlePasteFromClipboard() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let (pastedTitle, pastedContent) = ScriptImporter.extractFromClipboard() {
            undoStack.append(ScriptSnapshot(title: script.title, content: script.content))
            if script.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                script.title = pastedTitle
            }
            if script.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                script.content = pastedContent
            } else {
                script.content += "\n\n" + pastedContent
            }
            showUndoBanner(message: "Pasted from Notes")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            errorMessage = "No text found in clipboard. Copy your script from Apple Notes or Files first!"
            showingErrorAlert = true
        }
    }
    
    private func handleUndo() {
        guard let previous = undoStack.popLast() else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            script.title = previous.title
            script.content = previous.content
            showingUndoToast = false
        }
    }
    
    private func showUndoBanner(message: String) {
        undoToastMessage = message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showingUndoToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showingUndoToast = false
            }
        }
    }

}


struct ScriptSnapshot: Equatable {
    let title: String
    let content: String
}
