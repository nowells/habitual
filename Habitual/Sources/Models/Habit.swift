import CoreData
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

// MARK: - Habit Value Type

struct Habit: Identifiable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var icon: String
    var color: Color
    var colorComponents: (red: Double, green: Double, blue: Double)
    var createdAt: Date
    var isArchived: Bool
    var goalFrequency: Int
    var goalPeriod: GoalPeriod
    var reminderTime: Date?
    var sortOrder: Int
    var completions: [Completion]

    enum GoalPeriod: String, CaseIterable, Identifiable {
        case daily
        case weekly
        case monthly
        case yearly

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }

        var periodLabel: String {
            switch self {
            case .daily: return "day"
            case .weekly: return "week"
            case .monthly: return "month"
            case .yearly: return "year"
            }
        }

        var periodLabelPlural: String {
            switch self {
            case .daily: return "days"
            case .weekly: return "weeks"
            case .monthly: return "months"
            case .yearly: return "years"
            }
        }

        /// Returns the start date of the period containing the given date
        func periodStart(for date: Date, calendar: Calendar = .current) -> Date {
            switch self {
            case .daily:
                return calendar.startOfDay(for: date)
            case .weekly:
                var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                components.weekday = calendar.firstWeekday
                return calendar.date(from: components) ?? calendar.startOfDay(for: date)
            case .monthly:
                let components = calendar.dateComponents([.year, .month], from: date)
                return calendar.date(from: components) ?? calendar.startOfDay(for: date)
            case .yearly:
                let components = calendar.dateComponents([.year], from: date)
                return calendar.date(from: components) ?? calendar.startOfDay(for: date)
            }
        }

        /// Returns the end date (exclusive) of the period containing the given date
        func periodEnd(for date: Date, calendar: Calendar = .current) -> Date {
            let start = periodStart(for: date, calendar: calendar)
            switch self {
            case .daily:
                return calendar.date(byAdding: .day, value: 1, to: start) ?? start
            case .weekly:
                return calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
            case .monthly:
                return calendar.date(byAdding: .month, value: 1, to: start) ?? start
            case .yearly:
                return calendar.date(byAdding: .year, value: 1, to: start) ?? start
            }
        }

        /// Calendar component for stepping through periods
        var calendarComponent: Calendar.Component {
            switch self {
            case .daily: return .day
            case .weekly: return .weekOfYear
            case .monthly: return .month
            case .yearly: return .year
            }
        }

        /// Short label for period legends in heatmaps
        func legendLabel(for date: Date, calendar: Calendar = .current) -> String {
            let formatter = DateFormatter()
            switch self {
            case .daily:
                formatter.dateFormat = "MMM d"
            case .weekly:
                formatter.dateFormat = "MMM d"
            case .monthly:
                formatter.dateFormat = "MMM"
            case .yearly:
                formatter.dateFormat = "yyyy"
            }
            return formatter.string(from: date)
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        icon: String = "star.fill",
        color: Color = .blue,
        colorComponents: (red: Double, green: Double, blue: Double) = (0.35, 0.65, 0.85),
        createdAt: Date = Date(),
        isArchived: Bool = false,
        goalFrequency: Int = 1,
        goalPeriod: GoalPeriod = .daily,
        reminderTime: Date? = nil,
        sortOrder: Int = 0,
        completions: [Completion] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = HabitIcon.resolve(icon)
        self.color = color
        self.colorComponents = colorComponents
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.goalFrequency = goalFrequency
        self.goalPeriod = goalPeriod
        self.reminderTime = reminderTime
        self.sortOrder = sortOrder
        self.completions = completions
    }

    /// The effective start date for this habit, accounting for back-dated completions.
    /// Uses the earlier of `createdAt` or the earliest completion date.
    var effectiveStartDate: Date {
        guard let earliest = completions.map(\.date).min() else { return createdAt }
        return min(earliest, createdAt)
    }

    static func == (lhs: Habit, rhs: Habit) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.description == rhs.description
            && lhs.icon == rhs.icon
            && lhs.isArchived == rhs.isArchived
            && lhs.goalFrequency == rhs.goalFrequency
            && lhs.goalPeriod == rhs.goalPeriod
            && lhs.sortOrder == rhs.sortOrder
            && lhs.colorComponents.red == rhs.colorComponents.red
            && lhs.colorComponents.green == rhs.colorComponents.green
            && lhs.colorComponents.blue == rhs.colorComponents.blue
            && lhs.completions == rhs.completions
    }
}

// MARK: - Completion Value Type

struct Completion: Identifiable, Equatable {
    let id: UUID
    var date: Date
    var value: Double
    var note: String?
    /// Stable identifier of the device that created this completion (CRDT origin).
    var deviceID: String?
    /// Precise timestamp of the user action that created this completion (CRDT clock).
    var createdAt: Date?

    init(
        id: UUID = UUID(),
        date: Date,
        value: Double = 1.0,
        note: String? = nil,
        deviceID: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.value = value
        self.note = note
        self.deviceID = deviceID
        self.createdAt = createdAt
    }
}

// MARK: - Core Data Conversions

extension CDHabit {
    func toHabit() -> Habit {
        let completionSet = (completions as? Set<CDCompletion>) ?? []
        let completionArray = completionSet.map { $0.toCompletion() }.sorted { $0.date < $1.date }

        let color = Color(
            red: colorRed,
            green: colorGreen,
            blue: colorBlue
        )

        return Habit(
            id: id ?? UUID(),
            name: name ?? "",
            description: habitDescription ?? "",
            icon: icon ?? "star.fill",
            color: color,
            colorComponents: (red: colorRed, green: colorGreen, blue: colorBlue),
            createdAt: createdAt ?? Date(),
            isArchived: isArchived,
            goalFrequency: Int(goalFrequency),
            goalPeriod: Habit.GoalPeriod(rawValue: goalPeriod ?? "daily") ?? .daily,
            reminderTime: reminderTime,
            sortOrder: Int(sortOrder),
            completions: completionArray
        )
    }

    func update(from habit: Habit) {
        self.name = habit.name
        self.habitDescription = habit.description
        self.icon = HabitIcon.resolve(habit.icon)
        self.colorRed = habit.colorComponents.red
        self.colorGreen = habit.colorComponents.green
        self.colorBlue = habit.colorComponents.blue
        self.isArchived = habit.isArchived
        self.goalFrequency = Int16(habit.goalFrequency)
        self.goalPeriod = habit.goalPeriod.rawValue
        self.reminderTime = habit.reminderTime
        self.sortOrder = Int16(habit.sortOrder)
    }
}

extension CDCompletion {
    func toCompletion() -> Completion {
        Completion(
            id: id ?? UUID(),
            date: date ?? Date(),
            value: value,
            note: note,
            deviceID: deviceID,
            createdAt: createdAt
        )
    }
}

// MARK: - Habit Computed Properties

extension Habit {
    var currentStreak: Int { currentStreak(asOf: Date()) }

    /// Streak of consecutive periods where the goal was met.
    /// For daily habits this counts days; for weekly/monthly it counts weeks/months.
    func currentStreak(asOf today: Date) -> Int {
        let calendar = Calendar.current

        var streak = 0
        var periodStart = goalPeriod.periodStart(for: today, calendar: calendar)

        // If the current period's goal isn't met yet, start checking from the previous period
        if !isPeriodComplete(for: periodStart, calendar: calendar) {
            guard let prev = calendar.date(byAdding: goalPeriod.calendarComponent, value: -1, to: periodStart) else {
                return 0
            }
            periodStart = goalPeriod.periodStart(for: prev, calendar: calendar)
        }

        while isPeriodComplete(for: periodStart, calendar: calendar) {
            streak += 1
            guard let prev = calendar.date(byAdding: goalPeriod.calendarComponent, value: -1, to: periodStart) else {
                break
            }
            periodStart = goalPeriod.periodStart(for: prev, calendar: calendar)
        }

        return streak
    }

    /// Longest run of consecutive periods where the goal was met.
    var longestStreak: Int { longestStreak(asOf: Date()) }

    func longestStreak(asOf today: Date) -> Int {
        let calendar = Calendar.current
        guard !completions.isEmpty else { return 0 }

        // Find the range of periods to check: from effectiveStartDate to today
        let startDate = calendar.startOfDay(for: effectiveStartDate)
        let todayStart = calendar.startOfDay(for: today)
        var periodStart = goalPeriod.periodStart(for: startDate, calendar: calendar)
        let endPeriod = goalPeriod.periodEnd(for: todayStart, calendar: calendar)

        var longest = 0
        var current = 0

        while periodStart < endPeriod {
            if isPeriodComplete(for: periodStart, calendar: calendar) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
            guard let next = calendar.date(byAdding: goalPeriod.calendarComponent, value: 1, to: periodStart) else {
                break
            }
            periodStart = goalPeriod.periodStart(for: next, calendar: calendar)
        }

        return longest
    }

    /// Number of periods where the goal was fully met.
    var totalCompletions: Int { totalCompletions(asOf: Date()) }

    func totalCompletions(asOf today: Date) -> Int {
        let calendar = Calendar.current
        guard !completions.isEmpty else { return 0 }

        // Group completions by their period start date and count periods that met the goal
        var periodCounts: [Date: Int] = [:]
        for completion in completions {
            let periodStart = goalPeriod.periodStart(for: completion.date, calendar: calendar)
            periodCounts[periodStart, default: 0] += 1
        }

        return periodCounts.values.filter { $0 >= goalFrequency }.count
    }

    var completionRate: Double { completionRate(asOf: Date()) }

    /// Fraction of elapsed periods where the goal was met (0.0–1.0).
    func completionRate(asOf today: Date) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: effectiveStartDate)
        let todayStart = calendar.startOfDay(for: today)

        var periodStart = goalPeriod.periodStart(for: startDate, calendar: calendar)
        let endPeriod = goalPeriod.periodEnd(for: todayStart, calendar: calendar)

        var totalPeriods = 0
        var completedPeriods = 0

        while periodStart < endPeriod {
            totalPeriods += 1
            if isPeriodComplete(for: periodStart, calendar: calendar) {
                completedPeriods += 1
            }
            guard let next = calendar.date(byAdding: goalPeriod.calendarComponent, value: 1, to: periodStart) else {
                break
            }
            periodStart = goalPeriod.periodStart(for: next, calendar: calendar)
        }

        guard totalPeriods > 0 else { return 0 }
        return Double(completedPeriods) / Double(totalPeriods)
    }

    func isCompletedOn(date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return completions.contains { calendar.startOfDay(for: $0.date) == targetDay }
    }

    /// Number of completions logged on a specific day (not the whole period)
    func completionsOnDay(_ date: Date, calendar: Calendar = .current) -> Int {
        let targetDay = calendar.startOfDay(for: date)
        return completions.filter { calendar.startOfDay(for: $0.date) == targetDay }.count
    }

    func completionValue(for date: Date) -> Double {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return
            completions
            .filter { calendar.startOfDay(for: $0.date) == targetDay }
            .reduce(0) { $0 + $1.value }
    }

    /// Number of completions within the period containing the given date
    func completionsInPeriod(containing date: Date, calendar: Calendar = .current) -> Int {
        let start = goalPeriod.periodStart(for: date, calendar: calendar)
        let end = goalPeriod.periodEnd(for: date, calendar: calendar)
        return completions.filter { completion in
            let day = calendar.startOfDay(for: completion.date)
            return day >= start && day < end
        }.count
    }

    /// Progress ratio for the period containing the given date (can exceed 1.0)
    func periodProgress(for date: Date, calendar: Calendar = .current) -> Double {
        guard goalFrequency > 0 else { return 0 }
        return Double(completionsInPeriod(containing: date, calendar: calendar)) / Double(goalFrequency)
    }

    /// Whether the goal is fully met for the period containing the given date
    func isPeriodComplete(for date: Date, calendar: Calendar = .current) -> Bool {
        completionsInPeriod(containing: date, calendar: calendar) >= goalFrequency
    }

    /// Returns period-based heatmap data: one entry per period going back N months
    /// and forward by `forwardPeriods` additional periods past the current one.
    func periodHeatmapData(months: Int = 4, forwardPeriods: Int = 0, today: Date = Date()) -> [PeriodData] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        guard let startDate = calendar.date(byAdding: .month, value: -months, to: todayStart) else { return [] }

        let firstPeriodStart = goalPeriod.periodStart(for: startDate, calendar: calendar)

        // End date: end of current period + forwardPeriods more periods
        var endDate = goalPeriod.periodEnd(for: todayStart, calendar: calendar)
        for _ in 0..<forwardPeriods {
            endDate = goalPeriod.periodEnd(for: endDate, calendar: calendar)
        }

        var periods: [PeriodData] = []
        var current = firstPeriodStart

        while current < endDate {
            let end = goalPeriod.periodEnd(for: current, calendar: calendar)
            let count = completions.filter { completion in
                let day = calendar.startOfDay(for: completion.date)
                return day >= current && day < end
            }.count
            let isFuture = current > todayStart
            let isCurrentPeriod = current <= todayStart && end > todayStart
            periods.append(
                PeriodData(
                    periodStart: current,
                    periodEnd: end,
                    completionCount: count,
                    goalFrequency: goalFrequency,
                    isFuture: isFuture,
                    isCurrentPeriod: isCurrentPeriod
                ))
            current = end
        }

        return periods
    }

    /// Compute the cell status for a given day based on the liquid fill spec.
    /// `consecutiveCompletionDays` is the number of consecutive days with completions
    /// immediately before this day. A broke streak requires at least 2 (a real streak).
    func cellStatus(
        for date: Date,
        count: Int,
        goal: Int,
        today: Date,
        consecutiveCompletionDays: Int,
        calendar: Calendar = .current
    ) -> CellStatus {
        let dayStart = calendar.startOfDay(for: date)
        let todayStart = calendar.startOfDay(for: today)
        let habitStart = calendar.startOfDay(for: effectiveStartDate)

        if dayStart > todayStart {
            return .future
        }
        if dayStart == todayStart {
            return .today
        }
        // Check count before habitStart — back-dated completions should still show
        if count > 0 {
            if count >= goal * 2 { return .overComplete }
            if count >= goal { return .complete }
            return .partial
        }
        if dayStart < habitStart {
            return .missed
        }
        // Broke streak requires a real streak (2+ consecutive days) that was broken
        if consecutiveCompletionDays >= 2 {
            return .brokeStreak
        }
        return .missed
    }

    /// Returns a grid of completion data for the heatmap, organized by weeks.
    /// Extends `forwardDays` days past today to show upcoming empty slots.
    func heatmapData(months: Int = 4, forwardDays: Int = 0, today: Date = Date()) -> [[DayData]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: today)
        guard let startDate = calendar.date(byAdding: .month, value: -months, to: today) else { return [] }

        // Align to start of week
        let weekday = calendar.component(.weekday, from: startDate)
        let daysToSubtract = weekday - calendar.firstWeekday
        guard let alignedStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: startDate) else { return [] }

        let endDate = calendar.date(byAdding: .day, value: forwardDays, to: today) ?? today

        // Group completions by day — both value sums and counts
        let grouped = Dictionary(
            grouping: completions,
            by: { calendar.startOfDay(for: $0.date) }
        )
        let completionValues = grouped.mapValues { $0.reduce(0.0) { $0 + $1.value } }
        let completionCounts = grouped.mapValues { $0.count }

        var weeks: [[DayData]] = []
        var currentDate = alignedStart
        var consecutiveCompletionDays = 0

        while currentDate <= endDate {
            var week: [DayData] = []
            for _ in 0..<7 {
                let isPadding = currentDate < alignedStart
                let isFuture = !isPadding && currentDate > today
                let value = (!isPadding && !isFuture) ? (completionValues[currentDate] ?? 0) : 0
                let count = (!isPadding && !isFuture) ? (completionCounts[currentDate] ?? 0) : 0

                let status: CellStatus
                if isPadding {
                    status = .missed
                } else {
                    status = cellStatus(
                        for: currentDate,
                        count: count,
                        goal: goalFrequency,
                        today: today,
                        consecutiveCompletionDays: consecutiveCompletionDays
                    )
                }

                week.append(
                    DayData(
                        date: currentDate,
                        value: value,
                        count: count,
                        isFuture: isFuture,
                        isPadding: isPadding,
                        status: status
                    ))

                // Track consecutive completion days for broke-streak detection
                if !isPadding && !isFuture {
                    if count > 0 {
                        consecutiveCompletionDays += 1
                    } else {
                        consecutiveCompletionDays = 0
                    }
                }

                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDay
            }
            weeks.append(week)
        }

        return weeks
    }
}

// MARK: - Cell Status (Liquid Fill System)

/// The 7 visual states a cell can be in. Each state has a distinct rendering treatment.
enum CellStatus: Equatable {
    /// Days that haven't occurred yet
    case future
    /// The current calendar day
    case today
    /// Days before the habit was created/started
    case missed
    /// A day where the user had been on a streak but logged zero
    case brokeStreak
    /// Some completions but fewer than the goal
    case partial
    /// Exactly met the goal
    case complete
    /// Exceeded the goal
    case overComplete
}

// MARK: - Day Data for Heatmap

struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    /// Number of individual completions logged on this day
    let count: Int
    /// True when this date is after today (an upcoming empty slot to show)
    let isFuture: Bool
    /// True when this date is outside the history window (padding to align the week grid — hide the cell)
    let isPadding: Bool
    /// The computed cell status for liquid fill rendering
    let status: CellStatus

    var isCompleted: Bool { value > 0 }
}

// MARK: - Max Count Helpers

/// Computes the maximum completion count across a grid of DayData weeks.
func maxCount(in weeks: [[DayData]]) -> Int {
    weeks.flatMap { $0 }.reduce(0) { max($0, $1.count) }
}

/// Computes the maximum completion count across PeriodData.
func maxCount(in periods: [PeriodData]) -> Int {
    periods.reduce(0) { max($0, $1.completionCount) }
}

// MARK: - Period Data for Period Heatmap

struct PeriodData: Identifiable {
    let id = UUID()
    let periodStart: Date
    let periodEnd: Date
    let completionCount: Int
    let goalFrequency: Int
    let isFuture: Bool
    let isCurrentPeriod: Bool

    /// Progress ratio (can exceed 1.0 for over-completion)
    var progress: Double {
        guard goalFrequency > 0 else { return 0 }
        return Double(completionCount) / Double(goalFrequency)
    }

    var isComplete: Bool { completionCount >= goalFrequency }

    /// Number of full rotations (0 = incomplete first ring, 1 = one full ring, etc.)
    var fullRotations: Int { goalFrequency > 0 ? completionCount / goalFrequency : 0 }

    /// Fractional progress within the current rotation (0.0 to 1.0)
    var currentRotationProgress: Double {
        guard goalFrequency > 0 else { return 0 }
        let remainder = completionCount % goalFrequency
        if remainder == 0 && completionCount > 0 { return 1.0 }
        return Double(remainder) / Double(goalFrequency)
    }
}

// MARK: - Preset Colors

struct HabitColor: Identifiable {
    let id = UUID()
    let name: String
    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    static let presets: [HabitColor] = [
        HabitColor(name: "Blue", red: 0.25, green: 0.55, blue: 0.95),
        HabitColor(name: "Green", red: 0.20, green: 0.78, blue: 0.35),
        HabitColor(name: "Red", red: 0.95, green: 0.30, blue: 0.30),
        HabitColor(name: "Orange", red: 0.95, green: 0.55, blue: 0.20),
        HabitColor(name: "Purple", red: 0.65, green: 0.35, blue: 0.90),
        HabitColor(name: "Pink", red: 0.95, green: 0.40, blue: 0.65),
        HabitColor(name: "Teal", red: 0.20, green: 0.75, blue: 0.75),
        HabitColor(name: "Yellow", red: 0.90, green: 0.80, blue: 0.20),
        HabitColor(name: "Indigo", red: 0.35, green: 0.35, blue: 0.85),
        HabitColor(name: "Mint", red: 0.40, green: 0.85, blue: 0.70),
        HabitColor(name: "Brown", red: 0.65, green: 0.45, blue: 0.30),
        HabitColor(name: "Cyan", red: 0.30, green: 0.75, blue: 0.95),
    ]
}

// MARK: - Preset Icons

struct HabitIcon {
    static let presets: [String] = [
        "star.fill", "heart.fill", "flame.fill", "bolt.fill",
        "figure.run", "figure.walk", "figure.yoga", "figure.swimming",
        "book.fill", "pencil", "brain.head.profile", "lightbulb.fill",
        "drop.fill", "leaf.fill", "moon.fill", "sun.max.fill",
        "cup.and.saucer.fill", "fork.knife", "pills.fill", "cross.fill",
        "music.note", "paintbrush.fill", "camera.fill", "gamecontroller.fill",
        "bed.double.fill", "alarm.fill", "clock.fill", "calendar",
        "banknote.fill", "cart.fill", "house.fill", "car.fill",
        "airplane", "graduationcap.fill", "dumbbell.fill", "trophy.fill",
        "hand.thumbsup.fill", "face.smiling.fill", "sparkles", "target",
    ]

    static var availablePresets: [String] {
        presets.filter { isSymbolAvailable($0) }
    }

    static func resolve(_ symbolName: String) -> String {
        guard isSymbolAvailable(symbolName) else {
            return availablePresets.first ?? "star.fill"
        }
        return symbolName
    }

    private static func isSymbolAvailable(_ symbolName: String) -> Bool {
        #if canImport(UIKit)
            return UIImage(systemName: symbolName) != nil
        #elseif canImport(AppKit)
            return NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) != nil
        #else
            return true
        #endif
    }

    static func image(_ symbolName: String) -> Image {
        Image(systemName: resolve(symbolName))
    }
}
