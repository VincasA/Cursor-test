import Foundation
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {
    enum ThemeOption: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var label: String {
            switch self {
            case .system:
                return "System Default"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            }
        }
    }

    @Published var customCategories: [String]
    @Published var theme: ThemeOption
    @Published private(set) var isArchiving: Bool = false

    private let userDefaults: UserDefaults
    private let customCategoryKey = "EarnTime.customCategories"
    private let themeKey = "EarnTime.theme"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.customCategories = userDefaults.stringArray(forKey: customCategoryKey) ?? []
        if let storedTheme = userDefaults.string(forKey: themeKey),
           let option = ThemeOption(rawValue: storedTheme) {
            self.theme = option
        } else {
            self.theme = .system
        }
    }

    func addCustomCategory(name: String) {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        guard !customCategories.contains(where: { $0.caseInsensitiveCompare(cleaned) == .orderedSame }) else { return }
        customCategories.append(cleaned)
        persistCustomCategories()
    }

    func removeCustomCategory(at offsets: IndexSet) {
        customCategories.remove(atOffsets: offsets)
        persistCustomCategories()
    }

    func updateTheme(_ option: ThemeOption) {
        theme = option
        userDefaults.set(option.rawValue, forKey: themeKey)
    }

    func persistCustomCategories() {
        userDefaults.set(customCategories, forKey: customCategoryKey)
    }

    func archiveOlderThanOneWeek(using context: ModelContext) async throws {
        guard !isArchiving else { return }
        isArchiving = true
        defer { isArchiving = false }

        let cutoff = CreditManager.archiveCutoff()
        let sessionDescriptor = FetchDescriptor<TaskSession>(
            predicate: #Predicate { $0.endDate < cutoff && !$0.isArchived }
        )
        let spendDescriptor = FetchDescriptor<ScreenTimeLog>(
            predicate: #Predicate { $0.createdAt < cutoff && !$0.isArchived }
        )

        let sessions = try context.fetch(sessionDescriptor)
        let spends = try context.fetch(spendDescriptor)

        sessions.forEach { $0.isArchived = true }
        spends.forEach { $0.isArchived = true }

        try context.save()
    }
}
