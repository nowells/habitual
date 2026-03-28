import SwiftUI

// MARK: - Period Heatmap Grid View

/// A heatmap that shows one cell per period (day/week/month).
/// Daily habits show a GitHub-style grid; weekly/monthly use a horizontal row.
/// Cells use liquid fill: a bottom-up fill with layered intensity levels.
struct PeriodHeatmapGridView: View {
    let habit: Habit
    let months: Int
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let showLabels: Bool
    var onTapPeriod: ((PeriodData) -> Void)?

    @Environment(\.today) private var today

    init(
        habit: Habit,
        months: Int = 12,
        cellSize: CGFloat = 14,
        cellSpacing: CGFloat = 3,
        showLabels: Bool = true,
        onTapPeriod: ((PeriodData) -> Void)? = nil
    ) {
        self.habit = habit
        self.months = months
        self.cellSize = cellSize
        self.cellSpacing = cellSpacing
        self.showLabels = showLabels
        self.onTapPeriod = onTapPeriod
    }

    // Forward periods per type: daily = 1 week, weekly = 5 weeks (~1 month), monthly = 12 months, yearly = 3 years
    private var forwardPeriods: Int {
        switch habit.goalPeriod {
        case .daily: return 0  // forward days handled separately
        case .weekly: return 5
        case .monthly: return 12
        case .yearly: return 3
        }
    }

    private var periodData: [PeriodData] {
        habit.periodHeatmapData(months: months, forwardPeriods: forwardPeriods, today: today)
    }

    var body: some View {
        switch habit.goalPeriod {
        case .daily:
            dailyLayout
        case .weekly:
            weeklyLayout
        case .monthly:
            monthlyLayout
        case .yearly:
            yearlyLayout
        }
    }

    // MARK: - Daily Layout

    private var dailyLayout: some View {
        // 1 week of future empty slots
        let weeks = habit.heatmapData(months: months, forwardDays: 7, today: today)
        let peak = maxCount(in: weeks)
        return HStack(alignment: .top, spacing: cellSpacing) {
            if showLabels {
                // Day-of-week labels with top spacer matching the month label row
                VStack(alignment: .trailing, spacing: 0) {
                    Text("")
                        .font(.system(size: 10))
                        .frame(height: 16)
                        .padding(.bottom, 4)
                    dayOfWeekLabels
                }
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        if showLabels {
                            dailyMonthLabels(weeks: weeks)
                        }

                        HStack(spacing: cellSpacing) {
                            ForEach(weeks.indices, id: \.self) { weekIndex in
                                VStack(spacing: cellSpacing) {
                                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                                        dailyCell(day: weeks[weekIndex][dayIndex], maxCount: peak)
                                    }
                                }
                                .id(weekIndex)
                            }
                        }
                    }
                }
                .onAppear {
                    if let todayWeek = weeks.lastIndex(where: { week in
                        week.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
                    }) {
                        proxy.scrollTo(todayWeek, anchor: .trailing)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dailyCell(day: DayData, maxCount peak: Int) -> some View {
        if day.isPadding {
            Color.clear.frame(width: periodCellSize, height: periodCellSize)
        } else {
            LiquidFillCell(
                count: day.count,
                goal: habit.goalFrequency,
                color: habit.color,
                status: day.status,
                size: periodCellSize,
                maxCount: peak
            )
        }
    }

    // MARK: - Shared Period Constants

    /// All period types (weekly/monthly/yearly) use the same cell size for consistency.
    private var periodCellSize: CGFloat { cellSize * 2.2 }
    private let weeklyRows = 4
    private let monthlyRows = 6
    private let yearlyRows = 4

    // MARK: - Weekly Layout (4 rows)

    private var weeklyLayout: some View {
        periodGridLayout(rows: weeklyRows) { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
    }

    // MARK: - Monthly Layout (6 rows)

    private var monthlyLayout: some View {
        periodGridLayout(rows: monthlyRows) { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
    }

    // MARK: - Yearly Layout (4 rows)

    private var yearlyLayout: some View {
        periodGridLayout(rows: yearlyRows) { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
    }

    /// Shared vertical-stacking grid layout for all period types.
    private func periodGridLayout(rows: Int, labelForDate: @escaping (Date) -> String) -> some View {
        let periods = periodData
        let peak = maxCount(in: periods)
        let columns = stride(from: 0, to: periods.count, by: rows).map { start in
            Array(periods[start..<min(start + rows, periods.count)])
        }
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    if showLabels {
                        HStack(spacing: cellSpacing) {
                            ForEach(columns.indices, id: \.self) { colIndex in
                                if let firstPeriod = columns[colIndex].first {
                                    Text(labelForDate(firstPeriod.periodStart))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .frame(width: periodCellSize)
                                }
                            }
                        }
                    }

                    HStack(spacing: cellSpacing) {
                        ForEach(columns.indices, id: \.self) { colIndex in
                            VStack(spacing: cellSpacing) {
                                ForEach(columns[colIndex]) { period in
                                    periodCell(period, size: periodCellSize, maxCount: peak)
                                }
                                // Pad short last column
                                ForEach(0..<(rows - columns[colIndex].count), id: \.self) { _ in
                                    Color.clear.frame(width: periodCellSize, height: periodCellSize)
                                }
                            }
                            .id(colIndex)
                        }
                    }
                }
            }
            .onAppear {
                if let currentIdx = periods.firstIndex(where: { $0.isCurrentPeriod }) {
                    let colIdx = currentIdx / rows
                    proxy.scrollTo(colIdx, anchor: .trailing)
                }
            }
        }
    }

    // MARK: - Period Cell (weekly/monthly/yearly)

    @ViewBuilder
    private func periodCell(_ period: PeriodData, size: CGFloat? = nil, maxCount peak: Int = 0) -> some View {
        let effectiveSize = size ?? cellSize
        let status = periodCellStatus(period)
        LiquidFillCell(
            count: period.completionCount,
            goal: period.goalFrequency,
            color: habit.color,
            status: status,
            size: effectiveSize,
            maxCount: peak
        )
        .id(period.id)
        .onTapGesture {
            if !period.isFuture {
                onTapPeriod?(period)
            }
        }
    }

    private func periodCellStatus(_ period: PeriodData) -> CellStatus {
        if period.isFuture { return .future }
        if period.isCurrentPeriod {
            return .today
        }
        if period.completionCount == 0 { return .missed }
        if period.completionCount < period.goalFrequency { return .partial }
        if period.completionCount >= period.goalFrequency * 2 { return .overComplete }
        if period.completionCount >= period.goalFrequency { return .complete }
        return .partial
    }

    // MARK: - Labels

    private var dayOfWeekLabels: some View {
        VStack(alignment: .trailing, spacing: cellSpacing) {
            ForEach(dayLabelStrings.indices, id: \.self) { index in
                if index % 2 == 1 {
                    Text(dayLabelStrings[index])
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(height: periodCellSize)
                } else {
                    Text("")
                        .font(.system(size: 9))
                        .frame(height: periodCellSize)
                }
            }
        }
        .frame(width: 20)
    }

    private var dayLabelStrings: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let first = Calendar.current.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    private func dailyMonthLabels(weeks: [[DayData]]) -> some View {
        HStack(spacing: 0) {
            ForEach(monthPositions(from: weeks), id: \.offset) { item in
                Text(item.label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .frame(width: CGFloat(item.span) * (periodCellSize + cellSpacing), alignment: .leading)
            }
        }
    }

    private func monthPositions(from weeks: [[DayData]]) -> [(offset: Int, label: String, span: Int)] {
        guard !weeks.isEmpty else { return [] }
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var positions: [(offset: Int, label: String, span: Int)] = []
        var lastMonth = -1

        for (index, week) in weeks.enumerated() {
            guard let firstDay = week.first else { continue }
            let month = calendar.component(.month, from: firstDay.date)
            if month != lastMonth {
                if !positions.isEmpty {
                    positions[positions.count - 1].span = index - positions[positions.count - 1].offset
                }
                positions.append((offset: index, label: formatter.string(from: firstDay.date), span: 1))
                lastMonth = month
            }
        }
        if let last = positions.last {
            positions[positions.count - 1].span = weeks.count - last.offset
        }

        return positions
    }

}

// MARK: - Compact Period Heatmap (for cards)

/// Automatically fills available width — shows as many periods as fit.
struct CompactPeriodHeatmapView: View {
    let habit: Habit
    let cellSize: CGFloat
    let cellSpacing: CGFloat

    @Environment(\.today) private var today

    init(habit: Habit, cellSize: CGFloat = 10, cellSpacing: CGFloat = 2) {
        self.habit = habit
        self.cellSize = cellSize
        self.cellSpacing = cellSpacing
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            switch habit.goalPeriod {
            case .daily:
                compactDaily(availableWidth: width)
            case .weekly:
                compactWeekly(availableWidth: width)
            case .monthly:
                compactMonthly(availableWidth: width)
            case .yearly:
                compactYearly(availableWidth: width)
            }
        }
        .frame(height: compactHeight)
    }

    /// All period types use the same cell size for consistency (matches yearly).
    private var compactPeriodCellSize: CGFloat { cellSize * 2 }
    private let compactWeeklyRows = 4
    private let compactMonthlyRows = 6
    private let compactYearlyRows = 4

    private var compactHeight: CGFloat {
        let pSize = compactPeriodCellSize
        switch habit.goalPeriod {
        case .daily:
            return 7 * pSize + 6 * cellSpacing
        case .weekly:
            let rows = CGFloat(compactWeeklyRows)
            return rows * pSize + (rows - 1) * cellSpacing
        case .monthly:
            let rows = CGFloat(compactMonthlyRows)
            return rows * pSize + (rows - 1) * cellSpacing
        case .yearly:
            let rows = CGFloat(compactYearlyRows)
            return rows * pSize + (rows - 1) * cellSpacing
        }
    }

    // MARK: - Daily

    private func compactDaily(availableWidth: CGFloat) -> some View {
        let pSize = compactPeriodCellSize
        let columnWidth = pSize + cellSpacing
        let maxWeeks = max(1, Int(availableWidth / columnWidth))
        let months = max(1, Int(ceil(Double(maxWeeks) / 4.33)))
        let weeks = habit.heatmapData(months: months, forwardDays: 7, today: today)
        let visibleWeeks = Array(weeks.suffix(maxWeeks))
        let peak = maxCount(in: visibleWeeks)
        return HStack(spacing: cellSpacing) {
            ForEach(visibleWeeks.indices, id: \.self) { weekIndex in
                VStack(spacing: cellSpacing) {
                    ForEach(visibleWeeks[weekIndex].indices, id: \.self) { dayIndex in
                        compactDailyCell(day: visibleWeeks[weekIndex][dayIndex], maxCount: peak)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private func compactDailyCell(day: DayData, maxCount peak: Int) -> some View {
        let pSize = compactPeriodCellSize
        if day.isPadding {
            Color.clear.frame(width: pSize, height: pSize)
        } else {
            LiquidFillCell(
                count: day.count,
                goal: habit.goalFrequency,
                color: habit.color,
                status: day.status,
                size: pSize,
                maxCount: peak
            )
        }
    }

    // MARK: - Weekly (4 rows)

    private func compactWeekly(availableWidth: CGFloat) -> some View {
        let pSize = compactPeriodCellSize
        let columnWidth = pSize + cellSpacing
        let maxColumns = max(1, Int(availableWidth / columnWidth))
        let maxPeriods = maxColumns * compactWeeklyRows
        let months = max(1, Int(ceil(Double(maxPeriods) / 4.33)))
        let periods = habit.periodHeatmapData(months: months, forwardPeriods: 5, today: today)
        let visiblePeriods = Array(periods.suffix(maxPeriods))
        let peak = maxCount(in: visiblePeriods)
        let columns = stride(from: 0, to: visiblePeriods.count, by: compactWeeklyRows).map { start in
            Array(visiblePeriods[start..<min(start + compactWeeklyRows, visiblePeriods.count)])
        }
        return HStack(spacing: cellSpacing) {
            ForEach(columns.indices, id: \.self) { colIndex in
                VStack(spacing: cellSpacing) {
                    ForEach(columns[colIndex]) { period in
                        compactPeriodCell(period, size: pSize, maxCount: peak)
                    }
                    ForEach(0..<(compactWeeklyRows - columns[colIndex].count), id: \.self) { _ in
                        Color.clear.frame(width: pSize, height: pSize)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Monthly (6 rows)

    private func compactMonthly(availableWidth: CGFloat) -> some View {
        let pSize = compactPeriodCellSize
        let columnWidth = pSize + cellSpacing
        let maxColumns = max(1, Int(availableWidth / columnWidth))
        let maxPeriods = maxColumns * compactMonthlyRows
        let backMonths = max(1, maxPeriods)
        let forwardMonths = min(12, maxPeriods / 3)
        let periods = habit.periodHeatmapData(months: backMonths, forwardPeriods: forwardMonths, today: today)
        let visiblePeriods = Array(periods.suffix(maxPeriods))
        let peak = maxCount(in: visiblePeriods)
        let columns = stride(from: 0, to: visiblePeriods.count, by: compactMonthlyRows).map { start in
            Array(visiblePeriods[start..<min(start + compactMonthlyRows, visiblePeriods.count)])
        }
        return HStack(spacing: cellSpacing) {
            ForEach(columns.indices, id: \.self) { colIndex in
                VStack(spacing: cellSpacing) {
                    ForEach(columns[colIndex]) { period in
                        compactPeriodCell(period, size: pSize, maxCount: peak)
                    }
                    ForEach(0..<(compactMonthlyRows - columns[colIndex].count), id: \.self) { _ in
                        Color.clear.frame(width: pSize, height: pSize)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Yearly (4 rows)

    private func compactYearly(availableWidth: CGFloat) -> some View {
        let pSize = compactPeriodCellSize
        let columnWidth = pSize + cellSpacing
        let maxColumns = max(1, Int(availableWidth / columnWidth))
        let maxPeriods = maxColumns * compactYearlyRows
        let backMonths = max(12, maxPeriods * 12)
        let forwardYears = min(3, maxPeriods / 3)
        let periods = habit.periodHeatmapData(months: backMonths, forwardPeriods: forwardYears, today: today)
        let visiblePeriods = Array(periods.suffix(maxPeriods))
        let peak = maxCount(in: visiblePeriods)
        let columns = stride(from: 0, to: visiblePeriods.count, by: compactYearlyRows).map { start in
            Array(visiblePeriods[start..<min(start + compactYearlyRows, visiblePeriods.count)])
        }
        return HStack(spacing: cellSpacing) {
            ForEach(columns.indices, id: \.self) { colIndex in
                VStack(spacing: cellSpacing) {
                    ForEach(columns[colIndex]) { period in
                        compactPeriodCell(period, size: pSize, maxCount: peak)
                    }
                    ForEach(0..<(compactYearlyRows - columns[colIndex].count), id: \.self) { _ in
                        Color.clear.frame(width: pSize, height: pSize)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Period Cell

    @ViewBuilder
    private func compactPeriodCell(_ period: PeriodData, size: CGFloat? = nil, maxCount peak: Int = 0) -> some View {
        let effectiveSize = size ?? cellSize
        let status = compactPeriodStatus(period)
        LiquidFillCell(
            count: period.completionCount,
            goal: period.goalFrequency,
            color: habit.color,
            status: status,
            size: effectiveSize,
            maxCount: peak
        )
    }

    private func compactPeriodStatus(_ period: PeriodData) -> CellStatus {
        if period.isFuture { return .future }
        if period.isCurrentPeriod { return .today }
        if period.completionCount == 0 { return .missed }
        if period.completionCount < period.goalFrequency { return .partial }
        if period.completionCount >= period.goalFrequency * 2 { return .overComplete }
        if period.completionCount >= period.goalFrequency { return .complete }
        return .partial
    }
}

#Preview {
    let store = HabitStore(context: PersistenceController.preview.container.viewContext)
    let habit = store.habits.first ?? Habit(name: "Preview", goalFrequency: 3, goalPeriod: .weekly)

    return VStack {
        PeriodHeatmapGridView(habit: habit)
            .padding()
        CompactPeriodHeatmapView(habit: habit)
            .padding()
    }
}
