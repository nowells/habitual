import CoreData
import CloudKit

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
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
            if let model = NSManagedObjectModel.mergedModel(from: [bundle]),
               !model.entities.isEmpty {
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

        let hColorBlue    = attr("colorBlue",    .doubleAttributeType,    default: 0.5)
        let hColorGreen   = attr("colorGreen",   .doubleAttributeType,    default: 0.5)
        let hColorRed     = attr("colorRed",     .doubleAttributeType,    default: 0.3)
        let hCreatedAt    = attr("createdAt",    .dateAttributeType,      optional: true)
        let hGoalFreq     = attr("goalFrequency",.integer16AttributeType, default: Int16(1))
        let hGoalPeriod   = attr("goalPeriod",   .stringAttributeType,    default: "daily")
        let hDesc         = attr("habitDescription", .stringAttributeType, optional: true)
        let hIcon         = attr("icon",         .stringAttributeType,    default: "star.fill")
        let hId           = attr("id",           .UUIDAttributeType,      optional: true)
        let hIsArchived   = attr("isArchived",   .booleanAttributeType,   default: false)
        let hName         = attr("name",         .stringAttributeType,    default: "")
        let hReminder     = attr("reminderTime", .dateAttributeType,      optional: true)
        let hSortOrder    = attr("sortOrder",    .integer16AttributeType, default: Int16(0))

        // — CDCompletion —
        let completion = NSEntityDescription()
        completion.name = "CDCompletion"
        completion.managedObjectClassName = "CDCompletion"

        let cDate  = attr("date",  .dateAttributeType,   optional: true)
        let cId    = attr("id",    .UUIDAttributeType,    optional: true)
        let cNote  = attr("note",  .stringAttributeType,  optional: true)
        let cValue = attr("value", .doubleAttributeType,  default: 1.0)

        // — Relationships —
        let completionsRel = NSRelationshipDescription()
        completionsRel.name = "completions"
        completionsRel.destinationEntity = completion
        completionsRel.isOptional = true
        completionsRel.deleteRule = .cascadeDeleteRule
        completionsRel.maxCount = 0 // to-many

        let habitRel = NSRelationshipDescription()
        habitRel.name = "habit"
        habitRel.destinationEntity = habit
        habitRel.isOptional = true
        habitRel.deleteRule = .nullifyDeleteRule
        habitRel.maxCount = 1 // to-one

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
        _ type: NSAttributeDescription.AttributeType,
        optional: Bool = false,
        default defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = optional
        if let v = defaultValue { a.defaultValue = v }
        return a
    }

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample habits for previews
        let sampleHabits: [(String, String, String, Double, Double, Double)] = [
            ("Exercise", "Daily workout routine", "figure.run", 0.35, 0.65, 0.85),
            ("Read", "Read for 30 minutes", "book.fill", 0.95, 0.55, 0.20),
            ("Meditate", "Morning meditation", "brain.head.profile", 0.55, 0.40, 0.80),
            ("Water", "Drink 8 glasses of water", "drop.fill", 0.20, 0.70, 0.90),
        ]

        for (name, desc, icon, r, g, b) in sampleHabits {
            let habit = CDHabit(context: viewContext)
            habit.id = UUID()
            habit.name = name
            habit.habitDescription = desc
            habit.icon = icon
            habit.colorRed = r
            habit.colorGreen = g
            habit.colorBlue = b
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
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // Enable CloudKit sync
        if !inMemory {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.habitual.app"
            )
        }

        // Enable persistent history tracking for CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Enable shared app group for widgets
        if !inMemory {
            let storeURL = Self.appGroupStoreURL
            description.url = storeURL
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    static var appGroupStoreURL: URL {
        let appGroupID = "group.com.habitual.app"
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
