import XCTest
import SwiftUI
import SnapshotTesting
@testable import HabitualCore

final class HeatmapSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // On first run, set `isRecording = true` to generate reference images.
        // After reference images are generated, set back to false.
        // isRecording = true
    }

    // MARK: - HeatmapGridView

    func testHeatmapGridView_Light() {
        let view = SnapshotContainer(width: 390, height: 200) {
            HeatmapGridView(
                habit: TestData.exerciseHabit,
                months: 3,
                cellSize: 12,
                cellSpacing: 3,
                showMonthLabels: true
            )
            .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHeatmapGridView_Dark() {
        let view = SnapshotContainer(width: 390, height: 200) {
            HeatmapGridView(
                habit: TestData.exerciseHabit,
                months: 3,
                cellSize: 12,
                cellSpacing: 3,
                showMonthLabels: true
            )
            .padding()
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHeatmapGridView_NoCompletions() {
        let view = SnapshotContainer(width: 390, height: 200) {
            HeatmapGridView(
                habit: TestData.meditateHabit,
                months: 3,
                cellSize: 12,
                cellSpacing: 3,
                showMonthLabels: true
            )
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHeatmapGridView_FullCompletions() {
        let view = SnapshotContainer(width: 390, height: 200) {
            HeatmapGridView(
                habit: TestData.waterHabit,
                months: 1,
                cellSize: 14,
                cellSpacing: 3,
                showMonthLabels: true
            )
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHeatmapGridView_6Months() {
        let view = SnapshotContainer(width: 600, height: 200) {
            HeatmapGridView(
                habit: TestData.exerciseHabit,
                months: 6,
                cellSize: 10,
                cellSpacing: 2,
                showMonthLabels: true
            )
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHeatmapGridView_WithoutMonthLabels() {
        let view = SnapshotContainer(width: 390, height: 160) {
            HeatmapGridView(
                habit: TestData.exerciseHabit,
                months: 3,
                cellSize: 12,
                cellSpacing: 3,
                showMonthLabels: false
            )
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - CompactHeatmapView

    func testCompactHeatmapView_Light() {
        let view = SnapshotContainer(width: 350, height: 100) {
            CompactHeatmapView(habit: TestData.exerciseHabit)
                .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testCompactHeatmapView_Dark() {
        let view = SnapshotContainer(width: 350, height: 100) {
            CompactHeatmapView(habit: TestData.exerciseHabit)
                .padding()
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testCompactHeatmapView_DifferentColors() {
        let colors: [(String, Habit)] = [
            ("Blue", TestData.exerciseHabit),
            ("Orange", TestData.readHabit),
            ("Purple", TestData.meditateHabit),
            ("Cyan", TestData.waterHabit),
        ]

        for (name, habit) in colors {
            let view = SnapshotContainer(width: 350, height: 100) {
                CompactHeatmapView(habit: habit)
                    .padding()
            }

            assertSnapshot(of: view, as: .image(layout: .sizeThatFits), named: name)
        }
    }

    // MARK: - HeatmapCell

    func testHeatmapCell_Completed() {
        let day = DayData(date: Date(), value: 1.0, isFuture: false)
        let view = HeatmapCell(day: day, color: .blue, size: 24)
            .padding(8)
            .background(Color(.systemBackground))

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHeatmapCell_Empty() {
        let day = DayData(date: Date(), value: 0.0, isFuture: false)
        let view = HeatmapCell(day: day, color: .blue, size: 24)
            .padding(8)
            .background(Color(.systemBackground))

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHeatmapCell_Future() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let day = DayData(date: futureDate, value: 0.0, isFuture: true)
        let view = HeatmapCell(day: day, color: .blue, size: 24)
            .padding(8)
            .background(Color(.systemBackground))

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testHeatmapCell_PartialValue() {
        let day = DayData(date: Date(), value: 0.5, isFuture: false)
        let view = HeatmapCell(day: day, color: .green, size: 24)
            .padding(8)
            .background(Color(.systemBackground))

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
