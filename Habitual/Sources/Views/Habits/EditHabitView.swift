import SwiftUI

struct EditHabitView: View {
    @ObservedObject var habitStore: HabitStore
    @Environment(\.dismiss) private var dismiss

    let habit: Habit

    @State private var name: String
    @State private var description: String
    @State private var selectedIcon: String
    @State private var selectedColor: HabitColor
    @State private var goalFrequency: Int
    @State private var goalPeriod: Habit.GoalPeriod
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var nudgeEnabled: Bool
    @State private var nudgeTime: Date
    @State private var showDeleteConfirmation = false

    init(habit: Habit, habitStore: HabitStore) {
        self.habit = habit
        self.habitStore = habitStore
        _name = State(initialValue: habit.name)
        _description = State(initialValue: habit.description)
        _selectedIcon = State(initialValue: habit.icon)
        _goalFrequency = State(initialValue: habit.goalFrequency)
        _goalPeriod = State(initialValue: habit.goalPeriod)
        _reminderEnabled = State(initialValue: habit.reminderTime != nil)
        _reminderTime = State(initialValue: habit.reminderTime ?? Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date())

        let existingNudge = NudgeService.settings(for: habit)
        _nudgeEnabled = State(initialValue: existingNudge.isEnabled)
        _nudgeTime = State(initialValue: existingNudge.nudgeTime)

        let matchingColor = HabitColor.presets.first {
            abs($0.red - habit.colorComponents.red) < 0.01 &&
            abs($0.green - habit.colorComponents.green) < 0.01 &&
            abs($0.blue - habit.colorComponents.blue) < 0.01
        } ?? HabitColor.presets[0]
        _selectedColor = State(initialValue: matchingColor)
    }

    var body: some View {
        Form {
            // MARK: Name & Description

            Section {
                TextField("Habit Name", text: $name)
                    .font(.headline)
                TextField("Description (optional)", text: $description)
            } header: {
                Text("Habit")
            }

            // MARK: Appearance — Icon + Color in one section

            Section("Appearance") {
                IconPickerView(selectedIcon: $selectedIcon, color: selectedColor.color)
                ColorPickerView(selectedColor: $selectedColor)
            }

            // MARK: Live Preview

            Section("Preview") {
                HStack(spacing: 12) {
                    Image(systemName: selectedIcon)
                        .font(.title2)
                        .foregroundStyle(selectedColor.color)
                        .frame(width: 44, height: 44)
                        .background(selectedColor.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name.isEmpty ? "Habit Name" : name)
                            .font(.headline)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                        if !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(goalFrequency)x / \(goalPeriod.periodLabel)")
                            .font(.caption)
                            .foregroundStyle(description.isEmpty ? .secondary : .tertiary)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: Goal

            Section {
                Stepper(value: $goalFrequency, in: 1...30) {
                    HStack {
                        Text("Frequency")
                        Spacer()
                        Text("\(goalFrequency)x")
                            .foregroundStyle(.secondary)
                    }
                }

                Picker("Period", selection: $goalPeriod) {
                    ForEach(Habit.GoalPeriod.allCases) { period in
                        Text(period.displayName).tag(period)
                    }
                }
            } header: {
                Text("Goal")
            } footer: {
                Text("How often do you want to do this? Example: 3x / week means at least 3 times per week.")
            }

            // MARK: Notifications — Reminders + Smart Nudges combined

            Section {
                Toggle("Daily Reminder", isOn: $reminderEnabled)
                if reminderEnabled {
                    DatePicker(
                        "Time",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                }

                Toggle("Smart Nudges", isOn: $nudgeEnabled)
                if nudgeEnabled {
                    DatePicker(
                        "Nudge Time",
                        selection: $nudgeTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Notifications")
            } footer: {
                if nudgeEnabled {
                    Text("A nudge fires if you haven't logged this habit by the nudge time. Streak-at-risk alerts appear when you have 3+ days in a row.")
                } else {
                    Text("Reminders fire at a fixed time each day. Smart nudges are context-aware and adapt to your streak.")
                }
            }

            // MARK: Danger Zone

            Section {
                Button("Archive Habit") {
                    habitStore.archiveHabit(habit)
                    dismiss()
                }
                .foregroundStyle(.orange)

                Button("Delete Habit", role: .destructive) {
                    showDeleteConfirmation = true
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("Archiving hides the habit without losing data. Deleting is permanent.")
            }
        }
        .navigationTitle("Edit Habit")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .fontWeight(.semibold)
            }
        }
        .alert("Delete Habit", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                habitStore.deleteHabit(habit)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(habit.name)\"? This action cannot be undone.")
        }
    }

    private func saveChanges() {
        var updated = habit
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.icon = selectedIcon
        updated.color = selectedColor.color
        updated.colorComponents = (red: selectedColor.red, green: selectedColor.green, blue: selectedColor.blue)
        updated.goalFrequency = goalFrequency
        updated.goalPeriod = goalPeriod
        updated.reminderTime = reminderEnabled ? reminderTime : nil

        habitStore.updateHabit(updated)

        if reminderEnabled {
            NotificationService.shared.scheduleReminder(for: updated)
        } else {
            NotificationService.shared.removeReminder(for: updated)
        }

        let nudgeSettings = NudgeSettings(isEnabled: nudgeEnabled, nudgeTime: nudgeTime)
        NudgeService.apply(nudgeSettings, for: updated)

        dismiss()
    }
}

#Preview {
    let store = HabitStore(context: PersistenceController.preview.container.viewContext)
    let habit = store.habits.first ?? Habit(name: "Preview")

    return NavigationStack {
        EditHabitView(habit: habit, habitStore: store)
    }
}
