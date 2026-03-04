import XCTest
import SwiftUI
import SnapshotTesting
@testable import HabitualCore

final class MascotSnapshotTests: SnapshotTestCase {

    // MARK: - MascotFaceView — All Mascots

    func testMascotFaceView_AllMascots_Encouraging() {
        let view = SnapshotContainer(width: 390) {
            HStack(spacing: 20) {
                ForEach(Mascot.allCases, id: \.name) { mascot in
                    VStack(spacing: 8) {
                        MascotFaceView(mascot: mascot, mood: .encouraging, size: 80)
                        Text(mascot.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testMascotFaceView_AllMascots_Excited() {
        let view = SnapshotContainer(width: 390) {
            HStack(spacing: 20) {
                ForEach(Mascot.allCases, id: \.name) { mascot in
                    VStack(spacing: 8) {
                        MascotFaceView(mascot: mascot, mood: .excited, size: 80)
                        Text(mascot.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testMascotFaceView_AllMascots_Relaxed() {
        let view = SnapshotContainer(width: 390) {
            HStack(spacing: 20) {
                ForEach(Mascot.allCases, id: \.name) { mascot in
                    VStack(spacing: 8) {
                        MascotFaceView(mascot: mascot, mood: .relaxed, size: 80)
                        Text(mascot.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testMascotFaceView_AllMascots_Happy() {
        let view = SnapshotContainer(width: 390) {
            HStack(spacing: 20) {
                ForEach(Mascot.allCases, id: \.name) { mascot in
                    VStack(spacing: 8) {
                        MascotFaceView(mascot: mascot, mood: .happy, size: 80)
                        Text(mascot.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - MascotBannerView — All Moods

    func testMascotBannerView_Excited() {
        let view = SnapshotContainer(width: 390) {
            MascotBannerView(
                mascot: .dragon,
                mood: .excited,
                message: "7 days! Ryū is absolutely fired up! 🔥"
            )
            .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testMascotBannerView_Happy() {
        let view = SnapshotContainer(width: 390) {
            MascotBannerView(
                mascot: .cat,
                mood: .happy,
                message: "Nice work! 3 days in a row — you're building something real."
            )
            .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testMascotBannerView_Encouraging() {
        let view = SnapshotContainer(width: 390) {
            MascotBannerView(
                mascot: .capybara,
                mood: .encouraging,
                message: "Kapiiko is cheering you on. There's still time today!"
            )
            .padding()
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testMascotBannerView_Dark() {
        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 16) {
                MascotBannerView(
                    mascot: .dragon,
                    mood: .excited,
                    message: "7 days! Ryū is absolutely fired up! 🔥"
                )
                MascotBannerView(
                    mascot: .cat,
                    mood: .encouraging,
                    message: "Neko believes in you. There's still time today!"
                )
            }
            .padding()
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    // MARK: - MascotCelebrationView

    func testMascotCelebrationView_7DayStreak() {
        let view = SnapshotContainer(width: 390, height: 700) {
            ZStack {
                Color.systemBackground
                MascotCelebrationView(
                    mascot: .dragon,
                    streakCount: 7,
                    onDismiss: {}
                )
            }
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testMascotCelebrationView_30DayStreak() {
        let view = SnapshotContainer(width: 390, height: 700) {
            ZStack {
                Color.systemBackground
                MascotCelebrationView(
                    mascot: .dragon,
                    streakCount: 30,
                    onDismiss: {}
                )
            }
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
