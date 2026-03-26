import SwiftUI

// MARK: - Radial Progress View (Fitness Ring Style)

/// Renders a radial progress indicator similar to Apple Watch fitness rings.
/// Supports multiple rotations: each full completion of the goal adds a new ring layer
/// with a progressively adjusted color, creating an overlapping ring effect.
struct RadialProgressView: View {
    let completionCount: Int
    let goalFrequency: Int
    let baseColor: Color
    let lineWidth: CGFloat
    let size: CGFloat

    init(
        completionCount: Int,
        goalFrequency: Int,
        baseColor: Color,
        lineWidth: CGFloat = 4,
        size: CGFloat = 36
    ) {
        self.completionCount = completionCount
        self.goalFrequency = goalFrequency
        self.baseColor = baseColor
        self.lineWidth = lineWidth
        self.size = size
    }

    private var progress: Double {
        guard goalFrequency > 0 else { return 0 }
        return Double(completionCount) / Double(goalFrequency)
    }

    private var fullRotations: Int {
        guard goalFrequency > 0 else { return 0 }
        return completionCount / goalFrequency
    }

    private var currentRotationFraction: Double {
        guard goalFrequency > 0 else { return 0 }
        let remainder = completionCount % goalFrequency
        if remainder == 0 && completionCount > 0 { return 1.0 }
        return Double(remainder) / Double(goalFrequency)
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    baseColor.opacity(0.15),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Draw completed full rings (bottom to top)
            ForEach(Array(0..<max(fullRotations, 0)), id: \.self) { rotation in
                ringArc(fraction: 1.0, rotation: rotation)
            }

            // Draw current partial ring on top
            if currentRotationFraction > 0 && currentRotationFraction < 1.0 {
                ringArc(fraction: currentRotationFraction, rotation: fullRotations)
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func ringArc(fraction: Double, rotation: Int) -> some View {
        let ringColor = Self.ringColor(base: baseColor, rotation: rotation)
        let shadowOpacity = fraction >= 0.95 ? 0.3 : 0.0

        Circle()
            .trim(from: 0, to: CGFloat(min(fraction, 1.0)))
            .stroke(
                ringColor,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .shadow(color: ringColor.opacity(shadowOpacity), radius: lineWidth * 0.5)
    }

    /// Returns a color for each ring rotation, cycling through complementary colors
    static func ringColor(base: Color, rotation: Int) -> Color {
        switch rotation % 5 {
        case 0: return base
        case 1: return .orange
        case 2: return .green
        case 3: return .purple
        case 4: return .pink
        default: return base
        }
    }
}

// MARK: - Radial Progress Heatmap Cell

/// A single cell in the period heatmap, showing a small radial progress ring
struct RadialHeatmapCell: View {
    let periodData: PeriodData
    let baseColor: Color
    let size: CGFloat
    var onTap: (() -> Void)?

    var body: some View {
        ZStack {
            // Background square
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(Color.systemGray5.opacity(periodData.isFuture ? 0 : 1))
                .frame(width: size, height: size)

            if !periodData.isFuture && periodData.completionCount > 0 {
                RadialProgressView(
                    completionCount: periodData.completionCount,
                    goalFrequency: periodData.goalFrequency,
                    baseColor: baseColor,
                    lineWidth: max(1.5, size * 0.12),
                    size: size * 0.85
                )
            }
        }
        .onTapGesture {
            if !periodData.isFuture {
                onTap?()
            }
        }
    }
}

// MARK: - Radial Check-in Button

/// A check-in button that shows radial progress for the current period.
/// Tapping adds one completion. The ring fills as completions approach the goal.
struct RadialCheckInButton: View {
    let habit: Habit
    let today: Date
    let size: CGFloat
    var onTap: () -> Void

    private var completionsInPeriod: Int {
        habit.completionsInPeriod(containing: today)
    }

    private var progress: Double {
        habit.periodProgress(for: today)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    RadialProgressView(
                        completionCount: completionsInPeriod,
                        goalFrequency: habit.goalFrequency,
                        baseColor: habit.color,
                        lineWidth: size * 0.1,
                        size: size
                    )

                    // Center content
                    if completionsInPeriod == 0 {
                        Image(systemName: "plus")
                            .font(.system(size: size * 0.3, weight: .medium))
                            .foregroundStyle(Color.systemGray3)
                    } else {
                        Text("\(completionsInPeriod)")
                            .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                            .foregroundStyle(habit.color)
                    }
                }

                if habit.goalFrequency > 1 {
                    Text("\(completionsInPeriod)/\(habit.goalFrequency)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text(habit.goalPeriod == .daily ? "Today" : habit.goalPeriod.periodLabel.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Radial Progress Sizes") {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            ForEach([0, 1, 2, 3, 4, 5], id: \.self) { count in
                VStack {
                    RadialProgressView(
                        completionCount: count,
                        goalFrequency: 3,
                        baseColor: .blue,
                        lineWidth: 4,
                        size: 40
                    )
                    Text("\(count)/3")
                        .font(.caption)
                }
            }
        }

        HStack(spacing: 16) {
            ForEach([0, 1, 2, 3, 6, 9], id: \.self) { count in
                VStack {
                    RadialProgressView(
                        completionCount: count,
                        goalFrequency: 3,
                        baseColor: .green,
                        lineWidth: 6,
                        size: 60
                    )
                    Text("\(count)/3")
                        .font(.caption)
                }
            }
        }
    }
    .padding()
}
