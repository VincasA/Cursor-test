import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, ObservableObject {
    private let center = UNUserNotificationCenter.current()
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        center.delegate = self
        Task {
            await refreshAuthorizationStatus()
        }
    }

    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            if !granted {
                print("Notification permission not granted by user.")
            }
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
        }
    }

    func scheduleCountdownCompletion(in seconds: TimeInterval, message: String) {
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "EarnTime"
        content.body = message
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.sound, .banner]
    }
}
