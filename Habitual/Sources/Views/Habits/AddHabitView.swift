import SwiftUI

struct AddHabitView: View {
    @ObservedObject var habitStore: HabitStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = HabitIcon.availablePresets.first ?? "star.fill"
    @State private var selectedColor = HabitColor.presets[0]
    @State private var goalFrequency = 1
    @State private var goalPeriod: Habit.GoalPeriod = .daily
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var nudgeEnabled = false
    @State private var nudgeTime = NudgeSettings.defaultNudgeTime

    var body: some View {
        Form {
            // MARK: Name & Description

            Section {
                TextField("e.g. Morning Run, Read, Meditate", text: $name)
                    .font(.headline)
                TextField("What's this habit about? (optional)", text: $description)
            } header: {
                Text("Habit")
            }

            // MARK: Appearance — Icon + Color in one section

            Section("Appearance") {
                IconPickerView(selectedIcon: $selectedIcon, color: selectedColor.color)
                ColorPickerView(selectedColor: $selectedColor)
            }

            // MARK: Live Preview — see it before you commit

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
        }
        .navigationTitle("New Habit")
        #if os(macOS)
        .formStyle(.grouped)
        #elseif os(iOS)
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

        let nudgeSettings = NudgeSettings(isEnabled: nudgeEnabled, nudgeTime: nudgeTime)
        NudgeService.apply(nudgeSettings, for: habit)

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
            ForEach(HabitIcon.availablePresets, id: \.self) { icon in
                HabitIcon.image(icon)
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
    NavigationStack {
        AddHabitView(habitStore: HabitStore(context: PersistenceController.preview.container.viewContext))
    }
}
