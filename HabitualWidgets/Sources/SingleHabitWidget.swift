import AppIntents
import CoreData
import SwiftUI
import WidgetKit

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Single Habit Widget

/// Widget configuration intent — lets the user choose which habit to display.
struct SelectHabitIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Habit"
    static let description = IntentDescription("Choose which habit to display on the widget.")

    @Parameter(title: "Habit")
    var habit: HabitAppEntity?
}

struct SingleHabitWidgetProvider: AppIntentTimelineProvider {
    typealias Intent = SelectHabitIntent
    typealias Entry = SingleHabitEntry

    let persistenceController = PersistenceController.shared

    func placeholder(in context: Context) -> SingleHabitEntry {
        SingleHabitEntry.placeholder
    }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> SingleHabitEntry {
        await fetchEntry(for: configuration)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<SingleHabitEntry> {
        let entry = await fetchEntry(for: configuration)
        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }

    @MainActor
    private func fetchEntry(for configuration: SelectHabitIntent) -> SingleHabitEntry {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDHabit.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \CDHabit.createdAt, ascending: false),
        ]
        let habits = (try? context.fetch(request))?.map { $0.toHabit() } ?? []

        // Use the selected habit, or fall back to the first active habit
        let habit: Habit?
        if let selectedID = configuration.habit?.id {
            habit = habits.first { $0.id == selectedID }
        } else {
            habit = habits.first
        }

        guard let habit else {
            return .placeholder
        }

        let weeks = habit.heatmapData(months: 3)
        let heatmapValues = weeks.flatMap { week in
            week.map { day -> WidgetHeatmapDay in
                WidgetHeatmapDay(
                    count: day.count,
                    status: day.status
                )
            }
        }

        return SingleHabitEntry(
            date: Date(),
            habitName: habit.name,
            habitIcon: habit.icon,
            colorRed: habit.colorComponents.red,
            colorGreen: habit.colorComponents.green,
            colorBlue: habit.colorComponents.blue,
            isPeriodComplete: habit.isPeriodComplete(for: Date()),
            periodCompletions: habit.completionsInPeriod(containing: Date()),
            goalFrequency: habit.goalFrequency,
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
    let isPeriodComplete: Bool
    let periodCompletions: Int
    let goalFrequency: Int
    let currentStreak: Int
    let completionRate: Double
    let heatmapDays: [WidgetHeatmapDay]

    var color: Color {
        Color(red: colorRed, green: colorGreen, blue: colorBlue)
    }

    var isMultiFrequency: Bool { goalFrequency > 1 }

    static let placeholder = SingleHabitEntry(
        date: Date(),
        habitName: "Exercise",
        habitIcon: "figure.run",
        colorRed: 0.35,
        colorGreen: 0.65,
        colorBlue: 0.85,
        isPeriodComplete: false,
        periodCompletions: 0,
        goalFrequency: 1,
        currentStreak: 5,
        completionRate: 0.72,
        heatmapDays: []
    )
}

struct WidgetHeatmapDay {
    let count: Int
    let status: CellStatus
}

struct SingleHabitWidget: Widget {
    let kind: String = "SingleHabitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind, intent: SelectHabitIntent.self, provider: SingleHabitWidgetProvider()
        ) { entry in
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
                if entry.isPeriodComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if entry.isMultiFrequency && entry.periodCompletions > 0 {
                    Text("\(entry.periodCompletions)/\(entry.goalFrequency)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(entry.color)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.gray)
                }
            }

            if family == .systemMedium {
                // Mini heatmap grid using liquid fill cells
                WidgetHeatmapGrid(
                    days: entry.heatmapDays,
                    color: entry.color,
                    goal: entry.goalFrequency
                )
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
    let days: [WidgetHeatmapDay]
    let color: Color
    let goal: Int
    let cellSize: CGFloat = 8
    let spacing: CGFloat = 2

    private var peak: Int {
        days.map(\.count).max() ?? 0
    }

    var body: some View {
        let rows = 7
        let cols = days.count / rows

        HStack(spacing: spacing) {
            ForEach(0..<cols, id: \.self) { col in
                VStack(spacing: spacing) {
                    ForEach(0..<rows, id: \.self) { row in
                        let index = col * rows + row
                        if index < days.count {
                            let day = days[index]
                            LiquidFillCell(
                                count: day.count,
                                goal: goal,
                                color: color,
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
