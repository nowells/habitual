import Foundation

// MARK: - Nudge Settings

/// Per-habit nudge configuration, persisted in UserDefaults.
/// Using UserDefaults avoids a CoreData migration while still supporting per-habit settings.
struct NudgeSettings: Codable, Equatable {
    var isEnabled: Bool
    /// Time of day for the nudge (only hour/minute components are used).
    var nudgeTime: Date

    static let defaultNudgeHour = 20  // 8:00 PM
    static let defaultNudgeMinute = 0

    static var defaultNudgeTime: Date {
        Calendar.current.date(from: DateComponents(hour: defaultNudgeHour, minute: defaultNudgeMinute)) ?? Date()
    }

    static let `default` = NudgeSettings(isEnabled: false, nudgeTime: defaultNudgeTime)
}

// MARK: - Period Reminder Settings

/// Configuration for period-aware reminders (start/mid/end of period).
/// Each period type has appropriate default thresholds.
struct PeriodReminderSettings: Codable, Equatable {
    var isEnabled: Bool

    /// Start of period reminder time (hour/minute only)
    var startReminderTime: Date
    /// Whether start-of-period reminder is enabled
    var startReminderEnabled: Bool

    /// Mid-period reminder time (hour/minute only)
    var midReminderTime: Date
    /// Whether mid-period reminder is enabled
    var midReminderEnabled: Bool

    /// End-of-period (urgent) reminder time (hour/minute only)
    var endReminderTime: Date
    /// Whether end-of-period reminder is enabled
    var endReminderEnabled: Bool

    // MARK: - Defaults per period type

    static func defaults(for period: Habit.GoalPeriod) -> PeriodReminderSettings {
        let cal = Calendar.current
        switch period {
        case .daily:
            return PeriodReminderSettings(
                isEnabled: false,
                startReminderTime: cal.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
                startReminderEnabled: true,
                midReminderTime: cal.date(from: DateComponents(hour: 12, minute: 0)) ?? Date(),
                midReminderEnabled: true,
                endReminderTime: cal.date(from: DateComponents(hour: 20, minute: 0)) ?? Date(),
                endReminderEnabled: true
            )
        case .weekly:
            // Start: Monday morning, Mid: Wednesday/Thursday, End: Sunday
            return PeriodReminderSettings(
                isEnabled: false,
                startReminderTime: cal.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
                startReminderEnabled: true,
                midReminderTime: cal.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
                midReminderEnabled: true,
                endReminderTime: cal.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
                endReminderEnabled: true
            )
        case .monthly:
            // Start: 1st of month, Mid: 15th, End: last few days
            return PeriodReminderSettings(
                isEnabled: false,
                startReminderTime: cal.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
                startReminderEnabled: true,
                midReminderTime: cal.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
                midReminderEnabled: true,
                endReminderTime: cal.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
                endReminderEnabled: true
            )
        }
    }
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

    // MARK: - Period Reminder Settings

    private static let periodKeyPrefix = "periodReminderSettings-"

    static func periodSettings(for habit: Habit) -> PeriodReminderSettings {
        let key = periodKeyPrefix + habit.id.uuidString
        guard let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(PeriodReminderSettings.self, from: data)
        else { return PeriodReminderSettings.defaults(for: habit.goalPeriod) }
        return decoded
    }

    static func savePeriodSettings(_ settings: PeriodReminderSettings, for habit: Habit) {
        let key = periodKeyPrefix + habit.id.uuidString
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: key)
        }
    }

    static func removePeriodSettings(for habit: Habit) {
        defaults.removeObject(forKey: periodKeyPrefix + habit.id.uuidString)
        NotificationService.shared.removePeriodReminders(for: habit)
    }

    /// Apply period reminder settings: schedule or remove period-aware notifications.
    static func applyPeriodSettings(_ settings: PeriodReminderSettings, for habit: Habit) {
        savePeriodSettings(settings, for: habit)
        if settings.isEnabled {
            NotificationService.shared.schedulePeriodReminders(for: habit, settings: settings)
        } else {
            NotificationService.shared.removePeriodReminders(for: habit)
        }
    }

    /// Refresh period reminders for a single habit.
    static func refreshPeriod(for habit: Habit) {
        applyPeriodSettings(periodSettings(for: habit), for: habit)
    }

    /// Refresh period reminders for all habits.
    static func refreshAllPeriod(for habits: [Habit]) {
        for habit in habits {
            refreshPeriod(for: habit)
        }
    }
}
