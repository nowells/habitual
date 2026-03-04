import XCTest
import SwiftUI
import SnapshotTesting
@testable import HabitualCore

/// Full-screen showcase snapshots designed for README documentation.
/// Each test renders a complete, representative view of the app experience.
/// Snapshot images are saved to __Snapshots__/ShowcaseSnapshotTests/.
final class ShowcaseSnapshotTests: SnapshotTestCase {

    // MARK: - Onboarding / First Launch

    /// The welcoming empty state a new user sees on first launch.
    func testShowcase_EmptyState() {
        let view = SnapshotContainer(width: 390, height: 600) {
            EmptyStateView(showingAddHabit: .constant(false))
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Habit Dashboard

    /// The main dashboard with a mix of habit states — active streaks,
    /// weekly goals, fresh habits with no data, and fully completed habits.
    func testShowcase_Dashboard_Light() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 16) {
                ForEach(TestData.allHabits) { habit in
                    HabitCardView(habit: habit, habitStore: store)
                }
            }
            .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    /// Dark mode variant of the dashboard.
    func testShowcase_Dashboard_Dark() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 16) {
                ForEach(TestData.allHabits) { habit in
                    HabitCardView(habit: habit, habitStore: store)
                }
            }
            .padding()
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Habit Detail (Full Screen)

    /// Complete habit detail view: header with today toggle, 6-month heatmap,
    /// statistics grid, and monthly calendar — all in one scrollable layout.
    func testShowcase_HabitDetail_ActiveStreak_Light() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)
        let habit = TestData.exerciseHabit

        let view = SnapshotContainer(width: 390) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header card
                    HStack(spacing: 16) {
                        Image(systemName: habit.icon)
                            .font(.largeTitle)
                            .foregroundStyle(habit.color)
                            .frame(width: 60, height: 60)
                            .background(habit.color.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(habit.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(habit.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(habit.goalFrequency)x / \(habit.goalPeriod.periodLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.systemGray6)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(habit.color)
                            Text("Today")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.systemBackground)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }

                    // Heatmap section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity")
                            .font(.headline)
                        HeatmapGridView(habit: habit, months: 6, cellSize: 14, cellSpacing: 3, showMonthLabels: true)
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.systemBackground)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }

                    // Statistics section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(title: "Current Streak", value: "\(habit.currentStreak)", subtitle: "days", icon: "flame.fill", color: .orange)
                            StatCard(title: "Longest Streak", value: "\(habit.longestStreak)", subtitle: "days", icon: "trophy.fill", color: .yellow)
                            StatCard(title: "Total", value: "\(habit.totalCompletions)", subtitle: "completions", icon: "checkmark.circle.fill", color: habit.color)
                            StatCard(title: "Success Rate", value: "\(Int(habit.completionRate * 100))%", subtitle: "overall", icon: "chart.line.uptrend.xyaxis", color: .green)
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.systemBackground)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }

                    // Calendar section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Calendar")
                                .font(.headline)
                            Spacer()
                            Text("January 2026")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        CalendarGridView(habit: habit, month: TestData.referenceDate)
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.systemBackground)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                }
                .padding()
            }
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    /// Habit detail in dark mode — shows the heatmap color vibrancy.
    func testShowcase_HabitDetail_ActiveStreak_Dark() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)
        let habit = TestData.exerciseHabit

        let view = SnapshotContainer(width: 390) {
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 16) {
                        Image(systemName: habit.icon)
                            .font(.largeTitle)
                            .foregroundStyle(habit.color)
                            .frame(width: 60, height: 60)
                            .background(habit.color.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(habit.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(habit.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(habit.goalFrequency)x / \(habit.goalPeriod.periodLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.systemGray6)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(habit.color)
                            Text("Today")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.systemBackground)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity")
                            .font(.headline)
                        HeatmapGridView(habit: habit, months: 6, cellSize: 14, cellSpacing: 3, showMonthLabels: true)
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.systemBackground)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(title: "Current Streak", value: "\(habit.currentStreak)", subtitle: "days", icon: "flame.fill", color: .orange)
                            StatCard(title: "Longest Streak", value: "\(habit.longestStreak)", subtitle: "days", icon: "trophy.fill", color: .yellow)
                            StatCard(title: "Total", value: "\(habit.totalCompletions)", subtitle: "completions", icon: "checkmark.circle.fill", color: habit.color)
                            StatCard(title: "Success Rate", value: "\(Int(habit.completionRate * 100))%", subtitle: "overall", icon: "chart.line.uptrend.xyaxis", color: .green)
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.systemBackground)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                }
                .padding()
            }
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    /// Detail view for a habit with perfect 100% completion rate (30-day streak).
    func testShowcase_HabitDetail_PerfectStreak() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)
        let habit = TestData.waterHabit

        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    Image(systemName: habit.icon)
                        .font(.largeTitle)
                        .foregroundStyle(habit.color)
                        .frame(width: 60, height: 60)
                        .background(habit.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(habit.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(habit.color)
                        Text("Today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemBackground)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Statistics")
                        .font(.headline)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Current Streak", value: "\(habit.currentStreak)", subtitle: "days", icon: "flame.fill", color: .orange)
                        StatCard(title: "Longest Streak", value: "\(habit.longestStreak)", subtitle: "days", icon: "trophy.fill", color: .yellow)
                        StatCard(title: "Total", value: "\(habit.totalCompletions)", subtitle: "completions", icon: "checkmark.circle.fill", color: habit.color)
                        StatCard(title: "Success Rate", value: "\(Int(habit.completionRate * 100))%", subtitle: "overall", icon: "chart.line.uptrend.xyaxis", color: .green)
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemBackground)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    /// Detail view for a brand-new habit with zero completions.
    func testShowcase_HabitDetail_FreshHabit() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)
        let habit = TestData.meditateHabit

        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    Image(systemName: habit.icon)
                        .font(.largeTitle)
                        .foregroundStyle(habit.color)
                        .frame(width: 60, height: 60)
                        .background(habit.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(habit.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "circle")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.systemGray3)
                        Text("Today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemBackground)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity")
                        .font(.headline)
                    HeatmapGridView(habit: habit, months: 3, cellSize: 14, cellSpacing: 3, showMonthLabels: true)
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemBackground)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Statistics")
                        .font(.headline)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Current Streak", value: "0", subtitle: "days", icon: "flame.fill", color: .orange)
                        StatCard(title: "Longest Streak", value: "0", subtitle: "days", icon: "trophy.fill", color: .yellow)
                        StatCard(title: "Total", value: "0", subtitle: "completions", icon: "checkmark.circle.fill", color: habit.color)
                        StatCard(title: "Success Rate", value: "0%", subtitle: "overall", icon: "chart.line.uptrend.xyaxis", color: .green)
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemBackground)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Heatmap Showcase

    /// GitHub-style heatmap grid — the signature visualization.
    func testShowcase_Heatmap_6Months() {
        let view = SnapshotContainer(width: 600, height: 200) {
            HeatmapGridView(
                habit: TestData.exerciseHabit,
                months: 6,
                cellSize: 14,
                cellSpacing: 3,
                showMonthLabels: true
            )
            .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    /// Heatmap comparison across multiple habits and colors.
    func testShowcase_Heatmap_MultiColor() {
        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 20) {
                ForEach([TestData.exerciseHabit, TestData.readHabit, TestData.waterHabit]) { habit in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: habit.icon)
                                .foregroundStyle(habit.color)
                            Text(habit.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        CompactHeatmapView(habit: habit)
                    }
                }
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Statistics & Calendar

    /// 2x2 statistics grid showing streak, total, and rate metrics.
    func testShowcase_StatisticsGrid() {
        let habit = TestData.exerciseHabit
        let view = SnapshotContainer(width: 390) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Current Streak", value: "\(habit.currentStreak)", subtitle: "days", icon: "flame.fill", color: .orange)
                StatCard(title: "Longest Streak", value: "\(habit.longestStreak)", subtitle: "days", icon: "trophy.fill", color: .yellow)
                StatCard(title: "Total", value: "\(habit.totalCompletions)", subtitle: "completions", icon: "checkmark.circle.fill", color: habit.color)
                StatCard(title: "Success Rate", value: "\(Int(habit.completionRate * 100))%", subtitle: "overall", icon: "chart.line.uptrend.xyaxis", color: .green)
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    /// Monthly calendar view with completion dots showing daily progress.
    func testShowcase_CalendarView() {
        let view = SnapshotContainer(width: 350, height: 300) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Calendar")
                        .font(.headline)
                    Spacer()
                    Text("January 2026")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                CalendarGridView(habit: TestData.exerciseHabit, month: TestData.referenceDate)
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Create Habit Flow

    /// Icon picker grid — 40 SF Symbol icons across 8 columns.
    func testShowcase_IconPicker() {
        let view = SnapshotContainer(width: 390) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose an Icon")
                    .font(.headline)
                IconPickerView(selectedIcon: .constant("figure.run"), color: Color(red: 0.35, green: 0.65, blue: 0.85))
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    /// Color palette picker — 12 preset habit colors.
    func testShowcase_ColorPicker() {
        let view = SnapshotContainer(width: 390) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose a Color")
                    .font(.headline)
                ColorPickerView(selectedColor: .constant(HabitColor.presets[0]))
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    /// Live preview card shown while creating a new habit.
    func testShowcase_HabitPreviewCard() {
        let view = SnapshotContainer(width: 390) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Preview")
                    .font(.headline)
                HStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundStyle(Color(red: 0.35, green: 0.65, blue: 0.85))
                        .frame(width: 44, height: 44)
                        .background(Color(red: 0.35, green: 0.65, blue: 0.85).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading) {
                        Text("Morning Run")
                            .font(.headline)
                        Text("1x / day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Add Habit Form

    /// The full "New Habit" form — name, icon picker, color picker, goal stepper and period,
    /// reminder toggle, smart nudges section, and live preview card.
    func testShowcase_AddHabitForm_Light() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390, height: 1400) {
            NavigationStack {
                AddHabitView(habitStore: store)
            }
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    /// Dark mode variant of the Add Habit form.
    func testShowcase_AddHabitForm_Dark() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390, height: 1400) {
            NavigationStack {
                AddHabitView(habitStore: store)
            }
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Edit Habit Form

    /// Edit Habit form pre-populated with an existing habit's data —
    /// shows icon/color selection, goal configuration, and danger zone (archive/delete).
    func testShowcase_EditHabitForm_Light() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let view = SnapshotContainer(width: 390, height: 1600) {
            NavigationStack {
                EditHabitView(habit: TestData.exerciseHabit, habitStore: store)
            }
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Mascot System

    /// All four mascots in one banner column — dragon (high streak), cat (daily win),
    /// capybara (rest day), dog (new habit). Each with a distinct mood and speech bubble.
    func testShowcase_MascotBanners() {
        let banners: [(Mascot, MascotMood, String)] = [
            (.dragon, .excited, "7 days! Ryū is absolutely fired up! 🔥"),
            (.cat, .happy, "Nice work! 3 days in a row — you're building something real."),
            (.capybara, .encouraging, "Kapiiko is cheering you on. There's still time today!"),
            (.dog, .relaxed, "Wanko says: every journey starts with one step. No rush!"),
        ]

        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 12) {
                ForEach(banners, id: \.0.name) { mascot, mood, message in
                    MascotBannerView(mascot: mascot, mood: mood, message: message)
                }
            }
            .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Archive

    /// Archive list showing multiple habits that have been archived.
    func testShowcase_Archive() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        store.addHabit(TestData.exerciseHabit)
        store.addHabit(TestData.readHabit)
        store.addHabit(TestData.meditateHabit)
        for habit in store.habits {
            store.archiveHabit(habit)
        }

        let view = SnapshotContainer(width: 390, height: 500) {
            NavigationStack {
                ArchiveView(habitStore: store)
            }
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Settings

    /// Full settings screen showing all configuration options.
    func testShowcase_Settings_Light() {
        let view = SnapshotContainer(width: 390, height: 700) {
            NavigationStack {
                SettingsView()
            }
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testShowcase_Settings_Dark() {
        let view = SnapshotContainer(width: 390, height: 700) {
            NavigationStack {
                SettingsView()
            }
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - Habit Card States (Side-by-Side Comparison)

    /// Four habit cards showing the visual spectrum — active streak,
    /// weekly goal, empty (new), and fully completed.
    func testShowcase_HabitCardStates() {
        let controller = PersistenceController(inMemory: true)
        let store = HabitStore(context: controller.container.viewContext)

        let habits: [(Habit, String)] = [
            (TestData.exerciseHabit, "Active Streak"),
            (TestData.readHabit, "Weekly Goal"),
            (TestData.meditateHabit, "No Data Yet"),
            (TestData.waterHabit, "100% Complete"),
        ]

        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 20) {
                ForEach(habits, id: \.0.id) { habit, label in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(label)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        HabitCardView(habit: habit, habitStore: store)
                    }
                }
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
