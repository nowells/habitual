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
                NavigationStack {
                    AddHabitView(habitStore: habitStore)
                }
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
    @State private var mascotIndex = 0
    private let welcomeMascots: [Mascot] = [.dog, .capybara, .cat]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Rotating mascot welcome
            MascotFaceView(
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

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
