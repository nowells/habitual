import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    @ObservedObject var habitStore: HabitStore
    var onNavigate: (() -> Void)?

    @Environment(\.today) private var today

    @State private var isPressed = false
    @State private var showMascotReaction = false
    @State private var reactionMascot: Mascot = .cat
    private let calendar = Calendar.current

    private var isCompletedToday: Bool { habit.isCompletedOn(date: today) }
    private var periodCompletions: Int { habit.completionsInPeriod(containing: today) }
    private var isPeriodGoalMet: Bool { habit.isPeriodComplete(for: today) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack {
                    HabitIcon.image(habit.icon)
                        .font(.title3)
                        .foregroundStyle(habit.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if !habit.description.isEmpty {
                            Text(habit.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { onNavigate?() }

                // Mini mascot reaction (shown briefly after completion)
                if showMascotReaction {
                    MascotEmojiView(mascot: reactionMascot, mood: .excited, size: 36)
                        .transition(.scale.combined(with: .opacity))
                }

                // Quick check-in button: tap = add, long press = remove
                RadialCheckInButton(
                    habit: habit,
                    today: today,
                    size: 40,
                    onTap: {
                        withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                            habitStore.addCompletion(for: habit, on: today)
                        }
                        let streak = habit.currentStreak(asOf: today)
                        reactionMascot = Mascot.forStreak(streak + 1, completed: true)
                        withAnimation(.spring(duration: 0.4, bounce: 0.5)) {
                            showMascotReaction = true
                        }
                        Task {
                            try? await Task.sleep(nanoseconds: 1_800_000_000)
                            withAnimation { showMascotReaction = false }
                        }
                    },
                    onLongPress: {
                        withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                            habitStore.removeLastCompletion(for: habit, on: today)
                        }
                    }
                )
            }

            // Compact Period Heatmap Grid
            CompactPeriodHeatmapView(habit: habit)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { onNavigate?() }

            // Stats Row
            HStack(spacing: 16) {
                StatBadge(
                    label: "Streak",
                    value: "\(habit.currentStreak(asOf: today))",
                    icon: habit.currentStreak(asOf: today) >= 7 ? "flame.fill" : "flame",
                    color: habit.currentStreak(asOf: today) >= 3 ? .orange : habit.color
                )

                StatBadge(
                    label: "Total",
                    value: "\(habit.totalCompletions)",
                    icon: "checkmark",
                    color: habit.color
                )

                StatBadge(
                    label: "Rate",
                    value: "\(Int(habit.completionRate(asOf: today) * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: habit.color
                )

                Spacer()

                // Goal label
                Text("\(habit.goalFrequency)x/\(habit.goalPeriod.periodLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.systemGray6)
                    .clipShape(Capsule())
            }
            .contentShape(Rectangle())
            .onTapGesture { onNavigate?() }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.systemBackground)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isPeriodGoalMet ? habit.color.opacity(0.4) : Color.systemGray5,
                    lineWidth: isPeriodGoalMet ? 1.5 : 0.5
                )
                .allowsHitTesting(false)
        }
        .contextMenu {
            Button(action: { habitStore.addCompletion(for: habit, on: today) }) {
                Label("Add Completion", systemImage: "plus.circle")
            }

            if periodCompletions > 0 {
                Button(action: { habitStore.removeLastCompletion(for: habit, on: today) }) {
                    Label("Remove Last Completion", systemImage: "minus.circle")
                }
            }

            Divider()

            Button(action: { habitStore.archiveHabit(habit) }) {
                Label("Archive", systemImage: "archivebox")
            }

            Button(role: .destructive, action: { habitStore.deleteHabit(habit) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            HabitIcon.image(icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    let store = HabitStore(context: context)

    return ScrollView {
        LazyVStack(spacing: 16) {
            ForEach(store.habits) { habit in
                HabitCardView(habit: habit, habitStore: store)
            }
        }
        .padding()
    }
}
