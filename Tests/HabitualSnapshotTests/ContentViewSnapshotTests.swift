import XCTest
import SwiftUI
import SnapshotTesting
@testable import HabitualCore

final class ContentViewSnapshotTests: SnapshotTestCase {

    // MARK: - Empty State

    func testEmptyStateView_Light() {
        let view = SnapshotContainer(width: 390, height: 500) {
            EmptyStateView(showingAddHabit: .constant(false))
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testEmptyStateView_Dark() {
        let view = SnapshotContainer(width: 390, height: 500) {
            EmptyStateView(showingAddHabit: .constant(false))
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testEmptyStateView_LargeText() {
        let view = SnapshotContainer(width: 390, height: 700) {
            EmptyStateView(showingAddHabit: .constant(false))
        }
        .environment(\.sizeCategory, .extraExtraLarge)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Archive View

    func testArchiveView_Empty() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390, height: 400) {
            NavigationStack {
                ArchiveView(habitStore: store)
            }
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testArchiveView_WithHabits_Light() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        store.addHabit(TestData.exerciseHabit)
        store.addHabit(TestData.readHabit)
        store.addHabit(TestData.meditateHabit)
        for habit in store.habits {
            store.archiveHabit(habit)
        }

        let view = SnapshotContainer(width: 390, height: 500) {
            NavigationStack {
                ArchiveView(habitStore: store)
            }
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testArchiveView_WithHabits_Dark() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        store.addHabit(TestData.exerciseHabit)
        store.addHabit(TestData.readHabit)
        store.addHabit(TestData.meditateHabit)
        for habit in store.habits {
            store.archiveHabit(habit)
        }

        let view = SnapshotContainer(width: 390, height: 500) {
            NavigationStack {
                ArchiveView(habitStore: store)
            }
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Form Components

    func testIconPickerView() {
        let view = SnapshotContainer(width: 390) {
            IconPickerView(selectedIcon: .constant("figure.run"), color: Color(red: 0.35, green: 0.65, blue: 0.85))
                .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testIconPickerView_DifferentSelection() {
        let view = SnapshotContainer(width: 390) {
            IconPickerView(selectedIcon: .constant("book.fill"), color: Color(red: 0.95, green: 0.55, blue: 0.20))
                .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testColorPickerView() {
        let view = SnapshotContainer(width: 390) {
            ColorPickerView(selectedColor: .constant(HabitColor.presets[0]))
                .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testColorPickerView_DifferentSelection() {
        let view = SnapshotContainer(width: 390) {
            ColorPickerView(selectedColor: .constant(HabitColor.presets[4]))
                .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Responsive Design

    func testHabitCardView_iPhoneSE() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 320) {
            HabitCardView(habit: TestData.exerciseHabit, habitStore: store)
                .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHabitCardView_iPadWidth() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 600) {
            HabitCardView(habit: TestData.exerciseHabit, habitStore: store)
                .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Accessibility

    func testHabitCardView_LargeText() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 16) {
                HabitCardView(habit: TestData.exerciseHabit, habitStore: store)
                HabitCardView(habit: TestData.waterHabit, habitStore: store)
            }
            .padding()
        }
        .environment(\.sizeCategory, .extraExtraLarge)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
