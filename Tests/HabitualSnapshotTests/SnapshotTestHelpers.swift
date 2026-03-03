import SwiftUI
import XCTest
@testable import HabitualCore

/// Deterministic test data factory for snapshot tests.
/// Uses fixed dates and UUIDs to ensure pixel-perfect reproducibility.
enum TestData {

    // Fixed reference date: 2026-01-15 00:00:00 UTC
    static let referenceDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: components)!
    }()

    static let fixedUUID1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let fixedUUID2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let fixedUUID3 = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    static let fixedUUID4 = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!

    static let calendar = Calendar.current

    static func date(daysAgo: Int) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: referenceDate))!
    }

    // MARK: - Sample Habits

    /// Exercise habit with a 7-day streak
    static var exerciseHabit: Habit {
        let completions = (0..<7).map { daysAgo in
            Completion(
                id: UUID(uuidString: "10000000-0000-0000-0000-\(String(format: "%012d", daysAgo))")!,
                date: date(daysAgo: daysAgo)
            )
        }
        // Add some older completions for heatmap variety
        let olderCompletions = stride(from: 10, to: 60, by: 2).map { daysAgo in
            Completion(
                id: UUID(uuidString: "10000000-0000-0000-0001-\(String(format: "%012d", daysAgo))")!,
                date: date(daysAgo: daysAgo)
            )
        }

        return Habit(
            id: fixedUUID1,
            name: "Exercise",
            description: "Daily workout routine",
            icon: "figure.run",
            color: Color(red: 0.35, green: 0.65, blue: 0.85),
            colorComponents: (red: 0.35, green: 0.65, blue: 0.85),
            createdAt: date(daysAgo: 90),
            goalFrequency: 1,
            goalPeriod: .daily,
            completions: completions + olderCompletions
        )
    }

    /// Read habit with a 3-day streak, weekly goal
    static var readHabit: Habit {
        let completions = [0, 1, 2, 5, 8, 12, 15, 20, 25].map { daysAgo in
            Completion(
                id: UUID(uuidString: "20000000-0000-0000-0000-\(String(format: "%012d", daysAgo))")!,
                date: date(daysAgo: daysAgo)
            )
        }

        return Habit(
            id: fixedUUID2,
            name: "Read",
            description: "Read for 30 minutes",
            icon: "book.fill",
            color: Color(red: 0.95, green: 0.55, blue: 0.20),
            colorComponents: (red: 0.95, green: 0.55, blue: 0.20),
            createdAt: date(daysAgo: 60),
            goalFrequency: 3,
            goalPeriod: .weekly,
            completions: completions
        )
    }

    /// Meditate habit — no completions (empty state)
    static var meditateHabit: Habit {
        Habit(
            id: fixedUUID3,
            name: "Meditate",
            description: "Morning meditation",
            icon: "brain.head.profile",
            color: Color(red: 0.65, green: 0.35, blue: 0.90),
            colorComponents: (red: 0.65, green: 0.35, blue: 0.90),
            createdAt: date(daysAgo: 30),
            goalFrequency: 1,
            goalPeriod: .daily,
            completions: []
        )
    }

    /// Water habit — fully completed (high rate)
    static var waterHabit: Habit {
        let completions = (0..<30).map { daysAgo in
            Completion(
                id: UUID(uuidString: "40000000-0000-0000-0000-\(String(format: "%012d", daysAgo))")!,
                date: date(daysAgo: daysAgo)
            )
        }

        return Habit(
            id: fixedUUID4,
            name: "Drink Water",
            description: "8 glasses daily",
            icon: "drop.fill",
            color: Color(red: 0.20, green: 0.75, blue: 0.95),
            colorComponents: (red: 0.20, green: 0.75, blue: 0.95),
            createdAt: date(daysAgo: 30),
            goalFrequency: 1,
            goalPeriod: .daily,
            completions: completions
        )
    }

    static var allHabits: [Habit] {
        [exerciseHabit, readHabit, meditateHabit, waterHabit]
    }

    // MARK: - Heatmap Data

    /// Pre-built heatmap data for deterministic snapshot rendering
    static func deterministicHeatmapWeeks(months: Int = 3) -> [[DayData]] {
        exerciseHabit.heatmapData(months: months)
    }
}

/// Wraps a SwiftUI view in a sized container suitable for snapshot testing.
struct SnapshotContainer<Content: View>: View {
    let width: CGFloat
    let height: CGFloat?
    let content: Content

    init(width: CGFloat = 390, height: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.width = width
        self.height = height
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: width)
            .frame(height: height)
            .background(Color(.systemBackground))
    }
}
