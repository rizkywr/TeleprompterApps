import Foundation

struct Script: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var folderId: UUID? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        folderId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.folderId = folderId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, folderId, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.folderId = try container.decodeIfPresent(UUID.self, forKey: .folderId)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
    
    var wordCount: Int {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    var characterCount: Int {
        content.count
    }
    
    /// Estimated reading duration based on typical speaking rate (130 words per minute)
    var estimatedDuration: TimeInterval {
        guard wordCount > 0 else { return 0 }
        return Double(wordCount) / (130.0 / 60.0)
    }
    
    var formattedDuration: String {
        let minutes = Int(estimatedDuration) / 60
        let seconds = Int(estimatedDuration) % 60
        if minutes > 0 {
            return String(format: "%d min %02d sec", minutes, seconds)
        } else {
            return String(format: "%d sec", seconds)
        }
    }
    
    static var sample: Script {
        Script(
            title: "Welcome to PromptCam",
            content: """
            Hey Creator! Welcome to PromptCam.
            
            Today, I want to share a quick secret that completely changed the way I create videos.
            
            For a long time, talking to a camera lens felt difficult. I would lose my train of thought, constantly look away from the lens, and spend hours recording take after take.
            
            With PromptCam, everything just clicks.
            
            Your words scroll naturally right next to the camera, so you never miss a beat—all while keeping direct, confident eye contact with your audience.
            
            Here is the best part: you don't have to memorize a single line. Just relax, be yourself, and speak with confidence.
            
            Whenever you're ready, tap that red record button—and let's create something amazing!
            
            From Developer - Rizky WR
            """
        )
    }
}


import UniformTypeIdentifiers
import UIKit

enum ScriptImporter {
    static let supportedContentTypes: [UTType] = [
        .plainText,
        .utf8PlainText,
        .text,
        .rtf
    ]
    
    static func extractScript(from url: URL) throws -> (title: String, content: String) {
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let rawFileName = url.deletingPathExtension().lastPathComponent
        let cleanTitle = rawFileName
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
        
        // RTF support
        if url.pathExtension.lowercased() == "rtf" {
            if let attributed = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) {
                let text = attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    return (cleanTitle, text)
                }
            }
        }
        
        // UTF-8 Plain text & markdown
        if let utf8String = try? String(contentsOf: url, encoding: .utf8) {
            let trimmed = utf8String.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return (cleanTitle, trimmed)
            }
        }
        
        // ISO Latin 1 fallback
        if let latinString = try? String(contentsOf: url, encoding: .isoLatin1) {
            let trimmed = latinString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return (cleanTitle, trimmed)
            }
        }
        
        // General Data fallback
        if let data = try? Data(contentsOf: url), let asciiString = String(data: data, encoding: .ascii) {
            let trimmed = asciiString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return (cleanTitle, trimmed)
            }
        }
        
        throw NSError(domain: "ScriptImporter", code: 2, userInfo: [NSLocalizedDescriptionKey: "The selected file is empty or cannot be read as text."])
    }
    
    static func extractFromClipboard() -> (title: String, content: String)? {
        guard let text = UIPasteboard.general.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        let title: String
        if let firstLine = lines.first, !firstLine.isEmpty {
            title = String(firstLine.prefix(32))
        } else {
            title = "Imported Notes"
        }
        
        return (title, trimmed)
    }
}
