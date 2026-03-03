import WidgetKit

/// Service to notify widgets when habit data changes
struct WidgetUpdateService {
    static func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func reloadHabitWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "HabitualWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "SingleHabitWidget")
    }
}
