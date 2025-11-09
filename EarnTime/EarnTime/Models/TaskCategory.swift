import Foundation

enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case focusSession = "focus"
    case exercise = "exercise"
    case chores = "chores"
    case reading = "reading"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .focusSession:
            return "Focus Session"
        case .exercise:
            return "Exercise"
        case .chores:
            return "Chores"
        case .reading:
            return "Reading"
        case .custom:
            return "Custom"
        }
    }

    var defaultDurationMinutes: Int {
        switch self {
        case .focusSession:
            return 25
        case .exercise:
            return 30
        case .chores:
            return 15
        case .reading:
            return 20
        case .custom:
            return 10
        }
    }
}
