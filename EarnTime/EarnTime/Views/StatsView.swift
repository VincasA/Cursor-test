import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @ObservedObject var viewModel: StatsViewModel

    @Query(
        filter: #Predicate<TaskSession> { !$0.isArchived },
        sort: [SortDescriptor(\TaskSession.endDate, order: .forward)]
    )
    private var sessions: [TaskSession]

    @Query(
        filter: #Predicate<ScreenTimeLog> { !$0.isArchived },
        sort: [SortDescriptor(\ScreenTimeLog.createdAt, order: .forward)]
    )
    private var spendLogs: [ScreenTimeLog]

    private var filteredSessions: [TaskSession] {
        viewModel.filter(sessions: sessions)
    }

    private var filteredLogs: [ScreenTimeLog] {
        viewModel.filter(logs: spendLogs)
    }

    private var chartData: [StatsViewModel.DailyStat] {
        viewModel.makeChartData(sessions: sessions, logs: spendLogs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    chartCard
                    summaryCard
                    exportCard
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
            .navigationTitle("Statistics")
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Earned vs. Spent")
                    .font(.title2.weight(.semibold))

                Spacer()

                Picker("Range", selection: $viewModel.range) {
                    ForEach(StatsViewModel.RangeOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            Chart(chartData) { stat in
                BarMark(
                    x: .value("Date", stat.date),
                    y: .value("Minutes Earned", stat.earnedMinutes)
                )
                .foregroundStyle(.green.opacity(0.75))
                .cornerRadius(4)

                BarMark(
                    x: .value("Date", stat.date),
                    y: .value("Minutes Spent", stat.spentMinutes)
                )
                .foregroundStyle(.orange.opacity(0.75))
                .cornerRadius(4)
            }
            .chartYAxisLabel("Minutes")
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: Date.FormatStyle().day().month(.abbreviated))
                        }
                    }
                }
            }
            .frame(minHeight: 240)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private var summaryCard: some View {
        let totalEarned = filteredSessions.reduce(0) { $0 + $1.earnedMinutes }
        let totalSpent = filteredLogs.reduce(0) { $0 + $1.minutesUsed }
        let balance = max(0, totalEarned - totalSpent)

        return VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.title2.weight(.semibold))

            HStack(spacing: 16) {
                SummaryCell(title: "Earned", value: totalEarned, color: .green)
                SummaryCell(title: "Spent", value: totalSpent, color: .orange)
                SummaryCell(title: "Balance", value: balance, color: .blue)
            }
            .frame(maxWidth: .infinity)

            if let bestCategory = bestPerformerCategory() {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strongest Habit")
                        .font(.headline)
                    Text("\(bestCategory.name) · \(bestCategory.minutes) minutes logged")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export")
                .font(.title2.weight(.semibold))

            Text("Save your data as CSV or JSON for personal backups or to automate Shortcuts.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Picker("Format", selection: $viewModel.exportFormat) {
                ForEach(StatsViewModel.ExportFormat.allCases) { format in
                    Text(format.label).tag(format)
                }
            }
            .pickerStyle(.segmented)

            exportButton
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private var exportButton: some View {
        Group {
            if let document = try? viewModel.makeExportDocument(
                sessions: filteredSessions,
                logs: filteredLogs
            ) {
                ShareLink(item: document) {
                    Label("Export \(viewModel.exportFormat.label)", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("No sessions available to export yet.", systemImage: "info.circle")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.secondary)
                    Text("Complete a task or log screen-time to unlock exports.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func bestPerformerCategory() -> (name: String, minutes: Int)? {
        guard !filteredSessions.isEmpty else { return nil }
        let grouped = Dictionary(grouping: filteredSessions, by: \.category)
        let totals = grouped.mapValues { sessions in
            sessions.reduce(0) { $0 + $1.earnedMinutes }
        }
        if let maxEntry = totals.max(by: { $0.value < $1.value }) {
            return (maxEntry.key.displayName, maxEntry.value)
        }
        return nil
    }
}

private struct SummaryCell: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
            Text("minutes")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
