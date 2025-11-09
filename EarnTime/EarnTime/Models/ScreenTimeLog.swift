import Foundation
import SwiftData

@Model
final class ScreenTimeLog {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var minutesUsed: Int
    var source: String
    var notes: String?
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        minutesUsed: Int,
        source: String = "Manual",
        notes: String? = nil,
        isArchived: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.minutesUsed = minutesUsed
        self.source = source
        self.notes = notes
        self.isArchived = isArchived
    }
}
