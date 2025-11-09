import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    enum SessionState {
        case idle
        case running
        case completed(SessionResult)
    }

    struct SessionResult: Equatable {
        let category: TaskCategory
        let customLabel: String?
        let startDate: Date
        let endDate: Date
        let durationSeconds: Double
        let earnedMinutes: Int
    }

    @Published var selectedCategory: TaskCategory = .focusSession
    @Published var customLabel: String = ""
    @Published var durationMinutes: Int = TaskCategory.focusSession.defaultDurationMinutes
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var state: SessionState = .idle

    private var timerCancellable: AnyCancellable?
    private var sessionStartDate: Date?
    private var totalDurationSeconds: Int { durationMinutes * 60 }

    func startSession() {
        guard case .running = state else {
            sessionStartDate = .now
            remainingSeconds = totalDurationSeconds
            state = .running
            timerCancellable?.cancel()
            timerCancellable = Timer
                .publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    Task { @MainActor in
                        self?.tick()
                    }
                }
            return
        }
    }

    func cancelSession() {
        timerCancellable?.cancel()
        timerCancellable = nil
        state = .idle
        remainingSeconds = 0
        sessionStartDate = nil
    }

    func completeSessionEarly() {
        guard case .running = state else { return }
        let elapsed = Double(totalDurationSeconds - remainingSeconds)
        finishSession(actualDuration: elapsed)
    }

    private func tick() {
        guard case .running = state else { return }
        guard remainingSeconds > 0 else {
            finishSession(actualDuration: Double(totalDurationSeconds))
            return
        }
        remainingSeconds -= 1
    }

    private func finishSession(actualDuration: Double) {
        timerCancellable?.cancel()
        timerCancellable = nil

        let endDate = Date()
        let startDate = sessionStartDate ?? endDate.addingTimeInterval(-actualDuration)
        let earnedMinutes = Int(round(actualDuration / 60.0))
        let label = customLabel.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = SessionResult(
            category: selectedCategory,
            customLabel: label.isEmpty ? nil : label,
            startDate: startDate,
            endDate: endDate,
            durationSeconds: actualDuration,
            earnedMinutes: max(earnedMinutes, 1)
        )

        state = .completed(result)
        remainingSeconds = 0
        sessionStartDate = nil
    }

    func resetSession() {
        state = .idle
        remainingSeconds = 0
        sessionStartDate = nil
    }
}
