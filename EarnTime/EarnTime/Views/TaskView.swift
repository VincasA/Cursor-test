import SwiftUI

struct TaskView: View {
    let session: TaskSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.displayName)
                    .font(.headline)
                Spacer()
                Text("+\(session.earnedMinutes) min")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            }
            Text(session.endDate.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview("Task View") {
    TaskView(
        session: TaskSession(
            category: .focusSession,
            customLabel: "Deep Work",
            startDate: .now.addingTimeInterval(-1500),
            endDate: .now,
            durationSeconds: 1500,
            earnedMinutes: 25,
            notes: "Finished chapter draft."
        )
    )
    .padding()
}
