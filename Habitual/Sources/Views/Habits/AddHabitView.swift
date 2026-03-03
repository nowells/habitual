import SwiftUI

struct AddHabitView: View {
    @ObservedObject var habitStore: HabitStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = HabitColor.presets[0]
    @State private var goalFrequency = 1
    @State private var goalPeriod: Habit.GoalPeriod = .daily
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                // Name & Description
                Section {
                    TextField("Habit Name", text: $name)
                        .font(.headline)
                    TextField("Description (optional)", text: $description)
                }

                // Icon Selection
                Section("Icon") {
                    IconPickerView(selectedIcon: $selectedIcon, color: selectedColor.color)
                }

                // Color Selection
                Section("Color") {
                    ColorPickerView(selectedColor: $selectedColor)
                }

                // Goal
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

                // Reminder
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

                // Preview
                Section("Preview") {
                    HStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundStyle(selectedColor.color)
                            .frame(width: 44, height: 44)
                            .background(selectedColor.color.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "Habit Name" : name)
                                .font(.headline)
                                .foregroundStyle(name.isEmpty ? .secondary : .primary)
                            Text("\(goalFrequency)x / \(goalPeriod.periodLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Habit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addHabit()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addHabit() {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: selectedIcon,
            color: selectedColor.color,
            colorComponents: (red: selectedColor.red, green: selectedColor.green, blue: selectedColor.blue),
            goalFrequency: goalFrequency,
            goalPeriod: goalPeriod,
            reminderTime: reminderEnabled ? reminderTime : nil
        )

        habitStore.addHabit(habit)

        if reminderEnabled {
            NotificationService.shared.scheduleReminder(for: habit)
        }

        dismiss()
    }
}

// MARK: - Icon Picker

struct IconPickerView: View {
    @Binding var selectedIcon: String
    let color: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(HabitIcon.presets, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(selectedIcon == icon ? .white : color)
                    .frame(width: 36, height: 36)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedIcon == icon ? color : color.opacity(0.1))
                    }
                    .onTapGesture {
                        selectedIcon = icon
                    }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Color Picker

struct ColorPickerView: View {
    @Binding var selectedColor: HabitColor

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(HabitColor.presets) { preset in
                Circle()
                    .fill(preset.color)
                    .frame(width: 36, height: 36)
                    .overlay {
                        if selectedColor.name == preset.name {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        selectedColor = preset
                    }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AddHabitView(habitStore: HabitStore(context: PersistenceController.preview.container.viewContext))
}
