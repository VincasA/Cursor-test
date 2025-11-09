import Foundation
import SwiftData

@Model
final class TaskSession {
    @Attribute(.unique) var id: UUID
    private var categoryRawValue: String
    var customLabel: String?
    var startDate: Date
    var endDate: Date
    var durationSeconds: Double
    var earnedMinutes: Int
    var notes: String?
    var isArchived: Bool

    var category: TaskCategory {
        get {
            TaskCategory(rawValue: categoryRawValue) ?? .custom
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }

    var durationMinutes: Int {
        Int(durationSeconds / 60.0)
    }

    var displayName: String {
        if let customLabel, !customLabel.isEmpty {
            return customLabel
        }
        return category.displayName
    }

    init(
        id: UUID = UUID(),
        category: TaskCategory,
        customLabel: String? = nil,
        startDate: Date,
        endDate: Date,
        durationSeconds: Double,
        earnedMinutes: Int,
        notes: String? = nil,
        isArchived: Bool = false
    ) {
        self.id = id
        self.categoryRawValue = category.rawValue
        self.customLabel = customLabel
        self.startDate = startDate
        self.endDate = endDate
        self.durationSeconds = durationSeconds
        self.earnedMinutes = earnedMinutes
        self.notes = notes
        self.isArchived = isArchived
    }
}
