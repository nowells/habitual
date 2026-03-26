import SwiftUI

// MARK: - Period Heatmap Grid View

/// A heatmap that shows one cell per period (day/week/month) with radial progress rings
/// instead of simple colored squares. Collapses daily heatmaps into period-appropriate views.
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
        months: Int = 4,
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

    private var periodData: [PeriodData] {
        habit.periodHeatmapData(months: months, today: today)
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

    // MARK: - Daily Layout (original heatmap style but with radial cells for multi-frequency)

    private var dailyLayout: some View {
        let weeks = habit.heatmapData(months: months, today: today)
        return VStack(alignment: .leading, spacing: 4) {
            if showLabels {
                dailyMonthLabels(weeks: weeks)
            }

            HStack(alignment: .top, spacing: cellSpacing) {
                if showLabels {
                    dayOfWeekLabels
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cellSpacing) {
                        ForEach(weeks.indices, id: \.self) { weekIndex in
                            VStack(spacing: cellSpacing) {
                                ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                                    let day = weeks[weekIndex][dayIndex]
                                    dailyCell(day: day)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dailyCell(day: DayData) -> some View {
        if habit.goalFrequency > 1 {
            // Multi-frequency: show radial progress
            let count = habit.completionsInPeriod(containing: day.date)
            ZStack {
                RoundedRectangle(cornerRadius: cellSize * 0.2)
                    .fill(day.isFuture ? Color.clear : Color.systemGray5)
                    .frame(width: cellSize, height: cellSize)

                if !day.isFuture && count > 0 {
                    RadialProgressView(
                        completionCount: count,
                        goalFrequency: habit.goalFrequency,
                        baseColor: habit.color,
                        lineWidth: max(1.5, cellSize * 0.12),
                        size: cellSize * 0.85
                    )
                }
            }
        } else {
            // Single-frequency: keep simple colored squares
            HeatmapCell(
                day: day,
                color: habit.color,
                size: cellSize,
                onTap: nil
            )
        }
    }

    // MARK: - Weekly Layout (horizontal row of weeks)

    private var weeklyLayout: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showLabels {
                weeklyLabels
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cellSpacing) {
                    ForEach(periodData) { period in
                        periodCell(period)
                    }
                }
            }
        }
    }

    // MARK: - Monthly Layout (horizontal row of months)

    private var monthlyLayout: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showLabels {
                monthlyLabels
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cellSpacing + 2) {
                    ForEach(periodData) { period in
                        periodCell(period, size: cellSize * 1.8)
                    }
                }
            }
        }
    }

    // MARK: - Period Cell

    @ViewBuilder
    private func periodCell(_ period: PeriodData, size: CGFloat? = nil) -> some View {
        let effectiveSize = size ?? cellSize
        ZStack {
            RoundedRectangle(cornerRadius: effectiveSize * 0.2)
                .fill(period.isFuture ? Color.clear : Color.systemGray5)
                .frame(width: effectiveSize, height: effectiveSize)

            if !period.isFuture && period.completionCount > 0 {
                RadialProgressView(
                    completionCount: period.completionCount,
                    goalFrequency: period.goalFrequency,
                    baseColor: habit.color,
                    lineWidth: max(1.5, effectiveSize * 0.1),
                    size: effectiveSize * 0.85
                )
            }

            if period.isCurrentPeriod {
                RoundedRectangle(cornerRadius: effectiveSize * 0.2)
                    .strokeBorder(habit.color.opacity(0.5), lineWidth: 1)
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
        switch habit.goalPeriod {
        case .daily:
            compactDaily
        case .weekly:
            compactWeekly
        case .monthly:
            compactMonthly
        }
    }

    private var compactDaily: some View {
        let weeks = habit.heatmapData(months: 3, today: today)
        return HStack(spacing: cellSpacing) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                VStack(spacing: cellSpacing) {
                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                        let day = weeks[weekIndex][dayIndex]
                        compactDailyCell(day: day)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func compactDailyCell(day: DayData) -> some View {
        if habit.goalFrequency > 1 {
            let count = habit.completionsInPeriod(containing: day.date)
            ZStack {
                RoundedRectangle(cornerRadius: cellSize * 0.2)
                    .fill(day.isFuture ? Color.clear : Color.systemGray5)
                    .frame(width: cellSize, height: cellSize)

                if !day.isFuture && count > 0 {
                    RadialProgressView(
                        completionCount: count,
                        goalFrequency: habit.goalFrequency,
                        baseColor: habit.color,
                        lineWidth: max(1, cellSize * 0.12),
                        size: cellSize * 0.85
                    )
                }
            }
        } else {
            RoundedRectangle(cornerRadius: cellSize * 0.2)
                .fill(cellColor(for: day))
                .frame(width: cellSize, height: cellSize)
        }
    }

    private var compactWeekly: some View {
        let periods = habit.periodHeatmapData(months: 3, today: today)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: cellSpacing) {
                ForEach(periods) { period in
                    compactPeriodCell(period)
                }
            }
        }
    }

    private var compactMonthly: some View {
        let periods = habit.periodHeatmapData(months: 6, today: today)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: cellSpacing + 1) {
                ForEach(periods) { period in
                    compactPeriodCell(period, size: cellSize * 1.5)
                }
            }
        }
    }

    @ViewBuilder
    private func compactPeriodCell(_ period: PeriodData, size: CGFloat? = nil) -> some View {
        let effectiveSize = size ?? cellSize
        ZStack {
            RoundedRectangle(cornerRadius: effectiveSize * 0.2)
                .fill(period.isFuture ? Color.clear : Color.systemGray5)
                .frame(width: effectiveSize, height: effectiveSize)

            if !period.isFuture && period.completionCount > 0 {
                RadialProgressView(
                    completionCount: period.completionCount,
                    goalFrequency: period.goalFrequency,
                    baseColor: habit.color,
                    lineWidth: max(1, effectiveSize * 0.1),
                    size: effectiveSize * 0.85
                )
            }
        }
    }

    private func cellColor(for day: DayData) -> Color {
        if day.isFuture { return .clear }
        if day.isCompleted {
            return habit.color.opacity(min(1.0, 0.4 + day.value * 0.6))
        }
        return Color.systemGray5
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
