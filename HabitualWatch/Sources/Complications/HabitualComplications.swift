import CoreData
import SwiftUI
import WidgetKit

// MARK: - Watch Complications using WidgetKit

struct HabitualComplicationProvider: TimelineProvider {
    let persistenceController = PersistenceController.shared

    func placeholder(in context: Context) -> HabitComplicationEntry {
        defaultEntry()
    }

    private func defaultEntry() -> HabitComplicationEntry {
        HabitComplicationEntry(
            date: Date(),
            habitName: "Exercise",
            habitIcon: "figure.run",
            isCompleted: false,
            periodCompletions: 0,
            goalFrequency: 1,
            streak: 7,
            completionRate: 0.85,
            colorRed: 0.35,
            colorGreen: 0.65,
            colorBlue: 0.85
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitComplicationEntry) -> Void) {
        let entry = fetchCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitComplicationEntry>) -> Void) {
        let entry = fetchCurrentEntry()

        // Refresh at midnight or when the next reminder is
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> HabitComplicationEntry {
        guard let habit = loadFirstActiveHabit() else {
            return defaultEntry()
        }

        return HabitComplicationEntry(
            date: Date(),
            habitName: habit.name,
            habitIcon: habit.icon,
            isCompleted: habit.isPeriodComplete(for: Date()),
            periodCompletions: habit.completionsInPeriod(containing: Date()),
            goalFrequency: habit.goalFrequency,
            streak: habit.currentStreak,
            completionRate: habit.completionRate,
            colorRed: habit.colorComponents.red,
            colorGreen: habit.colorComponents.green,
            colorBlue: habit.colorComponents.blue
        )
    }

    private func loadFirstActiveHabit() -> Habit? {
        let context = persistenceController.container.newBackgroundContext()
        var habit: Habit?

        context.performAndWait {
            let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest()
            request.predicate = NSPredicate(format: "isArchived == NO")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDHabit.sortOrder, ascending: true),
                NSSortDescriptor(keyPath: \CDHabit.createdAt, ascending: false),
            ]
            request.fetchLimit = 1

            do {
                if let cdHabit = try context.fetch(request).first {
                    habit = cdHabit.toHabit()
                }
            } catch {
                print("Complication fetch failed: \(error)")
            }
        }

        return habit
    }
}

struct HabitComplicationEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let habitIcon: String
    let isCompleted: Bool
    let periodCompletions: Int
    let goalFrequency: Int
    let streak: Int
    let completionRate: Double
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double

    var color: Color {
        Color(red: colorRed, green: colorGreen, blue: colorBlue)
    }

    var isMultiFrequency: Bool { goalFrequency > 1 }
}

// MARK: - Complication Views

struct HabitualCircularComplication: View {
    let entry: HabitComplicationEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                HabitIcon.image(entry.habitIcon)
                    .font(.caption)
                    .foregroundStyle(entry.isCompleted ? .green : entry.color)

                if entry.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else if entry.isMultiFrequency && entry.periodCompletions > 0 {
                    Text("\(entry.periodCompletions)/\(entry.goalFrequency)")
                        .font(.system(size: 9))
                        .fontWeight(.bold)
                        .foregroundStyle(entry.color)
                } else {
                    Text("\(entry.streak)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
        }
    }
}

struct HabitualRectangularComplication: View {
    let entry: HabitComplicationEntry

    var body: some View {
        HStack(spacing: 8) {
            HabitIcon.image(entry.habitIcon)
                .font(.title3)
                .foregroundStyle(entry.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.habitName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if entry.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("Done")
                            .font(.caption2)
                    } else if entry.isMultiFrequency && entry.periodCompletions > 0 {
                        Text("\(entry.periodCompletions)/\(entry.goalFrequency)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(entry.color)
                    } else {
                        Image(systemName: "circle")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text("Pending")
                            .font(.caption2)
                    }

                    Text("·")

                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(entry.streak)")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}

struct HabitualInlineComplication: View {
    let entry: HabitComplicationEntry

    var body: some View {
        HStack(spacing: 4) {
            HabitIcon.image(entry.habitIcon)
            Text(entry.habitName)
            Text("·")
            Image(systemName: "flame.fill")
            Text("\(entry.streak)d")
        }
    }
}

struct HabitualCornerComplication: View {
    let entry: HabitComplicationEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            if entry.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                HabitIcon.image(entry.habitIcon)
                    .font(.title3)
                    .foregroundStyle(entry.color)
            }
        }
    }
}

// MARK: - Widget Configuration

struct HabitualComplicationWidget: Widget {
    let kind: String = "HabitualComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitualComplicationProvider()) { entry in
            switch entry {
            default:
                HabitualCircularComplication(entry: entry)
            }
        }
        .configurationDisplayName("Habitual")
        .description("Track your habits at a glance.")
        #if os(watchOS)
            .supportedFamilies([
                .accessoryCircular,
                .accessoryRectangular,
                .accessoryInline,
                .accessoryCorner,
            ])
        #endif
    }
}

// MARK: - Widget Bundle for Watch

@main
struct HabitualWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitualComplicationWidget()
    }
}
