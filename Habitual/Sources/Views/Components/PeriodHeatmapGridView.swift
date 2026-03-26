import SwiftUI

// MARK: - Period Heatmap Grid View

/// A heatmap that shows one cell per period (day/week/month).
/// Daily habits show a GitHub-style grid; weekly/monthly use a horizontal row.
/// Cells use a pie fill: the rounded square fills clockwise as completions accumulate.
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

    // Forward periods per type: daily = 1 week, weekly = 5 weeks (~1 month), monthly = 12 months
    private var forwardPeriods: Int {
        switch habit.goalPeriod {
        case .daily: return 0      // forward days handled separately
        case .weekly: return 5
        case .monthly: return 12
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
        }
    }

    // MARK: - Daily Layout

    private var dailyLayout: some View {
        // 1 week of future empty slots
        let weeks = habit.heatmapData(months: months, forwardDays: 7, today: today)
        return VStack(alignment: .leading, spacing: 4) {
            if showLabels {
                dailyMonthLabels(weeks: weeks)
            }

            HStack(alignment: .top, spacing: cellSpacing) {
                if showLabels {
                    dayOfWeekLabels
                }

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: cellSpacing) {
                            ForEach(weeks.indices, id: \.self) { weekIndex in
                                VStack(spacing: cellSpacing) {
                                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                                        dailyCell(day: weeks[weekIndex][dayIndex])
                                    }
                                }
                                .id(weekIndex)
                            }
                        }
                    }
                    .onAppear {
                        // Find the week containing today and scroll to it
                        if let todayWeek = weeks.lastIndex(where: { week in
                            week.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
                        }) {
                            proxy.scrollTo(todayWeek, anchor: .trailing)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dailyCell(day: DayData) -> some View {
        if day.isPadding {
            Color.clear.frame(width: cellSize, height: cellSize)
        } else {
            let isToday = Calendar.current.isDateInToday(day.date)
            ZStack {
                RoundedRectangle(cornerRadius: cellSize * 0.2)
                    .fill(day.isFuture ? Color.systemGray5.opacity(0.35) : Color.systemGray5)
                    .frame(width: cellSize, height: cellSize)

                if !day.isFuture {
                    let count = habit.completionsInPeriod(containing: day.date)
                    if count > 0 {
                        PieProgressFill(
                            completionCount: count,
                            goalFrequency: habit.goalFrequency,
                            baseColor: habit.color,
                            size: cellSize
                        )
                    }
                }

                if isToday {
                    RoundedRectangle(cornerRadius: cellSize * 0.2)
                        .strokeBorder(habit.color, lineWidth: 1)
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
    }

    // MARK: - Weekly Layout

    private var weeklyLayout: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showLabels {
                weeklyLabels
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cellSpacing) {
                        ForEach(periodData) { period in
                            periodCell(period)
                        }
                    }
                }
                .onAppear {
                    if let current = periodData.first(where: { $0.isCurrentPeriod }) {
                        proxy.scrollTo(current.id, anchor: .trailing)
                    }
                }
            }
        }
    }

    // MARK: - Monthly Layout

    private var monthlyLayout: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showLabels {
                monthlyLabels
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cellSpacing + 2) {
                        ForEach(periodData) { period in
                            periodCell(period, size: cellSize * 1.8)
                        }
                    }
                }
                .onAppear {
                    if let current = periodData.first(where: { $0.isCurrentPeriod }) {
                        proxy.scrollTo(current.id, anchor: .trailing)
                    }
                }
            }
        }
    }

    // MARK: - Period Cell (weekly/monthly)

    @ViewBuilder
    private func periodCell(_ period: PeriodData, size: CGFloat? = nil) -> some View {
        let effectiveSize = size ?? cellSize
        ZStack {
            RoundedRectangle(cornerRadius: effectiveSize * 0.2)
                .fill(period.isFuture ? Color.systemGray5.opacity(0.35) : Color.systemGray5)
                .frame(width: effectiveSize, height: effectiveSize)

            if !period.isFuture && period.completionCount > 0 {
                PieProgressFill(
                    completionCount: period.completionCount,
                    goalFrequency: period.goalFrequency,
                    baseColor: habit.color,
                    size: effectiveSize
                )
            }

            if period.isCurrentPeriod {
                RoundedRectangle(cornerRadius: effectiveSize * 0.2)
                    .strokeBorder(habit.color, lineWidth: 1.5)
                    .frame(width: effectiveSize, height: effectiveSize)
            }
        }
        .onTapGesture {
            if !period.isFuture {
                onTapPeriod?(period)
            }
        }
    }

    // MARK: - Labels

    private var dayOfWeekLabels: some View {
        VStack(alignment: .trailing, spacing: cellSpacing) {
            ForEach(dayLabelStrings.indices, id: \.self) { index in
                if index % 2 == 1 {
                    Text(dayLabelStrings[index])
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(height: cellSize)
                } else {
                    Text("")
                        .font(.system(size: 9))
                        .frame(height: cellSize)
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
            if showLabels { Spacer().frame(width: 24) }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(monthPositions(from: weeks), id: \.offset) { item in
                        Text(item.label)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .frame(width: CGFloat(item.span) * (cellSize + cellSpacing), alignment: .leading)
                    }
                }
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

    private var weeklyLabels: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(weeklyLabelPositions, id: \.offset) { item in
                    Text(item.label)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(width: CGFloat(item.span) * (cellSize + cellSpacing), alignment: .leading)
                }
            }
        }
    }

    private var weeklyLabelPositions: [(offset: Int, label: String, span: Int)] {
        guard !periodData.isEmpty else { return [] }
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var positions: [(offset: Int, label: String, span: Int)] = []
        var lastMonth = -1

        for (index, period) in periodData.enumerated() {
            let month = calendar.component(.month, from: period.periodStart)
            if month != lastMonth {
                if !positions.isEmpty {
                    positions[positions.count - 1].span = index - positions[positions.count - 1].offset
                }
                positions.append((offset: index, label: formatter.string(from: period.periodStart), span: 1))
                lastMonth = month
            }
        }
        if let last = positions.last {
            positions[positions.count - 1].span = periodData.count - last.offset
        }

        return positions
    }

    private var monthlyLabels: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: cellSpacing + 2) {
                ForEach(periodData) { period in
                    Text(monthLabel(for: period.periodStart))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(width: cellSize * 1.8)
                }
            }
        }
    }

    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
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
            }
        }
        .frame(height: compactHeight)
    }

    private var compactHeight: CGFloat {
        switch habit.goalPeriod {
        case .daily:
            return 7 * cellSize + 6 * cellSpacing
        case .weekly:
            return cellSize
        case .monthly:
            return cellSize * 1.5
        }
    }

    // MARK: - Daily

    private func compactDaily(availableWidth: CGFloat) -> some View {
        let columnWidth = cellSize + cellSpacing
        let maxWeeks = max(1, Int(availableWidth / columnWidth))
        // Convert weeks to months (roughly 4.33 weeks/month), request enough data + 1 week forward
        let months = max(1, Int(ceil(Double(maxWeeks) / 4.33)))
        let weeks = habit.heatmapData(months: months, forwardDays: 7, today: today)
        // Take only as many weeks as fit
        let visibleWeeks = Array(weeks.suffix(maxWeeks))
        return HStack(spacing: cellSpacing) {
            ForEach(visibleWeeks.indices, id: \.self) { weekIndex in
                VStack(spacing: cellSpacing) {
                    ForEach(visibleWeeks[weekIndex].indices, id: \.self) { dayIndex in
                        compactDailyCell(day: visibleWeeks[weekIndex][dayIndex])
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private func compactDailyCell(day: DayData) -> some View {
        if day.isPadding {
            Color.clear.frame(width: cellSize, height: cellSize)
        } else {
            let isToday = Calendar.current.isDateInToday(day.date)
            ZStack {
                RoundedRectangle(cornerRadius: cellSize * 0.2)
                    .fill(day.isFuture ? Color.systemGray5.opacity(0.35) : Color.systemGray5)
                    .frame(width: cellSize, height: cellSize)

                if !day.isFuture {
                    let count = habit.completionsInPeriod(containing: day.date)
                    if count > 0 {
                        PieProgressFill(
                            completionCount: count,
                            goalFrequency: habit.goalFrequency,
                            baseColor: habit.color,
                            size: cellSize
                        )
                    }
                }

                if isToday {
                    RoundedRectangle(cornerRadius: cellSize * 0.2)
                        .strokeBorder(habit.color, lineWidth: 1)
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
    }

    // MARK: - Weekly

    private func compactWeekly(availableWidth: CGFloat) -> some View {
        let columnWidth = cellSize + cellSpacing
        let maxPeriods = max(1, Int(availableWidth / columnWidth))
        let months = max(1, Int(ceil(Double(maxPeriods) / 4.33)))
        let periods = habit.periodHeatmapData(months: months, forwardPeriods: 5, today: today)
        let visiblePeriods = Array(periods.suffix(maxPeriods))
        return HStack(spacing: cellSpacing) {
            ForEach(visiblePeriods) { period in
                compactPeriodCell(period)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Monthly

    private func compactMonthly(availableWidth: CGFloat) -> some View {
        let monthlyCellSize = cellSize * 1.5
        let monthlySpacing = cellSpacing + 1
        let columnWidth = monthlyCellSize + monthlySpacing
        let maxPeriods = max(1, Int(availableWidth / columnWidth))
        let backMonths = max(1, maxPeriods)
        let forwardMonths = min(12, maxPeriods / 3)
        let periods = habit.periodHeatmapData(months: backMonths, forwardPeriods: forwardMonths, today: today)
        let visiblePeriods = Array(periods.suffix(maxPeriods))
        return HStack(spacing: monthlySpacing) {
            ForEach(visiblePeriods) { period in
                compactPeriodCell(period, size: monthlyCellSize)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Period Cell

    @ViewBuilder
    private func compactPeriodCell(_ period: PeriodData, size: CGFloat? = nil) -> some View {
        let effectiveSize = size ?? cellSize
        ZStack {
            RoundedRectangle(cornerRadius: effectiveSize * 0.2)
                .fill(period.isFuture ? Color.systemGray5.opacity(0.35) : Color.systemGray5)
                .frame(width: effectiveSize, height: effectiveSize)

            if !period.isFuture && period.completionCount > 0 {
                PieProgressFill(
                    completionCount: period.completionCount,
                    goalFrequency: period.goalFrequency,
                    baseColor: habit.color,
                    size: effectiveSize
                )
            }

            if period.isCurrentPeriod {
                RoundedRectangle(cornerRadius: effectiveSize * 0.2)
                    .strokeBorder(habit.color, lineWidth: 1)
                    .frame(width: effectiveSize, height: effectiveSize)
            }
        }
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
