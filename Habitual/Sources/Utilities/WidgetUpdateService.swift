#if canImport(WidgetKit)
import WidgetKit
#endif

/// Service to notify widgets when habit data changes
struct WidgetUpdateService {
    static func reloadAllWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func reloadHabitWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "HabitualWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "SingleHabitWidget")
        #endif
    }
}
