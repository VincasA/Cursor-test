import Foundation

enum CreditManager {
    static func availableMinutes(
        sessions: [TaskSession],
        logs: [ScreenTimeLog]
    ) -> Int {
        let earned = sessions.reduce(into: 0) { partialResult, session in
            partialResult += session.earnedMinutes
        }
        let spent = logs.reduce(into: 0) { partialResult, log in
            partialResult += log.minutesUsed
        }
        return max(0, earned - spent)
    }

    static func earnedMinutesByDay(sessions: [TaskSession]) -> [Date: Int] {
        var daily: [Date: Int] = [:]
        let calendar = Calendar.current

        for session in sessions {
            let day = calendar.startOfDay(for: session.endDate)
            daily[day, default: 0] += session.earnedMinutes
        }
        return daily
    }

    static func spentMinutesByDay(logs: [ScreenTimeLog]) -> [Date: Int] {
        var daily: [Date: Int] = [:]
        let calendar = Calendar.current

        for log in logs {
            let day = calendar.startOfDay(for: log.createdAt)
            daily[day, default: 0] += log.minutesUsed
        }
        return daily
    }

    static func archiveCutoff(referenceDate: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
    }
}
