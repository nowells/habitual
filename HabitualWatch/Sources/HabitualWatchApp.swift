import SwiftUI
import WatchKit
import WidgetKit

@main
struct HabitualWatchApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .backgroundTask(.appRefresh("com.habitual-helper.app.refresh")) {
            await handleAppRefresh()
        }
        .backgroundTask(.appRefresh("com.apple.cloudkit.scheduler")) {
            // CloudKit silent push: just refresh the view context so the UI picks up
            // any changes that NSPersistentCloudKitContainer imported in the background.
            await handleCloudKitSync()
        }
    }

    private func handleAppRefresh() async {
        // Refresh the persistent store to pick up any CloudKit changes
        persistenceController.container.viewContext.refreshAllObjects()

        // Reload complications so they show current data
        WidgetCenter.shared.reloadAllTimelines()

        // Schedule the next background refresh
        scheduleNextRefresh()
    }

    private func handleCloudKitSync() async {
        // CloudKit pushed new data — refresh the view context
        persistenceController.container.viewContext.refreshAllObjects()

        // Update complications with fresh data
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func scheduleNextRefresh() {
        // Request a background refresh in ~30 minutes
        let targetDate = Date(timeIntervalSinceNow: 30 * 60)
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: targetDate,
            userInfo: nil
        ) { error in
            if let error {
                print("[Watch] ⚠️ Failed to schedule background refresh: \(error)")
            }
        }
    }
}
