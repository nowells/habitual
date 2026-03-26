import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("showCompletionAnimations") private var showCompletionAnimations: Bool = true
    @AppStorage("startOfWeek") private var startOfWeek: Int = 1 // 1 = Sunday (Calendar default)
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            // Appearance
            Section("Appearance") {
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }

            }

            // Behavior
            Section("Behavior") {
                Toggle("Completion Animations", isOn: $showCompletionAnimations)

                Picker("Week Starts On", selection: $startOfWeek) {
                    Text("Sunday").tag(1)
                    Text("Monday").tag(2)
                    Text("Saturday").tag(7)
                }
            }

            // Notifications
            if shouldShowNotificationPrompt {
                Section("Notifications") {
                    Button("Allow Notifications") {
                        NotificationService.shared.requestPermission { _ in
                            Task { await refreshNotificationStatus() }
                        }
                    }
                }
            }

            // Data
            Section("Data & Sync") {
                HStack {
                    Image(systemName: "icloud")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("iCloud Sync")
                            .font(.body)
                        Text("Your habits sync automatically across all devices via iCloud.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Built with")
                    Spacer()
                    Text("SwiftUI + CloudKit")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        #if os(macOS)
        .formStyle(.grouped)
        #elseif os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        #endif
        .task {
            await refreshNotificationStatus()
        }
    }

    private var shouldShowNotificationPrompt: Bool {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return false
        default:
            return true
        }
    }

    private func refreshNotificationStatus() async {
        let status = await NotificationService.shared.authorizationStatus()
        await MainActor.run {
            notificationStatus = status
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
