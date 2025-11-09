import Foundation
import Combine

@MainActor
final class SpendCreditsViewModel: ObservableObject {
    enum SpendState {
        case idle
        case countingDown
        case completed
    }

    @Published var minutesToSpend: Int = 15
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var state: SpendState = .idle

    private var timerCancellable: AnyCancellable?
    private var spendStartDate: Date?

    func startCountdown() {
        guard case .idle = state, minutesToSpend > 0 else { return }
        remainingSeconds = minutesToSpend * 60
        spendStartDate = .now
        state = .countingDown

        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.tick()
                }
            }
    }

    func cancelCountdown() {
        timerCancellable?.cancel()
        timerCancellable = nil
        state = .idle
        remainingSeconds = 0
        spendStartDate = nil
    }

    private func tick() {
        guard case .countingDown = state else { return }
        guard remainingSeconds > 0 else {
            finishCountdown()
            return
        }
        remainingSeconds -= 1
    }

    private func finishCountdown() {
        timerCancellable?.cancel()
        timerCancellable = nil
        state = .completed
    }

    func commitSpend() -> ScreenTimeLog? {
        guard case .completed = state else { return nil }
        defer {
            state = .idle
            remainingSeconds = 0
            spendStartDate = nil
        }
        let log = ScreenTimeLog(
            createdAt: spendStartDate ?? .now,
            minutesUsed: minutesToSpend,
            source: "Manual Spend"
        )
        return log
    }
}
