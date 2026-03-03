import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    @ObservedObject var habitStore: HabitStore

    @State private var isPressed = false
    private let calendar = Calendar.current

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

                // Quick complete button for today
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        habitStore.toggleTodayCompletion(for: habit)
                    }
                }) {
                    Image(systemName: habit.isCompletedOn(date: Date()) ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(habit.isCompletedOn(date: Date()) ? habit.color : Color(.systemGray3))
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
                    icon: "flame.fill",
                    color: habit.color
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
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray5), lineWidth: 0.5)
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
