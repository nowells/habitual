import XCTest
import SwiftUI
import SnapshotTesting
@testable import HabitualCore

final class SettingsSnapshotTests: SnapshotTestCase {

    // MARK: - Settings View

    func testSettingsView_Light() {
        let view = SnapshotContainer(width: 390, height: 700) {
            NavigationStack {
                SettingsView()
            }
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testSettingsView_Dark() {
        let view = SnapshotContainer(width: 390, height: 700) {
            NavigationStack {
                SettingsView()
            }
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
