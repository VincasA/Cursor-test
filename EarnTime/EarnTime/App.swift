import SwiftUI
import SwiftData

@main
struct EarnTimeApp: App {
    private let sharedModelContainer: ModelContainer
    @StateObject private var notificationService = NotificationService()
    @StateObject private var settingsViewModel = SettingsViewModel()

    init() {
        do {
            let schema = Schema([
                TaskSession.self,
                ScreenTimeLog.self
            ])
            sharedModelContainer = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationService)
                .environmentObject(settingsViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
