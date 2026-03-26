import SwiftUI

struct ContentView: View {
    @StateObject private var habitStore: HabitStore
    @State private var showingAddHabit = false
    @State private var showingSettings = false
    @State private var showingArchive = false
    @State private var selectedHabit: Habit?
    @State private var isSyncing = false
    @State private var lastSuccessfulSync: Date?
    @State private var syncErrorMessage: String?
    @State private var showSyncErrorAlert = false
    @AppStorage("appTheme") private var appTheme: String = "system"
    private let relativeSyncFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    init() {
        let context = PersistenceController.shared.container.viewContext
        _habitStore = StateObject(wrappedValue: HabitStore(context: context))
    }

    var body: some View {
        NavigationStack {
            Group {
                if habitStore.activeHabits.isEmpty {
                    EmptyStateView(showingAddHabit: $showingAddHabit)
                } else {
                    habitListView
                }
            }
            .navigationTitle("Habitual")
            .searchable(text: $habitStore.searchText, prompt: "Search habits")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            Task { await triggerManualSync() }
                        } label: {
                            Label("Sync Now", systemImage: "arrow.clockwise")
                        }
                        .disabled(isSyncing)

                        Button(action: { showingSettings = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                        Button(action: { showingArchive = true }) {
                            Label("Archive", systemImage: "archivebox")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem {
                    Button(action: {
                        Task { await triggerManualSync() }
                    }) {
                        Label("Sync", systemImage: "arrow.clockwise")
                    }
                    .disabled(isSyncing)
                }
                ToolbarItem {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem {
                    Button(action: { showingArchive = true }) {
                        Label("Archive", systemImage: "archivebox")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddHabit) {
                NavigationStack {
                    AddHabitView(habitStore: habitStore)
                }
                #if os(macOS)
                .frame(minWidth: 520, minHeight: 620)
                #endif
            }
            .sheet(isPresented: $showingSettings) {
                #if os(iOS)
                NavigationStack {
                    SettingsView()
                }
                #else
                SettingsView()
                    .frame(minWidth: 400, minHeight: 300)
                #endif
            }
            .sheet(isPresented: $showingArchive) {
                NavigationStack {
                    ArchiveView(habitStore: habitStore)
                }
                #if os(macOS)
                .frame(minWidth: 400, minHeight: 300)
                #endif
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedHabit != nil },
                set: { if !$0 { selectedHabit = nil } }
            )) {
                if let habit = selectedHabit {
                    HabitDetailView(habit: habit, habitStore: habitStore)
                }
            }
        }
        .preferredColorScheme(colorScheme)
        .alert(
            "Sync Failed",
            isPresented: $showSyncErrorAlert,
            presenting: syncErrorMessage
        ) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }

    private var habitListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                syncStatusView

                ForEach(habitStore.filteredHabits) { habit in
                    HabitCardView(habit: habit, habitStore: habitStore)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedHabit = habit }
                }
            }
            .padding()
        }
        #if os(iOS)
        .refreshable {
            await triggerManualSync()
        }
        #endif
    }

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    @ViewBuilder
    private var syncStatusView: some View {
        if isSyncing {
            Label("Syncing with iCloud…", systemImage: "arrow.clockwise")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        } else if let lastSuccessfulSync {
            Label(
                "Last synced \(relativeSyncFormatter.localizedString(for: lastSuccessfulSync, relativeTo: Date()))",
                systemImage: "checkmark.icloud"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }

    @MainActor
    private func triggerManualSync() async {
        if isSyncing { return }
        isSyncing = true
        do {
            try await CloudSyncService.shared.forceSync()
            habitStore.fetchHabits()
            lastSuccessfulSync = Date()
        } catch {
            let message = error.localizedDescription
            syncErrorMessage = message
            showSyncErrorAlert = true
            NotificationService.shared.notifySyncFailure(message: message)
        }
        isSyncing = false
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    @Binding var showingAddHabit: Bool
    @State private var mascotIndex = 0
    private let welcomeMascots: [Mascot] = [.dog, .capybara, .cat]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Rotating mascot welcome
            MascotEmojiView(
                mascot: welcomeMascots[mascotIndex],
                mood: .encouraging,
                size: 110
            )
            .padding(.bottom, 8)
            .onTapGesture {
                withAnimation(.spring(duration: 0.35, bounce: 0.5)) {
                    mascotIndex = (mascotIndex + 1) % welcomeMascots.count
                }
            }

            Text(welcomeMascots[mascotIndex].name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)

            Text("はじめましょう！")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .padding(.bottom, 4)

            Text("Let's get started!")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 10)

            Text("Build great habits, one day at a time.\nTap a mascot to meet the crew.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 28)

            Button(action: { showingAddHabit = true }) {
                Label("Add Your First Habit", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Archive View

struct ArchiveView: View {
    @ObservedObject var habitStore: HabitStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if habitStore.archivedHabits.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "archivebox")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Archived Habits")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(habitStore.archivedHabits) { habit in
                            HStack {
                                HabitIcon.image(habit.icon)
                                    .foregroundStyle(habit.color)
                                    .frame(width: 30)
                                Text(habit.name)
                                Spacer()
                                Button("Restore") {
                                    habitStore.unarchiveHabit(habit)
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            Divider()
                        }
                    }
                }
            }
        }
        .navigationTitle("Archive")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
