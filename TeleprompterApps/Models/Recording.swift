import Foundation

struct Recording: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var fileURL: URL
    var createdAt: Date = Date()
    var duration: TimeInterval = 0
}
