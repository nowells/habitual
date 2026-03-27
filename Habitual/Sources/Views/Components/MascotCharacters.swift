import SwiftUI

// MARK: - Mascot Character Drawing

/// Dispatches to the correct custom-drawn character view based on mascot type.
/// Each character is drawn entirely with SwiftUI Canvas — no emoji, no assets.
struct MascotCharacterDrawing: View {
    let mascot: Mascot
    let mood: MascotMood
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let drawRect = CGRect(origin: .zero, size: canvasSize)
            switch mascot {
            case .dragon:
                DragonRenderer.draw(in: context, rect: drawRect, mood: mood)
            case .cat:
                CatRenderer.draw(in: context, rect: drawRect, mood: mood)
            case .capybara:
                CapybaraRenderer.draw(in: context, rect: drawRect, mood: mood)
            case .dog:
                DogRenderer.draw(in: context, rect: drawRect, mood: mood)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Drawing Helpers

private struct DrawKit {
    static func ellipse(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: Color) {
        let rect = CGRect(x: x - w / 2, y: y - h / 2, width: w, height: h)
        ctx.fill(Ellipse().path(in: rect), with: .color(color))
    }

    static func circle(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, r: CGFloat, color: Color) {
        ellipse(&ctx, x: x, y: y, w: r * 2, h: r * 2, color: color)
    }

    static func roundedRect(
        _ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, radius: CGFloat, color: Color
    ) {
        let rect = CGRect(x: x - w / 2, y: y - h / 2, width: w, height: h)
        ctx.fill(RoundedRectangle(cornerRadius: radius).path(in: rect), with: .color(color))
    }

    /// Draw an arc/smile path
    static func smile(
        _ ctx: inout GraphicsContext, centerX: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: Color,
        lineWidth: CGFloat = 2
    ) {
        var path = Path()
        path.addArc(
            center: CGPoint(x: centerX, y: y), radius: width / 2,
            startAngle: .degrees(10), endAngle: .degrees(170), clockwise: false)
        ctx.stroke(path, with: .color(color), lineWidth: lineWidth)
    }

    /// Draw an open mouth (filled ellipse)
    static func openMouth(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        ellipse(&ctx, x: x, y: y, w: w, h: h, color: Color(red: 0.2, green: 0.1, blue: 0.1))
        // tongue
        ellipse(&ctx, x: x, y: y + h * 0.25, w: w * 0.55, h: h * 0.5, color: Color(red: 0.9, green: 0.45, blue: 0.45))
    }

    /// Draw a closed curved line (frown or neutral)
    static func line(_ ctx: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color, lineWidth: CGFloat = 2) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        ctx.stroke(path, with: .color(color), lineWidth: lineWidth)
    }

    /// Draw standard cute eyes — two ovals with white highlights
    static func cuteEyes(
        _ ctx: inout GraphicsContext, leftX: CGFloat, rightX: CGFloat, y: CGFloat, eyeW: CGFloat, eyeH: CGFloat,
        mood: MascotMood
    ) {
        let pupilColor = Color(red: 0.15, green: 0.1, blue: 0.1)
        let highlightColor = Color.white

        switch mood {
        case .relaxed:
            // Happy squint — curved lines
            let hw = eyeW * 0.7
            smile(&ctx, centerX: leftX, y: y, width: hw, height: hw * 0.4, color: pupilColor, lineWidth: 2.5)
            smile(&ctx, centerX: rightX, y: y, width: hw, height: hw * 0.4, color: pupilColor, lineWidth: 2.5)
        case .excited, .celebrating:
            // Big sparkly eyes
            let bigW = eyeW * 1.2
            let bigH = eyeH * 1.2
            ellipse(&ctx, x: leftX, y: y, w: bigW, h: bigH, color: pupilColor)
            ellipse(&ctx, x: rightX, y: y, w: bigW, h: bigH, color: pupilColor)
            // Big highlight
            circle(&ctx, x: leftX - bigW * 0.15, y: y - bigH * 0.15, r: bigW * 0.2, color: highlightColor)
            circle(&ctx, x: rightX - bigW * 0.15, y: y - bigH * 0.15, r: bigW * 0.2, color: highlightColor)
            // Small highlight
            circle(&ctx, x: leftX + bigW * 0.15, y: y + bigH * 0.12, r: bigW * 0.1, color: highlightColor)
            circle(&ctx, x: rightX + bigW * 0.15, y: y + bigH * 0.12, r: bigW * 0.1, color: highlightColor)
        default:
            // Normal round eyes
            ellipse(&ctx, x: leftX, y: y, w: eyeW, h: eyeH, color: pupilColor)
            ellipse(&ctx, x: rightX, y: y, w: eyeW, h: eyeH, color: pupilColor)
            // Highlight
            circle(&ctx, x: leftX - eyeW * 0.12, y: y - eyeH * 0.15, r: eyeW * 0.18, color: highlightColor)
            circle(&ctx, x: rightX - eyeW * 0.12, y: y - eyeH * 0.15, r: eyeW * 0.18, color: highlightColor)
        }
    }

    /// Draw blush circles on cheeks
    static func blush(_ ctx: inout GraphicsContext, leftX: CGFloat, rightX: CGFloat, y: CGFloat, r: CGFloat) {
        let blushColor = Color(red: 1.0, green: 0.6, blue: 0.6).opacity(0.45)
        circle(&ctx, x: leftX, y: y, r: r, color: blushColor)
        circle(&ctx, x: rightX, y: y, r: r, color: blushColor)
    }

    /// Draw a mood-based mouth
    static func moodMouth(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, size: CGFloat, mood: MascotMood) {
        let dark = Color(red: 0.2, green: 0.1, blue: 0.1)
        switch mood {
        case .excited, .celebrating:
            openMouth(&ctx, x: x, y: y, w: size * 0.9, h: size * 0.7)
        case .happy:
            smile(
                &ctx, centerX: x, y: y - size * 0.1, width: size * 0.8, height: size * 0.3, color: dark, lineWidth: 2.5)
        case .encouraging:
            // Small "o" mouth
            ellipse(&ctx, x: x, y: y, w: size * 0.35, h: size * 0.4, color: dark)
        case .relaxed:
            // Gentle wavy smile
            smile(
                &ctx, centerX: x, y: y - size * 0.15, width: size * 0.55, height: size * 0.15, color: dark, lineWidth: 2
            )
        }
    }

    /// Triangle shape helper
    static func triangle(_ ctx: inout GraphicsContext, p1: CGPoint, p2: CGPoint, p3: CGPoint, color: Color) {
        var path = Path()
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.closeSubpath()
        ctx.fill(path, with: .color(color))
    }
}

// MARK: - Dragon Renderer (Ryū)

/// A cute chibi dragon — round green body, tiny wings, small horns, flame-tipped tail.
enum DragonRenderer {
    static func draw(in ctx: GraphicsContext, rect: CGRect, mood: MascotMood) {
        var ctx = ctx
        let s = min(rect.width, rect.height)
        let cx = rect.midX
        let cy = rect.midY

        let bodyColor = Color(red: 0.35, green: 0.75, blue: 0.55)
        let bellyColor = Color(red: 0.65, green: 0.92, blue: 0.72)
        let darkGreen = Color(red: 0.2, green: 0.55, blue: 0.35)
        let hornColor = Color(red: 0.95, green: 0.8, blue: 0.35)
        let wingColor = Color(red: 0.45, green: 0.82, blue: 0.62)

        // Tail (drawn behind body)
        let tailStart = CGPoint(x: cx + s * 0.2, y: cy + s * 0.15)
        let tailMid = CGPoint(x: cx + s * 0.38, y: cy + s * 0.05)
        let tailEnd = CGPoint(x: cx + s * 0.42, y: cy - s * 0.08)
        var tailPath = Path()
        tailPath.move(to: tailStart)
        tailPath.addQuadCurve(to: tailEnd, control: tailMid)
        ctx.stroke(tailPath, with: .color(darkGreen), lineWidth: s * 0.06)

        // Flame on tail tip
        let flameColor = Color(red: 1.0, green: 0.5, blue: 0.15)
        DrawKit.circle(&ctx, x: tailEnd.x + s * 0.02, y: tailEnd.y - s * 0.02, r: s * 0.045, color: flameColor)
        DrawKit.circle(
            &ctx, x: tailEnd.x + s * 0.01, y: tailEnd.y - s * 0.04, r: s * 0.03,
            color: Color(red: 1.0, green: 0.85, blue: 0.2))

        // Left wing
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx - s * 0.22, y: cy - s * 0.05),
            p2: CGPoint(x: cx - s * 0.42, y: cy - s * 0.28),
            p3: CGPoint(x: cx - s * 0.12, y: cy - s * 0.12),
            color: wingColor)
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx - s * 0.22, y: cy - s * 0.05),
            p2: CGPoint(x: cx - s * 0.36, y: cy - s * 0.22),
            p3: CGPoint(x: cx - s * 0.15, y: cy - s * 0.08),
            color: wingColor.opacity(0.7))

        // Right wing
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx + s * 0.22, y: cy - s * 0.05),
            p2: CGPoint(x: cx + s * 0.42, y: cy - s * 0.28),
            p3: CGPoint(x: cx + s * 0.12, y: cy - s * 0.12),
            color: wingColor)

        // Body
        DrawKit.ellipse(&ctx, x: cx, y: cy + s * 0.05, w: s * 0.52, h: s * 0.48, color: bodyColor)

        // Belly patch
        DrawKit.ellipse(&ctx, x: cx, y: cy + s * 0.1, w: s * 0.3, h: s * 0.28, color: bellyColor)

        // Head
        DrawKit.ellipse(&ctx, x: cx, y: cy - s * 0.16, w: s * 0.44, h: s * 0.38, color: bodyColor)

        // Horns
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx - s * 0.12, y: cy - s * 0.32),
            p2: CGPoint(x: cx - s * 0.16, y: cy - s * 0.45),
            p3: CGPoint(x: cx - s * 0.06, y: cy - s * 0.32),
            color: hornColor)
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx + s * 0.12, y: cy - s * 0.32),
            p2: CGPoint(x: cx + s * 0.16, y: cy - s * 0.45),
            p3: CGPoint(x: cx + s * 0.06, y: cy - s * 0.32),
            color: hornColor)

        // Nostrils
        DrawKit.circle(&ctx, x: cx - s * 0.04, y: cy - s * 0.1, r: s * 0.02, color: darkGreen)
        DrawKit.circle(&ctx, x: cx + s * 0.04, y: cy - s * 0.1, r: s * 0.02, color: darkGreen)

        // Small smoke puffs from nostrils when excited
        if mood == .excited || mood == .celebrating {
            let smokeColor = Color.gray.opacity(0.3)
            DrawKit.circle(&ctx, x: cx - s * 0.07, y: cy - s * 0.14, r: s * 0.02, color: smokeColor)
            DrawKit.circle(&ctx, x: cx + s * 0.07, y: cy - s * 0.14, r: s * 0.02, color: smokeColor)
            DrawKit.circle(&ctx, x: cx - s * 0.09, y: cy - s * 0.17, r: s * 0.015, color: smokeColor)
            DrawKit.circle(&ctx, x: cx + s * 0.09, y: cy - s * 0.17, r: s * 0.015, color: smokeColor)
        }

        // Eyes
        let eyeY = cy - s * 0.18
        let eyeSpacing = s * 0.1
        DrawKit.cuteEyes(
            &ctx, leftX: cx - eyeSpacing, rightX: cx + eyeSpacing, y: eyeY, eyeW: s * 0.08, eyeH: s * 0.09, mood: mood)

        // Mouth
        DrawKit.moodMouth(&ctx, x: cx, y: cy - s * 0.06, size: s * 0.14, mood: mood)

        // Blush
        DrawKit.blush(&ctx, leftX: cx - s * 0.16, rightX: cx + s * 0.16, y: cy - s * 0.12, r: s * 0.04)

        // Feet
        DrawKit.ellipse(&ctx, x: cx - s * 0.12, y: cy + s * 0.3, w: s * 0.13, h: s * 0.07, color: darkGreen)
        DrawKit.ellipse(&ctx, x: cx + s * 0.12, y: cy + s * 0.3, w: s * 0.13, h: s * 0.07, color: darkGreen)
    }
}

// MARK: - Cat Renderer (Neko)

/// A cute chibi cat — round face, pointy ears, whiskers, curled tail.
enum CatRenderer {
    static func draw(in ctx: GraphicsContext, rect: CGRect, mood: MascotMood) {
        var ctx = ctx
        let s = min(rect.width, rect.height)
        let cx = rect.midX
        let cy = rect.midY

        let bodyColor = Color(red: 1.0, green: 0.72, blue: 0.35)
        let bellyColor = Color(red: 1.0, green: 0.92, blue: 0.78)
        let darkOrange = Color(red: 0.8, green: 0.5, blue: 0.2)
        let stripeColor = Color(red: 0.85, green: 0.55, blue: 0.2)

        // Tail (behind body) — curled upward
        var tailPath = Path()
        tailPath.move(to: CGPoint(x: cx + s * 0.18, y: cy + s * 0.12))
        tailPath.addCurve(
            to: CGPoint(x: cx + s * 0.38, y: cy - s * 0.15),
            control1: CGPoint(x: cx + s * 0.35, y: cy + s * 0.2),
            control2: CGPoint(x: cx + s * 0.42, y: cy - s * 0.05)
        )
        ctx.stroke(tailPath, with: .color(bodyColor), lineWidth: s * 0.06)
        // Tail tip stripe
        var tipPath = Path()
        tipPath.move(to: CGPoint(x: cx + s * 0.36, y: cy - s * 0.08))
        tipPath.addCurve(
            to: CGPoint(x: cx + s * 0.38, y: cy - s * 0.15),
            control1: CGPoint(x: cx + s * 0.40, y: cy - s * 0.08),
            control2: CGPoint(x: cx + s * 0.42, y: cy - s * 0.12)
        )
        ctx.stroke(tipPath, with: .color(stripeColor), lineWidth: s * 0.065)

        // Body
        DrawKit.ellipse(&ctx, x: cx, y: cy + s * 0.08, w: s * 0.46, h: s * 0.42, color: bodyColor)

        // Belly
        DrawKit.ellipse(&ctx, x: cx, y: cy + s * 0.12, w: s * 0.26, h: s * 0.25, color: bellyColor)

        // Head
        DrawKit.ellipse(&ctx, x: cx, y: cy - s * 0.14, w: s * 0.46, h: s * 0.38, color: bodyColor)

        // Ears — triangles with inner pink
        let earPink = Color(red: 1.0, green: 0.7, blue: 0.72)
        // Left ear
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx - s * 0.2, y: cy - s * 0.22),
            p2: CGPoint(x: cx - s * 0.2, y: cy - s * 0.44),
            p3: CGPoint(x: cx - s * 0.06, y: cy - s * 0.26),
            color: bodyColor)
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx - s * 0.17, y: cy - s * 0.24),
            p2: CGPoint(x: cx - s * 0.18, y: cy - s * 0.39),
            p3: CGPoint(x: cx - s * 0.09, y: cy - s * 0.27),
            color: earPink)
        // Right ear
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx + s * 0.2, y: cy - s * 0.22),
            p2: CGPoint(x: cx + s * 0.2, y: cy - s * 0.44),
            p3: CGPoint(x: cx + s * 0.06, y: cy - s * 0.26),
            color: bodyColor)
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx + s * 0.17, y: cy - s * 0.24),
            p2: CGPoint(x: cx + s * 0.18, y: cy - s * 0.39),
            p3: CGPoint(x: cx + s * 0.09, y: cy - s * 0.27),
            color: earPink)

        // Forehead stripes
        DrawKit.line(
            &ctx, from: CGPoint(x: cx - s * 0.04, y: cy - s * 0.28), to: CGPoint(x: cx - s * 0.06, y: cy - s * 0.22),
            color: stripeColor, lineWidth: 2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx, y: cy - s * 0.3), to: CGPoint(x: cx, y: cy - s * 0.22), color: stripeColor,
            lineWidth: 2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx + s * 0.04, y: cy - s * 0.28), to: CGPoint(x: cx + s * 0.06, y: cy - s * 0.22),
            color: stripeColor, lineWidth: 2)

        // Eyes
        let eyeY = cy - s * 0.15
        DrawKit.cuteEyes(
            &ctx, leftX: cx - s * 0.1, rightX: cx + s * 0.1, y: eyeY, eyeW: s * 0.08, eyeH: s * 0.09, mood: mood)

        // Nose — tiny pink triangle
        let noseY = cy - s * 0.06
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx, y: noseY - s * 0.02),
            p2: CGPoint(x: cx - s * 0.02, y: noseY + s * 0.01),
            p3: CGPoint(x: cx + s * 0.02, y: noseY + s * 0.01),
            color: earPink)

        // Mouth
        DrawKit.moodMouth(&ctx, x: cx, y: cy - s * 0.01, size: s * 0.12, mood: mood)

        // Whiskers
        let whiskerColor = Color(red: 0.4, green: 0.35, blue: 0.3)
        let whiskerY = cy - s * 0.04
        // Left whiskers
        DrawKit.line(
            &ctx, from: CGPoint(x: cx - s * 0.08, y: whiskerY - s * 0.02),
            to: CGPoint(x: cx - s * 0.28, y: whiskerY - s * 0.06), color: whiskerColor, lineWidth: 1.2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx - s * 0.08, y: whiskerY), to: CGPoint(x: cx - s * 0.28, y: whiskerY),
            color: whiskerColor, lineWidth: 1.2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx - s * 0.08, y: whiskerY + s * 0.02),
            to: CGPoint(x: cx - s * 0.28, y: whiskerY + s * 0.06), color: whiskerColor, lineWidth: 1.2)
        // Right whiskers
        DrawKit.line(
            &ctx, from: CGPoint(x: cx + s * 0.08, y: whiskerY - s * 0.02),
            to: CGPoint(x: cx + s * 0.28, y: whiskerY - s * 0.06), color: whiskerColor, lineWidth: 1.2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx + s * 0.08, y: whiskerY), to: CGPoint(x: cx + s * 0.28, y: whiskerY),
            color: whiskerColor, lineWidth: 1.2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx + s * 0.08, y: whiskerY + s * 0.02),
            to: CGPoint(x: cx + s * 0.28, y: whiskerY + s * 0.06), color: whiskerColor, lineWidth: 1.2)

        // Blush
        DrawKit.blush(&ctx, leftX: cx - s * 0.16, rightX: cx + s * 0.16, y: cy - s * 0.06, r: s * 0.04)

        // Paws
        DrawKit.ellipse(&ctx, x: cx - s * 0.1, y: cy + s * 0.28, w: s * 0.12, h: s * 0.08, color: darkOrange)
        DrawKit.ellipse(&ctx, x: cx + s * 0.1, y: cy + s * 0.28, w: s * 0.12, h: s * 0.08, color: darkOrange)
        // Paw pads
        DrawKit.circle(&ctx, x: cx - s * 0.1, y: cy + s * 0.29, r: s * 0.02, color: earPink)
        DrawKit.circle(&ctx, x: cx + s * 0.1, y: cy + s * 0.29, r: s * 0.02, color: earPink)
    }
}

// MARK: - Capybara Renderer (Kapiiko)

/// A cute chibi capybara — very round, small ears, buck teeth, zen expression.
enum CapybaraRenderer {
    static func draw(in ctx: GraphicsContext, rect: CGRect, mood: MascotMood) {
        var ctx = ctx
        let s = min(rect.width, rect.height)
        let cx = rect.midX
        let cy = rect.midY

        let bodyColor = Color(red: 0.65, green: 0.48, blue: 0.32)
        let bellyColor = Color(red: 0.82, green: 0.7, blue: 0.55)
        let darkBrown = Color(red: 0.45, green: 0.32, blue: 0.2)
        let noseColor = Color(red: 0.3, green: 0.22, blue: 0.15)

        // Body — extra round, capybara style
        DrawKit.ellipse(&ctx, x: cx, y: cy + s * 0.08, w: s * 0.54, h: s * 0.44, color: bodyColor)

        // Belly
        DrawKit.ellipse(&ctx, x: cx, y: cy + s * 0.14, w: s * 0.32, h: s * 0.26, color: bellyColor)

        // Head — large and round
        DrawKit.ellipse(&ctx, x: cx, y: cy - s * 0.13, w: s * 0.48, h: s * 0.4, color: bodyColor)

        // Snout area — slightly lighter, round bump
        DrawKit.ellipse(&ctx, x: cx, y: cy - s * 0.04, w: s * 0.22, h: s * 0.14, color: bellyColor)

        // Small round ears
        DrawKit.ellipse(&ctx, x: cx - s * 0.18, y: cy - s * 0.3, w: s * 0.1, h: s * 0.08, color: bodyColor)
        DrawKit.ellipse(&ctx, x: cx + s * 0.18, y: cy - s * 0.3, w: s * 0.1, h: s * 0.08, color: bodyColor)
        // Inner ear
        DrawKit.ellipse(&ctx, x: cx - s * 0.18, y: cy - s * 0.3, w: s * 0.06, h: s * 0.05, color: darkBrown)
        DrawKit.ellipse(&ctx, x: cx + s * 0.18, y: cy - s * 0.3, w: s * 0.06, h: s * 0.05, color: darkBrown)

        // Eyes — capybara has small eyes set wide apart
        let eyeY = cy - s * 0.18
        DrawKit.cuteEyes(
            &ctx, leftX: cx - s * 0.1, rightX: cx + s * 0.1, y: eyeY, eyeW: s * 0.065, eyeH: s * 0.07, mood: mood)

        // Nose — big oval
        DrawKit.ellipse(&ctx, x: cx, y: cy - s * 0.06, w: s * 0.1, h: s * 0.06, color: noseColor)

        // Mouth — with buck teeth for encouraging/excited
        if mood == .excited || mood == .celebrating {
            DrawKit.openMouth(&ctx, x: cx, y: cy + s * 0.02, w: s * 0.1, h: s * 0.08)
            // Buck teeth
            DrawKit.roundedRect(&ctx, x: cx - s * 0.02, y: cy, w: s * 0.03, h: s * 0.04, radius: 1, color: .white)
            DrawKit.roundedRect(&ctx, x: cx + s * 0.02, y: cy, w: s * 0.03, h: s * 0.04, radius: 1, color: .white)
        } else if mood == .happy || mood == .encouraging {
            DrawKit.smile(
                &ctx, centerX: cx, y: cy + s * 0.0, width: s * 0.1, height: s * 0.04, color: darkBrown, lineWidth: 2)
        } else {
            // Relaxed — very gentle smile
            DrawKit.smile(
                &ctx, centerX: cx, y: cy - s * 0.01, width: s * 0.07, height: s * 0.02, color: darkBrown, lineWidth: 1.5
            )
        }

        // Blush
        DrawKit.blush(&ctx, leftX: cx - s * 0.15, rightX: cx + s * 0.15, y: cy - s * 0.08, r: s * 0.04)

        // Tiny stubby legs
        DrawKit.ellipse(&ctx, x: cx - s * 0.14, y: cy + s * 0.3, w: s * 0.11, h: s * 0.07, color: darkBrown)
        DrawKit.ellipse(&ctx, x: cx + s * 0.14, y: cy + s * 0.3, w: s * 0.11, h: s * 0.07, color: darkBrown)

        // Optional: little leaf/grass on head for zen vibes
        if mood == .relaxed {
            var leafPath = Path()
            leafPath.move(to: CGPoint(x: cx + s * 0.02, y: cy - s * 0.32))
            leafPath.addQuadCurve(
                to: CGPoint(x: cx + s * 0.12, y: cy - s * 0.42), control: CGPoint(x: cx + s * 0.12, y: cy - s * 0.32))
            leafPath.addQuadCurve(
                to: CGPoint(x: cx + s * 0.02, y: cy - s * 0.32), control: CGPoint(x: cx + s * 0.02, y: cy - s * 0.42))
            ctx.fill(leafPath, with: .color(Color(red: 0.4, green: 0.75, blue: 0.35)))
            // Stem
            DrawKit.line(
                &ctx, from: CGPoint(x: cx + s * 0.02, y: cy - s * 0.32), to: CGPoint(x: cx + s * 0.0, y: cy - s * 0.28),
                color: Color(red: 0.35, green: 0.6, blue: 0.3), lineWidth: 1.5)
        }
    }
}

// MARK: - Dog Renderer (Wanko)

/// A cute chibi dog — floppy ears, big eyes, tongue out when happy, wagging tail.
enum DogRenderer {
    static func draw(in ctx: GraphicsContext, rect: CGRect, mood: MascotMood) {
        var ctx = ctx
        let s = min(rect.width, rect.height)
        let cx = rect.midX
        let cy = rect.midY

        let bodyColor = Color(red: 0.85, green: 0.68, blue: 0.42)
        let bellyColor = Color(red: 1.0, green: 0.92, blue: 0.78)
        let darkBrown = Color(red: 0.55, green: 0.38, blue: 0.2)
        let noseColor = Color(red: 0.2, green: 0.15, blue: 0.1)
        let tongueColor = Color(red: 0.95, green: 0.5, blue: 0.5)

        // Tail (behind body) — upward wag
        var tailPath = Path()
        tailPath.move(to: CGPoint(x: cx + s * 0.18, y: cy + s * 0.05))
        tailPath.addQuadCurve(
            to: CGPoint(x: cx + s * 0.35, y: cy - s * 0.2),
            control: CGPoint(x: cx + s * 0.38, y: cy + s * 0.05)
        )
        ctx.stroke(tailPath, with: .color(bodyColor), lineWidth: s * 0.06)

        // Body
        DrawKit.ellipse(&ctx, x: cx, y: cy + s * 0.08, w: s * 0.48, h: s * 0.42, color: bodyColor)

        // Belly
        DrawKit.ellipse(&ctx, x: cx, y: cy + s * 0.12, w: s * 0.28, h: s * 0.25, color: bellyColor)

        // Head
        DrawKit.ellipse(&ctx, x: cx, y: cy - s * 0.14, w: s * 0.46, h: s * 0.38, color: bodyColor)

        // Floppy ears
        // Left ear — oval hanging down at angle
        let leftEarPath = earPath(cx: cx - s * 0.17, cy: cy - s * 0.22, w: s * 0.12, h: s * 0.2, angle: -15, s: s)
        ctx.fill(leftEarPath, with: .color(darkBrown))
        // Right ear
        let rightEarPath = earPath(cx: cx + s * 0.17, cy: cy - s * 0.22, w: s * 0.12, h: s * 0.2, angle: 15, s: s)
        ctx.fill(rightEarPath, with: .color(darkBrown))

        // Face patch — lighter muzzle area
        DrawKit.ellipse(&ctx, x: cx, y: cy - s * 0.06, w: s * 0.22, h: s * 0.16, color: bellyColor)

        // Eyes
        let eyeY = cy - s * 0.17
        DrawKit.cuteEyes(
            &ctx, leftX: cx - s * 0.1, rightX: cx + s * 0.1, y: eyeY, eyeW: s * 0.08, eyeH: s * 0.09, mood: mood)

        // Eyebrows (expressive!)
        let browColor = darkBrown
        if mood == .encouraging {
            // Worried/determined brows — angled inward
            DrawKit.line(
                &ctx, from: CGPoint(x: cx - s * 0.15, y: cy - s * 0.25),
                to: CGPoint(x: cx - s * 0.06, y: cy - s * 0.23), color: browColor, lineWidth: 2.5)
            DrawKit.line(
                &ctx, from: CGPoint(x: cx + s * 0.15, y: cy - s * 0.25),
                to: CGPoint(x: cx + s * 0.06, y: cy - s * 0.23), color: browColor, lineWidth: 2.5)
        }

        // Nose
        DrawKit.ellipse(&ctx, x: cx, y: cy - s * 0.07, w: s * 0.08, h: s * 0.05, color: noseColor)

        // Mouth + tongue
        if mood == .excited || mood == .celebrating || mood == .happy {
            DrawKit.openMouth(&ctx, x: cx, y: cy + s * 0.01, w: s * 0.1, h: s * 0.08)
            // Tongue hanging out
            DrawKit.ellipse(&ctx, x: cx, y: cy + s * 0.06, w: s * 0.06, h: s * 0.07, color: tongueColor)
        } else if mood == .encouraging {
            DrawKit.ellipse(&ctx, x: cx, y: cy + s * 0.01, w: s * 0.04, h: s * 0.05, color: noseColor)
        } else {
            DrawKit.smile(
                &ctx, centerX: cx, y: cy - s * 0.0, width: s * 0.08, height: s * 0.03, color: noseColor, lineWidth: 2)
        }

        // Blush
        DrawKit.blush(&ctx, leftX: cx - s * 0.15, rightX: cx + s * 0.15, y: cy - s * 0.07, r: s * 0.04)

        // Paws
        DrawKit.ellipse(&ctx, x: cx - s * 0.11, y: cy + s * 0.29, w: s * 0.13, h: s * 0.08, color: darkBrown)
        DrawKit.ellipse(&ctx, x: cx + s * 0.11, y: cy + s * 0.29, w: s * 0.13, h: s * 0.08, color: darkBrown)
        // Lighter paw pads
        DrawKit.circle(&ctx, x: cx - s * 0.11, y: cy + s * 0.3, r: s * 0.025, color: bellyColor)
        DrawKit.circle(&ctx, x: cx + s * 0.11, y: cy + s * 0.3, r: s * 0.025, color: bellyColor)

        // Collar
        let collarY = cy - s * 0.0
        DrawKit.ellipse(
            &ctx, x: cx, y: collarY, w: s * 0.32, h: s * 0.04, color: Color(red: 0.85, green: 0.25, blue: 0.25))
        // Tag
        DrawKit.circle(&ctx, x: cx, y: collarY + s * 0.03, r: s * 0.025, color: Color(red: 0.95, green: 0.8, blue: 0.2))
    }

    private static func earPath(cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, angle: Double, s: CGFloat) -> Path {
        var path = Path()
        let rect = CGRect(x: cx - w / 2, y: cy - h * 0.2, width: w, height: h)
        path.addEllipse(in: rect)
        return path
    }
}
