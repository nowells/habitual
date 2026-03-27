import CoreData
import XCTest

@testable import HabitualCore

final class PersistenceTests: XCTestCase {

    // MARK: - Controller Initialization

    func testInMemoryStoreCreation() {
        let controller = PersistenceController(inMemory: true)
        XCTAssertNotNil(controller.container)
        XCTAssertNotNil(controller.container.viewContext)
    }

    func testInMemoryStoreIsEmpty() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest() as! NSFetchRequest<CDHabit>
        let habits = try? context.fetch(request)

        XCTAssertNotNil(habits)
        XCTAssertEqual(habits?.count, 0)
    }

    func testAutoMergeEnabled() {
        let controller = PersistenceController(inMemory: true)
        XCTAssertTrue(controller.container.viewContext.automaticallyMergesChangesFromParent)
    }

    // MARK: - Core Data CRUD

    func testCreateAndFetchHabit() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let habit = CDHabit(context: context)
        habit.id = UUID()
        habit.name = "Test Habit"
        habit.habitDescription = "Description"
        habit.icon = "star.fill"
        habit.colorRed = 0.5
        habit.colorGreen = 0.5
        habit.colorBlue = 0.5
        habit.createdAt = Date()
        habit.isArchived = false
        habit.goalFrequency = 1
        habit.goalPeriod = "daily"
        habit.sortOrder = 0

        try! context.save()

        let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest() as! NSFetchRequest<CDHabit>
        let results = try! context.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Test Habit")
    }

    func testCreateCompletionRelationship() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let habit = CDHabit(context: context)
        habit.id = UUID()
        habit.name = "Test"
        habit.icon = "star.fill"
        habit.colorRed = 0.5
        habit.colorGreen = 0.5
        habit.colorBlue = 0.5
        habit.createdAt = Date()
        habit.goalFrequency = 1
        habit.goalPeriod = "daily"

        let completion = CDCompletion(context: context)
        completion.id = UUID()
        completion.date = Date()
        completion.value = 1.0
        completion.habit = habit

        try! context.save()

        let completionSet = habit.completions as? Set<CDCompletion>
        XCTAssertEqual(completionSet?.count, 1)
    }

    func testCascadeDeleteRemovesCompletions() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let habit = CDHabit(context: context)
        habit.id = UUID()
        habit.name = "Test"
        habit.icon = "star.fill"
        habit.colorRed = 0.5
        habit.colorGreen = 0.5
        habit.colorBlue = 0.5
        habit.createdAt = Date()
        habit.goalFrequency = 1
        habit.goalPeriod = "daily"

        for _ in 0..<5 {
            let completion = CDCompletion(context: context)
            completion.id = UUID()
            completion.date = Date()
            completion.value = 1.0
            completion.habit = habit
        }

        try! context.save()

        // Delete habit
        context.delete(habit)
        try! context.save()

        // Completions should also be deleted (cascade)
        let completionRequest: NSFetchRequest<CDCompletion> =
            CDCompletion.fetchRequest() as! NSFetchRequest<CDCompletion>
        let completions = try! context.fetch(completionRequest)
        XCTAssertEqual(completions.count, 0, "Completions should be cascade-deleted with habit")
    }

    // MARK: - Core Data Conversions

    func testCDHabitToHabitConversion() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let id = UUID()
        let cdHabit = CDHabit(context: context)
        cdHabit.id = id
        cdHabit.name = "Exercise"
        cdHabit.habitDescription = "Daily workout"
        cdHabit.icon = "figure.run"
        cdHabit.colorRed = 0.35
        cdHabit.colorGreen = 0.65
        cdHabit.colorBlue = 0.85
        cdHabit.createdAt = Date()
        cdHabit.isArchived = false
        cdHabit.goalFrequency = 3
        cdHabit.goalPeriod = "weekly"
        cdHabit.sortOrder = 2

        let habit = cdHabit.toHabit()

        XCTAssertEqual(habit.id, id)
        XCTAssertEqual(habit.name, "Exercise")
        XCTAssertEqual(habit.description, "Daily workout")
        XCTAssertEqual(habit.icon, "figure.run")
        XCTAssertEqual(habit.colorComponents.red, 0.35, accuracy: 0.01)
        XCTAssertEqual(habit.colorComponents.green, 0.65, accuracy: 0.01)
        XCTAssertEqual(habit.colorComponents.blue, 0.85, accuracy: 0.01)
        XCTAssertFalse(habit.isArchived)
        XCTAssertEqual(habit.goalFrequency, 3)
        XCTAssertEqual(habit.goalPeriod, .weekly)
        XCTAssertEqual(habit.sortOrder, 2)
    }

    func testCDHabitUpdateFromHabit() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let cdHabit = CDHabit(context: context)
        cdHabit.id = UUID()
        cdHabit.name = "Original"
        cdHabit.icon = "star.fill"
        cdHabit.colorRed = 0.5
        cdHabit.colorGreen = 0.5
        cdHabit.colorBlue = 0.5
        cdHabit.createdAt = Date()
        cdHabit.goalFrequency = 1
        cdHabit.goalPeriod = "daily"

        var updatedHabit = cdHabit.toHabit()
        updatedHabit.name = "Updated"
        updatedHabit.description = "New description"
        updatedHabit.icon = "figure.run"
        updatedHabit.goalFrequency = 5
        updatedHabit.goalPeriod = .monthly

        cdHabit.update(from: updatedHabit)

        XCTAssertEqual(cdHabit.name, "Updated")
        XCTAssertEqual(cdHabit.habitDescription, "New description")
        XCTAssertEqual(cdHabit.icon, "figure.run")
        XCTAssertEqual(cdHabit.goalFrequency, 5)
        XCTAssertEqual(cdHabit.goalPeriod, "monthly")
    }

    func testCDCompletionToCompletionConversion() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let id = UUID()
        let date = Date()
        let cdCompletion = CDCompletion(context: context)
        cdCompletion.id = id
        cdCompletion.date = date
        cdCompletion.value = 0.75
        cdCompletion.note = "Good session"

        let completion = cdCompletion.toCompletion()

        XCTAssertEqual(completion.id, id)
        XCTAssertEqual(completion.date, date)
        XCTAssertEqual(completion.value, 0.75, accuracy: 0.001)
        XCTAssertEqual(completion.note, "Good session")
    }

    func testCDHabitWithNilFieldsDefaults() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // CDHabit with nil fields should get defaults
        let cdHabit = CDHabit(context: context)
        // Don't set optional fields

        let habit = cdHabit.toHabit()

        XCTAssertEqual(habit.name, "")
        XCTAssertEqual(habit.description, "")
        XCTAssertEqual(habit.icon, "star.fill")
        XCTAssertEqual(habit.goalPeriod, .daily)
        XCTAssertTrue(habit.completions.isEmpty)
    }

    // MARK: - Save

    func testSaveWithNoChanges() {
        let controller = PersistenceController(inMemory: true)
        // Should not throw or crash
        controller.save()
    }

    func testSaveWithChanges() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let habit = CDHabit(context: context)
        habit.id = UUID()
        habit.name = "Test"
        habit.icon = "star.fill"
        habit.colorRed = 0.5
        habit.colorGreen = 0.5
        habit.colorBlue = 0.5
        habit.createdAt = Date()
        habit.goalFrequency = 1
        habit.goalPeriod = "daily"

        controller.save()

        // Verify it was saved
        let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest() as! NSFetchRequest<CDHabit>
        let results = try! context.fetch(request)
        XCTAssertEqual(results.count, 1)
    }

    // MARK: - Preview Controller

    func testPreviewControllerHasSampleData() {
        let controller = PersistenceController.preview
        let context = controller.container.viewContext

        let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest() as! NSFetchRequest<CDHabit>
        let habits = try! context.fetch(request)

        XCTAssertEqual(habits.count, 4, "Preview should have 4 sample habits")

        // Verify sample habits have completions
        for habit in habits {
            let completionSet = (habit.completions as? Set<CDCompletion>) ?? []
            XCTAssertGreaterThan(completionSet.count, 0, "\(habit.name ?? "Unknown") should have completions")
        }
    }
}
