import Foundation

struct ScriptFolder: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, icon: String = "folder.fill", createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
    }
}
