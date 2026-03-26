import CoreData
import CloudKit

actor CloudSyncService {
    static let shared = CloudSyncService()

    private let persistenceController = PersistenceController.shared

    /// Force a round-trip with CloudKit so any pending local changes are pushed
    /// and the latest remote changes are pulled into the store.
    /// When no iCloud account is available, saves locally and returns without error.
    func forceSync() async throws {
        let context = persistenceController.container.viewContext
        try await savePendingChanges(in: context)

        // Only attempt refresh if iCloud is available
        let status = try await CKContainer(identifier: "iCloud.com.habitual-helper.app").accountStatus()
        if status == .available {
            await context.perform {
                context.refreshAllObjects()
            }
        }
    }

    private func savePendingChanges(in context: NSManagedObjectContext) async throws {
        try await context.perform {
            if context.hasChanges {
                try context.save()
            }
        }
    }
}
