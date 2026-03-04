import XCTest
import CoreData
@testable import HabitualCore

/// Integration tests that validate complete user workflows end-to-end.
@MainActor
final class HabitWorkflowTests: XCTestCase {

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

    // MARK: - Workflow: Create, Complete, Track Streak

    func testCreateHabitAndBuildStreak() {
        // 1. User creates a new habit
        let habit = Habit(
            name: "Morning Run",
            description: "Run 5km every morning",
            icon: "figure.run",
            colorComponents: (red: 0.35, green: 0.65, blue: 0.85),
            goalFrequency: 1,
            goalPeriod: .daily
        )
        store.addHabit(habit)
        XCTAssertEqual(store.activeHabits.count, 1)

        // 2. User completes it today
        store.toggleTodayCompletion(for: store.activeHabits.first!)
        XCTAssertTrue(store.activeHabits.first!.isCompletedOn(date: Date()))

        // 3. User adds past completions to build a streak
        let calendar = Calendar.current
        for dayOffset in 1...6 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            store.toggleCompletion(for: store.activeHabits.first!, on: date)
        }

        // 4. Verify streak
        let updated = store.activeHabits.first!
        XCTAssertEqual(updated.currentStreak, 7, "Should have 7-day streak")
        XCTAssertEqual(updated.totalCompletions, 7)
    }

    // MARK: - Workflow: Create, Archive, Restore

    func testArchiveAndRestoreWorkflow() {
        // 1. Create habits
        store.addHabit(Habit(name: "Exercise"))
        store.addHabit(Habit(name: "Read"))
        store.addHabit(Habit(name: "Meditate"))

        XCTAssertEqual(store.activeHabits.count, 3)
        XCTAssertEqual(store.archivedHabits.count, 0)

        // 2. Archive one habit
        let readHabit = store.habits.first { $0.name == "Read" }!
        store.archiveHabit(readHabit)

        XCTAssertEqual(store.activeHabits.count, 2)
        XCTAssertEqual(store.archivedHabits.count, 1)
        XCTAssertFalse(store.activeHabits.contains { $0.name == "Read" })

        // 3. Verify search doesn't find archived habits
        store.searchText = "Read"
        XCTAssertTrue(store.filteredHabits.isEmpty)
        store.searchText = ""

        // 4. Restore the habit
        let archived = store.archivedHabits.first!
        store.unarchiveHabit(archived)

        XCTAssertEqual(store.activeHabits.count, 3)
        XCTAssertEqual(store.archivedHabits.count, 0)
    }

    // MARK: - Workflow: Edit Habit Properties

    func testEditHabitWorkflow() {
        // 1. Create habit
        store.addHabit(Habit(
            name: "Exercise",
            icon: "star.fill",
            colorComponents: (red: 0.35, green: 0.65, blue: 0.85),
            goalFrequency: 1,
            goalPeriod: .daily
        ))

        // 2. Add some completions
        store.toggleTodayCompletion(for: store.habits.first!)

        // 3. Edit the habit
        var habit = store.habits.first!
        habit.name = "Morning Exercise"
        habit.description = "30 min cardio + stretching"
        habit.icon = "figure.run"
        habit.colorComponents = (red: 0.20, green: 0.78, blue: 0.35)
        habit.goalFrequency = 5
        habit.goalPeriod = .weekly
        store.updateHabit(habit)

        // 4. Verify changes persisted and completions survived
        let updated = store.habits.first!
        XCTAssertEqual(updated.name, "Morning Exercise")
        XCTAssertEqual(updated.description, "30 min cardio + stretching")
        XCTAssertEqual(updated.icon, "figure.run")
        XCTAssertEqual(updated.goalFrequency, 5)
        XCTAssertEqual(updated.goalPeriod, .weekly)
        XCTAssertTrue(updated.isCompletedOn(date: Date()), "Completions should survive edit")
    }

    // MARK: - Workflow: Toggle Completions On Calendar

    func testCalendarCompletionToggling() {
        store.addHabit(Habit(name: "Meditate"))
        let calendar = Calendar.current

        // Toggle a week of completions
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            store.toggleCompletion(for: store.habits.first!, on: date)
        }

        let habit = store.habits.first!
        XCTAssertEqual(habit.totalCompletions, 7)
        XCTAssertEqual(habit.currentStreak, 7)

        // Toggle off day 3 (break the streak)
        let day3 = calendar.date(byAdding: .day, value: -3, to: Date())!
        store.toggleCompletion(for: store.habits.first!, on: day3)

        let afterToggle = store.habits.first!
        XCTAssertEqual(afterToggle.totalCompletions, 6)
        XCTAssertFalse(afterToggle.isCompletedOn(date: day3))

        // Current streak should only be 3 (today + 2 before the gap)
        XCTAssertEqual(afterToggle.currentStreak, 3)
    }

    // MARK: - Workflow: Search and Filter

    func testSearchWorkflow() {
        store.addHabit(Habit(name: "Morning Exercise", description: "Cardio and weights"))
        store.addHabit(Habit(name: "Evening Walk", description: "30 min walk"))
        store.addHabit(Habit(name: "Read Books", description: "Technical reading"))
        store.addHabit(Habit(name: "Meditate", description: "Morning mindfulness"))

        // Search by name
        store.searchText = "morning"
        XCTAssertEqual(store.filteredHabits.count, 2, "Should find 'Morning Exercise' and 'Meditate' (morning mindfulness)")

        // Search by description
        store.searchText = "cardio"
        XCTAssertEqual(store.filteredHabits.count, 1)
        XCTAssertEqual(store.filteredHabits.first?.name, "Morning Exercise")

        // Clear search shows all
        store.searchText = ""
        XCTAssertEqual(store.filteredHabits.count, 4)

        // No results
        store.searchText = "swimming"
        XCTAssertTrue(store.filteredHabits.isEmpty)
    }

    // MARK: - Workflow: Reorder Habits

    func testReorderWorkflow() {
        store.addHabit(Habit(name: "First"))
        store.addHabit(Habit(name: "Second"))
        store.addHabit(Habit(name: "Third"))

        XCTAssertEqual(store.activeHabits.map { $0.name }, ["First", "Second", "Third"])

        // Move first to last
        store.moveHabits(from: IndexSet(integer: 0), to: 3)
        XCTAssertEqual(store.activeHabits.map { $0.name }, ["Second", "Third", "First"])

        // Move last to first
        store.moveHabits(from: IndexSet(integer: 2), to: 0)
        XCTAssertEqual(store.activeHabits.map { $0.name }, ["First", "Second", "Third"])
    }

    // MARK: - Workflow: Delete With Completions

    func testDeleteHabitWithCompletions() {
        store.addHabit(Habit(name: "To Delete"))
        store.addHabit(Habit(name: "To Keep"))

        // Add completions to both
        store.toggleTodayCompletion(for: store.habits.first { $0.name == "To Delete" }!)
        store.toggleTodayCompletion(for: store.habits.first { $0.name == "To Keep" }!)

        // Delete one
        let toDelete = store.habits.first { $0.name == "To Delete" }!
        store.deleteHabit(toDelete)

        XCTAssertEqual(store.habits.count, 1)
        XCTAssertEqual(store.habits.first?.name, "To Keep")
        XCTAssertTrue(store.habits.first!.isCompletedOn(date: Date()), "Other habit's completions should survive")
    }

    // MARK: - Workflow: Multiple Habits Independent Completions

    func testMultipleHabitsIndependentCompletions() {
        store.addHabit(Habit(name: "Exercise"))
        store.addHabit(Habit(name: "Read"))
        store.addHabit(Habit(name: "Meditate"))

        // Complete only Exercise and Read today
        let exercise = store.habits.first { $0.name == "Exercise" }!
        let read = store.habits.first { $0.name == "Read" }!
        store.toggleTodayCompletion(for: exercise)
        store.toggleTodayCompletion(for: read)

        // Verify independence
        XCTAssertTrue(store.habits.first { $0.name == "Exercise" }!.isCompletedOn(date: Date()))
        XCTAssertTrue(store.habits.first { $0.name == "Read" }!.isCompletedOn(date: Date()))
        XCTAssertFalse(store.habits.first { $0.name == "Meditate" }!.isCompletedOn(date: Date()))

        // Uncomplete Exercise, others unaffected
        store.toggleTodayCompletion(for: store.habits.first { $0.name == "Exercise" }!)
        XCTAssertFalse(store.habits.first { $0.name == "Exercise" }!.isCompletedOn(date: Date()))
        XCTAssertTrue(store.habits.first { $0.name == "Read" }!.isCompletedOn(date: Date()))
    }

    // MARK: - Workflow: Heatmap Data Consistency

    func testHeatmapDataConsistency() {
        store.addHabit(Habit(name: "Test"))

        let calendar = Calendar.current
        // Add scattered completions
        let completionDays = [0, 1, 2, 5, 10, 15, 20, 30, 45, 60, 90]
        for dayOffset in completionDays {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            store.toggleCompletion(for: store.habits.first!, on: date)
        }

        let habit = store.habits.first!

        // Verify heatmap data contains all completions within range
        let data3m = habit.heatmapData(months: 3)
        let allDays3m = data3m.flatMap { $0 }
        let completedDays3m = allDays3m.filter { $0.isCompleted }

        // Within 3 months, we should have completions at days 0,1,2,5,10,15,20,30,45,60,90
        // Some of these may fall outside 3 months
        XCTAssertGreaterThan(completedDays3m.count, 0, "Should have some completed days in 3-month heatmap")

        // Verify no future days are marked as completed
        let today = calendar.startOfDay(for: Date())
        let futureDays = allDays3m.filter { $0.date > today }
        for day in futureDays {
            XCTAssertFalse(day.isCompleted, "Future days should not be completed")
        }

        // Verify all weeks have 7 days
        for week in data3m {
            XCTAssertEqual(week.count, 7)
        }
    }

    // MARK: - Edge Cases

    func testEmptyStoreOperations() {
        // Operations on empty store should not crash
        XCTAssertTrue(store.activeHabits.isEmpty)
        XCTAssertTrue(store.archivedHabits.isEmpty)
        XCTAssertTrue(store.filteredHabits.isEmpty)

        store.searchText = "anything"
        XCTAssertTrue(store.filteredHabits.isEmpty)
    }

    func testRapidToggle() {
        store.addHabit(Habit(name: "Test"))

        // Rapidly toggle completions
        for _ in 0..<10 {
            store.toggleTodayCompletion(for: store.habits.first!)
        }

        // After even number of toggles, should be uncompleted
        XCTAssertFalse(store.habits.first!.isCompletedOn(date: Date()))

        // One more toggle to complete
        store.toggleTodayCompletion(for: store.habits.first!)
        XCTAssertTrue(store.habits.first!.isCompletedOn(date: Date()))
    }
}
