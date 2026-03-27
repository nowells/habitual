import SnapshotTesting
import SwiftUI
import XCTest

@testable import HabitualCore

final class DetailViewSnapshotTests: SnapshotTestCase {

    // MARK: - StatCard

    func testStatCard_CurrentStreak() {
        let view = StatCard(
            title: "Current Streak",
            value: "7",
            subtitle: "days",
            icon: "flame.fill",
            color: .orange
        )
        .frame(width: 170)
        .padding()
        .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testStatCard_LongestStreak() {
        let view = StatCard(
            title: "Longest Streak",
            value: "23",
            subtitle: "days",
            icon: "trophy.fill",
            color: .yellow
        )
        .frame(width: 170)
        .padding()
        .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testStatCard_Total() {
        let view = StatCard(
            title: "Total",
            value: "156",
            subtitle: "completions",
            icon: "checkmark.circle.fill",
            color: .blue
        )
        .frame(width: 170)
        .padding()
        .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testStatCard_SuccessRate() {
        let view = StatCard(
            title: "Success Rate",
            value: "85%",
            subtitle: "overall",
            icon: "chart.line.uptrend.xyaxis",
            color: .green
        )
        .frame(width: 170)
        .padding()
        .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Stats Grid (2x2)

    func testStatsGrid_Light() {
        let view = SnapshotContainer(width: 390) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 12
            ) {
                StatCard(title: "Current Streak", value: "7", subtitle: "days", icon: "flame.fill", color: .orange)
                StatCard(title: "Longest Streak", value: "23", subtitle: "days", icon: "trophy.fill", color: .yellow)
                StatCard(
                    title: "Total", value: "156", subtitle: "completions", icon: "checkmark.circle.fill", color: .blue)
                StatCard(
                    title: "Success Rate", value: "85%", subtitle: "overall", icon: "chart.line.uptrend.xyaxis",
                    color: .green)
            }
            .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testStatsGrid_Dark() {
        let view = SnapshotContainer(width: 390) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 12
            ) {
                StatCard(title: "Current Streak", value: "7", subtitle: "days", icon: "flame.fill", color: .orange)
                StatCard(title: "Longest Streak", value: "23", subtitle: "days", icon: "trophy.fill", color: .yellow)
                StatCard(
                    title: "Total", value: "156", subtitle: "completions", icon: "checkmark.circle.fill", color: .blue)
                StatCard(
                    title: "Success Rate", value: "85%", subtitle: "overall", icon: "chart.line.uptrend.xyaxis",
                    color: .green)
            }
            .padding()
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Calendar Day Cell

    func testCalendarDayCell_Completed() {
        let view = CalendarDayCell(
            date: TestData.referenceDate,
            isCompleted: true,
            isToday: true,
            isFuture: false,
            color: .blue,
            onTap: {}
        )
        .padding()
        .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testCalendarDayCell_Today_Incomplete() {
        let view = CalendarDayCell(
            date: TestData.referenceDate,
            isCompleted: false,
            isToday: true,
            isFuture: false,
            color: .blue,
            onTap: {}
        )
        .padding()
        .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testCalendarDayCell_Past_Incomplete() {
        let view = CalendarDayCell(
            date: TestData.date(daysAgo: 1),
            isCompleted: false,
            isToday: false,
            isFuture: false,
            color: .blue,
            onTap: {}
        )
        .padding()
        .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testCalendarDayCell_Future() {
        let view = CalendarDayCell(
            date: TestData.date(daysAgo: -1),
            isCompleted: false,
            isToday: false,
            isFuture: true,
            color: .blue,
            onTap: {}
        )
        .padding()
        .background(Color.systemBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Calendar Grid

    func testCalendarGridView_Light() {
        let view = SnapshotContainer(width: 350, height: 300) {
            CalendarGridView(
                habit: TestData.exerciseHabit,
                month: TestData.referenceDate
            )
            .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testCalendarGridView_Dark() {
        let view = SnapshotContainer(width: 350, height: 300) {
            CalendarGridView(
                habit: TestData.exerciseHabit,
                month: TestData.referenceDate
            )
            .padding()
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testCalendarGridView_EmptyMonth() {
        let view = SnapshotContainer(width: 350, height: 300) {
            CalendarGridView(
                habit: TestData.meditateHabit,
                month: TestData.referenceDate
            )
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
