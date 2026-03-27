import CloudKit
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static let containerName = "Habitual"

    let container: NSPersistentCloudKitContainer

    static let managedObjectModel: NSManagedObjectModel = {
        // Try loading the compiled .momd from the appropriate bundle.
        let bundles: [Bundle] = {
            #if SWIFT_PACKAGE
                return [Bundle.module, Bundle.main]
            #else
                return [Bundle.main]
            #endif
        }()

        for bundle in bundles {
            if let url = bundle.url(forResource: containerName, withExtension: "momd")
                ?? bundle.url(forResource: containerName, withExtension: "mom"),
                let model = NSManagedObjectModel(contentsOf: url)
            {
                return model
            }
            if let model = NSManagedObjectModel.mergedModel(from: [bundle]),
                !model.entities.isEmpty
            {
                return model
            }
        }

        // SPM does not always compile .xcdatamodeld via momc.
        // Build the model programmatically so `swift test` works reliably.
        return buildManagedObjectModel()
    }()

    // MARK: - Programmatic model (SPM fallback)

    private static func buildManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // — CDHabit —
        let habit = NSEntityDescription()
        habit.name = "CDHabit"
        habit.managedObjectClassName = "CDHabit"

        let hColorBlue = attr("colorBlue", .doubleAttributeType, default: 0.5)
        let hColorGreen = attr("colorGreen", .doubleAttributeType, default: 0.5)
        let hColorRed = attr("colorRed", .doubleAttributeType, default: 0.3)
        let hCreatedAt = attr("createdAt", .dateAttributeType, optional: true)
        let hGoalFreq = attr("goalFrequency", .integer16AttributeType, default: Int16(1))
        let hGoalPeriod = attr("goalPeriod", .stringAttributeType, default: "daily")
        let hDesc = attr("habitDescription", .stringAttributeType, optional: true)
        let hIcon = attr("icon", .stringAttributeType, default: "star.fill")
        let hId = attr("id", .UUIDAttributeType, optional: true)
        let hIsArchived = attr("isArchived", .booleanAttributeType, default: false)
        let hName = attr("name", .stringAttributeType, default: "")
        let hReminder = attr("reminderTime", .dateAttributeType, optional: true)
        let hSortOrder = attr("sortOrder", .integer16AttributeType, default: Int16(0))

        // — CDCompletion —
        let completion = NSEntityDescription()
        completion.name = "CDCompletion"
        completion.managedObjectClassName = "CDCompletion"

        let cDate = attr("date", .dateAttributeType, optional: true)
        let cId = attr("id", .UUIDAttributeType, optional: true)
        let cNote = attr("note", .stringAttributeType, optional: true)
        let cValue = attr("value", .doubleAttributeType, default: 1.0)

        // — Relationships —
        let completionsRel = NSRelationshipDescription()
        completionsRel.name = "completions"
        completionsRel.destinationEntity = completion
        completionsRel.isOptional = true
        completionsRel.deleteRule = .cascadeDeleteRule
        completionsRel.maxCount = 0  // to-many

        let habitRel = NSRelationshipDescription()
        habitRel.name = "habit"
        habitRel.destinationEntity = habit
        habitRel.isOptional = true
        habitRel.deleteRule = .nullifyDeleteRule
        habitRel.maxCount = 1  // to-one

        completionsRel.inverseRelationship = habitRel
        habitRel.inverseRelationship = completionsRel

        habit.properties = [
            hColorBlue, hColorGreen, hColorRed, hCreatedAt,
            hGoalFreq, hGoalPeriod, hDesc, hIcon,
            hId, hIsArchived, hName, hReminder, hSortOrder,
            completionsRel,
        ]
        completion.properties = [cDate, cId, cNote, cValue, habitRel]

        model.entities = [habit, completion]
        return model
    }

    private static func attr(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        default defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        if let value = defaultValue { attribute.defaultValue = value }
        return attribute
    }

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample habits for previews
        let names = ["Exercise", "Read", "Meditate", "Water"]
        let descs = ["Daily workout routine", "Read for 30 minutes", "Morning meditation", "Drink 8 glasses of water"]
        let icons = ["figure.run", "book.fill", "brain.head.profile", "drop.fill"]
        let reds = [0.35, 0.95, 0.55, 0.20]
        let greens = [0.65, 0.55, 0.40, 0.70]
        let blues = [0.85, 0.20, 0.80, 0.90]

        for index in names.indices {
            let name = names[index]
            let desc = descs[index]
            let icon = icons[index]
            let red = reds[index]
            let green = greens[index]
            let blue = blues[index]
            let habit = CDHabit(context: viewContext)
            habit.id = UUID()
            habit.name = name
            habit.habitDescription = desc
            habit.icon = HabitIcon.resolve(icon)
            habit.colorRed = red
            habit.colorGreen = green
            habit.colorBlue = blue
            habit.createdAt = Date()
            habit.isArchived = false
            habit.goalFrequency = 1
            habit.goalPeriod = "daily"
            habit.sortOrder = 0

            // Add sample completions for the last 120 days
            let calendar = Calendar.current
            for dayOffset in 0..<120 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
                // Random completion based on a pattern
                if Bool.random() || dayOffset % 3 == 0 {
                    let completion = CDCompletion(context: viewContext)
                    completion.id = UUID()
                    completion.date = calendar.startOfDay(for: date)
                    completion.value = 1.0
                    completion.habit = habit
                }
            }
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return controller
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(
            name: Self.containerName,
            managedObjectModel: Self.managedObjectModel
        )

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // Enable persistent history tracking (needed for CloudKit and useful for local too)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Enable shared app group for widgets
        if !inMemory {
            let storeURL = Self.appGroupStoreURL
            description.url = storeURL
        }

        // Only enable CloudKit sync if an iCloud account is available.
        // Without this guard the container setup crashes on devices/simulators
        // with no iCloud account (CKAccountStatusNoAccount).
        if !inMemory {
            let semaphore = DispatchSemaphore(value: 0)
            var hasICloud = false
            CKContainer(identifier: "iCloud.com.habitual-helper.app").accountStatus { status, _ in
                hasICloud = (status == .available)
                semaphore.signal()
            }
            semaphore.wait()

            if hasICloud {
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: "iCloud.com.habitual-helper.app"
                )
            } else {
                // Local-only mode — disable CloudKit integration
                description.cloudKitContainerOptions = nil
                print("[CloudKit] ⚠️ No iCloud account — running in local-only mode")
            }
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        // Log CloudKit sync events to help diagnose sync issues.
        // Look for these in Xcode console or Console.app when debugging.
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: nil
        ) { notification in
            guard
                let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event
            else { return }
            let type: String
            switch event.type {
            case .setup: type = "setup"
            case .import: type = "import"
            case .export: type = "export"
            @unknown default: type = "unknown"
            }
            if let error = event.error {
                print("[CloudKit] ❌ \(type) failed: \(error)")
            } else if event.endDate != nil {
                print("[CloudKit] ✅ \(type) finished")
            } else {
                print("[CloudKit] ⏳ \(type) started")
            }
        }
    }

    static var appGroupStoreURL: URL {
        let appGroupID = "group.com.habitual-helper.app"
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return url.appendingPathComponent("Habitual.sqlite")
        }
        // Fallback to default location
        return NSPersistentCloudKitContainer.defaultDirectoryURL().appendingPathComponent("Habitual.sqlite")
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
