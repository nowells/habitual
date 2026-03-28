import SwiftUI

// MARK: - Heatmap Grid View (GitHub-style)

struct HeatmapGridView: View {
    let habit: Habit
    let months: Int
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let showMonthLabels: Bool
    var onTapDate: ((Date) -> Void)?

    @Environment(\.today) private var today

    init(
        habit: Habit,
        months: Int = 4,
        cellSize: CGFloat = 12,
        cellSpacing: CGFloat = 3,
        showMonthLabels: Bool = true,
        onTapDate: ((Date) -> Void)? = nil
    ) {
        self.habit = habit
        self.months = months
        self.cellSize = cellSize
        self.cellSpacing = cellSpacing
        self.showMonthLabels = showMonthLabels
        self.onTapDate = onTapDate
    }

    private var weeks: [[DayData]] {
        habit.heatmapData(months: months, today: today)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showMonthLabels {
                monthLabelsRow
            }

            HStack(alignment: .top, spacing: cellSpacing) {
                // Day-of-week labels
                VStack(alignment: .trailing, spacing: cellSpacing) {
                    ForEach(dayLabels.indices, id: \.self) { index in
                        if index % 2 == 1 {
                            Text(dayLabels[index])
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

                // Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cellSpacing) {
                        ForEach(weeks.indices, id: \.self) { weekIndex in
                            VStack(spacing: cellSpacing) {
                                ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                                    let day = weeks[weekIndex][dayIndex]
                                    HeatmapCell(
                                        day: day,
                                        color: habit.color,
                                        goal: habit.goalFrequency,
                                        size: cellSize,
                                        onTap: onTapDate
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var monthLabelsRow: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 24)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(monthPositions, id: \.offset) { item in
                        Text(item.label)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .frame(width: CGFloat(item.span) * (cellSize + cellSpacing), alignment: .leading)
                    }
                }
            }
        }
    }

    private var dayLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        // Reorder based on firstWeekday
        let first = Calendar.current.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    private var monthPositions: [(offset: Int, label: String, span: Int)] {
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

// MARK: - Individual Heatmap Cell

struct HeatmapCell: View {
    let day: DayData
    let color: Color
    let goal: Int
    let size: CGFloat
    var onTap: ((Date) -> Void)?

    var body: some View {
        if day.isPadding {
            Color.clear.frame(width: size, height: size)
        } else {
            LiquidFillCell(
                count: day.count,
                goal: goal,
                color: color,
                status: day.status,
                size: size
            )
            .onTapGesture {
                if day.status != .future {
                    onTap?(day.date)
                }
            }
        }
    }
}

// MARK: - Compact Heatmap (for cards)

struct CompactHeatmapView: View {
    let habit: Habit
    let cellSize: CGFloat
    let cellSpacing: CGFloat

    @Environment(\.today) private var today

    init(habit: Habit, cellSize: CGFloat = 10, cellSpacing: CGFloat = 2) {
        self.habit = habit
        self.cellSize = cellSize
        self.cellSpacing = cellSpacing
    }

    private var weeks: [[DayData]] {
        habit.heatmapData(months: 3, today: today)
    }

    var body: some View {
        HStack(spacing: cellSpacing) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                VStack(spacing: cellSpacing) {
                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                        let day = weeks[weekIndex][dayIndex]
                        if day.isPadding {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        } else {
                            LiquidFillCell(
                                count: day.count,
                                goal: habit.goalFrequency,
                                color: habit.color,
                                status: day.status,
                                size: cellSize
                            )
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let store = HabitStore(context: PersistenceController.preview.container.viewContext)
    let habit = store.habits.first ?? Habit(name: "Preview")

    return VStack {
        HeatmapGridView(habit: habit)
            .padding()
        CompactHeatmapView(habit: habit)
            .padding()
    }
}
