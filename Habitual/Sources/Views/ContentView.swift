import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var habitStore: HabitStore
    @State private var showingAddHabit = false
    @State private var showingSettings = false
    @State private var showingArchive = false
    @AppStorage("appTheme") private var appTheme: String = "system"

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
                AddHabitView(habitStore: habitStore)
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
                ArchiveView(habitStore: habitStore)
            }
        }
        .preferredColorScheme(colorScheme)
    }

    private var habitListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(habitStore.filteredHabits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit, habitStore: habitStore)) {
                        HabitCardView(habit: habit, habitStore: habitStore)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    @Binding var showingAddHabit: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Habits Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start tracking your habits and build\nconsistency with visual progress grids.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showingAddHabit = true }) {
                Label("Add Your First Habit", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

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
        NavigationStack {
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
                    List {
                        ForEach(habitStore.archivedHabits) { habit in
                            HStack {
                                Image(systemName: habit.icon)
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
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
