import SwiftUI

struct WatchContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var habitStore: HabitStore

    init() {
        let context = PersistenceController.shared.container.viewContext
        _habitStore = StateObject(wrappedValue: HabitStore(context: context))
    }

    var body: some View {
        NavigationStack {
            if habitStore.activeHabits.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No Habits")
                        .font(.headline)
                    Text("Add habits on iPhone or Mac")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                List {
                    ForEach(habitStore.activeHabits) { habit in
                        NavigationLink(destination: WatchHabitDetailView(habit: habit, habitStore: habitStore)) {
                            WatchHabitRow(habit: habit, habitStore: habitStore)
                        }
                    }
                }
                .navigationTitle("Habitual")
            }
        }
    }
}

// MARK: - Watch Habit Row

struct WatchHabitRow: View {
    let habit: Habit
    @ObservedObject var habitStore: HabitStore

    private var currentHabit: Habit {
        habitStore.habits.first { $0.id == habit.id } ?? habit
    }

    var body: some View {
        HStack {
            HabitIcon.image(currentHabit.icon)
                .foregroundStyle(currentHabit.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(currentHabit.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(currentHabit.currentStreak)d")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: {
                withAnimation {
                    habitStore.toggleTodayCompletion(for: currentHabit)
                }
            }) {
                Image(systemName: currentHabit.isCompletedOn(date: Date()) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(currentHabit.isCompletedOn(date: Date()) ? currentHabit.color : .gray)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Watch Habit Detail

struct WatchHabitDetailView: View {
    let habit: Habit
    @ObservedObject var habitStore: HabitStore

    private var currentHabit: Habit {
        habitStore.habits.first { $0.id == habit.id } ?? habit
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Icon and toggle
                Button(action: {
                    withAnimation {
                        habitStore.toggleTodayCompletion(for: currentHabit)
                    }
                }) {
                    VStack(spacing: 8) {
                        HabitIcon.image(currentHabit.icon)
                            .font(.largeTitle)
                            .foregroundStyle(currentHabit.color)

                        Image(systemName: currentHabit.isCompletedOn(date: Date()) ? "checkmark.circle.fill" : "circle")
                            .font(.title)
                            .foregroundStyle(currentHabit.isCompletedOn(date: Date()) ? .green : .gray)

                        Text(currentHabit.isCompletedOn(date: Date()) ? "Completed" : "Tap to Complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Divider()

                // Mini heatmap (last 4 weeks)
                WatchHeatmapView(habit: currentHabit)

                Divider()

                // Stats
                VStack(spacing: 8) {
                    WatchStatRow(icon: "flame.fill", label: "Streak", value: "\(currentHabit.currentStreak) days", color: .orange)
                    WatchStatRow(icon: "trophy.fill", label: "Best", value: "\(currentHabit.longestStreak) days", color: .yellow)
                    WatchStatRow(icon: "checkmark", label: "Total", value: "\(currentHabit.totalCompletions)", color: currentHabit.color)
                    WatchStatRow(icon: "chart.line.uptrend.xyaxis", label: "Rate", value: "\(Int(currentHabit.completionRate * 100))%", color: .green)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(currentHabit.name)
    }
}

struct WatchStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            HabitIcon.image(icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Watch Heatmap (compact)

struct WatchHeatmapView: View {
    let habit: Habit
    private let cellSize: CGFloat = 8
    private let spacing: CGFloat = 2

    private var weeks: [[DayData]] {
        habit.heatmapData(months: 1)
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                VStack(spacing: spacing) {
                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                        let day = weeks[weekIndex][dayIndex]
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(cellColor(for: day))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }

    private func cellColor(for day: DayData) -> Color {
        if day.isFuture { return .clear }
        if day.isCompleted { return habit.color }
        return Color.gray.opacity(0.3)
    }
}
