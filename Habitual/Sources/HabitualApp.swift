import SwiftUI
import UserNotifications

// MARK: - App Delegate (iOS)

#if os(iOS)
import UIKit

/// Handles notification action responses and sets the UNUserNotificationCenter delegate.
/// Runs notification-triggered completions in the background without opening the app.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - Notification Response

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard
            let habitIDString = userInfo[NotificationService.UserInfoKey.habitID] as? String,
            let habitID = UUID(uuidString: habitIDString)
        else {
            completionHandler()
            return
        }

        let habitName = (userInfo[NotificationService.UserInfoKey.habitName] as? String) ?? ""

        switch response.actionIdentifier {
        case NotificationService.Action.completeBackground:
            // Mark complete without opening the app
            Task { @MainActor in
                let store = HabitStore(context: PersistenceController.shared.container.viewContext)
                if let habit = store.activeHabits.first(where: { $0.id == habitID }),
                   !habit.isCompletedOn(date: Date()) {
                    store.toggleTodayCompletion(for: habit)
                    // Reschedule nudges so today's windows are cleared
                    NudgeService.refresh(for: habit)
                }
                completionHandler()
            }

        case NotificationService.Action.snooze:
            NotificationService.shared.scheduleSnooze(for: habitID, habitName: habitName)
            completionHandler()

        case NotificationService.Action.skip:
            // User chose to skip — just dismiss; no completion logged
            completionHandler()

        default:
            // Default tap: app will open and navigate naturally
            completionHandler()
        }
    }

    // Show notifications as banners even when the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
#endif

// MARK: - App Entry Point

@main
struct HabitualApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    let persistenceController = PersistenceController.shared

    init() {
        NotificationService.shared.setupCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    refreshNudgesOnLaunch()
                    #if targetEnvironment(macCatalyst)
                    UIApplication.shared.registerForRemoteNotifications()
                    #endif
                }
        }
    }

    /// Refresh the 7-day nudge windows for all active habits every time the app comes to foreground.
    private func refreshNudgesOnLaunch() {
        Task { @MainActor in
            let store = HabitStore(context: persistenceController.container.viewContext)
            NudgeService.refreshAll(for: store.activeHabits)
        }
    }
}
