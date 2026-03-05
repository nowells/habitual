import SwiftUI

private struct TodayKey: EnvironmentKey {
    static var defaultValue: Date { Date() }
}

extension EnvironmentValues {
    /// The "current date" used for streak, completion rate, and heatmap calculations.
    /// Override in snapshot tests with a fixed date for deterministic renders.
    var today: Date {
        get { self[TodayKey.self] }
        set { self[TodayKey.self] = newValue }
    }
}
