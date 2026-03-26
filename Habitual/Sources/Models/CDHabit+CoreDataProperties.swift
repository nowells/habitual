import CoreData
import Foundation

extension CDHabit {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDHabit> {
        NSFetchRequest<CDHabit>(entityName: "CDHabit")
    }

    @NSManaged public var colorBlue: Double
    @NSManaged public var colorGreen: Double
    @NSManaged public var colorRed: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var goalFrequency: Int16
    @NSManaged public var goalPeriod: String?
    @NSManaged public var habitDescription: String?
    @NSManaged public var icon: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isArchived: Bool
    @NSManaged public var name: String?
    @NSManaged public var reminderTime: Date?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var completions: NSSet?
}

// MARK: Generated accessors for completions
extension CDHabit {
    @objc(addCompletionsObject:)
    @NSManaged public func addToCompletions(_ value: CDCompletion)

    @objc(removeCompletionsObject:)
    @NSManaged public func removeFromCompletions(_ value: CDCompletion)

    @objc(addCompletions:)
    @NSManaged public func addToCompletions(_ values: NSSet)

    @objc(removeCompletions:)
    @NSManaged public func removeFromCompletions(_ values: NSSet)
}

extension CDHabit: Identifiable {}
