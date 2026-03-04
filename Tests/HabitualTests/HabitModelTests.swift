import XCTest
@testable import HabitualCore

final class HabitModelTests: XCTestCase {

    // MARK: - Test Helpers

    private let calendar = Calendar.current

    private func makeDate(daysAgo: Int) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))!
    }

    private func makeCompletion(daysAgo: Int, value: Double = 1.0) -> Completion {
        Completion(date: makeDate(daysAgo: daysAgo), value: value)
    }

    private func makeHabit(
        name: String = "Test",
        completions: [Completion] = [],
        createdAt: Date? = nil,
        goalFrequency: Int = 1,
        goalPeriod: Habit.GoalPeriod = .daily
    ) -> Habit {
        Habit(
            name: name,
            createdAt: createdAt ?? calendar.date(byAdding: .day, value: -30, to: Date())!,
            goalFrequency: goalFrequency,
            goalPeriod: goalPeriod,
            completions: completions
        )
    }

    // MARK: - Initialization Tests

    func testHabitDefaultValues() {
        let habit = Habit(name: "Exercise")
        XCTAssertEqual(habit.name, "Exercise")
        XCTAssertEqual(habit.description, "")
        XCTAssertEqual(habit.icon, "star.fill")
        XCTAssertFalse(habit.isArchived)
        XCTAssertEqual(habit.goalFrequency, 1)
        XCTAssertEqual(habit.goalPeriod, .daily)
        XCTAssertNil(habit.reminderTime)
        XCTAssertEqual(habit.sortOrder, 0)
        XCTAssertTrue(habit.completions.isEmpty)
    }

    func testHabitCustomValues() {
        let reminder = Date()
        let habit = Habit(
            name: "Read",
            description: "Read 30 minutes",
            icon: "book.fill",
            goalFrequency: 3,
            goalPeriod: .weekly,
            reminderTime: reminder,
            sortOrder: 5
        )
        XCTAssertEqual(habit.name, "Read")
        XCTAssertEqual(habit.description, "Read 30 minutes")
        XCTAssertEqual(habit.icon, "book.fill")
        XCTAssertEqual(habit.goalFrequency, 3)
        XCTAssertEqual(habit.goalPeriod, .weekly)
        XCTAssertNotNil(habit.reminderTime)
        XCTAssertEqual(habit.sortOrder, 5)
    }

    func testHabitEquality() {
        let id = UUID()
        let habit1 = Habit(id: id, name: "Exercise")
        let habit2 = Habit(id: id, name: "Different Name")
        let habit3 = Habit(name: "Exercise")

        XCTAssertEqual(habit1, habit2, "Habits with same ID should be equal")
        XCTAssertNotEqual(habit1, habit3, "Habits with different IDs should not be equal")
    }

    // MARK: - GoalPeriod Tests

    func testGoalPeriodDisplayNames() {
        XCTAssertEqual(Habit.GoalPeriod.daily.displayName, "Daily")
        XCTAssertEqual(Habit.GoalPeriod.weekly.displayName, "Weekly")
        XCTAssertEqual(Habit.GoalPeriod.monthly.displayName, "Monthly")
    }

    func testGoalPeriodLabels() {
        XCTAssertEqual(Habit.GoalPeriod.daily.periodLabel, "day")
        XCTAssertEqual(Habit.GoalPeriod.weekly.periodLabel, "week")
        XCTAssertEqual(Habit.GoalPeriod.monthly.periodLabel, "month")
    }

    func testGoalPeriodRawValues() {
        XCTAssertEqual(Habit.GoalPeriod.daily.rawValue, "daily")
        XCTAssertEqual(Habit.GoalPeriod.weekly.rawValue, "weekly")
        XCTAssertEqual(Habit.GoalPeriod.monthly.rawValue, "monthly")
    }

    func testGoalPeriodFromRawValue() {
        XCTAssertEqual(Habit.GoalPeriod(rawValue: "daily"), .daily)
        XCTAssertEqual(Habit.GoalPeriod(rawValue: "weekly"), .weekly)
        XCTAssertEqual(Habit.GoalPeriod(rawValue: "monthly"), .monthly)
        XCTAssertNil(Habit.GoalPeriod(rawValue: "invalid"))
    }

    func testGoalPeriodAllCases() {
        XCTAssertEqual(Habit.GoalPeriod.allCases.count, 3)
        XCTAssertTrue(Habit.GoalPeriod.allCases.contains(.daily))
        XCTAssertTrue(Habit.GoalPeriod.allCases.contains(.weekly))
        XCTAssertTrue(Habit.GoalPeriod.allCases.contains(.monthly))
    }

    // MARK: - Current Streak Tests

    func testCurrentStreakNoCompletions() {
        let habit = makeHabit()
        XCTAssertEqual(habit.currentStreak, 0)
    }

    func testCurrentStreakCompletedToday() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
        ])
        XCTAssertEqual(habit.currentStreak, 1)
    }

    func testCurrentStreakConsecutiveDaysIncludingToday() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
            makeCompletion(daysAgo: 1),
            makeCompletion(daysAgo: 2),
        ])
        XCTAssertEqual(habit.currentStreak, 3)
    }

    func testCurrentStreakConsecutiveDaysFromYesterday() {
        // Not completed today, but completed yesterday and before
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 1),
            makeCompletion(daysAgo: 2),
            makeCompletion(daysAgo: 3),
        ])
        XCTAssertEqual(habit.currentStreak, 3)
    }

    func testCurrentStreakBrokenByGap() {
        // Today + yesterday, then gap, then more completions
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
            makeCompletion(daysAgo: 1),
            // gap on day 2
            makeCompletion(daysAgo: 3),
            makeCompletion(daysAgo: 4),
        ])
        XCTAssertEqual(habit.currentStreak, 2)
    }

    func testCurrentStreakNotCompletedTodayOrYesterday() {
        // Only completed 2+ days ago — streak should be 0
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 2),
            makeCompletion(daysAgo: 3),
        ])
        XCTAssertEqual(habit.currentStreak, 0)
    }

    func testCurrentStreakSingleDayYesterday() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 1),
        ])
        XCTAssertEqual(habit.currentStreak, 1)
    }

    func testCurrentStreakDuplicateCompletionsSameDay() {
        // Multiple completions on the same day should not inflate streak
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
            Completion(date: makeDate(daysAgo: 0), value: 0.5),
            makeCompletion(daysAgo: 1),
        ])
        XCTAssertEqual(habit.currentStreak, 2)
    }

    // MARK: - Longest Streak Tests

    func testLongestStreakNoCompletions() {
        let habit = makeHabit()
        XCTAssertEqual(habit.longestStreak, 0)
    }

    func testLongestStreakSingleCompletion() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 5),
        ])
        XCTAssertEqual(habit.longestStreak, 1)
    }

    func testLongestStreakSingleBlock() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 3),
            makeCompletion(daysAgo: 4),
            makeCompletion(daysAgo: 5),
            makeCompletion(daysAgo: 6),
        ])
        XCTAssertEqual(habit.longestStreak, 4)
    }

    func testLongestStreakMultipleBlocks() {
        // Block 1: 3 days, Block 2: 5 days
        let habit = makeHabit(completions: [
            // Block 1 (recent, 3 days)
            makeCompletion(daysAgo: 0),
            makeCompletion(daysAgo: 1),
            makeCompletion(daysAgo: 2),
            // gap
            // Block 2 (older, 5 days)
            makeCompletion(daysAgo: 10),
            makeCompletion(daysAgo: 11),
            makeCompletion(daysAgo: 12),
            makeCompletion(daysAgo: 13),
            makeCompletion(daysAgo: 14),
        ])
        XCTAssertEqual(habit.longestStreak, 5)
    }

    func testLongestStreakCurrentIsLongest() {
        let habit = makeHabit(completions: [
            // Current streak is the longest
            makeCompletion(daysAgo: 0),
            makeCompletion(daysAgo: 1),
            makeCompletion(daysAgo: 2),
            makeCompletion(daysAgo: 3),
            makeCompletion(daysAgo: 4),
            // gap
            makeCompletion(daysAgo: 10),
            makeCompletion(daysAgo: 11),
        ])
        XCTAssertEqual(habit.longestStreak, 5)
    }

    func testLongestStreakDuplicateDates() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
            Completion(date: makeDate(daysAgo: 0), value: 0.5),
            makeCompletion(daysAgo: 1),
            makeCompletion(daysAgo: 2),
        ])
        XCTAssertEqual(habit.longestStreak, 3)
    }

    // MARK: - Total Completions Tests

    func testTotalCompletionsEmpty() {
        let habit = makeHabit()
        XCTAssertEqual(habit.totalCompletions, 0)
    }

    func testTotalCompletionsCount() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
            makeCompletion(daysAgo: 1),
            makeCompletion(daysAgo: 5),
        ])
        XCTAssertEqual(habit.totalCompletions, 3)
    }

    // MARK: - Completion Rate Tests

    func testCompletionRateNoCompletions() {
        let habit = makeHabit(createdAt: makeDate(daysAgo: 10))
        XCTAssertEqual(habit.completionRate, 0.0, accuracy: 0.001)
    }

    func testCompletionRateAllDays() {
        let createdAt = makeDate(daysAgo: 4) // 5 days total (0,1,2,3,4)
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
            makeCompletion(daysAgo: 1),
            makeCompletion(daysAgo: 2),
            makeCompletion(daysAgo: 3),
            makeCompletion(daysAgo: 4),
        ], createdAt: createdAt)
        XCTAssertEqual(habit.completionRate, 1.0, accuracy: 0.001)
    }

    func testCompletionRatePartial() {
        let createdAt = makeDate(daysAgo: 9) // 10 days total
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
            makeCompletion(daysAgo: 2),
            makeCompletion(daysAgo: 5),
        ], createdAt: createdAt)
        XCTAssertEqual(habit.completionRate, 0.3, accuracy: 0.001)
    }

    func testCompletionRateCreatedToday() {
        let habit = makeHabit(
            completions: [makeCompletion(daysAgo: 0)],
            createdAt: calendar.startOfDay(for: Date())
        )
        // 1 day total, 1 completion = 100%
        XCTAssertEqual(habit.completionRate, 1.0, accuracy: 0.001)
    }

    // MARK: - isCompletedOn Tests

    func testIsCompletedOnTrue() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
            makeCompletion(daysAgo: 3),
        ])
        XCTAssertTrue(habit.isCompletedOn(date: Date()))
        XCTAssertTrue(habit.isCompletedOn(date: makeDate(daysAgo: 3)))
    }

    func testIsCompletedOnFalse() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
        ])
        XCTAssertFalse(habit.isCompletedOn(date: makeDate(daysAgo: 1)))
        XCTAssertFalse(habit.isCompletedOn(date: makeDate(daysAgo: 5)))
    }

    func testIsCompletedOnSameDayDifferentTime() {
        // Completion at start of day, check at a later time
        let startOfToday = calendar.startOfDay(for: Date())
        let laterToday = calendar.date(byAdding: .hour, value: 14, to: startOfToday)!

        let habit = makeHabit(completions: [
            Completion(date: startOfToday),
        ])
        XCTAssertTrue(habit.isCompletedOn(date: laterToday))
    }

    func testIsCompletedOnNoCompletions() {
        let habit = makeHabit()
        XCTAssertFalse(habit.isCompletedOn(date: Date()))
    }

    // MARK: - completionValue Tests

    func testCompletionValueDefault() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
        ])
        XCTAssertEqual(habit.completionValue(for: Date()), 1.0, accuracy: 0.001)
    }

    func testCompletionValueMultipleOnSameDay() {
        let today = calendar.startOfDay(for: Date())
        let habit = makeHabit(completions: [
            Completion(date: today, value: 0.5),
            Completion(date: today, value: 0.3),
        ])
        XCTAssertEqual(habit.completionValue(for: Date()), 0.8, accuracy: 0.001)
    }

    func testCompletionValueNoCompletion() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 1),
        ])
        XCTAssertEqual(habit.completionValue(for: Date()), 0.0, accuracy: 0.001)
    }

    // MARK: - Heatmap Data Tests

    func testHeatmapDataReturnsWeeks() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
            makeCompletion(daysAgo: 5),
        ])
        let data = habit.heatmapData(months: 1)

        XCTAssertFalse(data.isEmpty, "Heatmap data should not be empty")

        // Each week should have exactly 7 days
        for week in data {
            XCTAssertEqual(week.count, 7, "Each week should contain 7 days")
        }
    }

    func testHeatmapDataContainsCompletions() {
        let habit = makeHabit(completions: [
            makeCompletion(daysAgo: 0),
        ])
        let data = habit.heatmapData(months: 1)
        let allDays = data.flatMap { $0 }

        let today = calendar.startOfDay(for: Date())
        let todayData = allDays.first { calendar.isDate($0.date, inSameDayAs: today) }

        XCTAssertNotNil(todayData, "Today should be in heatmap data")
        XCTAssertTrue(todayData!.isCompleted, "Today should show as completed")
    }

    func testHeatmapDataFutureDays() {
        let habit = makeHabit()
        let data = habit.heatmapData(months: 1)
        let allDays = data.flatMap { $0 }
        let today = calendar.startOfDay(for: Date())

        let futureDays = allDays.filter { $0.date > today }
        for day in futureDays {
            XCTAssertTrue(day.isFuture, "Days after today should be marked as future")
        }
    }

    func testHeatmapDataMonthRange() {
        let habit = makeHabit()

        let data1 = habit.heatmapData(months: 1)
        let data3 = habit.heatmapData(months: 3)
        let data6 = habit.heatmapData(months: 6)

        // Longer ranges should have more weeks
        XCTAssertGreaterThan(data3.count, data1.count)
        XCTAssertGreaterThan(data6.count, data3.count)
    }

    func testHeatmapDataStartsOnWeekBoundary() {
        let habit = makeHabit()
        let data = habit.heatmapData(months: 1)

        guard let firstWeek = data.first, let firstDay = firstWeek.first else {
            XCTFail("Heatmap data should have at least one week")
            return
        }

        let weekday = calendar.component(.weekday, from: firstDay.date)
        XCTAssertEqual(weekday, calendar.firstWeekday, "First day should align with calendar's first weekday")
    }

    // MARK: - DayData Tests

    func testDayDataIsCompleted() {
        let completedDay = DayData(date: Date(), value: 1.0, isFuture: false)
        XCTAssertTrue(completedDay.isCompleted)

        let partialDay = DayData(date: Date(), value: 0.5, isFuture: false)
        XCTAssertTrue(partialDay.isCompleted)

        let emptyDay = DayData(date: Date(), value: 0.0, isFuture: false)
        XCTAssertFalse(emptyDay.isCompleted)
    }

    // MARK: - Completion Tests

    func testCompletionDefaultValues() {
        let date = Date()
        let completion = Completion(date: date)
        XCTAssertEqual(completion.value, 1.0)
        XCTAssertNil(completion.note)
        XCTAssertEqual(completion.date, date)
    }

    func testCompletionWithNote() {
        let completion = Completion(date: Date(), value: 1.0, note: "Great workout!")
        XCTAssertEqual(completion.note, "Great workout!")
    }

    // MARK: - HabitColor Tests

    func testHabitColorPresetCount() {
        XCTAssertEqual(HabitColor.presets.count, 12)
    }

    func testHabitColorPresetNames() {
        let names = HabitColor.presets.map { $0.name }
        XCTAssertTrue(names.contains("Blue"))
        XCTAssertTrue(names.contains("Green"))
        XCTAssertTrue(names.contains("Red"))
        XCTAssertTrue(names.contains("Orange"))
        XCTAssertTrue(names.contains("Purple"))
        XCTAssertTrue(names.contains("Pink"))
        XCTAssertTrue(names.contains("Teal"))
        XCTAssertTrue(names.contains("Yellow"))
        XCTAssertTrue(names.contains("Indigo"))
        XCTAssertTrue(names.contains("Mint"))
        XCTAssertTrue(names.contains("Brown"))
        XCTAssertTrue(names.contains("Cyan"))
    }

    func testHabitColorRGBRanges() {
        for preset in HabitColor.presets {
            XCTAssertGreaterThanOrEqual(preset.red, 0.0, "\(preset.name) red should be >= 0")
            XCTAssertLessThanOrEqual(preset.red, 1.0, "\(preset.name) red should be <= 1")
            XCTAssertGreaterThanOrEqual(preset.green, 0.0, "\(preset.name) green should be >= 0")
            XCTAssertLessThanOrEqual(preset.green, 1.0, "\(preset.name) green should be <= 1")
            XCTAssertGreaterThanOrEqual(preset.blue, 0.0, "\(preset.name) blue should be >= 0")
            XCTAssertLessThanOrEqual(preset.blue, 1.0, "\(preset.name) blue should be <= 1")
        }
    }

    // MARK: - HabitIcon Tests

    func testHabitIconPresetCount() {
        XCTAssertEqual(HabitIcon.presets.count, 40)
    }

    func testHabitIconPresetsNotEmpty() {
        for icon in HabitIcon.presets {
            XCTAssertFalse(icon.isEmpty, "Icon name should not be empty")
        }
    }

    func testHabitIconPresetsUnique() {
        let uniqueIcons = Set(HabitIcon.presets)
        XCTAssertEqual(uniqueIcons.count, HabitIcon.presets.count, "All icon presets should be unique")
    }
}
