import Foundation

// MARK: - Nudge Settings

/// Per-habit nudge configuration, persisted in UserDefaults.
/// Using UserDefaults avoids a CoreData migration while still supporting per-habit settings.
struct NudgeSettings: Codable, Equatable {
    var isEnabled: Bool
    /// Time of day for the nudge (only hour/minute components are used).
    var nudgeTime: Date

    static let defaultNudgeHour = 20 // 8:00 PM
    static let defaultNudgeMinute = 0

    static var defaultNudgeTime: Date {
        Calendar.current.date(from: DateComponents(hour: defaultNudgeHour, minute: defaultNudgeMinute)) ?? Date()
    }

    static let `default` = NudgeSettings(isEnabled: false, nudgeTime: defaultNudgeTime)
}

// MARK: - Nudge Service

/// Manages per-habit nudge settings and orchestrates contextual notification scheduling.
enum NudgeService {

    private static let defaults = UserDefaults.standard
    private static let keyPrefix = "nudgeSettings-"

    // MARK: - Settings persistence

    static func settings(for habit: Habit) -> NudgeSettings {
        let key = keyPrefix + habit.id.uuidString
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(NudgeSettings.self, from: data)
        else { return .default }
        return decoded
    }

    static func save(_ settings: NudgeSettings, for habit: Habit) {
        let key = keyPrefix + habit.id.uuidString
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: key)
        }
    }

    static func removeSettings(for habit: Habit) {
        defaults.removeObject(forKey: keyPrefix + habit.id.uuidString)
        NotificationService.shared.removeNudges(for: habit)
    }

    // MARK: - Scheduling

    /// Apply nudge settings for a single habit: schedule or remove notifications as appropriate.
    static func apply(_ settings: NudgeSettings, for habit: Habit) {
        save(settings, for: habit)
        if settings.isEnabled {
            let cal = Calendar.current
            let hour = cal.component(.hour, from: settings.nudgeTime)
            let minute = cal.component(.minute, from: settings.nudgeTime)
            NotificationService.shared.scheduleNudges(for: habit, nudgeHour: hour, nudgeMinute: minute)
        } else {
            NotificationService.shared.removeNudges(for: habit)
        }
    }

    /// Refresh nudge notifications for a single habit using its stored settings.
    static func refresh(for habit: Habit) {
        apply(settings(for: habit), for: habit)
    }

    /// Refresh nudges for all habits. Call on app launch so the 7-day windows stay current.
    static func refreshAll(for habits: [Habit]) {
        for habit in habits {
            refresh(for: habit)
        }
    }
}
