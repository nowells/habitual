import UserNotifications
import SwiftUI

class NotificationService {
    static let shared = NotificationService()
    private init() {}

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
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error { print("Notification permission error: \(error)") }
            DispatchQueue.main.async { completion?(granted) }
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

        UNUserNotificationCenter.current().setNotificationCategories([
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
        UNUserNotificationCenter.current().add(request) { error in
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
                content.body = "\(habit.name) — \(streak) days in a row. You're so close!"
                content.categoryIdentifier = Category.streakAtRisk
            } else {
                content.title = nudgeTitle(for: habit, dayOffset: dayOffset)
                content.body = nudgeBody(streak: streak)
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
            UNUserNotificationCenter.current().add(request) { error in
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
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Error scheduling snooze: \(error)") }
        }
    }

    // MARK: - Removal

    func removeReminder(for habit: Habit) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminderID(for: habit)]
        )
    }

    func removeNudges(for habit: Habit) {
        let ids = (0..<7).map { nudgeID(for: habit, dayOffset: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func removeAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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
        if streak >= 7 {
            return "🔥 \(streak)-day streak! Keep the momentum going."
        } else if streak >= 3 {
            return "You're on a roll — \(streak) days in a row!"
        }
        return encouragingMessages.randomElement() ?? "Time to make it happen."
    }

    private func nudgeTitle(for habit: Habit, dayOffset: Int) -> String {
        dayOffset == 0 ? "Still time today" : habit.name
    }

    private func nudgeBody(streak: Int) -> String {
        if streak > 0 {
            return "You're on a \(streak)-day streak. Keep it going!"
        }
        return gentleNudgeMessages.randomElement() ?? "Every day counts."
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
