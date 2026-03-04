import XCTest
import SwiftUI
import SnapshotTesting
@testable import HabitualCore

final class EditHabitViewSnapshotTests: SnapshotTestCase {

    // MARK: - Full Form

    func testEditHabitView_Light() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            EditHabitView(habit: TestData.exerciseHabit, habitStore: store)
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testEditHabitView_Dark() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            EditHabitView(habit: TestData.exerciseHabit, habitStore: store)
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testEditHabitView_WeeklyGoalHabit() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            EditHabitView(habit: TestData.readHabit, habitStore: store)
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
