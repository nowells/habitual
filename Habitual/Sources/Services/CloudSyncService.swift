import CloudKit
import CoreData

actor CloudSyncService {
    static let shared = CloudSyncService()

    private let persistenceController = PersistenceController.shared

    /// Force a round-trip with CloudKit: save pending local changes (triggers
    /// export), wait for the export+import cycle to finish, then refresh the
    /// viewContext so subsequent reads return the converged data.
    ///
    /// When no iCloud account is available, saves locally and returns without
    /// error.
    func forceSync() async throws {
        let context = persistenceController.container.viewContext

        // 1. Persist any unsaved viewContext changes → triggers CloudKit export.
        try await savePendingChanges(in: context)

        // 2. Wait for the CloudKit round-trip (export + import) to complete.
        //    Falls back gracefully when iCloud is unavailable.
        let status = try await CKContainer(identifier: "iCloud.com.habitual-helper.app").accountStatus()
        if status == .available {
            await waitForSyncCycle()
        }

        // 3. Re-fault all objects so the next fetch reads post-import data.
        await context.perform {
            context.refreshAllObjects()
        }
    }

    // MARK: - Private

    private func savePendingChanges(in context: NSManagedObjectContext) async throws {
        try await context.perform {
            if context.hasChanges {
                try context.save()
            }
        }
    }

    /// Wait for an export **and** import event to finish, or time out after
    /// 15 seconds.  This observes `NSPersistentCloudKitContainer`'s event
    /// notification so we know when CloudKit has actually delivered remote
    /// changes into the local store.
    private func waitForSyncCycle() async {
        let container = persistenceController.container

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var observer: NSObjectProtocol?
            var hasExported = false
            var hasImported = false
            var resumed = false

            let finish = {
                guard !resumed else { return }
                resumed = true
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                continuation.resume()
            }

            // Timeout — don't block the UI forever if CloudKit is slow.
            let timeout = DispatchWorkItem { finish() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeout)

            observer = NotificationCenter.default.addObserver(
                forName: NSPersistentCloudKitContainer.eventChangedNotification,
                object: container,
                queue: .main
            ) { notification in
                guard
                    let event = notification.userInfo?[
                        NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                    ] as? NSPersistentCloudKitContainer.Event,
                    event.endDate != nil  // only care about completed events
                else { return }

                switch event.type {
                case .export: hasExported = true
                case .import: hasImported = true
                default: break
                }

                if hasExported && hasImported {
                    timeout.cancel()
                    finish()
                }
            }
        }
    }
}
