@preconcurrency import Dispatch
import CloudKit
import CoreData

actor CloudSyncService {
    static let shared = CloudSyncService()

    private let persistenceController = PersistenceController.shared
    private static let ckContainerID = "iCloud.com.habitual-helper.app"
    private static let ckZoneID = CKRecordZone.ID(
        zoneName: "com.apple.coredata.cloudkit.zone",
        ownerName: CKCurrentUserDefaultName
    )

    /// Force a round-trip with CloudKit: save pending local changes (triggers
    /// export), wait for the import cycle, then fall back to a direct CloudKit
    /// fetch if the container's push-driven import didn't fire.
    ///
    /// When no iCloud account is available, saves locally and returns without
    /// error.
    func forceSync() async throws {
        let context = persistenceController.container.viewContext

        // 1. Persist any unsaved viewContext changes → triggers CloudKit export.
        try await savePendingChanges(in: context)

        // 2. Wait for the CloudKit round-trip to complete.
        //    Falls back gracefully when iCloud is unavailable.
        let status = try await CKContainer(identifier: Self.ckContainerID).accountStatus()
        if status == .available {
            let importReceived = await waitForSyncCycle()

            // 3. If no import arrived (push notifications likely not working),
            //    fall back to directly fetching from CloudKit.
            if !importReceived {
                print("[CloudKit] No import event received — falling back to direct fetch")
                do {
                    try await fallbackCloudKitFetch(into: context)
                } catch {
                    print("[CloudKit] Fallback fetch failed: \(error)")
                }
            }
        }

        // 4. Re-fault all objects so the next fetch reads post-import data.
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

    /// Wait for a completed import event, or time out after 10 seconds.
    ///
    /// Returns `true` if an import event was received, `false` if the
    /// function timed out (indicating push notifications may not be working).
    private func waitForSyncCycle() async -> Bool {
        let container = persistenceController.container

        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            nonisolated(unsafe) var observer: NSObjectProtocol?
            nonisolated(unsafe) var resumed = false

            let finish = { @Sendable (didImport: Bool) in
                DispatchQueue.main.async {
                    guard !resumed else { return }
                    resumed = true
                    if let obs = observer {
                        NotificationCenter.default.removeObserver(obs)
                    }
                    continuation.resume(returning: didImport)
                }
            }

            // Timeout — don't block the UI forever if CloudKit is slow.
            let timeout = DispatchWorkItem { finish(false) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeout)

            observer = NotificationCenter.default.addObserver(
                forName: NSPersistentCloudKitContainer.eventChangedNotification,
                object: container,
                queue: .main
            ) { notification in
                guard
                    let event = notification.userInfo?[
                        NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                    ] as? NSPersistentCloudKitContainer.Event,
                    event.endDate != nil
                else { return }

                if event.type == .import {
                    timeout.cancel()
                    finish(true)
                }
            }
        }
    }

    // MARK: - CloudKit Direct Fetch Fallback

    /// Directly query CloudKit for records and upsert any missing data into
    /// CoreData. This bypasses `NSPersistentCloudKitContainer`'s push-driven
    /// import, which can fail when notifications aren't delivered (common on
    /// macOS).
    ///
    /// Only *inserts* records that don't exist locally (matched by UUID).
    /// Existing records are not overwritten to avoid conflicts with the
    /// container's own sync state.
    private func fallbackCloudKitFetch(into context: NSManagedObjectContext) async throws {
        let database = CKContainer(identifier: Self.ckContainerID).privateCloudDatabase

        // 1. Fetch all habit records from CloudKit.
        let habitRecords = try await fetchAllRecords(ofType: "CD_CDHabit", from: database)

        // Build CKRecord.ID → UUID map so we can resolve completion→habit refs.
        var ckRecordIDToHabitUUID: [String: UUID] = [:]
        var remoteHabits: [RemoteHabitData] = []

        for record in habitRecords {
            guard let idStr = record["CD_id"] as? String,
                let uuid = UUID(uuidString: idStr)
            else { continue }

            ckRecordIDToHabitUUID[record.recordID.recordName] = uuid
            remoteHabits.append(RemoteHabitData(
                id: uuid,
                name: record["CD_name"] as? String ?? "",
                habitDescription: record["CD_habitDescription"] as? String,
                icon: record["CD_icon"] as? String,
                colorRed: record["CD_colorRed"] as? Double ?? 0.35,
                colorGreen: record["CD_colorGreen"] as? Double ?? 0.65,
                colorBlue: record["CD_colorBlue"] as? Double ?? 0.85,
                createdAt: record["CD_createdAt"] as? Date,
                updatedAt: record["CD_updatedAt"] as? Date,
                isArchived: (record["CD_isArchived"] as? Int64 ?? 0) != 0,
                goalFrequency: Int16(record["CD_goalFrequency"] as? Int64 ?? 1),
                goalPeriod: record["CD_goalPeriod"] as? String ?? "daily",
                reminderTime: record["CD_reminderTime"] as? Date,
                sortOrder: Int16(record["CD_sortOrder"] as? Int64 ?? 0)
            ))
        }

        // 2. Fetch all completion records from CloudKit.
        let completionRecords = try await fetchAllRecords(ofType: "CD_CDCompletion", from: database)

        var remoteCompletions: [RemoteCompletionData] = []
        for record in completionRecords {
            guard let idStr = record["CD_id"] as? String,
                let uuid = UUID(uuidString: idStr)
            else { continue }

            let habitRef = record["CD_habit"] as? CKRecord.Reference
            let habitUUID = habitRef.flatMap { ckRecordIDToHabitUUID[$0.recordID.recordName] }

            remoteCompletions.append(RemoteCompletionData(
                id: uuid,
                habitID: habitUUID,
                date: record["CD_date"] as? Date,
                value: record["CD_value"] as? Double ?? 1.0,
                note: record["CD_note"] as? String,
                deviceID: record["CD_deviceID"] as? String,
                createdAt: record["CD_createdAt"] as? Date
            ))
        }

        // 3. Merge into CoreData — insert only missing records.
        let habits = remoteHabits
        let completions = remoteCompletions
        await context.perform {
            Self.mergeRemoteData(habits: habits, completions: completions, into: context)
        }
    }

    /// Fetch all CKRecords of the given type from the CoreData CloudKit zone,
    /// handling pagination automatically.
    private func fetchAllRecords(
        ofType recordType: String,
        from database: CKDatabase
    ) async throws -> [CKRecord] {
        var all: [CKRecord] = []
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))

        var (results, cursor) = try await database.records(
            matching: query,
            inZoneWith: Self.ckZoneID
        )
        all.append(contentsOf: results.compactMap { try? $0.1.get() })

        while let nextCursor = cursor {
            let (more, next) = try await database.records(continuingMatchFrom: nextCursor)
            all.append(contentsOf: more.compactMap { try? $0.1.get() })
            cursor = next
        }

        print("[CloudKit] Fetched \(all.count) \(recordType) records from CloudKit")
        return all
    }

    /// Insert any remote habits/completions that don't already exist locally.
    private static func mergeRemoteData(
        habits: [RemoteHabitData],
        completions: [RemoteCompletionData],
        into context: NSManagedObjectContext
    ) {
        // Load existing local IDs.
        let habitRequest: NSFetchRequest<CDHabit> = CDHabit.fetchRequest()
        let localHabits = (try? context.fetch(habitRequest)) ?? []
        let localHabitIDs = Set(localHabits.compactMap { $0.id })
        var habitByID: [UUID: CDHabit] = [:]
        for h in localHabits {
            if let id = h.id { habitByID[id] = h }
        }

        let completionRequest: NSFetchRequest<CDCompletion> = CDCompletion.fetchRequest()
        let localCompletions = (try? context.fetch(completionRequest)) ?? []
        let localCompletionIDs = Set(localCompletions.compactMap { $0.id })

        var inserted = 0

        // Insert missing habits.
        for remote in habits where !localHabitIDs.contains(remote.id) {
            let cd = CDHabit(context: context)
            cd.id = remote.id
            cd.name = remote.name
            cd.habitDescription = remote.habitDescription
            cd.icon = remote.icon ?? "star.fill"
            cd.colorRed = remote.colorRed
            cd.colorGreen = remote.colorGreen
            cd.colorBlue = remote.colorBlue
            cd.createdAt = remote.createdAt
            cd.updatedAt = remote.updatedAt
            cd.isArchived = remote.isArchived
            cd.goalFrequency = remote.goalFrequency
            cd.goalPeriod = remote.goalPeriod
            cd.reminderTime = remote.reminderTime
            cd.sortOrder = remote.sortOrder
            habitByID[remote.id] = cd
            inserted += 1
        }

        // Insert missing completions.
        for remote in completions where !localCompletionIDs.contains(remote.id) {
            let cd = CDCompletion(context: context)
            cd.id = remote.id
            cd.date = remote.date
            cd.value = remote.value
            cd.note = remote.note
            cd.deviceID = remote.deviceID
            cd.createdAt = remote.createdAt
            if let hid = remote.habitID {
                cd.habit = habitByID[hid]
            }
            inserted += 1
        }

        if context.hasChanges {
            do {
                try context.save()
                print("[CloudKit] Fallback merge inserted \(inserted) records")
            } catch {
                print("[CloudKit] Fallback merge save failed: \(error)")
            }
        } else {
            print("[CloudKit] Fallback merge: local store already up to date")
        }
    }
}

// MARK: - Value Types for CloudKit → CoreData Bridge

/// Parsed habit data from a CKRecord, safe to pass across actor boundaries.
private struct RemoteHabitData: Sendable {
    let id: UUID
    let name: String
    let habitDescription: String?
    let icon: String?
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double
    let createdAt: Date?
    let updatedAt: Date?
    let isArchived: Bool
    let goalFrequency: Int16
    let goalPeriod: String
    let reminderTime: Date?
    let sortOrder: Int16
}

/// Parsed completion data from a CKRecord, safe to pass across actor boundaries.
private struct RemoteCompletionData: Sendable {
    let id: UUID
    let habitID: UUID?
    let date: Date?
    let value: Double
    let note: String?
    let deviceID: String?
    let createdAt: Date?
}
