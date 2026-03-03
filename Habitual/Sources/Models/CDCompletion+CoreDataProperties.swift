import CoreData
import Foundation

extension CDCompletion {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCompletion> {
        return NSFetchRequest<CDCompletion>(entityName: "CDCompletion")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var note: String?
    @NSManaged public var value: Double
    @NSManaged public var habit: CDHabit?
}

extension CDCompletion: Identifiable {}
