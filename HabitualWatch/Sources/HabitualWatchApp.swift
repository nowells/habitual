import SwiftUI

@main
struct HabitualWatchApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
