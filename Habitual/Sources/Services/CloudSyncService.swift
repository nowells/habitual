import CoreData

actor CloudSyncService {
    static let shared = CloudSyncService()

    private let persistenceController = PersistenceController.shared

    /// Force a round-trip with CloudKit so any pending local changes are pushed
    /// and the latest remote changes are pulled into the store.
    func forceSync() async throws {
        let context = persistenceController.container.viewContext
        try await savePendingChanges(in: context)
        await context.perform {
            context.refreshAllObjects()
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
