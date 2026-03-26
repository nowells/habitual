import UserNotifications
import SwiftUI

class NotificationService {
    static let shared = NotificationService()
    private init() {}

    /// UNUserNotificationCenter.current() crashes in xctest / SPM test runners
    /// because the host process is not an .app bundle. Guard every call with this.
    private var notificationCenter: UNUserNotificationCenter? {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return nil }
        return UNUserNotificationCenter.current()
    }

    // MARK: - Identifiers

    enum Category {
        static let habitReminder = "HABIT_REMINDER"
        static let nudge = "HABIT_NUDGE"
        static let streakAtRisk = "STREAK_AT_RISK"
    }

    enum Action {
        static let completeBackground = "COMPLETE_BACKGROUND"
        static let snooze = "SNOOZE_ACTION"
        static let skip = "SKIP_ACTION"
    }

    enum UserInfoKey {
        static let habitID = "habitID"
        static let habitName = "habitName"
    }

    // MARK: - Permission

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        guard let center = notificationCenter else { completion?(false); return }
        center.requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error { print("Notification permission error: \(error)") }
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        guard let center = notificationCenter else { return .notDetermined }
        return await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    // MARK: - Category Setup

    func setupCategories() {
        // Reminder category: Complete, Snooze, Skip
        let completeAction = UNNotificationAction(
            identifier: Action.completeBackground,
            title: "Mark Complete",
            options: []
        )
        let snoozeAction = UNNotificationAction(
            identifier: Action.snooze,
            title: "Snooze 1 Hour",
            options: []
        )
        let skipAction = UNNotificationAction(
            identifier: Action.skip,
            title: "Skip Today",
            options: [.destructive]
        )
        let reminderCategory = UNNotificationCategory(
            identifier: Category.habitReminder,
            actions: [completeAction, snoozeAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Nudge category: gentler tone
        let nudgeComplete = UNNotificationAction(
            identifier: Action.completeBackground,
            title: "Done!",
            options: []
        )
        let nudgeSnooze = UNNotificationAction(
            identifier: Action.snooze,
            title: "Remind me later",
            options: []
        )
        let nudgeCategory = UNNotificationCategory(
            identifier: Category.nudge,
            actions: [nudgeComplete, nudgeSnooze],
            intentIdentifiers: [],
            options: []
        )

        // Streak-at-risk category: more urgent framing
        let streakComplete = UNNotificationAction(
            identifier: Action.completeBackground,
            title: "Keep the streak!",
            options: []
        )
        let streakCategory = UNNotificationCategory(
            identifier: Category.streakAtRisk,
            actions: [streakComplete, nudgeSnooze],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter?.setNotificationCategories([
            reminderCategory, nudgeCategory, streakCategory,
        ])
    }

    // MARK: - Scheduled Reminder

    /// Schedule a daily repeating reminder at the habit's reminderTime.
    func scheduleReminder(for habit: Habit) {
        guard let reminderTime = habit.reminderTime else { return }
        removeReminder(for: habit)

        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = scheduledReminderBody(for: habit)
        content.sound = .default
        content.categoryIdentifier = Category.habitReminder
        content.userInfo = [
            UserInfoKey.habitID: habit.id.uuidString,
            UserInfoKey.habitName: habit.name,
        ]

        let cal = Calendar.current
        let components = cal.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: reminderID(for: habit),
            content: content,
            trigger: trigger
        )
        notificationCenter?.add(request) { error in
            if let error { print("Error scheduling reminder: \(error)") }
        }
    }

    // MARK: - Contextual Nudges

    /// Schedule contextual nudge notifications for the next 7 days.
    /// Each nudge fires once (not repeating) so the message can reference today's streak.
    /// Call this on app launch and whenever nudge settings change.
    func scheduleNudges(for habit: Habit, nudgeHour: Int, nudgeMinute: Int) {
        removeNudges(for: habit)
        guard habit.goalPeriod == .daily else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        for dayOffset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: dayOffset, to: today),
                  let nudgeDate = cal.date(bySettingHour: nudgeHour, minute: nudgeMinute, second: 0, of: day)
            else { continue }

            // Skip nudges in the past
            if nudgeDate <= Date() { continue }

            // Don't schedule if already completed that day
            if habit.isCompletedOn(date: day) { continue }

            let streak = habit.currentStreak
            let streakAtRisk = streak >= 3 && dayOffset == 0

            let content = UNMutableNotificationContent()
            if streakAtRisk {
                content.title = "🔥 Don't break your streak!"
                content.body = "\(habit.name) — \(streak) \(habit.goalPeriod.periodLabelPlural) in a row. You're so close!"
                content.categoryIdentifier = Category.streakAtRisk
            } else {
                content.title = nudgeTitle(for: habit, dayOffset: dayOffset)
                content.body = nudgeBody(streak: streak, habit: habit)
                content.categoryIdentifier = Category.nudge
            }
            content.sound = .default
            content.userInfo = [
                UserInfoKey.habitID: habit.id.uuidString,
                UserInfoKey.habitName: habit.name,
            ]

            let triggerComponents = cal.dateComponents(
                [.year, .month, .day, .hour, .minute], from: nudgeDate
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: triggerComponents, repeats: false
            )
            let request = UNNotificationRequest(
                identifier: nudgeID(for: habit, dayOffset: dayOffset),
                content: content,
                trigger: trigger
            )
            notificationCenter?.add(request) { error in
                if let error { print("Error scheduling nudge day+\(dayOffset): \(error)") }
            }
        }
    }

    // MARK: - Snooze

    /// Create a one-off snooze notification N hours from now.
    func scheduleSnooze(for habitID: UUID, habitName: String, hoursFromNow: Double = 1) {
        let content = UNMutableNotificationContent()
        content.title = habitName
        content.body = "Ready to pick back up? You've got this."
        content.sound = .default
        content.categoryIdentifier = Category.nudge
        content.userInfo = [
            UserInfoKey.habitID: habitID.uuidString,
            UserInfoKey.habitName: habitName,
        ]
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: hoursFromNow * 3600,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "snooze-\(habitID.uuidString)-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )
        notificationCenter?.add(request) { error in
            if let error { print("Error scheduling snooze: \(error)") }
        }
    }

    // MARK: - Period-Aware Reminders

    /// Schedule start/mid/end-of-period reminders for the next 7 periods.
    func schedulePeriodReminders(for habit: Habit, settings: PeriodReminderSettings) {
        removePeriodReminders(for: habit)

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let currentPeriodStart = habit.goalPeriod.periodStart(for: today, calendar: cal)

        // Schedule for the next 7 periods
        for periodOffset in 0..<7 {
            guard let periodStart = cal.date(
                byAdding: habit.goalPeriod.calendarComponent,
                value: periodOffset,
                to: currentPeriodStart
            ) else { continue }

            let periodEnd = habit.goalPeriod.periodEnd(for: periodStart, calendar: cal)

            // Start of period reminder
            if settings.startReminderEnabled {
                let startHour = cal.component(.hour, from: settings.startReminderTime)
                let startMinute = cal.component(.minute, from: settings.startReminderTime)

                if let fireDate = cal.date(bySettingHour: startHour, minute: startMinute, second: 0, of: periodStart),
                   fireDate > Date() {
                    let content = periodReminderContent(
                        for: habit,
                        phase: .start,
                        periodStart: periodStart,
                        periodEnd: periodEnd
                    )
                    scheduleOneShotNotification(
                        id: periodReminderID(for: habit, periodOffset: periodOffset, phase: "start"),
                        content: content,
                        fireDate: fireDate
                    )
                }
            }

            // Mid-period reminder
            if settings.midReminderEnabled {
                let midDate = midPeriodDate(
                    period: habit.goalPeriod,
                    periodStart: periodStart,
                    periodEnd: periodEnd,
                    calendar: cal
                )
                let midHour = cal.component(.hour, from: settings.midReminderTime)
                let midMinute = cal.component(.minute, from: settings.midReminderTime)

                if let fireDate = cal.date(bySettingHour: midHour, minute: midMinute, second: 0, of: midDate),
                   fireDate > Date() {
                    // Only fire if goal not yet met
                    let completionsSoFar = habit.completionsInPeriod(containing: periodStart)
                    if completionsSoFar < habit.goalFrequency || periodOffset > 0 {
                        let content = periodReminderContent(
                            for: habit,
                            phase: .mid,
                            periodStart: periodStart,
                            periodEnd: periodEnd
                        )
                        scheduleOneShotNotification(
                            id: periodReminderID(for: habit, periodOffset: periodOffset, phase: "mid"),
                            content: content,
                            fireDate: fireDate
                        )
                    }
                }
            }

            // End of period (urgent) reminder
            if settings.endReminderEnabled {
                let endDate = endPeriodDate(
                    period: habit.goalPeriod,
                    periodStart: periodStart,
                    periodEnd: periodEnd,
                    calendar: cal
                )
                let endHour = cal.component(.hour, from: settings.endReminderTime)
                let endMinute = cal.component(.minute, from: settings.endReminderTime)

                if let fireDate = cal.date(bySettingHour: endHour, minute: endMinute, second: 0, of: endDate),
                   fireDate > Date() {
                    let completionsSoFar = habit.completionsInPeriod(containing: periodStart)
                    if completionsSoFar < habit.goalFrequency || periodOffset > 0 {
                        let content = periodReminderContent(
                            for: habit,
                            phase: .end,
                            periodStart: periodStart,
                            periodEnd: periodEnd
                        )
                        scheduleOneShotNotification(
                            id: periodReminderID(for: habit, periodOffset: periodOffset, phase: "end"),
                            content: content,
                            fireDate: fireDate
                        )
                    }
                }
            }
        }
    }

    // MARK: - Removal

    func removeReminder(for habit: Habit) {
        notificationCenter?.removePendingNotificationRequests(
            withIdentifiers: [reminderID(for: habit)]
        )
    }

    func removeNudges(for habit: Habit) {
        let ids = (0..<7).map { nudgeID(for: habit, dayOffset: $0) }
        notificationCenter?.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func removePeriodReminders(for habit: Habit) {
        let phases = ["start", "mid", "end"]
        let ids = (0..<7).flatMap { offset in
            phases.map { phase in periodReminderID(for: habit, periodOffset: offset, phase: phase) }
        }
        notificationCenter?.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func removeAllReminders() {
        notificationCenter?.removeAllPendingNotificationRequests()
    }

    func notifySyncFailure(message: String) {
        guard let center = notificationCenter else { return }
        let content = UNMutableNotificationContent()
        content.title = "iCloud Sync Failed"
        content.body = message
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "sync-failure-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request) { error in
            if let error { print("Error scheduling sync failure notification: \(error)") }
        }
    }

    // MARK: - Private helpers

    private func reminderID(for habit: Habit) -> String {
        "habit-\(habit.id.uuidString)-reminder"
    }

    private func nudgeID(for habit: Habit, dayOffset: Int) -> String {
        "habit-\(habit.id.uuidString)-nudge-day\(dayOffset)"
    }

    private func scheduledReminderBody(for habit: Habit) -> String {
        let streak = habit.currentStreak
        let unit = habit.goalPeriod.periodLabelPlural
        if streak >= 7 {
            return "🔥 \(streak)-\(habit.goalPeriod.periodLabel) streak! Keep the momentum going."
        } else if streak >= 3 {
            return "You're on a roll — \(streak) \(unit) in a row!"
        }
        return encouragingMessages.randomElement() ?? "Time to make it happen."
    }

    private func nudgeTitle(for habit: Habit, dayOffset: Int) -> String {
        dayOffset == 0 ? "Still time today" : habit.name
    }

    private func nudgeBody(streak: Int, habit: Habit) -> String {
        if streak > 0 {
            return "You're on a \(streak)-\(habit.goalPeriod.periodLabel) streak. Keep it going!"
        }
        return gentleNudgeMessages.randomElement() ?? "Every day counts."
    }

    // MARK: - Period Reminder Helpers

    private enum ReminderPhase {
        case start, mid, end
    }

    private func periodReminderID(for habit: Habit, periodOffset: Int, phase: String) -> String {
        "habit-\(habit.id.uuidString)-period-\(periodOffset)-\(phase)"
    }

    private func scheduleOneShotNotification(id: String, content: UNMutableNotificationContent, fireDate: Date) {
        let cal = Calendar.current
        let triggerComponents = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        notificationCenter?.add(request) { error in
            if let error { print("Error scheduling period reminder: \(error)") }
        }
    }

    private func midPeriodDate(period: Habit.GoalPeriod, periodStart: Date, periodEnd: Date, calendar: Calendar) -> Date {
        switch period {
        case .daily:
            // Noon
            return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: periodStart) ?? periodStart
        case .weekly:
            // Mid-week (Wednesday/Thursday = 3 days after start)
            return calendar.date(byAdding: .day, value: 3, to: periodStart) ?? periodStart
        case .monthly:
            // Mid-month (15th or middle of the month)
            return calendar.date(byAdding: .day, value: 14, to: periodStart) ?? periodStart
        }
    }

    private func endPeriodDate(period: Habit.GoalPeriod, periodStart: Date, periodEnd: Date, calendar: Calendar) -> Date {
        switch period {
        case .daily:
            // Evening of the same day
            return periodStart
        case .weekly:
            // Last day of the week (1 day before period end)
            return calendar.date(byAdding: .day, value: -1, to: periodEnd) ?? periodStart
        case .monthly:
            // Last 3 days of month (3 days before period end)
            return calendar.date(byAdding: .day, value: -3, to: periodEnd) ?? periodStart
        }
    }

    private func periodReminderContent(
        for habit: Habit,
        phase: ReminderPhase,
        periodStart: Date,
        periodEnd: Date
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.userInfo = [
            UserInfoKey.habitID: habit.id.uuidString,
            UserInfoKey.habitName: habit.name,
        ]

        let periodName = habit.goalPeriod.periodLabel
        let freq = habit.goalFrequency

        switch phase {
        case .start:
            content.title = habit.name
            content.body = startOfPeriodMessage(periodName: periodName, frequency: freq)
            content.categoryIdentifier = Category.nudge
        case .mid:
            content.title = "Check in: \(habit.name)"
            content.body = midPeriodMessage(periodName: periodName, frequency: freq)
            content.categoryIdentifier = Category.nudge
        case .end:
            content.title = "⏰ \(habit.name)"
            content.body = endOfPeriodMessage(periodName: periodName, frequency: freq)
            content.categoryIdentifier = Category.streakAtRisk
        }

        return content
    }

    private func startOfPeriodMessage(periodName: String, frequency: Int) -> String {
        if frequency == 1 {
            return "New \(periodName) starts now! You've got this."
        }
        return "New \(periodName)! Goal: \(frequency) times this \(periodName). Let's go!"
    }

    private func midPeriodMessage(periodName: String, frequency: Int) -> String {
        if frequency == 1 {
            return "Halfway through the \(periodName). Still time to check this off!"
        }
        return "The \(periodName) is halfway through. How's your progress?"
    }

    private func endOfPeriodMessage(periodName: String, frequency: Int) -> String {
        if frequency == 1 {
            return "The \(periodName) is almost over — don't miss it!"
        }
        return "Running out of time this \(periodName)! Make sure to hit your goal."
    }

    private let encouragingMessages = [
        "Your future self will thank you.",
        "Small steps, big results.",
        "You've got this!",
        "Consistency is the key.",
        "One step closer to your goal.",
    ]

    private let gentleNudgeMessages = [
        "Every day counts.",
        "A little progress is still progress.",
        "You can do this — one small step at a time.",
        "Building habits takes time. You're doing great.",
        "Still time today. No pressure.",
    ]
}
