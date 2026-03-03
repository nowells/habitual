import XCTest
import CoreData
@testable import HabitualCore

@MainActor
final class HabitStoreTests: XCTestCase {

    var persistenceController: PersistenceController!
    var store: HabitStore!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        store = HabitStore(context: persistenceController.container.viewContext)
    }

    override func tearDown() {
        store = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeHabit(
        name: String = "Test Habit",
        description: String = "",
        icon: String = "star.fill",
        goalFrequency: Int = 1,
        goalPeriod: Habit.GoalPeriod = .daily
    ) -> Habit {
        Habit(
            name: name,
            description: description,
            icon: icon,
            goalFrequency: goalFrequency,
            goalPeriod: goalPeriod
        )
    }

    // MARK: - Initial State Tests

    func testStoreStartsEmpty() {
        XCTAssertTrue(store.habits.isEmpty)
        XCTAssertTrue(store.activeHabits.isEmpty)
        XCTAssertTrue(store.archivedHabits.isEmpty)
    }

    func testSearchTextStartsEmpty() {
        XCTAssertEqual(store.searchText, "")
    }

    // MARK: - Add Habit Tests

    func testAddHabit() {
        let habit = makeHabit(name: "Exercise")
        store.addHabit(habit)

        XCTAssertEqual(store.habits.count, 1)
        XCTAssertEqual(store.habits.first?.name, "Exercise")
    }

    func testAddMultipleHabits() {
        store.addHabit(makeHabit(name: "Exercise"))
        store.addHabit(makeHabit(name: "Read"))
        store.addHabit(makeHabit(name: "Meditate"))

        XCTAssertEqual(store.habits.count, 3)
    }

    func testAddHabitPreservesProperties() {
        let habit = Habit(
            name: "Exercise",
            description: "Daily workout",
            icon: "figure.run",
            colorComponents: (red: 0.35, green: 0.65, blue: 0.85),
            goalFrequency: 3,
            goalPeriod: .weekly
        )
        store.addHabit(habit)

        let stored = store.habits.first!
        XCTAssertEqual(stored.name, "Exercise")
        XCTAssertEqual(stored.description, "Daily workout")
        XCTAssertEqual(stored.icon, "figure.run")
        XCTAssertEqual(stored.goalFrequency, 3)
        XCTAssertEqual(stored.goalPeriod, .weekly)
        XCTAssertEqual(stored.colorComponents.red, 0.35, accuracy: 0.01)
        XCTAssertEqual(stored.colorComponents.green, 0.65, accuracy: 0.01)
        XCTAssertEqual(stored.colorComponents.blue, 0.85, accuracy: 0.01)
    }

    // MARK: - Update Habit Tests

    func testUpdateHabit() {
        let habit = makeHabit(name: "Exercise")
        store.addHabit(habit)

        var updated = store.habits.first!
        updated.name = "Morning Exercise"
        updated.description = "30 min cardio"
        store.updateHabit(updated)

        XCTAssertEqual(store.habits.count, 1)
        XCTAssertEqual(store.habits.first?.name, "Morning Exercise")
        XCTAssertEqual(store.habits.first?.description, "30 min cardio")
    }

    func testUpdateHabitGoal() {
        store.addHabit(makeHabit())

        var updated = store.habits.first!
        updated.goalFrequency = 5
        updated.goalPeriod = .weekly
        store.updateHabit(updated)

        XCTAssertEqual(store.habits.first?.goalFrequency, 5)
        XCTAssertEqual(store.habits.first?.goalPeriod, .weekly)
    }

    // MARK: - Delete Habit Tests

    func testDeleteHabit() {
        store.addHabit(makeHabit(name: "Exercise"))
        store.addHabit(makeHabit(name: "Read"))

        XCTAssertEqual(store.habits.count, 2)

        store.deleteHabit(store.habits.first!)
        XCTAssertEqual(store.habits.count, 1)
    }

    func testDeleteLastHabit() {
        store.addHabit(makeHabit())
        store.deleteHabit(store.habits.first!)

        XCTAssertTrue(store.habits.isEmpty)
    }

    // MARK: - Archive Tests

    func testArchiveHabit() {
        store.addHabit(makeHabit(name: "Exercise"))

        store.archiveHabit(store.habits.first!)

        XCTAssertEqual(store.activeHabits.count, 0)
        XCTAssertEqual(store.archivedHabits.count, 1)
        XCTAssertEqual(store.archivedHabits.first?.name, "Exercise")
    }

    func testUnarchiveHabit() {
        store.addHabit(makeHabit(name: "Exercise"))
        store.archiveHabit(store.habits.first!)

        XCTAssertEqual(store.activeHabits.count, 0)

        let archived = store.archivedHabits.first!
        store.unarchiveHabit(archived)

        XCTAssertEqual(store.activeHabits.count, 1)
        XCTAssertEqual(store.archivedHabits.count, 0)
    }

    func testActiveHabitsExcludesArchived() {
        store.addHabit(makeHabit(name: "Active"))
        store.addHabit(makeHabit(name: "To Archive"))

        let toArchive = store.habits.first { $0.name == "To Archive" }!
        store.archiveHabit(toArchive)

        XCTAssertEqual(store.activeHabits.count, 1)
        XCTAssertEqual(store.activeHabits.first?.name, "Active")
    }

    // MARK: - Toggle Completion Tests

    func testToggleTodayCompletionAdds() {
        store.addHabit(makeHabit())

        let habit = store.habits.first!
        XCTAssertFalse(habit.isCompletedOn(date: Date()))

        store.toggleTodayCompletion(for: habit)

        let updated = store.habits.first!
        XCTAssertTrue(updated.isCompletedOn(date: Date()))
    }

    func testToggleTodayCompletionRemoves() {
        store.addHabit(makeHabit())

        // Add completion
        store.toggleTodayCompletion(for: store.habits.first!)
        XCTAssertTrue(store.habits.first!.isCompletedOn(date: Date()))

        // Remove completion
        store.toggleTodayCompletion(for: store.habits.first!)
        XCTAssertFalse(store.habits.first!.isCompletedOn(date: Date()))
    }

    func testToggleCompletionForSpecificDate() {
        store.addHabit(makeHabit())
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!

        store.toggleCompletion(for: store.habits.first!, on: threeDaysAgo)
        XCTAssertTrue(store.habits.first!.isCompletedOn(date: threeDaysAgo))

        store.toggleCompletion(for: store.habits.first!, on: threeDaysAgo)
        XCTAssertFalse(store.habits.first!.isCompletedOn(date: threeDaysAgo))
    }

    func testToggleCompletionPreservesOtherDays() {
        store.addHabit(makeHabit())
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        store.toggleTodayCompletion(for: store.habits.first!)
        store.toggleCompletion(for: store.habits.first!, on: yesterday)

        // Both should be completed
        XCTAssertTrue(store.habits.first!.isCompletedOn(date: Date()))
        XCTAssertTrue(store.habits.first!.isCompletedOn(date: yesterday))

        // Remove yesterday's — today should remain
        store.toggleCompletion(for: store.habits.first!, on: yesterday)
        XCTAssertTrue(store.habits.first!.isCompletedOn(date: Date()))
        XCTAssertFalse(store.habits.first!.isCompletedOn(date: yesterday))
    }

    // MARK: - Search/Filter Tests

    func testFilteredHabitsNoSearch() {
        store.addHabit(makeHabit(name: "Exercise"))
        store.addHabit(makeHabit(name: "Read"))

        XCTAssertEqual(store.filteredHabits.count, 2)
    }

    func testFilteredHabitsByName() {
        store.addHabit(makeHabit(name: "Morning Exercise"))
        store.addHabit(makeHabit(name: "Evening Read"))
        store.addHabit(makeHabit(name: "Morning Meditation"))

        store.searchText = "morning"
        XCTAssertEqual(store.filteredHabits.count, 2)
    }

    func testFilteredHabitsByDescription() {
        store.addHabit(Habit(name: "Exercise", description: "Daily cardio workout"))
        store.addHabit(Habit(name: "Read", description: "Read tech books"))

        store.searchText = "cardio"
        XCTAssertEqual(store.filteredHabits.count, 1)
        XCTAssertEqual(store.filteredHabits.first?.name, "Exercise")
    }

    func testFilteredHabitsCaseInsensitive() {
        store.addHabit(makeHabit(name: "Exercise"))

        store.searchText = "EXERCISE"
        XCTAssertEqual(store.filteredHabits.count, 1)

        store.searchText = "exercise"
        XCTAssertEqual(store.filteredHabits.count, 1)

        store.searchText = "ExErCiSe"
        XCTAssertEqual(store.filteredHabits.count, 1)
    }

    func testFilteredHabitsNoMatch() {
        store.addHabit(makeHabit(name: "Exercise"))

        store.searchText = "nonexistent"
        XCTAssertTrue(store.filteredHabits.isEmpty)
    }

    func testFilteredHabitsExcludesArchived() {
        store.addHabit(makeHabit(name: "Active Exercise"))
        store.addHabit(makeHabit(name: "Archived Exercise"))

        let toArchive = store.habits.first { $0.name == "Archived Exercise" }!
        store.archiveHabit(toArchive)

        store.searchText = "exercise"
        XCTAssertEqual(store.filteredHabits.count, 1)
        XCTAssertEqual(store.filteredHabits.first?.name, "Active Exercise")
    }

    // MARK: - Reorder Tests

    func testMoveHabits() {
        store.addHabit(makeHabit(name: "First"))
        store.addHabit(makeHabit(name: "Second"))
        store.addHabit(makeHabit(name: "Third"))

        // Move "First" to the end
        store.moveHabits(from: IndexSet(integer: 0), to: 3)

        let names = store.activeHabits.map { $0.name }
        XCTAssertEqual(names, ["Second", "Third", "First"])
    }

    // MARK: - Persistence Tests

    func testHabitsPersistAcrossStoreInstances() {
        store.addHabit(makeHabit(name: "Persistent Habit"))

        // Create new store instance with same context
        let newStore = HabitStore(context: persistenceController.container.viewContext)
        XCTAssertEqual(newStore.habits.count, 1)
        XCTAssertEqual(newStore.habits.first?.name, "Persistent Habit")
    }

    func testCompletionsPersistAcrossStoreInstances() {
        store.addHabit(makeHabit())
        store.toggleTodayCompletion(for: store.habits.first!)

        let newStore = HabitStore(context: persistenceController.container.viewContext)
        XCTAssertTrue(newStore.habits.first!.isCompletedOn(date: Date()))
    }
}
