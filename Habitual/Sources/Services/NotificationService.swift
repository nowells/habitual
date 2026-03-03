import UserNotifications
import SwiftUI

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            if granted {
                print("Notification permission granted")
            }
        }
    }

    func scheduleReminder(for habit: Habit) {
        guard let reminderTime = habit.reminderTime else { return }

        // Remove existing notifications for this habit
        removeReminder(for: habit)

        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "Time to complete: \(habit.name)"
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "habit-\(habit.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    func removeReminder(for habit: Habit) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["habit-\(habit.id.uuidString)"]
        )
    }

    func removeAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func setupCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Mark Complete",
            options: .foreground
        )

        let habitCategory = UNNotificationCategory(
            identifier: "HABIT_REMINDER",
            actions: [completeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([habitCategory])
    }
}
