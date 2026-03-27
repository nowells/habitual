import Combine
import CoreData
import SwiftUI

#if canImport(WidgetKit)
    import WidgetKit
#endif

@MainActor
class HabitStore: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    @Published var habits: [Habit] = []
    @Published var searchText: String = ""

    var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }
    }

    var archivedHabits: [Habit] {
        habits.filter { $0.isArchived }
    }

    var filteredHabits: [Habit] {
        if searchText.isEmpty {
            return activeHabits
        }
        return activeHabits.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchHabits()

        // Listen for remote changes from CloudKit
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.viewContext.refreshAllObjects()
                self?.fetchHabits()
            }
            .store(in: &cancellables)
    }

    func fetchHabits() {
        let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDHabit.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \CDHabit.createdAt, ascending: false),
        ]

        do {
            let cdHabits = try viewContext.fetch(request)
            self.habits = cdHabits.map { $0.toHabit() }
        } catch {
            print("Error fetching habits: \(error)")
        }
    }

    func addHabit(_ habit: Habit) {
        let cdHabit = CDHabit(context: viewContext)
        cdHabit.id = habit.id
        cdHabit.name = habit.name
        cdHabit.habitDescription = habit.description
        cdHabit.icon = HabitIcon.resolve(habit.icon)
        cdHabit.colorRed = habit.colorComponents.red
        cdHabit.colorGreen = habit.colorComponents.green
        cdHabit.colorBlue = habit.colorComponents.blue
        cdHabit.createdAt = habit.createdAt
        cdHabit.isArchived = false
        cdHabit.goalFrequency = Int16(habit.goalFrequency)
        cdHabit.goalPeriod = habit.goalPeriod.rawValue
        cdHabit.reminderTime = habit.reminderTime
        cdHabit.sortOrder = Int16(habits.count)

        save()
        fetchHabits()
    }

    func updateHabit(_ habit: Habit) {
        guard let cdHabit = fetchCDHabit(by: habit.id) else { return }
        cdHabit.update(from: habit)
        save()
        fetchHabits()
    }

    func deleteHabit(_ habit: Habit) {
        guard let cdHabit = fetchCDHabit(by: habit.id) else { return }
        viewContext.delete(cdHabit)
        save()
        fetchHabits()
        // Clean up associated notifications and nudge settings
        NotificationService.shared.removeReminder(for: habit)
        NudgeService.removeSettings(for: habit)
        NudgeService.removePeriodSettings(for: habit)
    }

    func archiveHabit(_ habit: Habit) {
        guard let cdHabit = fetchCDHabit(by: habit.id) else { return }
        cdHabit.isArchived = true
        save()
        fetchHabits()
    }

    func unarchiveHabit(_ habit: Habit) {
        guard let cdHabit = fetchCDHabit(by: habit.id) else { return }
        cdHabit.isArchived = false
        save()
        fetchHabits()
    }

    func toggleCompletion(for habit: Habit, on date: Date) {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        guard let cdHabit = fetchCDHabit(by: habit.id) else { return }
        let completionSet = (cdHabit.completions as? Set<CDCompletion>) ?? []

        if let existing = completionSet.first(where: { calendar.startOfDay(for: $0.date ?? Date()) == targetDay }) {
            // Remove completion
            viewContext.delete(existing)
        } else {
            // Add completion
            let completion = CDCompletion(context: viewContext)
            completion.id = UUID()
            completion.date = targetDay
            completion.value = 1.0
            completion.habit = cdHabit
        }

        save()
        fetchHabits()
        notifyWidgets()
    }

    func toggleTodayCompletion(for habit: Habit) {
        toggleCompletion(for: habit, on: Date())
    }

    /// Add one completion for the given date (incremental, does not toggle/remove)
    func addCompletion(for habit: Habit, on date: Date = Date()) {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        guard let cdHabit = fetchCDHabit(by: habit.id) else { return }

        let completion = CDCompletion(context: viewContext)
        completion.id = UUID()
        completion.date = targetDay
        completion.value = 1.0
        completion.habit = cdHabit

        save()
        fetchHabits()
        notifyWidgets()
    }

    /// Remove the most recent completion for the given date
    func removeLastCompletion(for habit: Habit, on date: Date = Date()) {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        guard let cdHabit = fetchCDHabit(by: habit.id) else { return }
        let completionSet = (cdHabit.completions as? Set<CDCompletion>) ?? []

        let dayCompletions =
            completionSet
            .filter { calendar.startOfDay(for: $0.date ?? Date()) == targetDay }
            .sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }

        if let last = dayCompletions.first {
            viewContext.delete(last)
            save()
            fetchHabits()
            notifyWidgets()
        }
    }

    /// Remove all completions within a given period for a habit
    func removeAllCompletionsInPeriod(for habit: Habit, periodStart: Date, periodEnd: Date) {
        let calendar = Calendar.current
        guard let cdHabit = fetchCDHabit(by: habit.id) else { return }
        let completionSet = (cdHabit.completions as? Set<CDCompletion>) ?? []

        let periodCompletions = completionSet.filter { completion in
            let completionDay = calendar.startOfDay(for: completion.date ?? Date())
            return completionDay >= periodStart && completionDay < periodEnd
        }

        for completion in periodCompletions {
            viewContext.delete(completion)
        }

        if !periodCompletions.isEmpty {
            save()
            fetchHabits()
        }
    }

    /// Mark a habit complete today by ID — used by notification action handlers and App Intents.
    func completeHabit(id: UUID) {
        guard let habit = activeHabits.first(where: { $0.id == id }) else { return }
        addCompletion(for: habit)
    }

    func moveHabits(from source: IndexSet, to destination: Int) {
        var reordered = activeHabits
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, habit) in reordered.enumerated() {
            if let cdHabit = fetchCDHabit(by: habit.id) {
                cdHabit.sortOrder = Int16(index)
            }
        }

        save()
        fetchHabits()
    }

    // MARK: - Private Helpers

    private func fetchCDHabit(by id: UUID) -> CDHabit? {
        let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }

    private func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    private func notifyWidgets() {
        #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: "HabitualWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "SingleHabitWidget")
        #endif
    }
}
