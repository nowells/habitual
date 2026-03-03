import WidgetKit
import SwiftUI

// MARK: - Watch Complications using WidgetKit

struct HabitualComplicationProvider: TimelineProvider {
    let persistenceController = PersistenceController.shared

    func placeholder(in context: Context) -> HabitComplicationEntry {
        HabitComplicationEntry(
            date: Date(),
            habitName: "Exercise",
            habitIcon: "figure.run",
            isCompleted: false,
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
        let context = persistenceController.container.viewContext
        let store = HabitStore(context: context)

        guard let firstHabit = store.activeHabits.first else {
            return placeholder(in: .init())
        }

        return HabitComplicationEntry(
            date: Date(),
            habitName: firstHabit.name,
            habitIcon: firstHabit.icon,
            isCompleted: firstHabit.isCompletedOn(date: Date()),
            streak: firstHabit.currentStreak,
            completionRate: firstHabit.completionRate,
            colorRed: firstHabit.colorComponents.red,
            colorGreen: firstHabit.colorComponents.green,
            colorBlue: firstHabit.colorComponents.blue
        )
    }
}

struct HabitComplicationEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let habitIcon: String
    let isCompleted: Bool
    let streak: Int
    let completionRate: Double
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double

    var color: Color {
        Color(red: colorRed, green: colorGreen, blue: colorBlue)
    }
}

// MARK: - Complication Views

struct HabitualCircularComplication: View {
    let entry: HabitComplicationEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                Image(systemName: entry.habitIcon)
                    .font(.caption)
                    .foregroundStyle(entry.isCompleted ? .green : entry.color)

                if entry.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundStyle(.green)
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
            Image(systemName: entry.habitIcon)
                .font(.title3)
                .foregroundStyle(entry.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.habitName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.caption2)
                        .foregroundStyle(entry.isCompleted ? .green : .gray)

                    Text(entry.isCompleted ? "Done" : "Pending")
                        .font(.caption2)

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
            Image(systemName: entry.habitIcon)
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

            Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : entry.habitIcon)
                .font(.title3)
                .foregroundStyle(entry.isCompleted ? .green : entry.color)
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
