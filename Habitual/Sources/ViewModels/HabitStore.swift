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
    private var pendingWidgetReload: DispatchWorkItem?

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
        backfillCRDTFields()
        fetchHabits()

        // Listen for remote changes from CloudKit, debounced to avoid
        // rapid-fire refreshes during multi-batch sync.
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)
    }

    private func handleRemoteChange() {
        // Re-fault every registered object so the next fetch reads the
        // latest values from the persistent store — which now includes
        // the CloudKit import.  Without this the viewContext row cache
        // can serve stale property values, causing the UI to diverge
        // from other devices even after a successful sync.
        viewContext.refreshAllObjects()
        deduplicateCompletions()
        fetchHabits()
        scheduleWidgetReload()
    }

    /// Full refresh from the persistent store — called after manual sync
    /// and when the app returns to the foreground.
    func forceRefresh() {
        viewContext.refreshAllObjects()
        deduplicateCompletions()
        fetchHabits()
        scheduleWidgetReload()
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
        cdHabit.updatedAt = Date()

        save()
        fetchHabits()
    }

    func updateHabit(_ habit: Habit) {
        guard let cdHabit = fetchCDHabit(by: habit.id) else { return }
        cdHabit.update(from: habit)
        cdHabit.updatedAt = Date()
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
        cdHabit.updatedAt = Date()
        save()
        fetchHabits()
    }

    func unarchiveHabit(_ habit: Habit) {
        guard let cdHabit = fetchCDHabit(by: habit.id) else { return }
        cdHabit.isArchived = false
        cdHabit.updatedAt = Date()
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
            completion.deviceID = DeviceIdentifier.current
            completion.createdAt = Date()
        }

        save()
        fetchHabits()
        scheduleWidgetReload()
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
        completion.deviceID = DeviceIdentifier.current
        completion.createdAt = Date()

        save()
        fetchHabits()
        scheduleWidgetReload()
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
            scheduleWidgetReload()
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

        let now = Date()
        for (index, habit) in reordered.enumerated() {
            if let cdHabit = fetchCDHabit(by: habit.id) {
                cdHabit.sortOrder = Int16(index)
                cdHabit.updatedAt = now
            }
        }

        save()
        fetchHabits()
    }

    // MARK: - Sync

    /// Force a refresh from the persistent store (useful for pull-to-refresh on watchOS).
    func refresh() async {
        viewContext.refreshAllObjects()
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

    /// One-time backfill: stamp legacy CDCompletion records (created before
    /// CRDT fields were added) with the current device's ID and use their
    /// existing `date` as `createdAt`.
    ///
    /// This runs once per device — gated by a UserDefaults flag in the shared
    /// app group so all targets (app, widgets, watch) share the migration state.
    /// After backfill, Layer 2 dedup covers historical records too.
    private func backfillCRDTFields() {
        let defaults = DeviceIdentifier.persistentDefaults
        let key = "com.habitual.crdtBackfillComplete"
        guard !defaults.bool(forKey: key) else { return }

        let request: NSFetchRequest<CDCompletion> = CDCompletion.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == nil")

        guard let legacyCompletions = try? viewContext.fetch(request),
            !legacyCompletions.isEmpty
        else {
            // No legacy records (or fetch failed) — mark complete either way
            // so we don't re-check on every launch.
            defaults.set(true, forKey: key)
            return
        }

        let deviceID = DeviceIdentifier.current
        for completion in legacyCompletions {
            completion.deviceID = deviceID
            completion.createdAt = completion.date ?? Date()
        }

        save()
        defaults.set(true, forKey: key)
        print("[CRDT] Backfilled \(legacyCompletions.count) legacy completions with deviceID=\(deviceID)")
    }

    /// CRDT-style deduplication for completions synced via CloudKit.
    ///
    /// Each user action (tap, increment, App Intent) stamps the CDCompletion
    /// with `(deviceID, createdAt)` — a unique origin identity that survives
    /// CloudKit re-import even when the local CoreData UUID changes.
    ///
    /// Dedup strategy (layered, from most to least confident):
    ///
    /// 1. **Exact UUID match**: Two CDCompletion objects with the same `id`
    ///    UUID within the same habit → definitive duplicate, keep one.
    ///
    /// 2. **CRDT origin match**: Two records with the same
    ///    `(deviceID, createdAt)` within the same habit → same user action
    ///    re-imported with a new UUID. Keep one.
    ///
    /// 3. **Legacy records** (no deviceID/createdAt) are never touched by
    ///    rule 2 — they can only be deduped by exact UUID match. This is
    ///    safe because pre-migration records won't produce new CRDT-style
    ///    duplicates going forward.
    ///
    /// This preserves intentional over-completions: two distinct taps on the
    /// same device produce different `createdAt` timestamps (even rapid taps
    /// differ by milliseconds). Taps on different devices have different
    /// `deviceID` values. Neither case triggers dedup.
    private func deduplicateCompletions() {
        let request: NSFetchRequest<CDHabit> = CDHabit.fetchRequest()
        guard let cdHabits = try? viewContext.fetch(request) else { return }

        var didDelete = false

        for cdHabit in cdHabits {
            let completions = (cdHabit.completions as? Set<CDCompletion>) ?? []
            guard completions.count > 1 else { continue }

            // Layer 1: Exact UUID duplicates
            var seenIDs: [UUID: CDCompletion] = [:]
            for completion in completions {
                guard let cid = completion.id else { continue }
                if seenIDs[cid] != nil {
                    viewContext.delete(completion)
                    didDelete = true
                } else {
                    seenIDs[cid] = completion
                }
            }

            // Layer 2: CRDT origin duplicates — same (deviceID, createdAt)
            // Only applies to records that have CRDT fields populated.
            struct OriginKey: Hashable {
                let deviceID: String
                let createdAt: Date
            }

            var seenOrigins: [OriginKey: CDCompletion] = [:]
            for completion in completions where !completion.isDeleted {
                guard let deviceID = completion.deviceID,
                    let createdAt = completion.createdAt
                else { continue }  // Legacy record — skip

                let key = OriginKey(deviceID: deviceID, createdAt: createdAt)
                if seenOrigins[key] != nil {
                    viewContext.delete(completion)
                    didDelete = true
                } else {
                    seenOrigins[key] = completion
                }
            }
        }

        if didDelete {
            save()
        }
    }

    /// Throttle widget reloads — coalesces rapid calls into one reload
    /// after a short delay.
    private func scheduleWidgetReload() {
        pendingWidgetReload?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.notifyWidgets()
        }
        pendingWidgetReload = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    private func notifyWidgets() {
        #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: "HabitualWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "SingleHabitWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "HabitualComplication")
        #endif
    }
}
