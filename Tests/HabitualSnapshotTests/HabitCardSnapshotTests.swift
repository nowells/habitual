import SnapshotTesting
import SwiftUI
import XCTest

@testable import HabitualCore

final class HabitCardSnapshotTests: SnapshotTestCase {

    // MARK: - StatBadge

    func testStatBadge_Streak() {
        let view = StatBadge(label: "Streak", value: "7", icon: "flame.fill", color: .orange)
            .padding()
            .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testStatBadge_Total() {
        let view = StatBadge(label: "Total", value: "42", icon: "checkmark", color: .blue)
            .padding()
            .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testStatBadge_Rate() {
        let view = StatBadge(label: "Rate", value: "85%", icon: "chart.line.uptrend.xyaxis", color: .green)
            .padding()
            .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - HabitCardView

    func testHabitCardView_ActiveWithStreak_Light() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            HabitCardView(habit: TestData.exerciseHabit, habitStore: store)
                .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHabitCardView_ActiveWithStreak_Dark() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            HabitCardView(habit: TestData.exerciseHabit, habitStore: store)
                .padding()
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHabitCardView_WeeklyGoal() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            HabitCardView(habit: TestData.readHabit, habitStore: store)
                .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHabitCardView_NoCompletions() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            HabitCardView(habit: TestData.meditateHabit, habitStore: store)
                .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHabitCardView_FullCompletions() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            HabitCardView(habit: TestData.waterHabit, habitStore: store)
                .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Multiple Cards (Dashboard-like)

    func testHabitCardList() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 16) {
                ForEach(TestData.allHabits) { habit in
                    HabitCardView(habit: habit, habitStore: store)
                }
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
