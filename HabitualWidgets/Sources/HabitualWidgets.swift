import AppIntents
import CoreData
import SwiftUI
import WidgetKit

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Platform Colors

extension Color {
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

        let now = Date()
        let habitSnapshots = habits.map { habit in
            // Build period-level data for the mini heatmap.
            // For daily habits each period is one day; for weekly/monthly
            // each period is one week/month — matching the main app's rendering.
            let periods: [WidgetPeriod]
            if habit.goalPeriod == .daily {
                periods = habit.heatmapData(months: 2).flatMap { $0 }.map { day in
                    WidgetPeriod(completionCount: day.isFuture ? 0 : Int(day.value), isFuture: day.isFuture)
                }
            } else {
                periods = habit.periodHeatmapData(months: 2).map { period in
                    WidgetPeriod(completionCount: period.completionCount, isFuture: period.isFuture)
                }
            }

            return HabitSnapshot(
                id: habit.id,
                name: habit.name,
                icon: habit.icon,
                colorRed: habit.colorComponents.red,
                colorGreen: habit.colorComponents.green,
                colorBlue: habit.colorComponents.blue,
                isPeriodComplete: habit.isPeriodComplete(for: now),
                periodCompletions: habit.completionsInPeriod(containing: now),
                goalFrequency: habit.goalFrequency,
                goalPeriod: habit.goalPeriod.rawValue,
                currentStreak: habit.currentStreak,
                completionRate: habit.completionRate,
                recentPeriods: periods
            )
        }
        // Sort: incomplete habits first, then completed — within each group
        // order by period frequency (daily → weekly → monthly → yearly).
        .sorted { first, second in
            if first.isPeriodComplete != second.isPeriodComplete {
                return !first.isPeriodComplete
            }
            return first.periodSortOrder < second.periodSortOrder
        }

        let completedCount = habits.filter { $0.isPeriodComplete(for: now) }.count

        return HabitWidgetEntry(
            date: Date(),
            habits: habitSnapshots,
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
            HabitSnapshot(
                id: UUID(), name: "Read", icon: "book.fill", colorRed: 0.95, colorGreen: 0.55, colorBlue: 0.20,
                isPeriodComplete: false, periodCompletions: 0, goalFrequency: 1, goalPeriod: "daily",
                currentStreak: 3, completionRate: 0.60, recentPeriods: []),
            HabitSnapshot(
                id: UUID(), name: "Exercise", icon: "figure.run", colorRed: 0.35, colorGreen: 0.65, colorBlue: 0.85,
                isPeriodComplete: true, periodCompletions: 1, goalFrequency: 1, goalPeriod: "daily",
                currentStreak: 7, completionRate: 0.85, recentPeriods: []),
            HabitSnapshot(
                id: UUID(), name: "Meditate", icon: "brain.head.profile", colorRed: 0.65, colorGreen: 0.35,
                colorBlue: 0.90, isPeriodComplete: true, periodCompletions: 3, goalFrequency: 3, goalPeriod: "daily",
                currentStreak: 12, completionRate: 0.75, recentPeriods: []),
        ],
        totalHabits: 3,
        completedToday: 2
    )
}

/// One period's worth of completion data for the widget mini heatmap.
struct WidgetPeriod {
    let completionCount: Int
    let isFuture: Bool
}

struct HabitSnapshot: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double
    let isPeriodComplete: Bool
    let periodCompletions: Int
    let goalFrequency: Int
    let goalPeriod: String
    let currentStreak: Int
    let completionRate: Double
    let recentPeriods: [WidgetPeriod]

    var color: Color {
        Color(red: colorRed, green: colorGreen, blue: colorBlue)
    }

    /// Whether this habit has multi-frequency goal (e.g. 3x/day)
    var isMultiFrequency: Bool { goalFrequency > 1 }

    /// Sort priority for goal period: daily first, then weekly, monthly, yearly.
    var periodSortOrder: Int {
        switch goalPeriod {
        case "daily": return 0
        case "weekly": return 1
        case "monthly": return 2
        case "yearly": return 3
        default: return 4
        }
    }
}

// MARK: - Small Widget

struct SmallHabitWidget: View {
    let entry: HabitWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
                        .stroke(Color.systemGray5, lineWidth: 5)
                        .frame(width: 46, height: 46)

                    Circle()
                        .trim(from: 0, to: entry.completionFraction)
                        .stroke(
                            Color.green,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 46, height: 46)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(entry.completionFraction * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                Spacer()
            }

            Spacer()

            // Habit icons — show up to 8, wrapping to a second row if needed
            let icons = Array(entry.habits.prefix(8))
            let topRow = Array(icons.prefix(min(icons.count, 5)))
            let bottomRow = icons.count > 5 ? Array(icons.suffix(from: 5)) : []

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    ForEach(topRow) { habit in
                        HabitIcon.image(habit.icon)
                            .font(.caption2)
                            .foregroundStyle(habit.isPeriodComplete ? habit.color : .gray)
                    }
                }
                if !bottomRow.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(bottomRow) { habit in
                            HabitIcon.image(habit.icon)
                                .font(.caption2)
                                .foregroundStyle(habit.isPeriodComplete ? habit.color : .gray)
                        }
                    }
                }
            }
        }
        .padding(10)
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
                    if habit.isPeriodComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(habit.color)
                    } else if habit.isMultiFrequency && habit.periodCompletions > 0 {
                        // Show partial progress for multi-frequency habits
                        Text("\(habit.periodCompletions)/\(habit.goalFrequency)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(habit.color)
                            .frame(width: 22)
                    } else {
                        Image(systemName: "circle")
                            .font(.body)
                            .foregroundStyle(Color.systemGray3)
                    }

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
                    if habit.isPeriodComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(habit.color)
                    } else if habit.isMultiFrequency && habit.periodCompletions > 0 {
                        Text("\(habit.periodCompletions)/\(habit.goalFrequency)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(habit.color)
                            .frame(width: 22)
                    } else {
                        Image(systemName: "circle")
                            .font(.body)
                            .foregroundStyle(Color.systemGray3)
                    }

                    HabitIcon.image(habit.icon)
                        .font(.caption)
                        .foregroundStyle(habit.color)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        // Mini heatmap dots — last 14 periods with pie-fill progress
                        WidgetMiniHeatmap(habit: habit)
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

// MARK: - Widget Mini Heatmap (with liquid fill progress)

/// Renders the last 14 periods as small liquid-fill cells,
/// matching the main app's `LiquidFillCell` rendering.
struct WidgetMiniHeatmap: View {
    let habit: HabitSnapshot
    private let dotSize: CGFloat = 6

    var body: some View {
        let periods = Array(habit.recentPeriods.suffix(14))
        let peak = periods.map(\.completionCount).max() ?? 0
        HStack(spacing: 2) {
            ForEach(periods.indices, id: \.self) { idx in
                let period = periods[idx]
                let status: CellStatus = {
                    if period.isFuture { return .future }
                    if period.completionCount == 0 { return .missed }
                    if period.completionCount < habit.goalFrequency { return .partial }
                    if period.completionCount >= habit.goalFrequency * 2 { return .overComplete }
                    return .complete
                }()
                LiquidFillCell(
                    count: period.completionCount,
                    goal: habit.goalFrequency,
                    color: habit.color,
                    status: status,
                    size: dotSize,
                    maxCount: peak
                )
            }
        }
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
                    Image(systemName: habit.isPeriodComplete ? "checkmark.circle.fill" : "circle")
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
