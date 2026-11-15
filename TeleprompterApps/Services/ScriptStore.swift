import Foundation
import Combine
import SwiftUI

@MainActor
final class ScriptStore: ObservableObject {
    @Published var scripts: [Script] = []
    @Published var folders: [ScriptFolder] = []
    @Published var selectedFolderId: UUID? = nil // nil means "All Scripts"
    @Published var recentRecordings: [Recording] = []
    
    private let fileURL: URL
    private let foldersFileURL: URL
    private let recordingsFileURL: URL
    
    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("saved_scripts.json")
        self.foldersFileURL = documents.appendingPathComponent("saved_folders.json")
        self.recordingsFileURL = documents.appendingPathComponent("saved_recordings.json")
        load()
    }
    
    func load() {
        // Load folders
        if FileManager.default.fileExists(atPath: foldersFileURL.path) {
            do {
                let data = try Data(contentsOf: foldersFileURL)
                self.folders = try JSONDecoder().decode([ScriptFolder].self, from: data)
            } catch {
                print("Failed to load folders: \(error)")
                self.folders = []
            }
        } else {
            // Default starter folders for neat organization
            self.folders = [
                ScriptFolder(name: "YouTube"),
                ScriptFolder(name: "TikTok / Reels")
            ]
            saveFolders()
        }
        
        // Load scripts
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            self.scripts = [Script.sample]
            save()
        } else {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoded = try JSONDecoder().decode([Script].self, from: data)
                var loaded = decoded.sorted { $0.updatedAt > $1.updatedAt }
                // Migrate old sample scripts if present
                for i in 0..<loaded.count {
                    if loaded[i].title == "Welcome to SpeakFrame" || (loaded[i].title == "Welcome to PromptCam" && (!loaded[i].content.contains("From Developer - Rizky Wr"))) {
                        loaded[i] = Script.sample
                        break
                    }
                }
                self.scripts = loaded
                save()
            } catch {
                print("Failed to load scripts: \(error)")
                self.scripts = [Script.sample]
            }
        }
        
        // Load recordings
        if FileManager.default.fileExists(atPath: recordingsFileURL.path) {
            do {
                let data = try Data(contentsOf: recordingsFileURL)
                self.recentRecordings = try JSONDecoder().decode([Recording].self, from: data)
            } catch {
                print("Failed to load recordings: \(error)")
            }
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(scripts)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Failed to save scripts: \(error)")
        }
    }
    
    func saveFolders() {
        do {
            let data = try JSONEncoder().encode(folders)
            try data.write(to: foldersFileURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Failed to save folders: \(error)")
        }
    }
    
    func saveRecordings() {
        do {
            let data = try JSONEncoder().encode(recentRecordings)
            try data.write(to: recordingsFileURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Failed to save recordings: \(error)")
        }
    }
    
    // MARK: - Folder Management
    @discardableResult
    func createFolder(name: String) -> ScriptFolder {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let folderName = trimmed.isEmpty ? "New Folder" : trimmed
        let folder = ScriptFolder(name: folderName)
        folders.append(folder)
        saveFolders()
        return folder
    }
    
    func renameFolder(_ folder: ScriptFolder, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index].name = trimmed
            saveFolders()
        }
    }
    
    func deleteFolder(_ folder: ScriptFolder) {
        // Move scripts from this folder to unfiled
        for i in 0..<scripts.count {
            if scripts[i].folderId == folder.id {
                scripts[i].folderId = nil
            }
        }
        folders.removeAll { $0.id == folder.id }
        if selectedFolderId == folder.id {
            selectedFolderId = nil
        }
        save()
        saveFolders()
    }
    
    func moveScript(_ script: Script, to folderId: UUID?) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index].folderId = folderId
            scripts[index].updatedAt = Date()
            save()
        }
    }
    
    func folder(for id: UUID?) -> ScriptFolder? {
        guard let id = id else { return nil }
        return folders.first(where: { $0.id == id })
    }
    
    func scriptCount(for folderId: UUID?) -> Int {
        if let folderId = folderId {
            return scripts.filter { $0.folderId == folderId }.count
        } else {
            return scripts.count
        }
    }
    
    var filteredScripts: [Script] {
        if let folderId = selectedFolderId {
            return scripts.filter { $0.folderId == folderId }
        } else {
            return scripts
        }
    }
    
    // MARK: - Recording Management
    func addRecording(_ recording: Recording) {
        recentRecordings.insert(recording, at: 0)
        saveRecordings()
    }
    
    func deleteRecording(_ recording: Recording) {
        try? FileManager.default.removeItem(at: recording.fileURL)
        recentRecordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }
    
    // MARK: - Script CRUD
    func add(_ script: Script) {
        var newScript = script
        newScript.updatedAt = Date()
        // If user is currently in a specific folder, assign it automatically
        if newScript.folderId == nil && selectedFolderId != nil {
            newScript.folderId = selectedFolderId
        }
        scripts.insert(newScript, at: 0)
        save()
    }
    
    func update(_ script: Script) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            var updated = script
            updated.updatedAt = Date()
            scripts[index] = updated
            scripts.sort { $0.updatedAt > $1.updatedAt }
            save()
        } else {
            add(script)
        }
    }
    
    func delete(at offsets: IndexSet) {
        let scriptsToDelete = offsets.map { filteredScripts[$0] }
        scripts.removeAll { script in
            scriptsToDelete.contains { $0.id == script.id }
        }
        save()
    }
    
    func delete(_ script: Script) {
        scripts.removeAll { $0.id == script.id }
        save()
    }
    
    func duplicate(_ script: Script) {
        let copy = Script(
            title: "\(script.title) (Copy)",
            content: script.content,
            folderId: script.folderId,
            createdAt: Date(),
            updatedAt: Date()
        )
        scripts.insert(copy, at: 0)
        save()
    }
}
