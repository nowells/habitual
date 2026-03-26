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
    @State private var nudgeEnabled = false
    @State private var nudgeTime = NudgeSettings.defaultNudgeTime
    @State private var periodStartEnabled = false
    @State private var periodStartTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var periodMidEnabled = false
    @State private var periodMidTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @State private var periodEndEnabled = false
    @State private var periodEndTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()

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

            // MARK: Reminders

            Section {
                Toggle(periodStartLabel, isOn: $periodStartEnabled)
                if periodStartEnabled {
                    DatePicker("Time", selection: $periodStartTime, displayedComponents: .hourAndMinute)
                }

                Toggle(periodMidLabel, isOn: $periodMidEnabled)
                if periodMidEnabled {
                    DatePicker("Time", selection: $periodMidTime, displayedComponents: .hourAndMinute)
                }

                Toggle(periodEndLabel, isOn: $periodEndEnabled)
                if periodEndEnabled {
                    DatePicker("Time", selection: $periodEndTime, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text(reminderSectionHeader)
            } footer: {
                Text(periodReminderFooter)
            }

            // MARK: Smart Nudges

            Section {
                Toggle("Smart Nudges", isOn: $nudgeEnabled)
                if nudgeEnabled {
                    DatePicker(
                        "Nudge Time",
                        selection: $nudgeTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Smart Nudges")
            } footer: {
                Text(
                    "A nudge fires if you haven't logged this habit by the nudge time. Streak-at-risk alerts appear when you have 3+ days in a row."
                )
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

    private var periodStartLabel: String {
        switch goalPeriod {
        case .daily: return "Morning Reminder"
        case .weekly: return "Start of Week"
        case .monthly: return "Start of Month"
        }
    }

    private var periodMidLabel: String {
        switch goalPeriod {
        case .daily: return "Midday Check-in"
        case .weekly: return "Mid-Week Check-in"
        case .monthly: return "Mid-Month Check-in"
        }
    }

    private var periodEndLabel: String {
        switch goalPeriod {
        case .daily: return "Evening Reminder"
        case .weekly: return "End of Week Reminder"
        case .monthly: return "End of Month Reminder"
        }
    }

    private var reminderSectionHeader: String {
        switch goalPeriod {
        case .daily: return "Daily Reminders"
        case .weekly: return "Weekly Reminders"
        case .monthly: return "Monthly Reminders"
        }
    }

    private var periodReminderFooter: String {
        switch goalPeriod {
        case .daily:
            return "Get reminded at the start, middle, and end of each day to hit your goal."
        case .weekly:
            return "Get reminded at the start of the week, mid-week, and before the week ends."
        case .monthly:
            return "Get reminded at the start, middle, and end of each month."
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
            goalPeriod: goalPeriod
        )

        habitStore.addHabit(habit)

        let nudgeSettings = NudgeSettings(isEnabled: nudgeEnabled, nudgeTime: nudgeTime)
        NudgeService.apply(nudgeSettings, for: habit)

        let anyReminderEnabled = periodStartEnabled || periodMidEnabled || periodEndEnabled
        let periodSettings = PeriodReminderSettings(
            isEnabled: anyReminderEnabled,
            startReminderTime: periodStartTime,
            startReminderEnabled: periodStartEnabled,
            midReminderTime: periodMidTime,
            midReminderEnabled: periodMidEnabled,
            endReminderTime: periodEndTime,
            endReminderEnabled: periodEndEnabled
        )
        NudgeService.applyPeriodSettings(periodSettings, for: habit)

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
