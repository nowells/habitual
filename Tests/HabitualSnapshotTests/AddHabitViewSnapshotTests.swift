import SnapshotTesting
import SwiftUI
import XCTest

@testable import HabitualCore

final class AddHabitViewSnapshotTests: SnapshotTestCase {

    // MARK: - Full Form (Default / Empty State)

    func testAddHabitView_Light() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390, height: 1000) {
            AddHabitView(habitStore: store)
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testAddHabitView_Dark() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390, height: 1000) {
            AddHabitView(habitStore: store)
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testAddHabitView_LargeText() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390, height: 1200) {
            AddHabitView(habitStore: store)
        }
        .environment(\.sizeCategory, .extraExtraLarge)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
