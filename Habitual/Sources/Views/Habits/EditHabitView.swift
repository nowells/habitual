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
        _reminderTime = State(initialValue: habit.reminderTime ?? Date())

        // Find matching preset color or use first
        let matchingColor = HabitColor.presets.first {
            abs($0.red - habit.colorComponents.red) < 0.01 &&
            abs($0.green - habit.colorComponents.green) < 0.01 &&
            abs($0.blue - habit.colorComponents.blue) < 0.01
        } ?? HabitColor.presets[0]
        _selectedColor = State(initialValue: matchingColor)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Habit Name", text: $name)
                        .font(.headline)
                    TextField("Description (optional)", text: $description)
                }

                Section("Icon") {
                    IconPickerView(selectedIcon: $selectedIcon, color: selectedColor.color)
                }

                Section("Color") {
                    ColorPickerView(selectedColor: $selectedColor)
                }

                Section("Goal") {
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
                }

                Section("Reminder") {
                    Toggle("Enable Reminder", isOn: $reminderEnabled)

                    if reminderEnabled {
                        DatePicker(
                            "Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section {
                    Button("Archive Habit") {
                        habitStore.archiveHabit(habit)
                        dismiss()
                    }
                    .foregroundStyle(.orange)

                    Button("Delete Habit", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .foregroundStyle(.red)
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

        dismiss()
    }
}

#Preview {
    let store = HabitStore(context: PersistenceController.preview.container.viewContext)
    let habit = store.habits.first ?? Habit(name: "Preview")

    return EditHabitView(habit: habit, habitStore: store)
}
