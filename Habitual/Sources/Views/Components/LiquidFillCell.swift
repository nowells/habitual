import SwiftUI

// MARK: - Liquid Fill Cell

/// A unified visual cell for rendering habit completion using a liquid fill metaphor.
/// Cells fill from the bottom like a glass, with layered intensity levels that stack
/// as the user exceeds their goal. Intensity is relative — scaled to `maxCount` so the
/// brightest cell in the dataset is always full intensity.
///
/// Level boundaries align with goal multiples: a goal of 3 crosses a boundary every 3
/// completions. The alpha for each level = `(levelNumber * goal) / maxCount`.
struct LiquidFillCell: View {
    let count: Int
    let goal: Int
    let color: Color
    let status: CellStatus
    let size: CGFloat
    /// The maximum count across all visible cells. Determines full intensity (alpha 1.0).
    /// When 0 or omitted, defaults to `max(count, 1)` (absolute mode).
    var maxCount: Int = 0

    private var effectiveMax: Int { max(maxCount, count, 1) }

    /// Number of full goal cycles completed
    private var fullLevels: Int { count / max(goal, 1) }

    /// Fractional progress within the current goal cycle (0.0–1.0)
    private var partialProgress: CGFloat {
        CGFloat(count % max(goal, 1)) / CGFloat(max(goal, 1))
    }

    /// Alpha for a given level number, scaled relative to maxCount.
    /// Level N corresponds to `N * goal` completions.
    /// Alpha = `(N * goal) / effectiveMax`, capped at 1.0.
    private func levelAlpha(_ level: Int) -> CGFloat {
        guard effectiveMax > 0 else { return 0 }
        let levelCount = level * max(goal, 1)
        return min(CGFloat(levelCount) / CGFloat(effectiveMax), 1.0)
    }

    private var cornerRadius: CGFloat {
        size > 20 ? 3 : 2
    }

    private var innerCornerRadius: CGFloat {
        size > 20 ? 2 : 1
    }

    var body: some View {
        switch status {
        case .future:
            futureCell
        case .today:
            todayCell
        case .missed:
            missedCell
        case .brokeStreak:
            brokeStreakCell
        case .partial, .complete, .overComplete:
            liquidFillBody
        }
    }

    // MARK: - Future Cell

    private var futureCell: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.03))
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        Color.white.opacity(0.08),
                        style: StrokeStyle(lineWidth: 0.5, dash: [2, 2])
                    )
            )
    }

    // MARK: - Today Cell

    private var todayCell: some View {
        ZStack(alignment: .bottom) {
            if count >= 1 {
                // Base level fill
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color.opacity(levelAlpha(fullLevels)))
                    .frame(width: size, height: size)

                // Next level liquid fill from bottom
                if partialProgress > 0 {
                    RoundedRectangle(cornerRadius: innerCornerRadius)
                        .fill(color.opacity(levelAlpha(fullLevels + 1)))
                        .frame(width: size - 2, height: (size - 2) * partialProgress)
                        .padding(1)
                }
            } else {
                // Empty today — show center dot
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.clear)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .fill(color)
                            .frame(width: size * 0.22, height: size * 0.22)
                    )
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color, lineWidth: size > 20 ? 2 : 1.5)
        )
        .shadow(color: color.opacity(0.35), radius: size > 20 ? 8 : 4)
    }

    // MARK: - Missed Cell (Pre-Habit / No Data)

    private var missedCell: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.03))
            .frame(width: size, height: size)
    }

    // MARK: - Broke Streak Cell (outline only)

    private var brokeStreakCell: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.clear)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.red.opacity(0.35), lineWidth: 1)
            )
    }

    // MARK: - Liquid Fill Body (Partial, Complete, Over-Complete)

    private var liquidFillBody: some View {
        ZStack(alignment: .bottom) {
            // Base level fill
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color.opacity(levelAlpha(fullLevels)))

            // Next level liquid fill from bottom
            if partialProgress > 0 {
                RoundedRectangle(cornerRadius: innerCornerRadius)
                    .fill(color.opacity(levelAlpha(fullLevels + 1)))
                    .frame(height: size * partialProgress)
                    .padding(1)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            // Border for 2x+ goal
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color.opacity(0.4), lineWidth: 1)
                .opacity(fullLevels >= 2 ? 1 : 0)
        )
        .shadow(
            color: color.opacity(fullLevels >= 3 ? 0.3 : 0),
            radius: size > 20 ? 6 : 3
        )
    }
}

// MARK: - Calendar Liquid Fill Cell

/// A variant of LiquidFillCell for calendar month views with a day number overlay.
struct CalendarLiquidFillCell: View {
    let dayNumber: Int
    let count: Int
    let goal: Int
    let color: Color
    let status: CellStatus
    let size: CGFloat
    var maxCount: Int = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            LiquidFillCell(
                count: count,
                goal: goal,
                color: color,
                status: status,
                size: size,
                maxCount: maxCount
            )

            // Day number
            Text("\(dayNumber)")
                .font(.caption)
                .fontWeight(status == .today ? .bold : .regular)
                .foregroundStyle(dayNumberColor)
                .padding(.leading, 4)
                .padding(.top, 2)
        }
        .frame(width: size, height: size)
    }

    private var dayNumberColor: Color {
        switch status {
        case .future, .missed:
            return .secondary
        case .today:
            return color
        case .brokeStreak:
            return .primary
        case .partial, .complete, .overComplete:
            return count >= goal ? .white : .primary
        }
    }
}

// MARK: - Intensity Legend

/// The "Less → More" legend strip showing 5 intensity swatches.
struct LiquidFillLegend: View {
    let color: Color
    let cellSize: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            ForEach(0..<5) { level in
                let alpha: CGFloat = CGFloat(level) / 4.0
                RoundedRectangle(cornerRadius: cellSize > 14 ? 2 : 1)
                    .fill(level == 0 ? Color.white.opacity(0.03) : color.opacity(alpha))
                    .frame(width: cellSize, height: cellSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: cellSize > 14 ? 2 : 1)
                            .strokeBorder(
                                level == 0 ? Color.white.opacity(0.08) : Color.clear,
                                lineWidth: 0.5
                            )
                    )
            }

            Text("More")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Liquid Fill — Relative Intensity") {
    VStack(spacing: 20) {
        // Goal = 3, max = 12, showing 0/3 through 12/3
        let maxCount = 12
        HStack(spacing: 8) {
            ForEach([0, 1, 2, 3, 4, 5, 6, 9, 12], id: \.self) { count in
                VStack(spacing: 4) {
                    LiquidFillCell(
                        count: count,
                        goal: 3,
                        color: .blue,
                        status: count == 0 ? .missed : (count < 3 ? .partial : (count == 3 ? .complete : .overComplete)),
                        size: 32,
                        maxCount: maxCount
                    )
                    Text("\(count)/3")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }

        // Same data but max = 3 (everything at 3 is full brightness)
        HStack(spacing: 8) {
            ForEach([0, 1, 2, 3], id: \.self) { count in
                VStack(spacing: 4) {
                    LiquidFillCell(
                        count: count,
                        goal: 3,
                        color: .blue,
                        status: count == 0 ? .missed : (count < 3 ? .partial : .complete),
                        size: 32,
                        maxCount: 3
                    )
                    Text("\(count)/3 max=3")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }

        // Special states
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                LiquidFillCell(count: 0, goal: 3, color: .blue, status: .future, size: 32)
                Text("Future").font(.system(size: 9)).foregroundStyle(.secondary)
            }
            VStack(spacing: 4) {
                LiquidFillCell(count: 0, goal: 3, color: .blue, status: .today, size: 32)
                Text("Today").font(.system(size: 9)).foregroundStyle(.secondary)
            }
            VStack(spacing: 4) {
                LiquidFillCell(count: 2, goal: 3, color: .blue, status: .today, size: 32, maxCount: 6)
                Text("Today 2/3").font(.system(size: 9)).foregroundStyle(.secondary)
            }
            VStack(spacing: 4) {
                LiquidFillCell(count: 0, goal: 3, color: .blue, status: .missed, size: 32)
                Text("Missed").font(.system(size: 9)).foregroundStyle(.secondary)
            }
            VStack(spacing: 4) {
                LiquidFillCell(count: 0, goal: 3, color: .blue, status: .brokeStreak, size: 32)
                Text("Broke").font(.system(size: 9)).foregroundStyle(.secondary)
            }
        }

        LiquidFillLegend(color: .blue, cellSize: 12)
    }
    .padding()
    .background(Color(red: 0.004, green: 0.016, blue: 0.035))
}
