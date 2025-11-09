import Foundation
import UniformTypeIdentifiers

@MainActor
final class StatsViewModel: ObservableObject {
    enum RangeOption: String, CaseIterable, Identifiable {
        case last7Days
        case last30Days
        case allTime

        var id: String { rawValue }

        var label: String {
            switch self {
            case .last7Days:
                return "7 Days"
            case .last30Days:
                return "30 Days"
            case .allTime:
                return "All Time"
            }
        }

        func cutoffDate(reference: Date = .now) -> Date? {
            let calendar = Calendar.current
            switch self {
            case .last7Days:
                return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: reference))
            case .last30Days:
                return calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: reference))
            case .allTime:
                return nil
            }
        }
    }

    enum ExportFormat: String, CaseIterable, Identifiable {
        case csv
        case json

        var id: String { rawValue }
        var label: String { rawValue.uppercased() }
        var contentType: UTType {
            switch self {
            case .csv:
                return .commaSeparatedText
            case .json:
                return .json
            }
        }

        var fileExtension: String {
            switch self {
            case .csv:
                return "csv"
            case .json:
                return "json"
            }
        }
    }

    struct DailyStat: Identifiable {
        let id: Date
        let date: Date
        let earnedMinutes: Int
        let spentMinutes: Int
    }

    @Published var range: RangeOption = .last7Days
    @Published var exportFormat: ExportFormat = .csv

    func makeChartData(
        sessions: [TaskSession],
        logs: [ScreenTimeLog]
    ) -> [DailyStat] {
        let filteredSessions = filter(sessions: sessions)
        let filteredLogs = filter(logs: logs)
        let earnedByDay = CreditManager.earnedMinutesByDay(sessions: filteredSessions)
        let spentByDay = CreditManager.spentMinutesByDay(logs: filteredLogs)

        let allKeys = Set(earnedByDay.keys).union(spentByDay.keys)
        let sortedKeys = allKeys.sorted()

        return sortedKeys.map { day in
            DailyStat(
                id: day,
                date: day,
                earnedMinutes: earnedByDay[day] ?? 0,
                spentMinutes: spentByDay[day] ?? 0
            )
        }
    }

    func filter(sessions: [TaskSession]) -> [TaskSession] {
        guard let cutoff = range.cutoffDate() else { return sessions }
        return sessions.filter { $0.endDate >= cutoff }
    }

    func filter(logs: [ScreenTimeLog]) -> [ScreenTimeLog] {
        guard let cutoff = range.cutoffDate() else { return logs }
        return logs.filter { $0.createdAt >= cutoff }
    }

    func makeExportDocument(
        sessions: [TaskSession],
        logs: [ScreenTimeLog]
    ) throws -> ExportDocument {
        let stats = makeChartData(sessions: sessions, logs: logs)
        let filename = "earn-time-stats-\(range.label.lowercased().replacingOccurrences(of: " ", with: "-")).\(exportFormat.fileExtension)"

        switch exportFormat {
        case .csv:
            let csv = makeCSV(from: stats)
            guard let data = csv.data(using: .utf8) else {
                throw StatsExporterError.encodingFailed
            }
            return ExportDocument(data: data, filename: filename, contentType: exportFormat.contentType)

        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let payload = stats.map { stat in
                DailyExportPayload(
                    date: stat.date,
                    earnedMinutes: stat.earnedMinutes,
                    spentMinutes: stat.spentMinutes
                )
            }
            let data = try encoder.encode(payload)
            return ExportDocument(data: data, filename: filename, contentType: exportFormat.contentType)
        }
    }
}

private extension StatsViewModel {
    struct DailyExportPayload: Codable {
        let date: Date
        let earnedMinutes: Int
        let spentMinutes: Int
    }

    func makeCSV(from stats: [DailyStat]) -> String {
        var rows = ["date,earned_minutes,spent_minutes"]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        for stat in stats {
            let row = [
                formatter.string(from: stat.date),
                "\(stat.earnedMinutes)",
                "\(stat.spentMinutes)"
            ].joined(separator: ",")
            rows.append(row)
        }

        return rows.joined(separator: "\n")
    }
}

enum StatsExporterError: Error {
    case encodingFailed
}
