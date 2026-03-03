import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @ObservedObject var habitStore: HabitStore
    @State private var showingEditSheet = false
    @State private var selectedMonth = Date()

    private let calendar = Calendar.current

    // Refresh habit data from store
    private var currentHabit: Habit {
        habitStore.habits.first { $0.id == habit.id } ?? habit
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                headerCard

                // Heatmap
                heatmapSection

                // Statistics
                statisticsSection

                // Calendar
                calendarSection
            }
            .padding()
        }
        .navigationTitle(currentHabit.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditHabitView(habit: currentHabit, habitStore: habitStore)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            Image(systemName: currentHabit.icon)
                .font(.largeTitle)
                .foregroundStyle(currentHabit.color)
                .frame(width: 60, height: 60)
                .background(currentHabit.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(currentHabit.name)
                    .font(.title2)
                    .fontWeight(.bold)

                if !currentHabit.description.isEmpty {
                    Text(currentHabit.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("\(currentHabit.goalFrequency)x / \(currentHabit.goalPeriod.periodLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }

            Spacer()

            // Today toggle
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    habitStore.toggleTodayCompletion(for: currentHabit)
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: currentHabit.isCompletedOn(date: Date()) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 36))
                        .foregroundStyle(currentHabit.isCompletedOn(date: Date()) ? currentHabit.color : Color(.systemGray3))
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Heatmap Section

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)

            HeatmapGridView(
                habit: currentHabit,
                months: 6,
                cellSize: 14,
                cellSpacing: 3,
                showMonthLabels: true,
                onTapDate: { date in
                    withAnimation(.spring(response: 0.3)) {
                        habitStore.toggleCompletion(for: currentHabit, on: date)
                    }
                }
            )
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                StatCard(
                    title: "Current Streak",
                    value: "\(currentHabit.currentStreak)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "Longest Streak",
                    value: "\(currentHabit.longestStreak)",
                    subtitle: "days",
                    icon: "trophy.fill",
                    color: .yellow
                )

                StatCard(
                    title: "Total",
                    value: "\(currentHabit.totalCompletions)",
                    subtitle: "completions",
                    icon: "checkmark.circle.fill",
                    color: currentHabit.color
                )

                StatCard(
                    title: "Success Rate",
                    value: "\(Int(currentHabit.completionRate * 100))%",
                    subtitle: "overall",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Calendar")
                    .font(.headline)

                Spacer()

                HStack(spacing: 16) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }

                    Text(monthYearString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 120)

                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
                }
                .buttonStyle(.plain)
            }

            CalendarGridView(
                habit: currentHabit,
                month: selectedMonth,
                onTapDate: { date in
                    withAnimation(.spring(response: 0.3)) {
                        habitStore.toggleCompletion(for: currentHabit, on: date)
                    }
                }
            )
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        }
    }
}

// MARK: - Calendar Grid

struct CalendarGridView: View {
    let habit: Habit
    let month: Date
    var onTapDate: ((Date) -> Void)?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            // Day of week headers
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            isCompleted: habit.isCompletedOn(date: date),
                            isToday: calendar.isDateInToday(date),
                            isFuture: date > Date(),
                            color: habit.color,
                            onTap: {
                                if date <= Date() {
                                    onTapDate?(date)
                                }
                            }
                        )
                    } else {
                        Text("")
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    private var calendarDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []

        // Add empty slots for days before the month starts
        let startWeekday = calendar.component(.weekday, from: monthInterval.start)
        let offset = (startWeekday - calendar.firstWeekday + 7) % 7
        for _ in 0..<offset {
            days.append(nil)
        }

        // Add days of the month
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }

        return days
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isCompleted: Bool
    let isToday: Bool
    let isFuture: Bool
    let color: Color
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Text("\(calendar.component(.day, from: date))")
            .font(.caption)
            .fontWeight(isToday ? .bold : .regular)
            .foregroundStyle(foregroundColor)
            .frame(width: 36, height: 36)
            .background {
                if isCompleted {
                    Circle()
                        .fill(color)
                } else if isToday {
                    Circle()
                        .strokeBorder(color, lineWidth: 1.5)
                }
            }
            .opacity(isFuture ? 0.3 : 1.0)
            .onTapGesture {
                onTap()
            }
    }

    private var foregroundColor: Color {
        if isCompleted { return .white }
        if isFuture { return .secondary }
        return .primary
    }
}

#Preview {
    let store = HabitStore(context: PersistenceController.preview.container.viewContext)
    let habit = store.habits.first ?? Habit(name: "Preview")

    return NavigationStack {
        HabitDetailView(habit: habit, habitStore: store)
    }
}
