import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    @ObservedObject var habitStore: HabitStore

    @State private var isPressed = false
    @State private var showMascotReaction = false
    @State private var reactionMascot: Mascot = .cat
    private let calendar = Calendar.current

    private var isCompletedToday: Bool { habit.isCompletedOn(date: Date()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: habit.icon)
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

                // Mini mascot reaction (shown briefly after completion)
                if showMascotReaction {
                    MascotFaceView(mascot: reactionMascot, mood: .excited, size: 36)
                        .transition(.scale.combined(with: .opacity))
                }

                // Quick complete button for today
                Button(action: {
                    withAnimation(.spring(response: 0.3, bounce: 0.5)) {
                        habitStore.toggleTodayCompletion(for: habit)
                    }
                    // Show mascot reaction when completing (not uncompleting)
                    if !isCompletedToday {
                        let streak = habit.currentStreak
                        reactionMascot = Mascot.forStreak(streak + 1, completed: true)
                        withAnimation(.spring(duration: 0.4, bounce: 0.5)) {
                            showMascotReaction = true
                        }
                        Task {
                            try? await Task.sleep(nanoseconds: 1_800_000_000)
                            withAnimation { showMascotReaction = false }
                        }
                    }
                }) {
                    Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isCompletedToday ? habit.color : Color.systemGray3)
                        .scaleEffect(isCompletedToday ? 1.1 : 1.0)
                        .animation(.spring(duration: 0.3, bounce: 0.6), value: isCompletedToday)
                }
                .buttonStyle(.plain)
            }

            // Compact Heatmap Grid
            CompactHeatmapView(habit: habit)
                .frame(maxWidth: .infinity)

            // Stats Row
            HStack(spacing: 16) {
                StatBadge(
                    label: "Streak",
                    value: "\(habit.currentStreak)",
                    icon: habit.currentStreak >= 7 ? "flame.fill" : "flame",
                    color: habit.currentStreak >= 3 ? .orange : habit.color
                )

                StatBadge(
                    label: "Total",
                    value: "\(habit.totalCompletions)",
                    icon: "checkmark",
                    color: habit.color
                )

                StatBadge(
                    label: "Rate",
                    value: "\(Int(habit.completionRate * 100))%",
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
                    isCompletedToday ? habit.color.opacity(0.4) : Color.systemGray5,
                    lineWidth: isCompletedToday ? 1.5 : 0.5
                )
        }
        .contextMenu {
            Button(action: { habitStore.toggleTodayCompletion(for: habit) }) {
                Label(
                    habit.isCompletedOn(date: Date()) ? "Unmark Today" : "Complete Today",
                    systemImage: habit.isCompletedOn(date: Date()) ? "xmark.circle" : "checkmark.circle"
                )
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
            Image(systemName: icon)
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
