import SwiftUI
import WatchKit

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
                ScrollView {
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No Habits")
                            .font(.headline)
                        Text("Pull to refresh or\nadd habits on iPhone or Mac")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
                .refreshable {
                    await habitStore.refresh()
                }
            } else {
                List {
                    ForEach(habitStore.activeHabits) { habit in
                        NavigationLink(destination: WatchHabitDetailView(habit: habit, habitStore: habitStore)) {
                            WatchHabitRow(habit: habit, habitStore: habitStore)
                        }
                    }
                }
                .refreshable {
                    await habitStore.refresh()
                }
                .navigationTitle("Habitual")
            }
        }
        .onAppear {
            // Schedule periodic background refresh for CloudKit sync
            WKApplication.shared().scheduleBackgroundRefresh(
                withPreferredDate: Date(timeIntervalSinceNow: 30 * 60),
                userInfo: nil
            ) { _ in }
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
                    habitStore.addCompletion(for: currentHabit, on: Date())
                }
            }) {
                if currentHabit.isPeriodComplete(for: Date()) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(currentHabit.color)
                } else if currentHabit.goalFrequency > 1 && currentHabit.completionsInPeriod(containing: Date()) > 0 {
                    Text("\(currentHabit.completionsInPeriod(containing: Date()))/\(currentHabit.goalFrequency)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(currentHabit.color)
                } else {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
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
                        habitStore.addCompletion(for: currentHabit, on: Date())
                    }
                }) {
                    VStack(spacing: 8) {
                        HabitIcon.image(currentHabit.icon)
                            .font(.largeTitle)
                            .foregroundStyle(currentHabit.color)

                        if currentHabit.isPeriodComplete(for: Date()) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.green)
                        } else if currentHabit.goalFrequency > 1 {
                            Text(
                                "\(currentHabit.completionsInPeriod(containing: Date()))/\(currentHabit.goalFrequency)"
                            )
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(currentHabit.color)
                        } else {
                            Image(systemName: "circle")
                                .font(.title)
                                .foregroundStyle(.gray)
                        }

                        Text(currentHabit.isPeriodComplete(for: Date()) ? "Completed" : "Tap to Add")
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
                    WatchStatRow(
                        icon: "flame.fill", label: "Streak",
                        value: "\(currentHabit.currentStreak) \(currentHabit.goalPeriod.periodLabelPlural)",
                        color: .orange)
                    WatchStatRow(
                        icon: "trophy.fill", label: "Best",
                        value: "\(currentHabit.longestStreak) \(currentHabit.goalPeriod.periodLabelPlural)",
                        color: .yellow)
                    WatchStatRow(
                        icon: "checkmark", label: "Total",
                        value: "\(currentHabit.totalCompletions) \(currentHabit.goalPeriod.periodLabelPlural)",
                        color: currentHabit.color)
                    WatchStatRow(
                        icon: "chart.line.uptrend.xyaxis", label: "Rate",
                        value: "\(Int(currentHabit.completionRate * 100))%", color: .green)
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
        let weeksData = weeks
        let peak = maxCount(in: weeksData)

        HStack(spacing: spacing) {
            ForEach(weeksData.indices, id: \.self) { weekIndex in
                VStack(spacing: spacing) {
                    ForEach(weeksData[weekIndex].indices, id: \.self) { dayIndex in
                        let day = weeksData[weekIndex][dayIndex]
                        if day.isPadding {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        } else {
                            LiquidFillCell(
                                count: day.count,
                                goal: habit.goalFrequency,
                                color: habit.color,
                                status: day.status,
                                size: cellSize,
                                maxCount: peak
                            )
                        }
                    }
                }
            }
        }
    }
}
