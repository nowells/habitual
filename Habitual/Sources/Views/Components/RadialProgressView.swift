import SwiftUI

// MARK: - Pie Progress Fill (for heatmap cells)

/// Fills a rounded square like a pie/clock sweep. As completions accumulate the
/// square fills clockwise from 12 o'clock. Completing the goal fills it fully;
/// over-completion wraps into a new rotation with a complementary color.
struct PieProgressFill: View {
    let completionCount: Int
    let goalFrequency: Int
    let baseColor: Color
    let size: CGFloat

    private var cornerRadius: CGFloat { size * 0.2 }

    private var fullRotations: Int {
        guard goalFrequency > 0 else { return 0 }
        return completionCount / goalFrequency
    }

    private var currentFraction: Double {
        guard goalFrequency > 0 else { return 0 }
        let remainder = completionCount % goalFrequency
        if remainder == 0 && completionCount > 0 { return 1.0 }
        return Double(remainder) / Double(goalFrequency)
    }

    private var fillColor: Color {
        RadialProgressView.ringColor(base: baseColor, rotation: fullRotations)
    }

    var body: some View {
        // Path-based pie wedge: draw from center with an oversized radius so the arc
        // extends past every corner of the bounding square, then clip to the rounded rect.
        Path { path in
            let center = CGPoint(x: size / 2, y: size / 2)
            // radius = size covers the half-diagonal (size/2 * √2 ≈ 0.71*size) with room to spare
            path.move(to: center)
            path.addArc(
                center: center,
                radius: size,
                startAngle: .degrees(-90),
                endAngle: .degrees(-90 + 360 * currentFraction),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(fillColor.opacity(0.85))
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Radial Progress View (ring style — used only in check-in button)

/// Renders a radial ring indicator similar to Apple Watch fitness rings.
/// Each full completion of the goal adds a new ring layer with a complementary color.
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

// MARK: - Radial Check-in Button

/// A check-in button that shows radial ring progress for the current period.
/// Tap = add one completion. Long press (≥0.5 s) = remove last completion.
///
/// Uses a real Button (so it consumes taps and prevents parent onTapGesture from firing)
/// combined with simultaneousGesture(LongPressGesture). A `longPressActivated` flag
/// prevents the Button action from also firing after a long press.
struct RadialCheckInButton: View {
    let habit: Habit
    let today: Date
    let size: CGFloat
    var onTap: () -> Void
    var onLongPress: (() -> Void)?

    @State private var longPressActivated = false

    private var completionsInPeriod: Int {
        habit.completionsInPeriod(containing: today)
    }

    var body: some View {
        Button {
            if longPressActivated {
                longPressActivated = false
            } else {
                onTap()
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RadialProgressView(
                        completionCount: completionsInPeriod,
                        goalFrequency: habit.goalFrequency,
                        baseColor: habit.color,
                        lineWidth: size * 0.1,
                        size: size
                    )

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
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    longPressActivated = true
                    onLongPress?()
                }
        )
    }
}

// MARK: - Previews

#Preview("Pie Fill Cells") {
    VStack(spacing: 20) {
        HStack(spacing: 8) {
            ForEach([0, 1, 2, 3, 4, 5, 6], id: \.self) { count in
                VStack(spacing: 4) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.systemGray5)
                            .frame(width: 24, height: 24)
                        if count > 0 {
                            PieProgressFill(completionCount: count, goalFrequency: 3, baseColor: .blue, size: 24)
                        }
                    }
                    Text("\(count)/3").font(.system(size: 9))
                }
            }
        }
    }
    .padding()
}

#Preview("Radial Check-In Button") {
    HStack(spacing: 24) {
        ForEach([0, 1, 2, 3, 5], id: \.self) { count in
            let habit = Habit(name: "Test", goalFrequency: 3, goalPeriod: .daily)
            RadialCheckInButton(habit: habit, today: Date(), size: 44, onTap: {})
        }
    }
    .padding()
}
