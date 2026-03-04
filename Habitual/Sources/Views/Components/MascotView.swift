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

// MARK: - Mascot Face View

/// A kawaii chibi mascot face drawn entirely in SwiftUI shapes — no images needed.
struct MascotFaceView: View {
    let mascot: Mascot
    let mood: MascotMood
    var size: CGFloat = 80

    @State private var bouncing = false
    @State private var blinking = false

    private var bodyColor: Color {
        switch mascot {
        case .dragon:   return Color(red: 0.25, green: 0.72, blue: 0.42)
        case .cat:      return Color(red: 0.95, green: 0.75, blue: 0.50)
        case .capybara: return Color(red: 0.65, green: 0.52, blue: 0.38)
        case .dog:      return Color(red: 0.92, green: 0.82, blue: 0.62)
        }
    }

    private var accentColor: Color {
        switch mascot {
        case .dragon:   return Color(red: 0.15, green: 0.55, blue: 0.30)
        case .cat:      return Color(red: 0.75, green: 0.50, blue: 0.28)
        case .capybara: return Color(red: 0.48, green: 0.36, blue: 0.22)
        case .dog:      return Color(red: 0.70, green: 0.58, blue: 0.38)
        }
    }

    var body: some View {
        ZStack {
            // Drop shadow
            Ellipse()
                .fill(Color.black.opacity(0.12))
                .frame(width: size * 0.9, height: size * 0.18)
                .offset(y: size * 0.52)
                .blur(radius: 4)

            GeometryReader { _ in
                ZStack {
                    faceLayer
                }
                .frame(width: size, height: size)
            }
            .frame(width: size, height: size)
        }
        .offset(y: bouncing ? -6 : 0)
        .animation(
            .easeInOut(duration: 0.55).repeatForever(autoreverses: true),
            value: bouncing
        )
        .onAppear {
            bouncing = true
            // Blink every few seconds
            Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
                Task { @MainActor in
                    blinking = true
                    try? await Task.sleep(nanoseconds: 120_000_000)
                    blinking = false
                }
            }
        }
    }

    @ViewBuilder
    private var faceLayer: some View {
        let s = size
        ZStack {
            // Ears / special features (behind head)
            earLayer(s: s)

            // Head
            Circle()
                .fill(bodyColor)
                .overlay(Circle().strokeBorder(accentColor.opacity(0.6), lineWidth: s * 0.035))
                .frame(width: s * 0.88, height: s * 0.88)

            // Face features
            VStack(spacing: 0) {
                Spacer(minLength: s * 0.08)

                // Eyes row
                HStack(spacing: s * 0.16) {
                    eyeView(s: s)
                    eyeView(s: s)
                }

                Spacer(minLength: s * 0.03)

                // Nose
                Ellipse()
                    .fill(Color.pink.opacity(0.7))
                    .frame(width: s * 0.1, height: s * 0.07)

                Spacer(minLength: s * 0.02)

                // Mouth
                mouthShape(s: s)

                Spacer(minLength: s * 0.1)
            }
            .frame(width: s * 0.88, height: s * 0.88)

            // Blush
            HStack(spacing: s * 0.38) {
                blushCircle(s: s)
                blushCircle(s: s)
            }
            .offset(y: s * 0.12)

            // Dragon horns / dog ears overlay
            specialFeatureOverlay(s: s)

            // Mood exclamation bubble
            if mood == .excited || mood == .celebrating {
                Text("!")
                    .font(.system(size: s * 0.3, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)
                    .shadow(color: .orange.opacity(0.6), radius: 2, x: 1, y: 1)
                    .offset(x: s * 0.42, y: -s * 0.38)
            }
        }
    }

    @ViewBuilder
    private func earLayer(s: CGFloat) -> some View {
        switch mascot {
        case .cat:
            // Cat pointy ears
            HStack(spacing: s * 0.45) {
                Triangle()
                    .fill(bodyColor)
                    .overlay(Triangle().stroke(accentColor.opacity(0.5), lineWidth: 2))
                    .frame(width: s * 0.22, height: s * 0.22)
                Triangle()
                    .fill(bodyColor)
                    .overlay(Triangle().stroke(accentColor.opacity(0.5), lineWidth: 2))
                    .frame(width: s * 0.22, height: s * 0.22)
            }
            .offset(y: -s * 0.36)
        case .dog:
            // Floppy dog ears
            HStack(spacing: s * 0.52) {
                Ellipse()
                    .fill(accentColor.opacity(0.8))
                    .frame(width: s * 0.25, height: s * 0.35)
                    .rotationEffect(.degrees(-15))
                    .offset(y: s * 0.05)
                Ellipse()
                    .fill(accentColor.opacity(0.8))
                    .frame(width: s * 0.25, height: s * 0.35)
                    .rotationEffect(.degrees(15))
                    .offset(y: s * 0.05)
            }
            .offset(y: -s * 0.28)
        case .capybara:
            // Round capybara ears
            HStack(spacing: s * 0.5) {
                Circle()
                    .fill(bodyColor)
                    .overlay(Circle().strokeBorder(accentColor.opacity(0.4), lineWidth: 2))
                    .frame(width: s * 0.2, height: s * 0.2)
                Circle()
                    .fill(bodyColor)
                    .overlay(Circle().strokeBorder(accentColor.opacity(0.4), lineWidth: 2))
                    .frame(width: s * 0.2, height: s * 0.2)
            }
            .offset(y: -s * 0.38)
        case .dragon:
            EmptyView() // horns handled in overlay
        }
    }

    @ViewBuilder
    private func specialFeatureOverlay(s: CGFloat) -> some View {
        if mascot == .dragon {
            // Dragon horns (on top)
            HStack(spacing: s * 0.3) {
                Triangle()
                    .fill(Color(red: 0.15, green: 0.55, blue: 0.30))
                    .frame(width: s * 0.15, height: s * 0.28)
                    .rotationEffect(.degrees(-10))
                Triangle()
                    .fill(Color(red: 0.15, green: 0.55, blue: 0.30))
                    .frame(width: s * 0.15, height: s * 0.28)
                    .rotationEffect(.degrees(10))
            }
            .offset(y: -s * 0.42)
        }
    }

    @ViewBuilder
    private func eyeView(s: CGFloat) -> some View {
        ZStack {
            if blinking {
                // Closed eye: arc line
                Capsule()
                    .fill(accentColor)
                    .frame(width: s * 0.17, height: s * 0.04)
            } else {
                // Open eye
                Circle()
                    .fill(Color.white)
                    .frame(width: s * 0.22, height: s * 0.22)
                // Iris
                Circle()
                    .fill(mood == .relaxed ? Color(red: 0.3, green: 0.6, blue: 0.9) : Color(red: 0.1, green: 0.1, blue: 0.15))
                    .frame(width: s * 0.14, height: s * 0.14)
                    .offset(y: 1)
                // Shine
                Circle()
                    .fill(Color.white)
                    .frame(width: s * 0.07, height: s * 0.07)
                    .offset(x: -s * 0.04, y: -s * 0.04)
                // Happy squint when excited
                if mood == .excited || mood == .celebrating {
                    Arc(startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
                        .stroke(Color.white, lineWidth: s * 0.025)
                        .frame(width: s * 0.18, height: s * 0.14)
                }
            }
        }
    }

    @ViewBuilder
    private func mouthShape(s: CGFloat) -> some View {
        switch mood {
        case .excited, .celebrating, .happy:
            // Big smile
            Arc(startAngle: .degrees(10), endAngle: .degrees(170), clockwise: false)
                .stroke(accentColor, lineWidth: s * 0.045)
                .frame(width: s * 0.3, height: s * 0.18)
        case .encouraging:
            // Neutral-positive small smile
            Arc(startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                .stroke(accentColor, lineWidth: s * 0.04)
                .frame(width: s * 0.22, height: s * 0.12)
        case .relaxed:
            // Tiny content curve
            Arc(startAngle: .degrees(15), endAngle: .degrees(165), clockwise: false)
                .stroke(accentColor, lineWidth: s * 0.035)
                .frame(width: s * 0.18, height: s * 0.08)
        }
    }

    private func blushCircle(s: CGFloat) -> some View {
        Ellipse()
            .fill(Color.pink.opacity(0.35))
            .frame(width: s * 0.2, height: s * 0.12)
            .blur(radius: 3)
    }
}

// MARK: - Mascot Banner

/// Full mascot banner with speech bubble — used in empty states, streak milestones, celebrations.
struct MascotBannerView: View {
    let mascot: Mascot
    let mood: MascotMood
    let message: String
    var mascotSize: CGFloat = 72

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            MascotFaceView(mascot: mascot, mood: mood, size: mascotSize)

            SpeechBubbleView(text: message, mood: mood)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
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

/// Full-screen celebration overlay with sparkles and bouncing mascot.
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
                // Manga speed lines
                MangaSpeedLinesView()
                    .frame(width: 260, height: 260)
                    .opacity(0.25)

                MascotFaceView(mascot: mascot, mood: .celebrating, size: 110)

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

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let clockwise: Bool

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addArc(
                center: CGPoint(x: rect.midX, y: rect.midY),
                radius: rect.width / 2,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: clockwise
            )
        }
    }
}

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
#Preview("Dragon - Celebrating") {
    VStack(spacing: 24) {
        MascotFaceView(mascot: .dragon, mood: .celebrating, size: 100)
        MascotFaceView(mascot: .cat, mood: .happy, size: 100)
        MascotFaceView(mascot: .capybara, mood: .relaxed, size: 100)
        MascotFaceView(mascot: .dog, mood: .encouraging, size: 100)
    }
    .padding()
}

#Preview("Banner") {
    VStack(spacing: 16) {
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
