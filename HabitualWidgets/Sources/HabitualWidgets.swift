import WidgetKit
import SwiftUI
import CoreData
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Platform Colors

private extension Color {
    static var systemGray3: Color {
        #if canImport(UIKit)
        Color(UIColor.systemGray3)
        #else
        Color.gray.opacity(0.45)
        #endif
    }
    static var systemGray5: Color {
        #if canImport(UIKit)
        Color(UIColor.systemGray5)
        #else
        Color.gray.opacity(0.18)
        #endif
    }
}

// MARK: - Widget Timeline Provider

struct HabitWidgetProvider: TimelineProvider {
    let persistenceController = PersistenceController.shared

    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> Void) {
        let entry = fetchEntry()
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func fetchEntry() -> HabitWidgetEntry {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDHabit.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \CDHabit.createdAt, ascending: false),
        ]
        let habits = (try? context.fetch(request))?.map { $0.toHabit() } ?? []

        let habitSnapshots = habits.prefix(6).map { habit in
            HabitSnapshot(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                colorRed: habit.colorComponents.red,
                colorGreen: habit.colorComponents.green,
                colorBlue: habit.colorComponents.blue,
                isCompletedToday: habit.isCompletedOn(date: Date()),
                currentStreak: habit.currentStreak,
                completionRate: habit.completionRate,
                recentCompletions: habit.heatmapData(months: 2).flatMap { $0 }.map { $0.isCompleted }
            )
        }

        let completedCount = habits.filter { $0.isCompletedOn(date: Date()) }.count

        return HabitWidgetEntry(
            date: Date(),
            habits: Array(habitSnapshots),
            totalHabits: habits.count,
            completedToday: completedCount
        )
    }
}

// MARK: - Widget Entry

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let habits: [HabitSnapshot]
    let totalHabits: Int
    let completedToday: Int

    var completionFraction: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedToday) / Double(totalHabits)
    }

    static let placeholder = HabitWidgetEntry(
        date: Date(),
        habits: [
            HabitSnapshot(id: UUID(), name: "Exercise", icon: "figure.run", colorRed: 0.35, colorGreen: 0.65, colorBlue: 0.85, isCompletedToday: true, currentStreak: 7, completionRate: 0.85, recentCompletions: []),
            HabitSnapshot(id: UUID(), name: "Read", icon: "book.fill", colorRed: 0.95, colorGreen: 0.55, colorBlue: 0.20, isCompletedToday: false, currentStreak: 3, completionRate: 0.60, recentCompletions: []),
            HabitSnapshot(id: UUID(), name: "Meditate", icon: "brain.head.profile", colorRed: 0.65, colorGreen: 0.35, colorBlue: 0.90, isCompletedToday: true, currentStreak: 12, completionRate: 0.75, recentCompletions: []),
        ],
        totalHabits: 3,
        completedToday: 2
    )
}

struct HabitSnapshot: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double
    let isCompletedToday: Bool
    let currentStreak: Int
    let completionRate: Double
    let recentCompletions: [Bool]

    var color: Color {
        Color(red: colorRed, green: colorGreen, blue: colorBlue)
    }
}

// MARK: - Small Widget

struct SmallHabitWidget: View {
    let entry: HabitWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Progress header
            HStack {
                Text("Habitual")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(entry.completedToday)/\(entry.totalHabits)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            // Progress ring
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.systemGray5, lineWidth: 6)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: entry.completionFraction)
                        .stroke(
                            Color.green,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(entry.completionFraction * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                Spacer()
            }

            Spacer()

            // Habit icons row
            HStack(spacing: 6) {
                ForEach(entry.habits.prefix(4)) { habit in
                    HabitIcon.image(habit.icon)
                        .font(.caption)
                        .foregroundStyle(habit.isCompletedToday ? habit.color : .gray)
                }
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget

struct MediumHabitWidget: View {
    let entry: HabitWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Habitual")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(entry.completedToday) of \(entry.totalHabits) done")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Habit list
            ForEach(entry.habits.prefix(3)) { habit in
                HStack(spacing: 8) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.body)
                        .foregroundStyle(habit.isCompletedToday ? habit.color : Color.systemGray3)

                    HabitIcon.image(habit.icon)
                        .font(.caption)
                        .foregroundStyle(habit.color)

                    Text(habit.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(habit.currentStreak)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if entry.habits.isEmpty {
                HStack {
                    Spacer()
                    Text("No habits yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
    }
}

// MARK: - Large Widget (with mini heatmaps)

struct LargeHabitWidget: View {
    let entry: HabitWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Habitual")
                        .font(.headline)
                    Text("Today's Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.systemGray5, lineWidth: 4)
                        .frame(width: 36, height: 36)
                    Circle()
                        .trim(from: 0, to: entry.completionFraction)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.completedToday)/\(entry.totalHabits)")
                        .font(.system(size: 9))
                        .fontWeight(.bold)
                }
            }

            Divider()

            // Habit rows with mini heatmaps
            ForEach(entry.habits.prefix(5)) { habit in
                HStack(spacing: 8) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.body)
                        .foregroundStyle(habit.isCompletedToday ? habit.color : Color.systemGray3)

                    HabitIcon.image(habit.icon)
                        .font(.caption)
                        .foregroundStyle(habit.color)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        // Mini heatmap dots (last 14 days)
                        HStack(spacing: 2) {
                            ForEach(0..<min(14, habit.recentCompletions.count), id: \.self) { idx in
                                Circle()
                                    .fill(habit.recentCompletions[idx] ? habit.color : Color.systemGray5)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("\(habit.currentStreak)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        Text("\(Int(habit.completionRate * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if entry.habits.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Add habits to get started")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularHabitWidget: View {
    let entry: HabitWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                Text("\(entry.completedToday)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("of \(entry.totalHabits)")
                    .font(.caption2)
            }
        }
    }
}

struct AccessoryRectangularHabitWidget: View {
    let entry: HabitWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.caption2)
                Text("Habitual")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            ForEach(entry.habits.prefix(2)) { habit in
                HStack(spacing: 4) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.caption2)
                    Text(habit.name)
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct AccessoryInlineHabitWidget: View {
    let entry: HabitWidgetEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
            Text("\(entry.completedToday)/\(entry.totalHabits) habits done")
        }
    }
}

// MARK: - Widget Configuration

struct HabitualWidget: Widget {
    let kind: String = "HabitualWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitWidgetProvider()) { entry in
            HabitualWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Habitual")
        .description("Track your daily habits at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }
}

struct HabitualWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HabitWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallHabitWidget(entry: entry)
        case .systemMedium:
            MediumHabitWidget(entry: entry)
        case .systemLarge:
            LargeHabitWidget(entry: entry)
        #if !os(macOS)
        case .accessoryCircular:
            AccessoryCircularHabitWidget(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularHabitWidget(entry: entry)
        case .accessoryInline:
            AccessoryInlineHabitWidget(entry: entry)
        #endif
        default:
            MediumHabitWidget(entry: entry)
        }
    }
}

// MARK: - Single Habit Widget

struct SingleHabitWidgetProvider: IntentTimelineProvider {
    typealias Intent = SingleHabitIntent
    typealias Entry = SingleHabitEntry

    let persistenceController = PersistenceController.shared

    func placeholder(in context: Context) -> SingleHabitEntry {
        SingleHabitEntry.placeholder
    }

    func getSnapshot(for configuration: SingleHabitIntent, in context: Context, completion: @escaping (SingleHabitEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(for configuration: SingleHabitIntent, in context: Context, completion: @escaping (Timeline<SingleHabitEntry>) -> Void) {
        let entry = fetchEntry()
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func fetchEntry() -> SingleHabitEntry {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDHabit.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \CDHabit.createdAt, ascending: false),
        ]
        request.fetchLimit = 1
        let habits = (try? context.fetch(request))?.map { $0.toHabit() } ?? []

        guard let habit = habits.first else {
            return .placeholder
        }

        let weeks = habit.heatmapData(months: 3)
        let heatmapValues = weeks.flatMap { week in
            week.map { day -> HeatmapDay in
                HeatmapDay(isCompleted: day.isCompleted, isFuture: day.isFuture)
            }
        }

        return SingleHabitEntry(
            date: Date(),
            habitName: habit.name,
            habitIcon: habit.icon,
            colorRed: habit.colorComponents.red,
            colorGreen: habit.colorComponents.green,
            colorBlue: habit.colorComponents.blue,
            isCompletedToday: habit.isCompletedOn(date: Date()),
            currentStreak: habit.currentStreak,
            completionRate: habit.completionRate,
            heatmapDays: heatmapValues
        )
    }
}

struct SingleHabitEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let habitIcon: String
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double
    let isCompletedToday: Bool
    let currentStreak: Int
    let completionRate: Double
    let heatmapDays: [HeatmapDay]

    var color: Color {
        Color(red: colorRed, green: colorGreen, blue: colorBlue)
    }

    static let placeholder = SingleHabitEntry(
        date: Date(),
        habitName: "Exercise",
        habitIcon: "figure.run",
        colorRed: 0.35,
        colorGreen: 0.65,
        colorBlue: 0.85,
        isCompletedToday: false,
        currentStreak: 5,
        completionRate: 0.72,
        heatmapDays: []
    )
}

struct HeatmapDay {
    let isCompleted: Bool
    let isFuture: Bool
}

// Placeholder intent - in a real project this would be defined in an Intent Definition file
class SingleHabitIntent: INIntent {}

import Intents

struct SingleHabitWidget: Widget {
    let kind: String = "SingleHabitWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SingleHabitIntent.self, provider: SingleHabitWidgetProvider()) { entry in
            SingleHabitWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Single Habit")
        .description("Focus on a specific habit with a heatmap grid.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SingleHabitWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SingleHabitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                HabitIcon.image(entry.habitIcon)
                    .foregroundStyle(entry.color)
                Text(entry.habitName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
                Image(systemName: entry.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(entry.isCompletedToday ? .green : .gray)
            }

            if family == .systemMedium {
                // Mini heatmap grid
                WidgetHeatmapGrid(days: entry.heatmapDays, color: entry.color)
            }

            Spacer()

            // Stats
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(entry.currentStreak)d")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                Spacer()
                Text("\(Int(entry.completionRate * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct WidgetHeatmapGrid: View {
    let days: [HeatmapDay]
    let color: Color
    let cellSize: CGFloat = 8
    let spacing: CGFloat = 2

    var body: some View {
        let rows = 7
        let cols = days.count / rows

        HStack(spacing: spacing) {
            ForEach(0..<cols, id: \.self) { col in
                VStack(spacing: spacing) {
                    ForEach(0..<rows, id: \.self) { row in
                        let index = col * rows + row
                        if index < days.count {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(cellColor(for: days[index]))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private func cellColor(for day: HeatmapDay) -> Color {
        if day.isFuture { return .clear }
        if day.isCompleted { return color }
        return Color.systemGray5
    }
}

// MARK: - Widget Bundle

@main
struct HabitualWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitualWidget()
        SingleHabitWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    HabitualWidget()
} timeline: {
    HabitWidgetEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    HabitualWidget()
} timeline: {
    HabitWidgetEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    HabitualWidget()
} timeline: {
    HabitWidgetEntry.placeholder
}
