import SnapshotTesting
import SwiftUI
import XCTest

@testable import HabitualCore

final class MascotSnapshotTests: SnapshotTestCase {

    // MARK: - MascotEmojiView — All Mascots per Mood

    func testMascotEmojiView_AllMascots_Encouraging() {
        let view = SnapshotContainer(width: 390) {
            HStack(spacing: 20) {
                ForEach(Mascot.allCases, id: \.name) { mascot in
                    VStack(spacing: 8) {
                        MascotEmojiView(mascot: mascot, mood: .encouraging, size: 80)
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

    func testMascotEmojiView_AllMascots_Excited() {
        let view = SnapshotContainer(width: 390) {
            HStack(spacing: 20) {
                ForEach(Mascot.allCases, id: \.name) { mascot in
                    VStack(spacing: 8) {
                        MascotEmojiView(mascot: mascot, mood: .excited, size: 80)
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

    func testMascotEmojiView_AllMascots_Relaxed() {
        let view = SnapshotContainer(width: 390) {
            HStack(spacing: 20) {
                ForEach(Mascot.allCases, id: \.name) { mascot in
                    VStack(spacing: 8) {
                        MascotEmojiView(mascot: mascot, mood: .relaxed, size: 80)
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

    func testMascotEmojiView_AllMascots_Happy() {
        let view = SnapshotContainer(width: 390) {
            HStack(spacing: 20) {
                ForEach(Mascot.allCases, id: \.name) { mascot in
                    VStack(spacing: 8) {
                        MascotEmojiView(mascot: mascot, mood: .happy, size: 80)
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

    // MARK: - MascotBannerView

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

    // MARK: - Celebration Card (static — no random sparkle particles)

    /// Renders the milestone card content without sparkle particles,
    /// which use CGFloat.random and would produce non-deterministic snapshots.
    func testMascotCelebrationCard_7DayStreak() {
        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 20) {
                MangaSpeedLinesView()
                    .frame(width: 260, height: 260)
                    .opacity(0.25)

                MascotEmojiView(mascot: .dragon, mood: .celebrating, size: 110)

                VStack(spacing: 6) {
                    Text(MascotMood.celebrating.exclamation)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("7 Day Streak!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Ryū is so proud of you! 🌟")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button("Keep Going! 🔥") {}
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                    )
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.systemBackground)
                    .shadow(color: .black.opacity(0.25), radius: 24, y: 8)
            )
            .padding(32)
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func testMascotCelebrationCard_30DayStreak() {
        let view = SnapshotContainer(width: 390) {
            VStack(spacing: 20) {
                MangaSpeedLinesView()
                    .frame(width: 260, height: 260)
                    .opacity(0.25)

                MascotEmojiView(mascot: .dragon, mood: .celebrating, size: 110)

                VStack(spacing: 6) {
                    Text(MascotMood.celebrating.exclamation)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("30 Day Streak!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("A full month! Ryū bows deeply. 🙇")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button("Keep Going! 🔥") {}
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                    )
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.systemBackground)
                    .shadow(color: .black.opacity(0.25), radius: 24, y: 8)
            )
            .padding(32)
        }

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
