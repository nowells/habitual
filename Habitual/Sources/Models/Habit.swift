import SwiftUI
import CoreData
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

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            }
        }

        var periodLabel: String {
            switch self {
            case .daily: return "day"
            case .weekly: return "week"
            case .monthly: return "month"
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
            }
        }

        /// Calendar component for stepping through periods
        var calendarComponent: Calendar.Component {
            switch self {
            case .daily: return .day
            case .weekly: return .weekOfYear
            case .monthly: return .month
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

    static func == (lhs: Habit, rhs: Habit) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Completion Value Type

struct Completion: Identifiable, Equatable {
    let id: UUID
    var date: Date
    var value: Double
    var note: String?

    init(id: UUID = UUID(), date: Date, value: Double = 1.0, note: String? = nil) {
        self.id = id
        self.date = date
        self.value = value
        self.note = note
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
            note: note
        )
    }
}

// MARK: - Habit Computed Properties

extension Habit {
    var currentStreak: Int { currentStreak(asOf: Date()) }

    func currentStreak(asOf today: Date) -> Int {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        let completionDates = Set(completions.map { calendar.startOfDay(for: $0.date) })

        var streak = 0
        var checkDate = todayStart

        // Check if today is completed, if not start from yesterday
        if !completionDates.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while completionDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current
        let sortedDates = completions.map { calendar.startOfDay(for: $0.date) }.sorted()
        let uniqueDates = Array(Set(sortedDates)).sorted()

        guard !uniqueDates.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<uniqueDates.count {
            let daysBetween = calendar.dateComponents([.day], from: uniqueDates[i - 1], to: uniqueDates[i]).day ?? 0
            if daysBetween == 1 {
                current += 1
                longest = max(longest, current)
            } else if daysBetween > 1 {
                current = 1
            }
        }

        return longest
    }

    var totalCompletions: Int {
        completions.count
    }

    var completionRate: Double { completionRate(asOf: Date()) }

    func completionRate(asOf today: Date) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: createdAt)
        let todayStart = calendar.startOfDay(for: today)
        let totalDays = max(1, (calendar.dateComponents([.day], from: startDate, to: todayStart).day ?? 0) + 1)
        return Double(totalCompletions) / Double(totalDays)
    }

    func isCompletedOn(date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return completions.contains { calendar.startOfDay(for: $0.date) == targetDay }
    }

    func completionValue(for date: Date) -> Double {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return completions
            .filter { calendar.startOfDay(for: $0.date) == targetDay }
            .reduce(0) { $0 + $1.value }
    }

    /// Number of completions within the period containing the given date
    func completionsInPeriod(containing date: Date, calendar: Calendar = .current) -> Int {
        let start = goalPeriod.periodStart(for: date, calendar: calendar)
        let end = goalPeriod.periodEnd(for: date, calendar: calendar)
        return completions.filter { completion in
            let d = calendar.startOfDay(for: completion.date)
            return d >= start && d < end
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
                let d = calendar.startOfDay(for: completion.date)
                return d >= current && d < end
            }.count
            let isFuture = current > todayStart
            let isCurrentPeriod = current <= todayStart && end > todayStart
            periods.append(PeriodData(
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

        let completionDates = Dictionary(
            grouping: completions,
            by: { calendar.startOfDay(for: $0.date) }
        ).mapValues { $0.reduce(0.0) { $0 + $1.value } }

        var weeks: [[DayData]] = []
        var currentDate = alignedStart

        while currentDate <= endDate {
            var week: [DayData] = []
            for _ in 0..<7 {
                let isPadding = currentDate < alignedStart
                let isFuture = !isPadding && currentDate > today
                let value = (!isPadding && !isFuture) ? (completionDates[currentDate] ?? 0) : 0
                week.append(DayData(date: currentDate, value: value, isFuture: isFuture, isPadding: isPadding))
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDay
            }
            weeks.append(week)
        }

        return weeks
    }
}

// MARK: - Day Data for Heatmap

struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    /// True when this date is after today (an upcoming empty slot to show)
    let isFuture: Bool
    /// True when this date is outside the history window (padding to align the week grid — hide the cell)
    let isPadding: Bool

    var isCompleted: Bool { value > 0 }
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
