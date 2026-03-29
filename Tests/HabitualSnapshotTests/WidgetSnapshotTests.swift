import SnapshotTesting
import SwiftUI
import XCTest

@testable import HabitualCore

// MARK: - Widget Test Data Types

/// Mirrors HabitualWidgets.PeriodRingData for snapshot testing without WidgetKit dependency.
private struct TestPeriodRingData {
    let period: String
    let completed: Int
    let total: Int
    let color: Color

    var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var label: String {
        switch period {
        case "daily": return "D"
        case "weekly": return "W"
        case "monthly": return "M"
        case "yearly": return "Y"
        default: return "?"
        }
    }

    static func color(for period: String) -> Color {
        switch period {
        case "daily": return .green
        case "weekly": return .blue
        case "monthly": return .orange
        case "yearly": return .purple
        default: return .gray
        }
    }
}

/// Mirrors HabitualWidgets.HabitSnapshot for snapshot testing.
private struct TestHabitSnapshot: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double
    let isPeriodComplete: Bool
    let periodCompletions: Int
    let goalFrequency: Int
    let goalPeriod: String
    let currentStreak: Int
    let completionRate: Double
    let recentPeriods: [TestWidgetPeriod]

    var color: Color { Color(red: colorRed, green: colorGreen, blue: colorBlue) }
    var isMultiFrequency: Bool { goalFrequency > 1 }
}

private struct TestWidgetPeriod {
    let completionCount: Int
    let isFuture: Bool
}

/// Mirrors HabitualWidgets.HabitWidgetEntry for snapshot testing.
private struct TestWidgetEntry {
    let habits: [TestHabitSnapshot]
    let totalHabits: Int
    let completedToday: Int

    var periodRings: [TestPeriodRingData] {
        let periods = ["daily", "weekly", "monthly", "yearly"]
        return periods.compactMap { period in
            let periodHabits = habits.filter { $0.goalPeriod == period }
            guard !periodHabits.isEmpty else { return nil }
            let completed = periodHabits.filter(\.isPeriodComplete).count
            return TestPeriodRingData(
                period: period,
                completed: completed,
                total: periodHabits.count,
                color: TestPeriodRingData.color(for: period)
            )
        }
    }
}

/// Mirrors SingleHabitWidget.SingleHabitEntry for snapshot testing.
private struct TestSingleHabitEntry {
    let habitName: String
    let habitIcon: String
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double
    let isPeriodComplete: Bool
    let periodCompletions: Int
    let goalFrequency: Int
    let currentStreak: Int
    let completionRate: Double
    let heatmapDays: [(count: Int, status: CellStatus)]

    var color: Color { Color(red: colorRed, green: colorGreen, blue: colorBlue) }
    var isMultiFrequency: Bool { goalFrequency > 1 }
}

/// Mirrors HabitComplicationEntry for snapshot testing.
private struct TestComplicationEntry {
    let habitName: String
    let habitIcon: String
    let isCompleted: Bool
    let periodCompletions: Int
    let goalFrequency: Int
    let streak: Int
    let completionRate: Double
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double

    var color: Color { Color(red: colorRed, green: colorGreen, blue: colorBlue) }
    var isMultiFrequency: Bool { goalFrequency > 1 }
}

// MARK: - Widget View Mirrors

/// Mirrors ConcentricRingsView (full-color mode only, no WidgetKit environment).
private struct TestConcentricRingsView: View {
    let rings: [TestPeriodRingData]
    let size: CGFloat

    private var lineWidth: CGFloat { max(size / 12, 3) }
    private var gap: CGFloat { lineWidth + 2 }

    var body: some View {
        ZStack {
            ForEach(Array(rings.enumerated()), id: \.offset) { index, ring in
                let ringSize = size - CGFloat(index) * gap * 2
                Circle()
                    .stroke(ring.color.opacity(0.2), lineWidth: lineWidth)
                    .frame(width: ringSize, height: ringSize)
                Circle()
                    .trim(from: 0, to: ring.fraction)
                    .stroke(ring.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: size, height: size)
    }
}

/// Mirrors SmallHabitWidget layout.
private struct TestSmallWidget: View {
    let entry: TestWidgetEntry

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Habitual")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 8) {
                Spacer()
                TestConcentricRingsView(rings: entry.periodRings, size: 56)
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(entry.periodRings, id: \.period) { ring in
                        HStack(spacing: 3) {
                            Circle().fill(ring.color).frame(width: 5, height: 5)
                            Text(ring.label).font(.system(size: 8)).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }
            Spacer()
            let icons = Array(entry.habits.prefix(8))
            let topRow = Array(icons.prefix(min(icons.count, 5)))
            let bottomRow = icons.count > 5 ? Array(icons.suffix(from: 5)) : []
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    ForEach(topRow) { habit in
                        HabitIcon.image(habit.icon).font(.caption2)
                            .foregroundStyle(habit.isPeriodComplete ? habit.color : .gray)
                    }
                }
                if !bottomRow.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(bottomRow) { habit in
                            HabitIcon.image(habit.icon).font(.caption2)
                                .foregroundStyle(habit.isPeriodComplete ? habit.color : .gray)
                        }
                    }
                }
            }
        }
        .padding(10)
    }
}

/// Mirrors MediumHabitWidget layout.
private struct TestMediumWidget: View {
    let entry: TestWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Habitual").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                Spacer()
                TestConcentricRingsView(rings: entry.periodRings, size: 28)
            }
            ForEach(entry.habits.prefix(3)) { habit in
                HStack(spacing: 8) {
                    if habit.isPeriodComplete {
                        Image(systemName: "checkmark.circle.fill").font(.body).foregroundStyle(habit.color)
                    } else if habit.isMultiFrequency && habit.periodCompletions > 0 {
                        Text("\(habit.periodCompletions)/\(habit.goalFrequency)")
                            .font(.caption2).fontWeight(.bold).foregroundStyle(habit.color).frame(width: 22)
                    } else {
                        Image(systemName: "circle").font(.body).foregroundStyle(.gray)
                    }
                    HabitIcon.image(habit.icon).font(.caption).foregroundStyle(habit.color)
                    Text(habit.name).font(.caption).fontWeight(.medium).lineLimit(1)
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill").font(.caption2).foregroundStyle(.orange)
                        Text("\(habit.currentStreak)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

/// Mirrors LargeHabitWidget layout.
private struct TestLargeWidget: View {
    let entry: TestWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Habitual").font(.headline)
                    HStack(spacing: 6) {
                        ForEach(entry.periodRings, id: \.period) { ring in
                            HStack(spacing: 2) {
                                Circle().fill(ring.color).frame(width: 6, height: 6)
                                Text("\(ring.label) \(ring.completed)/\(ring.total)")
                                    .font(.system(size: 9)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Spacer()
                TestConcentricRingsView(rings: entry.periodRings, size: 42)
            }
            Divider()
            ForEach(entry.habits.prefix(5)) { habit in
                HStack(spacing: 8) {
                    if habit.isPeriodComplete {
                        Image(systemName: "checkmark.circle.fill").font(.body).foregroundStyle(habit.color)
                    } else if habit.isMultiFrequency && habit.periodCompletions > 0 {
                        Text("\(habit.periodCompletions)/\(habit.goalFrequency)")
                            .font(.caption2).fontWeight(.bold).foregroundStyle(habit.color).frame(width: 22)
                    } else {
                        Image(systemName: "circle").font(.body).foregroundStyle(.gray)
                    }
                    HabitIcon.image(habit.icon).font(.caption).foregroundStyle(habit.color).frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name).font(.caption).fontWeight(.medium).lineLimit(1)
                        TestWidgetMiniHeatmap(habit: habit)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill").font(.caption2).foregroundStyle(.orange)
                            Text("\(habit.currentStreak)").font(.caption2).fontWeight(.semibold)
                        }
                        Text("\(Int(habit.completionRate * 100))%")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

/// Mirrors WidgetMiniHeatmap layout.
private struct TestWidgetMiniHeatmap: View {
    let habit: TestHabitSnapshot
    private let dotSize: CGFloat = 6

    var body: some View {
        let periods = Array(habit.recentPeriods.suffix(14))
        let peak = periods.map(\.completionCount).max() ?? 0
        HStack(spacing: 2) {
            ForEach(periods.indices, id: \.self) { idx in
                let period = periods[idx]
                let status: CellStatus = {
                    if period.isFuture { return .future }
                    if period.completionCount == 0 { return .missed }
                    if period.completionCount < habit.goalFrequency { return .partial }
                    if period.completionCount >= habit.goalFrequency * 2 { return .overComplete }
                    return .complete
                }()
                LiquidFillCell(
                    count: period.completionCount, goal: habit.goalFrequency,
                    color: habit.color, status: status, size: dotSize, maxCount: peak
                )
            }
        }
    }
}

/// Mirrors SingleHabitWidgetView layout (small size).
private struct TestSingleHabitSmallWidget: View {
    let entry: TestSingleHabitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HabitIcon.image(entry.habitIcon).foregroundStyle(entry.color)
                Text(entry.habitName).font(.caption).fontWeight(.semibold).lineLimit(1)
                Spacer()
                if entry.isPeriodComplete {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else if entry.isMultiFrequency && entry.periodCompletions > 0 {
                    Text("\(entry.periodCompletions)/\(entry.goalFrequency)")
                        .font(.caption2).fontWeight(.bold).foregroundStyle(entry.color)
                } else {
                    Image(systemName: "circle").foregroundStyle(.gray)
                }
            }
            Spacer()
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill").font(.caption2).foregroundStyle(.orange)
                    Text("\(entry.currentStreak)d").font(.caption2).fontWeight(.semibold)
                }
                Spacer()
                Text("\(Int(entry.completionRate * 100))%").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

/// Mirrors SingleHabitWidgetView layout (medium size, with heatmap).
private struct TestSingleHabitMediumWidget: View {
    let entry: TestSingleHabitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HabitIcon.image(entry.habitIcon).foregroundStyle(entry.color)
                Text(entry.habitName).font(.caption).fontWeight(.semibold).lineLimit(1)
                Spacer()
                if entry.isPeriodComplete {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else if entry.isMultiFrequency && entry.periodCompletions > 0 {
                    Text("\(entry.periodCompletions)/\(entry.goalFrequency)")
                        .font(.caption2).fontWeight(.bold).foregroundStyle(entry.color)
                } else {
                    Image(systemName: "circle").foregroundStyle(.gray)
                }
            }
            TestHeatmapGrid(days: entry.heatmapDays, color: entry.color, goal: entry.goalFrequency)
            Spacer()
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill").font(.caption2).foregroundStyle(.orange)
                    Text("\(entry.currentStreak)d").font(.caption2).fontWeight(.semibold)
                }
                Spacer()
                Text("\(Int(entry.completionRate * 100))%").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

/// Mirrors WidgetHeatmapGrid layout.
private struct TestHeatmapGrid: View {
    let days: [(count: Int, status: CellStatus)]
    let color: Color
    let goal: Int
    let cellSize: CGFloat = 8
    let spacing: CGFloat = 2

    private var peak: Int { days.map(\.count).max() ?? 0 }

    var body: some View {
        let rows = 7
        let cols = days.count / rows
        HStack(spacing: spacing) {
            ForEach(0..<cols, id: \.self) { col in
                VStack(spacing: spacing) {
                    ForEach(0..<rows, id: \.self) { row in
                        let index = col * rows + row
                        if index < days.count {
                            let day = days[index]
                            LiquidFillCell(
                                count: day.count, goal: goal, color: color,
                                status: day.status, size: cellSize, maxCount: peak
                            )
                        }
                    }
                }
            }
        }
    }
}

/// Mirrors HabitualCircularComplication layout.
private struct TestCircularComplication: View {
    let entry: TestComplicationEntry

    var body: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.2))
            VStack(spacing: 1) {
                HabitIcon.image(entry.habitIcon)
                    .font(.caption)
                    .foregroundStyle(entry.isCompleted ? .green : entry.color)
                if entry.isCompleted {
                    Image(systemName: "checkmark").font(.caption2).foregroundStyle(.green)
                } else if entry.isMultiFrequency {
                    Text("\(entry.periodCompletions)/\(entry.goalFrequency)")
                        .font(.system(size: 9)).fontWeight(.bold).foregroundStyle(entry.color)
                } else {
                    Image(systemName: "circle").font(.caption2).foregroundStyle(.gray)
                }
            }
        }
    }
}

/// Mirrors HabitualRectangularComplication layout.
private struct TestRectangularComplication: View {
    let entry: TestComplicationEntry

    var body: some View {
        HStack(spacing: 8) {
            HabitIcon.image(entry.habitIcon).font(.title3).foregroundStyle(entry.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.habitName).font(.headline).lineLimit(1)
                HStack(spacing: 4) {
                    if entry.isCompleted {
                        Image(systemName: "checkmark.circle.fill").font(.caption2).foregroundStyle(.green)
                        Text("Done").font(.caption2)
                    } else if entry.isMultiFrequency && entry.periodCompletions > 0 {
                        Text("\(entry.periodCompletions)/\(entry.goalFrequency)")
                            .font(.caption2).fontWeight(.bold).foregroundStyle(entry.color)
                    } else {
                        Image(systemName: "circle").font(.caption2).foregroundStyle(.gray)
                        Text("Pending").font(.caption2)
                    }
                    Text("·")
                    Image(systemName: "flame.fill").font(.caption2).foregroundStyle(.orange)
                    Text("\(entry.streak)").font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}

/// Mirrors HabitualInlineComplication layout.
private struct TestInlineComplication: View {
    let entry: TestComplicationEntry

    var body: some View {
        HStack(spacing: 4) {
            HabitIcon.image(entry.habitIcon)
            Text(entry.habitName)
            Text("·")
            Image(systemName: "flame.fill")
            Text("\(entry.streak)d")
        }
    }
}

// MARK: - Test Data Factory

private enum WidgetTestData {
    static let fixedUUIDs = (0..<10).map {
        UUID(uuidString: "A0000000-0000-0000-0000-\(String(format: "%012d", $0))")!
    }

    static func samplePeriods(goal: Int, completedDays: [Int]) -> [TestWidgetPeriod] {
        (0..<14).map { idx in
            let count = completedDays.contains(idx) ? goal : 0
            return TestWidgetPeriod(completionCount: count, isFuture: idx > 12)
        }
    }

    static let dailyExercise = TestHabitSnapshot(
        id: fixedUUIDs[0], name: "Push-ups", icon: "dumbbell.fill",
        colorRed: 0.2, colorGreen: 0.78, colorBlue: 0.35,
        isPeriodComplete: true, periodCompletions: 1, goalFrequency: 1, goalPeriod: "daily",
        currentStreak: 3, completionRate: 0.15,
        recentPeriods: samplePeriods(goal: 1, completedDays: [11, 12])
    )

    static let dailyWater = TestHabitSnapshot(
        id: fixedUUIDs[1], name: "Drink Water", icon: "drop.fill",
        colorRed: 0.20, colorGreen: 0.55, colorBlue: 0.95,
        isPeriodComplete: true, periodCompletions: 1, goalFrequency: 1, goalPeriod: "daily",
        currentStreak: 3, completionRate: 0.15,
        recentPeriods: samplePeriods(goal: 1, completedDays: [11, 12])
    )

    static let dailyIncomplete = TestHabitSnapshot(
        id: fixedUUIDs[2], name: "Visit Family", icon: "house.fill",
        colorRed: 0.55, colorGreen: 0.55, colorBlue: 0.55,
        isPeriodComplete: false, periodCompletions: 0, goalFrequency: 1, goalPeriod: "daily",
        currentStreak: 0, completionRate: 0.0,
        recentPeriods: samplePeriods(goal: 1, completedDays: [])
    )

    static let weeklyHike = TestHabitSnapshot(
        id: fixedUUIDs[3], name: "Hike", icon: "figure.walk",
        colorRed: 0.95, colorGreen: 0.35, colorBlue: 0.55,
        isPeriodComplete: true, periodCompletions: 1, goalFrequency: 1, goalPeriod: "weekly",
        currentStreak: 1, completionRate: 1.0,
        recentPeriods: samplePeriods(goal: 1, completedDays: [6, 12])
    )

    static let monthlyDate = TestHabitSnapshot(
        id: fixedUUIDs[4], name: "Date Day", icon: "heart.fill",
        colorRed: 0.6, colorGreen: 0.35, colorBlue: 0.85,
        isPeriodComplete: true, periodCompletions: 1, goalFrequency: 1, goalPeriod: "monthly",
        currentStreak: 2, completionRate: 1.0,
        recentPeriods: samplePeriods(goal: 1, completedDays: [5, 12])
    )

    static let multiFrequency = TestHabitSnapshot(
        id: fixedUUIDs[5], name: "Meditate", icon: "brain.head.profile",
        colorRed: 0.65, colorGreen: 0.35, colorBlue: 0.90,
        isPeriodComplete: false, periodCompletions: 2, goalFrequency: 3, goalPeriod: "daily",
        currentStreak: 0, completionRate: 0.45,
        recentPeriods: samplePeriods(goal: 3, completedDays: [10, 11])
    )

    static let mixedEntry = TestWidgetEntry(
        habits: [dailyIncomplete, dailyExercise, dailyWater, weeklyHike, monthlyDate],
        totalHabits: 5,
        completedToday: 4
    )

    static let allDailyEntry = TestWidgetEntry(
        habits: [dailyIncomplete, dailyExercise, dailyWater, multiFrequency],
        totalHabits: 4,
        completedToday: 2
    )

    static let emptyEntry = TestWidgetEntry(habits: [], totalHabits: 0, completedToday: 0)

    static let allCompleteEntry = TestWidgetEntry(
        habits: [dailyExercise, dailyWater, weeklyHike, monthlyDate],
        totalHabits: 4,
        completedToday: 4
    )

    // Single habit entries
    static let singleComplete = TestSingleHabitEntry(
        habitName: "Push-ups", habitIcon: "dumbbell.fill",
        colorRed: 0.2, colorGreen: 0.78, colorBlue: 0.35,
        isPeriodComplete: true, periodCompletions: 1, goalFrequency: 1,
        currentStreak: 7, completionRate: 0.85,
        heatmapDays: buildHeatmapDays(completedIndices: Set(stride(from: 0, to: 84, by: 2)))
    )

    static let singleIncomplete = TestSingleHabitEntry(
        habitName: "Read", habitIcon: "book.fill",
        colorRed: 0.95, colorGreen: 0.55, colorBlue: 0.20,
        isPeriodComplete: false, periodCompletions: 0, goalFrequency: 1,
        currentStreak: 0, completionRate: 0.30,
        heatmapDays: buildHeatmapDays(completedIndices: Set([60, 62, 65, 70, 72, 75, 78, 80]))
    )

    static let singleMultiFreq = TestSingleHabitEntry(
        habitName: "Meditate", habitIcon: "brain.head.profile",
        colorRed: 0.65, colorGreen: 0.35, colorBlue: 0.90,
        isPeriodComplete: false, periodCompletions: 2, goalFrequency: 3,
        currentStreak: 0, completionRate: 0.45,
        heatmapDays: buildHeatmapDays(completedIndices: Set(stride(from: 50, to: 84, by: 3)), count: 2)
    )

    // Complication entries
    static let complicationPending = TestComplicationEntry(
        habitName: "Push-ups", habitIcon: "dumbbell.fill",
        isCompleted: false, periodCompletions: 0, goalFrequency: 1,
        streak: 3, completionRate: 0.65,
        colorRed: 0.2, colorGreen: 0.78, colorBlue: 0.35
    )

    static let complicationDone = TestComplicationEntry(
        habitName: "Drink Water", habitIcon: "drop.fill",
        isCompleted: true, periodCompletions: 1, goalFrequency: 1,
        streak: 14, completionRate: 0.92,
        colorRed: 0.20, colorGreen: 0.55, colorBlue: 0.95
    )

    static let complicationMulti = TestComplicationEntry(
        habitName: "Meditate", habitIcon: "brain.head.profile",
        isCompleted: false, periodCompletions: 2, goalFrequency: 3,
        streak: 5, completionRate: 0.70,
        colorRed: 0.65, colorGreen: 0.35, colorBlue: 0.90
    )

    private static func buildHeatmapDays(
        completedIndices: Set<Int>, count: Int = 1, total: Int = 84
    ) -> [(count: Int, status: CellStatus)] {
        (0..<total).map { idx in
            let count = completedIndices.contains(idx) ? count : 0
            let isFuture = idx > total - 3
            let status: CellStatus
            if isFuture {
                status = .future
            } else if count == 0 {
                status = .missed
            } else if count >= count {
                status = .complete
            } else {
                status = .partial
            }
            return (count: count, status: status)
        }
    }
}

// MARK: - Tests

final class WidgetSnapshotTests: SnapshotTestCase {

    // MARK: - Concentric Rings

    func testConcentricRings_SingleRing() {
        let rings = [TestPeriodRingData(period: "daily", completed: 2, total: 3, color: .green)]
        let view = TestConcentricRingsView(rings: rings, size: 60)
            .padding(8).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testConcentricRings_TwoRings() {
        let rings = [
            TestPeriodRingData(period: "daily", completed: 2, total: 3, color: .green),
            TestPeriodRingData(period: "weekly", completed: 1, total: 1, color: .blue),
        ]
        let view = TestConcentricRingsView(rings: rings, size: 60)
            .padding(8).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testConcentricRings_FourRings() {
        let rings = [
            TestPeriodRingData(period: "daily", completed: 2, total: 3, color: .green),
            TestPeriodRingData(period: "weekly", completed: 1, total: 2, color: .blue),
            TestPeriodRingData(period: "monthly", completed: 0, total: 1, color: .orange),
            TestPeriodRingData(period: "yearly", completed: 1, total: 1, color: .purple),
        ]
        let view = TestConcentricRingsView(rings: rings, size: 60)
            .padding(8).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testConcentricRings_AllComplete() {
        let rings = [
            TestPeriodRingData(period: "daily", completed: 3, total: 3, color: .green),
            TestPeriodRingData(period: "weekly", completed: 1, total: 1, color: .blue),
            TestPeriodRingData(period: "monthly", completed: 1, total: 1, color: .orange),
        ]
        let view = TestConcentricRingsView(rings: rings, size: 60)
            .padding(8).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testConcentricRings_AllEmpty() {
        let rings = [
            TestPeriodRingData(period: "daily", completed: 0, total: 3, color: .green),
            TestPeriodRingData(period: "weekly", completed: 0, total: 1, color: .blue),
        ]
        let view = TestConcentricRingsView(rings: rings, size: 60)
            .padding(8).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testConcentricRings_SmallSize() {
        let rings = [
            TestPeriodRingData(period: "daily", completed: 2, total: 3, color: .green),
            TestPeriodRingData(period: "weekly", completed: 1, total: 1, color: .blue),
        ]
        let view = TestConcentricRingsView(rings: rings, size: 28)
            .padding(8).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Small Widget

    func testSmallWidget_Mixed_Light() {
        let view = SnapshotContainer(width: 170, height: 170) {
            TestSmallWidget(entry: WidgetTestData.mixedEntry)
        }.environment(\.colorScheme, .light)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSmallWidget_Mixed_Dark() {
        let view = SnapshotContainer(width: 170, height: 170) {
            TestSmallWidget(entry: WidgetTestData.mixedEntry)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSmallWidget_AllDaily() {
        let view = SnapshotContainer(width: 170, height: 170) {
            TestSmallWidget(entry: WidgetTestData.allDailyEntry)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSmallWidget_AllComplete() {
        let view = SnapshotContainer(width: 170, height: 170) {
            TestSmallWidget(entry: WidgetTestData.allCompleteEntry)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSmallWidget_Empty() {
        let view = SnapshotContainer(width: 170, height: 170) {
            TestSmallWidget(entry: WidgetTestData.emptyEntry)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Medium Widget

    func testMediumWidget_Mixed_Light() {
        let view = SnapshotContainer(width: 360, height: 170) {
            TestMediumWidget(entry: WidgetTestData.mixedEntry)
        }.environment(\.colorScheme, .light)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testMediumWidget_Mixed_Dark() {
        let view = SnapshotContainer(width: 360, height: 170) {
            TestMediumWidget(entry: WidgetTestData.mixedEntry)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testMediumWidget_AllComplete() {
        let view = SnapshotContainer(width: 360, height: 170) {
            TestMediumWidget(entry: WidgetTestData.allCompleteEntry)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Large Widget

    func testLargeWidget_Mixed_Light() {
        let view = SnapshotContainer(width: 360, height: 380) {
            TestLargeWidget(entry: WidgetTestData.mixedEntry)
        }.environment(\.colorScheme, .light)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testLargeWidget_Mixed_Dark() {
        let view = SnapshotContainer(width: 360, height: 380) {
            TestLargeWidget(entry: WidgetTestData.mixedEntry)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testLargeWidget_AllDaily_Dark() {
        let view = SnapshotContainer(width: 360, height: 380) {
            TestLargeWidget(entry: WidgetTestData.allDailyEntry)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testLargeWidget_AllComplete_Dark() {
        let view = SnapshotContainer(width: 360, height: 380) {
            TestLargeWidget(entry: WidgetTestData.allCompleteEntry)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testLargeWidget_Empty_Dark() {
        let view = SnapshotContainer(width: 360, height: 380) {
            TestLargeWidget(entry: WidgetTestData.emptyEntry)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Single Habit Widget (Small)

    func testSingleHabitSmall_Complete_Light() {
        let view = SnapshotContainer(width: 170, height: 170) {
            TestSingleHabitSmallWidget(entry: WidgetTestData.singleComplete)
        }.environment(\.colorScheme, .light)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSingleHabitSmall_Complete_Dark() {
        let view = SnapshotContainer(width: 170, height: 170) {
            TestSingleHabitSmallWidget(entry: WidgetTestData.singleComplete)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSingleHabitSmall_Incomplete() {
        let view = SnapshotContainer(width: 170, height: 170) {
            TestSingleHabitSmallWidget(entry: WidgetTestData.singleIncomplete)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSingleHabitSmall_MultiFrequency() {
        let view = SnapshotContainer(width: 170, height: 170) {
            TestSingleHabitSmallWidget(entry: WidgetTestData.singleMultiFreq)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Single Habit Widget (Medium)

    func testSingleHabitMedium_Complete_Light() {
        let view = SnapshotContainer(width: 360, height: 170) {
            TestSingleHabitMediumWidget(entry: WidgetTestData.singleComplete)
        }.environment(\.colorScheme, .light)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSingleHabitMedium_Complete_Dark() {
        let view = SnapshotContainer(width: 360, height: 170) {
            TestSingleHabitMediumWidget(entry: WidgetTestData.singleComplete)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSingleHabitMedium_Incomplete() {
        let view = SnapshotContainer(width: 360, height: 170) {
            TestSingleHabitMediumWidget(entry: WidgetTestData.singleIncomplete)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSingleHabitMedium_MultiFrequency() {
        let view = SnapshotContainer(width: 360, height: 170) {
            TestSingleHabitMediumWidget(entry: WidgetTestData.singleMultiFreq)
        }.environment(\.colorScheme, .dark)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Watch Complications

    func testComplication_Circular_Pending() {
        let view = TestCircularComplication(entry: WidgetTestData.complicationPending)
            .frame(width: 50, height: 50).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testComplication_Circular_Done() {
        let view = TestCircularComplication(entry: WidgetTestData.complicationDone)
            .frame(width: 50, height: 50).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testComplication_Circular_MultiFreq() {
        let view = TestCircularComplication(entry: WidgetTestData.complicationMulti)
            .frame(width: 50, height: 50).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testComplication_Rectangular_Pending() {
        let view = TestRectangularComplication(entry: WidgetTestData.complicationPending)
            .frame(width: 180, height: 50).padding(4).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testComplication_Rectangular_Done() {
        let view = TestRectangularComplication(entry: WidgetTestData.complicationDone)
            .frame(width: 180, height: 50).padding(4).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testComplication_Rectangular_MultiFreq() {
        let view = TestRectangularComplication(entry: WidgetTestData.complicationMulti)
            .frame(width: 180, height: 50).padding(4).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testComplication_Inline_Pending() {
        let view = TestInlineComplication(entry: WidgetTestData.complicationPending)
            .padding(4).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testComplication_Inline_Done() {
        let view = TestInlineComplication(entry: WidgetTestData.complicationDone)
            .padding(4).background(Color.systemBackground)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
