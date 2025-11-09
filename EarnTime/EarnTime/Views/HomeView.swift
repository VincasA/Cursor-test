import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var settings: SettingsViewModel
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var spendViewModel: SpendCreditsViewModel

    @Query(
        filter: #Predicate<TaskSession> { !$0.isArchived },
        sort: [SortDescriptor(\TaskSession.endDate, order: .reverse)]
    )
    private var sessions: [TaskSession]

    @Query(
        filter: #Predicate<ScreenTimeLog> { !$0.isArchived },
        sort: [SortDescriptor(\ScreenTimeLog.createdAt, order: .reverse)]
    )
    private var spendLogs: [ScreenTimeLog]

    @State private var completionResult: HomeViewModel.SessionResult?
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showNotificationPrompt: Bool = false
    @State private var showInsufficientCreditsAlert: Bool = false

    private var availableMinutes: Int {
        CreditManager.availableMinutes(sessions: sessions, logs: spendLogs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    creditBalanceCard
                    earnSection
                    spendSection
                    recentActivitySection
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
            .navigationTitle("Earn Credits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await notificationService.requestAuthorization() }
                    } label: {
                        Image(systemName: "bell.badge")
                    }
                    .accessibilityLabel("Request notification permission")
                }
            }
        }
        .onChange(of: viewModel.state) { _, newValue in
            if case .completed(let result) = newValue {
                notificationService.cancelAllPendingNotifications()
                completionResult = result
                persistSessionIfNeeded(result: result)
            }
        }
        .onChange(of: spendViewModel.state) { _, newValue in
            if case .completed = newValue {
                notificationService.cancelAllPendingNotifications()
                persistSpendIfNeeded()
            }
        }
        .alert("Unable to save", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage)
        })
        .alert("Not enough credits", isPresented: $showInsufficientCreditsAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text("Earn more credits before starting a screen-time session.")
        })
        .task {
            if notificationService.authorizationStatus == .notDetermined {
                showNotificationPrompt = true
            }
        }
        .onChange(of: notificationService.authorizationStatus) { oldValue, newValue in
            // Auto-dismiss the prompt once authorization is determined
            if oldValue == .notDetermined && newValue != .notDetermined {
                showNotificationPrompt = false
            }
        }
        .sheet(isPresented: $showNotificationPrompt) {
            notificationPrompt
        }
    }

    private var creditBalanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Credits")
                .font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(availableMinutes)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("minutes")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            if let result = completionResult {
                Text("Last earned: +\(result.earnedMinutes) minutes from \(result.category.displayName.lowercased()).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if let lastSpend = spendLogs.first {
                Text("Last spent: −\(lastSpend.minutesUsed) minutes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var earnSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Earn Credits")
                .font(.title2.weight(.semibold))

            categoryPicker

            if viewModel.selectedCategory == .custom || !settings.customCategories.isEmpty {
                customCategorySuggestions
            }

            durationStepper
            timerDisplay
            earnButtons
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private var spendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spend Credits")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 12) {
                Stepper(value: $spendViewModel.minutesToSpend, in: 5...240, step: 5) {
                    Text("Session length: \(spendViewModel.minutesToSpend) minutes")
                }
                spendTimerDisplay
            }

            spendButtons
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.title3.weight(.semibold))

            if sessions.isEmpty && spendLogs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Complete a task or log screen-time to see your history.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(sessions.prefix(3))) { session in
                        ActivityRow(
                            title: "+\(session.earnedMinutes) min · \(session.displayName)",
                            subtitle: session.endDate.formatted(date: .abbreviated, time: .shortened),
                            icon: "star.fill",
                            color: .green,
                            onDelete: {
                                deleteSession(session)
                            }
                        )
                    }
                    ForEach(Array(spendLogs.prefix(3))) { log in
                        ActivityRow(
                            title: "−\(log.minutesUsed) min · \(log.source)",
                            subtitle: log.createdAt.formatted(date: .abbreviated, time: .shortened),
                            icon: "iphone",
                            color: .orange,
                            onDelete: {
                                deleteLog(log)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task Category")
                .font(.headline)
            
            // Use menu style to prevent text truncation
            Picker("Task Category", selection: $viewModel.selectedCategory) {
                ForEach(TaskCategory.allCases) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.selectedCategory == .custom {
                TextField("Custom label", text: $viewModel.customLabel)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var customCategorySuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !settings.customCategories.isEmpty {
                Text("Quick fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(settings.customCategories, id: \.self) { label in
                            Button {
                                viewModel.customLabel = label
                                viewModel.selectedCategory = .custom
                            } label: {
                                Text(label)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.secondary.opacity(0.15))
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    private var durationStepper: some View {
        VStack(alignment: .leading, spacing: 8) {
            Stepper(value: $viewModel.durationMinutes, in: 5...180, step: 5) {
                Text("Duration: \(viewModel.durationMinutes) minutes")
            }
            Text("Earn the same number of minutes you focus.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var timerDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch viewModel.state {
            case .idle:
                Text("Ready to start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .running:
                Text("\(formatTime(viewModel.remainingSeconds)) remaining")
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(.primary)
            case .completed(let result):
                Text("Completed +\(result.earnedMinutes) minutes")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        }
    }

    private var earnButtons: some View {
        HStack {
            switch viewModel.state {
            case .idle, .completed:
                Button {
                    if notificationService.authorizationStatus == .notDetermined {
                        showNotificationPrompt = true
                    }
                    viewModel.startSession()
                    notificationService.scheduleCountdownCompletion(
                        in: TimeInterval(viewModel.durationMinutes * 60),
                        message: "Focus block finished — log your credits!"
                    )
                } label: {
                    Label("Start Focus Timer", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            case .running:
                Button(role: .cancel) {
                    viewModel.cancelSession()
                    notificationService.cancelAllPendingNotifications()
                } label: {
                    Label("Cancel", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    viewModel.completeSessionEarly()
                    notificationService.cancelAllPendingNotifications()
                } label: {
                    Label("Finish Early", systemImage: "flag.checkered")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var spendTimerDisplay: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch spendViewModel.state {
            case .idle:
                Text("Start when you're ready to open a distracting app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            case .countingDown:
                Text("\(formatTime(spendViewModel.remainingSeconds)) remaining")
                    .font(.title2.monospacedDigit())
            case .completed:
                Text("Session finished — log recorded.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var spendButtons: some View {
        HStack {
            switch spendViewModel.state {
            case .idle, .completed:
                Button {
                    guard availableMinutes >= spendViewModel.minutesToSpend else {
                        showInsufficientCreditsAlert = true
                        return
                    }
                    spendViewModel.startCountdown()
                    notificationService.scheduleCountdownCompletion(
                        in: TimeInterval(spendViewModel.minutesToSpend * 60),
                        message: "Take a break — earn more time!"
                    )
                } label: {
                    Label("Start Using Screen-Time", systemImage: "iphone")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            case .countingDown:
                Button(role: .cancel) {
                    spendViewModel.cancelCountdown()
                    notificationService.cancelAllPendingNotifications()
                } label: {
                    Label("Stop", systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    private var notificationPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Stay on track")
                .font(.headline)
            Text("Enable notifications so EarnTime can nudge you when timers finish or credits expire.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Enable Notifications") {
                Task {
                    // Request authorization - this will show the system dialog
                    await notificationService.requestAuthorization()
                    // Refresh status to update the published property
                    await notificationService.refreshAuthorizationStatus()
                    // The sheet will auto-dismiss via onChange handler when status changes
                }
            }
            .buttonStyle(.borderedProminent)
            Button("Maybe Later") {
                showNotificationPrompt = false
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .presentationDetents([.medium])
    }

    private func persistSessionIfNeeded(result: HomeViewModel.SessionResult) {
        let session = TaskSession(
            category: result.category,
            customLabel: result.customLabel,
            startDate: result.startDate,
            endDate: result.endDate,
            durationSeconds: result.durationSeconds,
            earnedMinutes: result.earnedMinutes
        )
        context.insert(session)
        do {
            try context.save()
            viewModel.resetSession()
        } catch {
            context.delete(session)
            errorMessage = "We could not save your session. Please try again.\n\(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func persistSpendIfNeeded() {
        guard let log = spendViewModel.commitSpend() else { return }
        context.insert(log)
        do {
            try context.save()
        } catch {
            context.delete(log)
            errorMessage = "We could not save your screen-time log. Please try again.\n\(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
    
    private func deleteSession(_ session: TaskSession) {
        session.isArchived = true
        do {
            try context.save()
        } catch {
            errorMessage = "Could not delete session: \(error.localizedDescription)"
            showErrorAlert = true
            // Revert on error
            session.isArchived = false
        }
    }
    
    private func deleteLog(_ log: ScreenTimeLog) {
        log.isArchived = true
        do {
            try context.save()
        } catch {
            errorMessage = "Could not delete log: \(error.localizedDescription)"
            showErrorAlert = true
            // Revert on error
            log.isArchived = false
        }
    }
}

private struct ActivityRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let onDelete: (() -> Void)?

    init(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
