import SwiftUI

// MARK: - Mascot Character

enum Mascot: CaseIterable {
    case dragon    // epic milestone celebration (7+ streak)
    case cat       // daily win & encouragement (1–6 streak)
    case capybara  // zen rest-day / new habit starter
    case dog       // energetic new-habit welcome

    var emoji: String {
        switch self {
        case .dragon:   return "🐉"
        case .cat:      return "🐱"
        case .capybara: return "🦫"
        case .dog:      return "🐶"
        }
    }

    var name: String {
        switch self {
        case .dragon:   return "Ryū"      // 龍
        case .cat:      return "Neko"     // 猫
        case .capybara: return "Kapiiko"  // カピーコ
        case .dog:      return "Wanko"    // わんこ
        }
    }

    /// Pick the right mascot for a habit's current streak
    static func forStreak(_ streak: Int, completed: Bool) -> Mascot {
        if !completed { return .capybara }
        if streak >= 7 { return .dragon }
        if streak >= 1 { return .cat }
        return .dog
    }
}

// MARK: - Mascot Mood

enum MascotMood {
    case excited     // 大興奮！ — just completed, high streak
    case happy       // うれしい — good progress
    case encouraging // がんばれ — not done yet, gentle push
    case relaxed     // のんびり — rest / chill day
    case celebrating // おめでとう — milestone hit

    var exclamation: String {
        switch self {
        case .excited:      return "すごい！"      // Amazing!
        case .happy:        return "やったね！"     // You did it!
        case .encouraging:  return "がんばれ！"     // Do your best!
        case .relaxed:      return "のんびり〜"     // Easy does it~
        case .celebrating:  return "おめでとう！"   // Congratulations!
        }
    }

    var englishSubtitle: String {
        switch self {
        case .excited:      return "Amazing!"
        case .happy:        return "You did it!"
        case .encouraging:  return "You've got this!"
        case .relaxed:      return "Take it easy~"
        case .celebrating:  return "Congratulations!"
        }
    }
}

// MARK: - Mascot Emoji View

/// A large, animated emoji mascot — expressive, mood-driven, and delightful.
/// Shows the system emoji character with a continuous idle float plus
/// mood-triggered bounce and wiggle animations on state changes.
struct MascotEmojiView: View {
    let mascot: Mascot
    let mood: MascotMood
    var size: CGFloat = 80

    @State private var floating = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Soft ground shadow — contracts when mascot floats up
            Ellipse()
                .fill(Color.black.opacity(0.10))
                .frame(width: size * 0.65, height: size * 0.10)
                .blur(radius: 4)
                .offset(y: size * 0.52)
                .scaleEffect(x: floating ? 0.82 : 1.0)
                .animation(
                    .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                    value: floating
                )

            // Emoji character
            Text(mascot.emoji)
                .font(.system(size: size * 0.82))
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .offset(y: floating ? -6 : 0)
                .animation(
                    .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                    value: floating
                )
        }
        .frame(width: size, height: size)
        .onAppear {
            floating = true
            triggerMoodAnimation()
        }
        .onChange(of: mood) { _, _ in
            triggerMoodAnimation()
        }
    }

    private func triggerMoodAnimation() {
        Task { @MainActor in
            switch mood {
            case .excited, .celebrating:
                // Big pop, double left-right wiggle, spring settle
                withAnimation(.spring(response: 0.20, dampingFraction: 0.35)) {
                    scale = 1.30; rotation = 14
                }
                try? await Task.sleep(nanoseconds: 190_000_000)
                withAnimation(.spring(response: 0.18, dampingFraction: 0.40)) {
                    rotation = -14
                }
                try? await Task.sleep(nanoseconds: 170_000_000)
                withAnimation(.spring(response: 0.18, dampingFraction: 0.40)) {
                    rotation = 7
                }
                try? await Task.sleep(nanoseconds: 150_000_000)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.60)) {
                    scale = 1.0; rotation = 0
                }

            case .happy:
                // Bouncy pop, settle
                withAnimation(.spring(response: 0.22, dampingFraction: 0.38)) {
                    scale = 1.18
                }
                try? await Task.sleep(nanoseconds: 230_000_000)
                withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
                    scale = 1.0
                }

            case .encouraging:
                // Left-right nod: "come on, you can do it"
                withAnimation(.spring(response: 0.16, dampingFraction: 0.50)) {
                    rotation = 12
                }
                try? await Task.sleep(nanoseconds: 155_000_000)
                withAnimation(.spring(response: 0.16, dampingFraction: 0.50)) {
                    rotation = -12
                }
                try? await Task.sleep(nanoseconds: 155_000_000)
                withAnimation(.spring(response: 0.16, dampingFraction: 0.50)) {
                    rotation = 6
                }
                try? await Task.sleep(nanoseconds: 130_000_000)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.70)) {
                    rotation = 0
                }

            case .relaxed:
                // Just the idle float — no extra trigger
                break
            }
        }
    }
}

// MARK: - Mascot Banner

/// Full mascot banner with speech bubble — used in detail view and empty state.
struct MascotBannerView: View {
    let mascot: Mascot
    let mood: MascotMood
    let message: String
    var mascotSize: CGFloat = 72

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            MascotEmojiView(mascot: mascot, mood: mood, size: mascotSize)

            SpeechBubbleView(text: message, mood: mood)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .offset(y: appeared ? 0 : 8)
        .animation(.spring(duration: 0.5, bounce: 0.4), value: appeared)
        .onAppear { appeared = true }
    }
}

// MARK: - Speech Bubble

struct SpeechBubbleView: View {
    let text: String
    let mood: MascotMood

    private var bubbleColor: Color {
        switch mood {
        case .excited, .celebrating: return Color(red: 1.0, green: 0.95, blue: 0.80)
        case .happy:                  return Color(red: 0.90, green: 1.0, blue: 0.90)
        case .encouraging:            return Color(red: 0.90, green: 0.93, blue: 1.0)
        case .relaxed:                return Color(red: 0.95, green: 0.95, blue: 0.95)
        }
    }

    private var borderColor: Color {
        switch mood {
        case .excited, .celebrating: return .orange
        case .happy:                  return .green
        case .encouraging:            return .blue
        case .relaxed:                return .gray
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(mood.exclamation)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(borderColor)
                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(bubbleColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(borderColor.opacity(0.5), lineWidth: 2)
                    )
            )

            // Tail pointing left toward mascot
            BubbleTail()
                .fill(bubbleColor)
                .overlay(BubbleTail().stroke(borderColor.opacity(0.5), lineWidth: 1.5))
                .frame(width: 14, height: 10)
                .offset(x: -6, y: 0)
        }
    }
}

// MARK: - Mascot Celebration Overlay

/// Full-screen celebration overlay with sparkles and bouncing mascot emoji.
/// Show this on milestone streak hits (7, 14, 21, 30 days).
struct MascotCelebrationView: View {
    let mascot: Mascot
    let streakCount: Int
    var onDismiss: () -> Void

    @State private var sparkles: [SparkleParticle] = SparkleParticle.random(count: 18)
    @State private var animating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Sparkle particles
            ForEach(sparkles) { particle in
                particle.shape
                    .foregroundStyle(particle.color)
                    .font(.system(size: particle.size))
                    .position(x: particle.x, y: particle.y)
                    .opacity(animating ? 0 : 1)
                    .offset(y: animating ? -180 : 0)
                    .animation(
                        .easeOut(duration: Double.random(in: 0.8...1.5))
                            .delay(Double.random(in: 0...0.4)),
                        value: animating
                    )
            }

            // Center card
            VStack(spacing: 20) {
                MangaSpeedLinesView()
                    .frame(width: 260, height: 260)
                    .opacity(0.25)

                MascotEmojiView(mascot: mascot, mood: .celebrating, size: 110)

                VStack(spacing: 6) {
                    Text(MascotMood.celebrating.exclamation)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("\(streakCount) Day Streak!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(celebrationMessage)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button("Keep Going! 🔥") { onDismiss() }
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
            .scaleEffect(animating ? 1 : 0.7)
            .animation(.spring(duration: 0.5, bounce: 0.4), value: animating)
        }
        .onAppear { animating = true }
    }

    private var celebrationMessage: String {
        switch streakCount {
        case 7:   return "\(mascot.name) is so proud of you! 🌟"
        case 14:  return "Two weeks of consistency! \(mascot.name) does a happy dance!"
        case 21:  return "21 days — it's a habit now! \(mascot.name) is amazed!"
        case 30:  return "A full month! \(mascot.name) bows deeply. 🙇"
        default:  return "\(mascot.name) is cheering you on!"
        }
    }
}

// MARK: - Manga Speed Lines

struct MangaSpeedLinesView: View {
    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            Canvas { context, size in
                let lineCount = 24
                for i in 0..<lineCount {
                    let angle = Double(i) / Double(lineCount) * .pi * 2
                    let length = max(size.width, size.height) * 0.7
                    let x2 = cx + cos(angle) * length
                    let y2 = cy + sin(angle) * length
                    var path = Path()
                    path.move(to: CGPoint(x: cx, y: cy))
                    path.addLine(to: CGPoint(x: x2, y: y2))
                    context.stroke(path, with: .color(.orange), lineWidth: 2)
                }
            }
        }
    }
}

// MARK: - Sparkle Particle

struct SparkleParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color

    var shape: Text {
        let emojis = ["⭐", "✨", "🌟", "💫", "🎊", "🎉"]
        return Text(emojis.randomElement() ?? "✨")
    }

    static func random(count: Int) -> [SparkleParticle] {
        let colors: [Color] = [.yellow, .orange, .pink, .cyan, .green]
        return (0..<count).map { _ in
            SparkleParticle(
                x: CGFloat.random(in: 40...340),
                y: CGFloat.random(in: 100...600),
                size: CGFloat.random(in: 14...28),
                color: colors.randomElement() ?? .yellow
            )
        }
    }
}

// MARK: - Helper Shapes

struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Preview

#if !os(macOS)
#Preview("Mascot Emoji — All Characters") {
    VStack(spacing: 24) {
        HStack(spacing: 20) {
            ForEach(Mascot.allCases, id: \.name) { mascot in
                VStack(spacing: 6) {
                    MascotEmojiView(mascot: mascot, mood: .excited, size: 80)
                    Text(mascot.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }

        Divider()

        MascotBannerView(
            mascot: .dragon,
            mood: .excited,
            message: "You're on a 7-day streak! Nothing can stop you!"
        )
        MascotBannerView(
            mascot: .cat,
            mood: .encouraging,
            message: "Still time today — Neko believes in you!"
        )
        MascotBannerView(
            mascot: .capybara,
            mood: .relaxed,
            message: "Every journey starts with one step. No rush!"
        )
    }
    .padding()
}
#endif
