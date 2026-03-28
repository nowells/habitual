import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @ObservedObject var habitStore: HabitStore
    @Environment(\.today) private var today
    @State private var showingEditSheet = false
    @State private var selectedMonth = Date()
    @State private var showingCelebration = false
    @State private var lastKnownStreak = 0

    private let calendar = Calendar.current
    private let milestoneDays: Set<Int> = [7, 14, 21, 30, 60, 100]

    // Refresh habit data from store
    private var currentHabit: Habit {
        habitStore.habits.first { $0.id == habit.id } ?? habit
    }

    private var mascot: Mascot {
        Mascot.forStreak(currentHabit.currentStreak(asOf: today), completed: currentHabit.isCompletedOn(date: today))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                headerCard

                // Mascot banner — contextual message
                mascotBanner

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
            NavigationStack {
                EditHabitView(habit: currentHabit, habitStore: habitStore)
            }
            #if os(macOS)
                .frame(minWidth: 520, minHeight: 620)
            #endif
        }
        .overlay {
            if showingCelebration {
                MascotCelebrationView(
                    mascot: .dragon,
                    streakCount: currentHabit.currentStreak(asOf: today)
                ) {
                    showingCelebration = false
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingCelebration)
        .onAppear {
            lastKnownStreak = currentHabit.currentStreak(asOf: today)
        }
        .onChange(of: currentHabit.currentStreak(asOf: today)) { _, newStreak in
            if milestoneDays.contains(newStreak) && newStreak > lastKnownStreak {
                showingCelebration = true
            }
            lastKnownStreak = newStreak
        }
    }

    // MARK: - Mascot Banner

    @ViewBuilder
    private var mascotBanner: some View {
        let streak = currentHabit.currentStreak(asOf: today)
        let isDone = currentHabit.isCompletedOn(date: today)

        let unit = currentHabit.goalPeriod.periodLabelPlural
        let (mood, message): (MascotMood, String) = {
            if isDone && streak >= 7 {
                return (.excited, "\(streak) \(unit)! \(mascot.name) is absolutely fired up! 🔥")
            } else if isDone && streak >= 3 {
                return (.happy, "Nice work! \(streak) \(unit) in a row — you're building something real.")
            } else if isDone {
                return (
                    .happy, "\(mascot.name) is proud! Every \(currentHabit.goalPeriod.periodLabel) you show up matters."
                )
            } else if streak >= 3 {
                return (
                    .encouraging,
                    "You have a \(streak)-\(currentHabit.goalPeriod.periodLabel) streak at stake! "
                        + "\(mascot.name) believes in you."
                )
            } else {
                return (.encouraging, "\(mascot.name) is cheering you on. There's still time today!")
            }
        }()

        MascotBannerView(mascot: mascot, mood: mood, message: message, mascotSize: 64)
            .padding(.horizontal, 4)
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            HabitIcon.image(currentHabit.icon)
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

                Button(action: { showingEditSheet = true }) {
                    HStack(spacing: 4) {
                        Text("\(currentHabit.goalFrequency)x / \(currentHabit.goalPeriod.periodLabel)")
                        Image(systemName: "pencil")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.systemGray6)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Period check-in with radial progress
            RadialCheckInButton(
                habit: currentHabit,
                today: today,
                size: 48,
                onTap: {
                    withAnimation(.spring(response: 0.3)) {
                        habitStore.addCompletion(for: currentHabit, on: today)
                    }
                }
            )
            .contextMenu {
                let count = currentHabit.completionsInPeriod(containing: today)
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        habitStore.addCompletion(for: currentHabit, on: today)
                    }
                }) {
                    Label("Add Completion", systemImage: "plus.circle")
                }

                if count > 0 {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            habitStore.removeLastCompletion(for: currentHabit, on: today)
                        }
                    }) {
                        Label("Remove Last", systemImage: "minus.circle")
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.systemBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Heatmap Section

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity")
                    .font(.headline)
                Spacer()
                Text("\(currentHabit.goalFrequency)x / \(currentHabit.goalPeriod.periodLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.systemGray6)
                    .clipShape(Capsule())
            }

            PeriodHeatmapGridView(
                habit: currentHabit,
                months: 12,
                cellSize: 14,
                cellSpacing: 3,
                showLabels: true,
                onTapPeriod: { period in
                    // For daily habits, toggle on the period start date
                    // For weekly/monthly, add a completion on today if period is current
                    if period.isCurrentPeriod {
                        withAnimation(.spring(response: 0.3)) {
                            habitStore.addCompletion(for: currentHabit, on: today)
                        }
                    } else {
                        withAnimation(.spring(response: 0.3)) {
                            habitStore.addCompletion(for: currentHabit, on: period.periodStart)
                        }
                    }
                }
            )
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.systemBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 12
            ) {
                StatCard(
                    title: "Current Streak",
                    value: "\(currentHabit.currentStreak(asOf: today))",
                    subtitle: currentHabit.goalPeriod.periodLabelPlural,
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "Longest Streak",
                    value: "\(currentHabit.longestStreak(asOf: today))",
                    subtitle: currentHabit.goalPeriod.periodLabelPlural,
                    icon: "trophy.fill",
                    color: .yellow
                )

                StatCard(
                    title: "Total",
                    value: "\(currentHabit.totalCompletions(asOf: today))",
                    subtitle: currentHabit.goalPeriod.periodLabelPlural,
                    icon: "checkmark.circle.fill",
                    color: currentHabit.color
                )

                StatCard(
                    title: "Success Rate",
                    value: "\(Int(currentHabit.completionRate(asOf: today) * 100))%",
                    subtitle: "overall",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.systemBackground)
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
                        habitStore.addCompletion(for: currentHabit, on: date)
                    }
                },
                onLongPressDate: { date in
                    let count = currentHabit.completionsInPeriod(containing: date)
                    if count > 0 {
                        withAnimation(.spring(response: 0.3)) {
                            habitStore.removeLastCompletion(for: currentHabit, on: date)
                        }
                    }
                }
            )
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.systemBackground)
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
                HabitIcon.image(icon)
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
                .fill(Color.systemGray6)
        }
    }
}

// MARK: - Calendar Grid

struct CalendarGridView: View {
    let habit: Habit
    let month: Date
    var onTapDate: ((Date) -> Void)?
    var onLongPressDate: ((Date) -> Void)?

    @Environment(\.today) private var today

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let cellSize: CGFloat = 40

    var body: some View {
        VStack(spacing: 8) {
            // Day of week headers
            HStack {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
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
                        let count = habit.completionsInPeriod(containing: date)
                        let status = calendarCellStatus(for: date, count: count)
                        let dayNumber = calendar.component(.day, from: date)

                        CalendarDayCell(
                            dayNumber: dayNumber,
                            count: count,
                            goal: habit.goalFrequency,
                            color: habit.color,
                            status: status,
                            size: cellSize,
                            onTap: {
                                if status != .future {
                                    onTapDate?(date)
                                }
                            },
                            onLongPress: {
                                if status != .future && count > 0 {
                                    onLongPressDate?(date)
                                }
                            }
                        )
                    } else {
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }

    private func calendarCellStatus(for date: Date, count: Int) -> CellStatus {
        let dayStart = calendar.startOfDay(for: date)
        let todayStart = calendar.startOfDay(for: today)
        let habitStart = calendar.startOfDay(for: habit.createdAt)

        if dayStart > todayStart { return .future }
        if dayStart == todayStart { return .today }
        if dayStart < habitStart { return .missed }
        if count == 0 { return .missed }
        if count >= habit.goalFrequency * 2 { return .overComplete }
        if count >= habit.goalFrequency { return .complete }
        return .partial
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
            calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) != nil
        else {
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
    let dayNumber: Int
    let count: Int
    let goal: Int
    let color: Color
    let status: CellStatus
    let size: CGFloat
    let onTap: () -> Void
    var onLongPress: (() -> Void)?

    @State private var longPressActivated = false

    var body: some View {
        Button {
            if longPressActivated {
                longPressActivated = false
            } else {
                onTap()
            }
        } label: {
            CalendarLiquidFillCell(
                dayNumber: dayNumber,
                count: count,
                goal: goal,
                color: color,
                status: status,
                size: size
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    longPressActivated = true
                    onLongPress?()
                }
        )
    }
}

#Preview {
    let store = HabitStore(context: PersistenceController.preview.container.viewContext)
    let habit = store.habits.first ?? Habit(name: "Preview")

    return NavigationStack {
        HabitDetailView(habit: habit, habitStore: store)
    }
}
