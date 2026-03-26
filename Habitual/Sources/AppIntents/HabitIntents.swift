import AppIntents
import CoreData

// MARK: - Habit App Entity

/// Lightweight representation of a Habit for use in App Intents parameter resolution.
struct HabitAppEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    static let defaultQuery = HabitEntityQuery()

    let id: UUID
    let name: String
    let icon: String
    let goalDescription: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(goalDescription)"
        )
    }
}

// MARK: - Entity Query

struct HabitEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [HabitAppEntity] {
        let store = HabitStore(context: PersistenceController.shared.container.viewContext)
        return store.activeHabits
            .filter { identifiers.contains($0.id) }
            .map { $0.asAppEntity }
    }

    @MainActor
    func suggestedEntities() async throws -> [HabitAppEntity] {
        let store = HabitStore(context: PersistenceController.shared.container.viewContext)
        return store.activeHabits.map { $0.asAppEntity }
    }
}

extension Habit {
    var asAppEntity: HabitAppEntity {
        HabitAppEntity(
            id: id,
            name: name,
            icon: icon,
            goalDescription: "\(goalFrequency)x / \(goalPeriod.periodLabel)"
        )
    }
}

// MARK: - Log Habit Intent

/// Logs a habit as complete for today. Works from Siri, Shortcuts, and the Shortcuts automation
/// triggers (e.g., "When I wake up", "When I arrive at gym").
struct LogHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Habit"
    static let description = IntentDescription(
        "Mark a habit as complete for today. Use with Shortcuts automations to log habits on a schedule or when triggered by a location, focus mode, or other event.",
        categoryName: "Habit Tracking"
    )

    @Parameter(title: "Habit", description: "The habit to log for today.")
    var habit: HabitAppEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = HabitStore(context: PersistenceController.shared.container.viewContext)

        guard let match = store.activeHabits.first(where: { $0.id == habit.id }) else {
            return .result(dialog: "Couldn't find that habit. Make sure it's still active in Habitual.")
        }

        if match.isCompletedOn(date: Date()) {
            return .result(dialog: "\(match.name) is already logged for today. Nice work!")
        }

        store.toggleTodayCompletion(for: match)

        // Re-fetch to get updated streak
        let updated = store.activeHabits.first(where: { $0.id == match.id })
        let streak = updated?.currentStreak ?? 0
        let unit = match.goalPeriod.periodLabelPlural
        let streakMsg = streak > 1 ? " That's \(streak) \(unit) in a row!" : ""
        return .result(dialog: "Logged \(match.name)!\(streakMsg)")
    }
}

// MARK: - Check Habit Status Intent

/// Check whether a habit has been completed today — useful in Shortcuts conditionals.
struct CheckHabitStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Habit Status"
    static let description = IntentDescription(
        "Find out if a habit is already logged for today. Use in Shortcuts to skip a reminder if you've already completed the habit.",
        categoryName: "Habit Tracking"
    )

    @Parameter(title: "Habit", description: "The habit to check.")
    var habit: HabitAppEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Bool> {
        let store = HabitStore(context: PersistenceController.shared.container.viewContext)

        guard let match = store.activeHabits.first(where: { $0.id == habit.id }) else {
            return .result(value: false, dialog: "Habit not found.")
        }

        let isDone = match.isCompletedOn(date: Date())
        let streak = match.currentStreak

        if isDone {
            return .result(
                value: true,
                dialog: "\(match.name) is done today! You're on a \(streak)-\(match.goalPeriod.periodLabel) streak."
            )
        } else {
            let nudge = streak >= 3 ? " You have a \(streak)-\(match.goalPeriod.periodLabel) streak — don't break it!" : ""
            return .result(
                value: false,
                dialog: "\(match.name) isn't logged yet today.\(nudge)"
            )
        }
    }
}

// MARK: - App Shortcuts Provider

/// Registers Siri phrases and exposes habits to the Shortcuts app.
/// Users can also create Shortcuts automations to call LogHabitIntent on:
///   • a schedule (wake-up alarm, bedtime)
///   • location (arrive at gym, leave home)
///   • Focus mode changes (Fitness Focus, Sleep Focus)
///   • NFC tag tap
struct HabitualShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogHabitIntent(),
            phrases: [
                "Log \(\.$habit) in \(.applicationName)",
                "Mark \(\.$habit) done in \(.applicationName)",
                "I finished \(\.$habit) in \(.applicationName)",
                "Complete \(\.$habit) in \(.applicationName)",
            ],
            shortTitle: "Log Habit",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: CheckHabitStatusIntent(),
            phrases: [
                "Check \(\.$habit) in \(.applicationName)",
                "Did I do \(\.$habit) today in \(.applicationName)",
                "Have I completed \(\.$habit) in \(.applicationName)",
            ],
            shortTitle: "Check Habit",
            systemImageName: "questionmark.circle.fill"
        )
    }
}
