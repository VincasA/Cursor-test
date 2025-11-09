import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var notificationService: NotificationService

    @State private var newCategoryName: String = ""
    @State private var showArchiveConfirmation: Bool = false
    @State private var archiveErrorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                themeSection
                customCategoriesSection
                notificationsSection
                maintenanceSection
                shortcutsSection
                privacySection
            }
            .navigationTitle("Settings")
            .alert("Archive failed", isPresented: .constant(archiveErrorMessage != nil), actions: {
                Button("OK", role: .cancel) {
                    archiveErrorMessage = nil
                }
            }, message: {
                Text(archiveErrorMessage ?? "")
            })
            .confirmationDialog(
                "Archive last week's history?",
                isPresented: $showArchiveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Archive", role: .destructive) {
                    Task { await archiveHistory() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Older sessions and screen-time logs will be marked as archived. They stay on device but are hidden from day-to-day charts.")
            }
        }
    }

    private var themeSection: some View {
        Section(header: Text("Theme")) {
            Picker("Appearance", selection: $settings.theme) {
                ForEach(SettingsViewModel.ThemeOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: settings.theme) { _, newValue in
                settings.updateTheme(newValue)
            }
        }
    }

    private var customCategoriesSection: some View {
        Section(header: Text("Custom Categories"), footer: customCategoriesFooter) {
            if settings.customCategories.isEmpty {
                Text("Add shortcuts for common chores, study blocks, or rewards. They'll appear on the Home screen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(settings.customCategories, id: \.self) { name in
                    Text(name)
                }
                .onDelete { indexSet in
                    settings.removeCustomCategory(at: indexSet)
                }
            }

            HStack {
                TextField("New category", text: $newCategoryName)
                    .textInputAutocapitalization(.words)
                Button {
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    settings.addCustomCategory(name: trimmed)
                    newCategoryName = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.accentColor)
                }
                .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var customCategoriesFooter: some View {
        Text("Swipe to delete custom categories. Defaults like Focus Session and Exercise stay available at all times.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var notificationsSection: some View {
        Section(header: Text("Notifications")) {
            HStack {
                Label("Permission status", systemImage: "bell")
                Spacer()
                Text(notificationStatusLabel)
                    .foregroundStyle(.secondary)
            }
            Button("Request Permission") {
                Task { await notificationService.requestAuthorization() }
            }
        }
    }

    private var maintenanceSection: some View {
        Section(header: Text("Maintenance")) {
            Button("Archive last week's logs", role: .destructive) {
                showArchiveConfirmation = true
            }
            .disabled(settings.isArchiving)

            if settings.isArchiving {
                ProgressView("Archiving…")
            }
        }
    }

    private var shortcutsSection: some View {
        Section(header: Text("Shortcuts & Screen Time"), footer: shortcutsFooter) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Automate Focus modes")
                    .font(.headline)
                Text("Use Apple Shortcuts to toggle a Focus mode when your credit balance is above a threshold.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Link(destination: URL(string: "https://support.apple.com/guide/shortcuts/welcome/ios")!) {
                Label("Open Shortcuts User Guide", systemImage: "link")
            }
        }
    }

    private var shortcutsFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Suggested Shortcut steps:")
                .font(.caption.weight(.semibold))
            Text("1. Add the \"Get File\" action pointing to EarnTime's CSV export.")
            Text("2. Parse the JSON/CSV, check remaining balance.")
            Text("3. Use \"Set Focus\" to activate or deactivate your chosen mode.")
            Text("4. Finish with \"Open App\" to launch the distracting app only when credits remain.")
            Text("Focus automations must be triggered manually—Apple does not allow third-party apps to enforce Screen Time limits.")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var privacySection: some View {
        Section(header: Text("Privacy")) {
            Label("All data stays on this device. No ads, accounts, or trackers.", systemImage: "lock.shield")
            Label("Delete the app to wipe everything instantly.", systemImage: "trash")
        }
    }

    private var notificationStatusLabel: String {
        switch notificationService.authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied"
        case .ephemeral:
            return "Ephemeral"
        case .notDetermined:
            return "Not requested"
        case .provisional:
            return "Provisional"
        @unknown default:
            return "Unknown"
        }
    }

    private func archiveHistory() async {
        do {
            try await settings.archiveOlderThanOneWeek(using: context)
        } catch {
            archiveErrorMessage = error.localizedDescription
        }
    }
}
