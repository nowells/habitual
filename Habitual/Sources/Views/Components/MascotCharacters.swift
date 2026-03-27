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
    static func ellipse(_ ctx: inout GraphicsContext, xPos: CGFloat, yPos: CGFloat, width: CGFloat, height: CGFloat, color: Color) {
        let rect = CGRect(x: xPos - width / 2, y: yPos - height / 2, width: width, height: height)
        ctx.fill(Ellipse().path(in: rect), with: .color(color))
    }

    static func circle(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, r: CGFloat, color: Color) {
        ellipse(&ctx, xPos: x, yPos: y, width: r * 2, height: r * 2, color: color)
    }

    static func roundedRect(
        _ ctx: inout GraphicsContext, xPos: CGFloat, yPos: CGFloat, width: CGFloat, height: CGFloat, radius: CGFloat, color: Color
    ) {
        let rect = CGRect(x: xPos - width / 2, y: yPos - height / 2, width: width, height: height)
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
    static func openMouth(_ ctx: inout GraphicsContext, xPos: CGFloat, yPos: CGFloat, width: CGFloat, height: CGFloat) {
        ellipse(&ctx, xPos: xPos, yPos: yPos, width: width, height: height, color: Color(red: 0.2, green: 0.1, blue: 0.1))
        // tongue
        ellipse(&ctx, xPos: xPos, yPos: yPos + height * 0.25, width: width * 0.55, height: height * 0.5, color: Color(red: 0.9, green: 0.45, blue: 0.45))
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
        _ ctx: inout GraphicsContext, leftX: CGFloat, rightX: CGFloat, yPos: CGFloat, eyeWidth: CGFloat, eyeHeight: CGFloat,
        mood: MascotMood
    ) {
        let pupilColor = Color(red: 0.15, green: 0.1, blue: 0.1)
        let highlightColor = Color.white

        switch mood {
        case .relaxed:
            // Happy squint — curved lines
            let hw = eyeWidth * 0.7
            smile(&ctx, centerX: leftX, y: yPos, width: hw, height: hw * 0.4, color: pupilColor, lineWidth: 2.5)
            smile(&ctx, centerX: rightX, y: yPos, width: hw, height: hw * 0.4, color: pupilColor, lineWidth: 2.5)
        case .excited, .celebrating:
            // Big sparkly eyes
            let bigW = eyeWidth * 1.2
            let bigH = eyeHeight * 1.2
            ellipse(&ctx, xPos: leftX, yPos: yPos, width: bigW, height: bigH, color: pupilColor)
            ellipse(&ctx, xPos: rightX, yPos: yPos, width: bigW, height: bigH, color: pupilColor)
            // Big highlight
            circle(&ctx, x: leftX - bigW * 0.15, y: yPos - bigH * 0.15, r: bigW * 0.2, color: highlightColor)
            circle(&ctx, x: rightX - bigW * 0.15, y: yPos - bigH * 0.15, r: bigW * 0.2, color: highlightColor)
            // Small highlight
            circle(&ctx, x: leftX + bigW * 0.15, y: yPos + bigH * 0.12, r: bigW * 0.1, color: highlightColor)
            circle(&ctx, x: rightX + bigW * 0.15, y: yPos + bigH * 0.12, r: bigW * 0.1, color: highlightColor)
        default:
            // Normal round eyes
            ellipse(&ctx, xPos: leftX, yPos: yPos, width: eyeWidth, height: eyeHeight, color: pupilColor)
            ellipse(&ctx, xPos: rightX, yPos: yPos, width: eyeWidth, height: eyeHeight, color: pupilColor)
            // Highlight
            circle(&ctx, x: leftX - eyeWidth * 0.12, y: yPos - eyeHeight * 0.15, r: eyeWidth * 0.18, color: highlightColor)
            circle(&ctx, x: rightX - eyeWidth * 0.12, y: yPos - eyeHeight * 0.15, r: eyeWidth * 0.18, color: highlightColor)
        }
    }

    /// Draw blush circles on cheeks
    static func blush(_ ctx: inout GraphicsContext, leftX: CGFloat, rightX: CGFloat, yPos: CGFloat, radius: CGFloat) {
        let blushColor = Color(red: 1.0, green: 0.6, blue: 0.6).opacity(0.45)
        circle(&ctx, x: leftX, y: yPos, r: radius, color: blushColor)
        circle(&ctx, x: rightX, y: yPos, r: radius, color: blushColor)
    }

    /// Draw a mood-based mouth
    static func moodMouth(_ ctx: inout GraphicsContext, xPos: CGFloat, yPos: CGFloat, size: CGFloat, mood: MascotMood) {
        let dark = Color(red: 0.2, green: 0.1, blue: 0.1)
        switch mood {
        case .excited, .celebrating:
            openMouth(&ctx, xPos: xPos, yPos: yPos, width: size * 0.9, height: size * 0.7)
        case .happy:
            smile(
                &ctx, centerX: xPos, y: yPos - size * 0.1, width: size * 0.8, height: size * 0.3, color: dark, lineWidth: 2.5)
        case .encouraging:
            // Small "o" mouth
            ellipse(&ctx, xPos: xPos, yPos: yPos, width: size * 0.35, height: size * 0.4, color: dark)
        case .relaxed:
            // Gentle wavy smile
            smile(
                &ctx, centerX: xPos, y: yPos - size * 0.15, width: size * 0.55, height: size * 0.15, color: dark, lineWidth: 2
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
        let size = min(rect.width, rect.height)
        let cx = rect.midX
        let cy = rect.midY

        let bodyColor = Color(red: 0.35, green: 0.75, blue: 0.55)
        let bellyColor = Color(red: 0.65, green: 0.92, blue: 0.72)
        let darkGreen = Color(red: 0.2, green: 0.55, blue: 0.35)
        let hornColor = Color(red: 0.95, green: 0.8, blue: 0.35)
        let wingColor = Color(red: 0.45, green: 0.82, blue: 0.62)

        // Tail (drawn behind body)
        let tailStart = CGPoint(x: cx + size * 0.2, y: cy + size * 0.15)
        let tailMid = CGPoint(x: cx + size * 0.38, y: cy + size * 0.05)
        let tailEnd = CGPoint(x: cx + size * 0.42, y: cy - size * 0.08)
        var tailPath = Path()
        tailPath.move(to: tailStart)
        tailPath.addQuadCurve(to: tailEnd, control: tailMid)
        ctx.stroke(tailPath, with: .color(darkGreen), lineWidth: size * 0.06)

        // Flame on tail tip
        let flameColor = Color(red: 1.0, green: 0.5, blue: 0.15)
        DrawKit.circle(&ctx, x: tailEnd.x + size * 0.02, y: tailEnd.y - size * 0.02, r: size * 0.045, color: flameColor)
        DrawKit.circle(
            &ctx, x: tailEnd.x + size * 0.01, y: tailEnd.y - size * 0.04, r: size * 0.03,
            color: Color(red: 1.0, green: 0.85, blue: 0.2))

        // Left wing
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx - size * 0.22, y: cy - size * 0.05),
            p2: CGPoint(x: cx - size * 0.42, y: cy - size * 0.28),
            p3: CGPoint(x: cx - size * 0.12, y: cy - size * 0.12),
            color: wingColor)
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx - size * 0.22, y: cy - size * 0.05),
            p2: CGPoint(x: cx - size * 0.36, y: cy - size * 0.22),
            p3: CGPoint(x: cx - size * 0.15, y: cy - size * 0.08),
            color: wingColor.opacity(0.7))

        // Right wing
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx + size * 0.22, y: cy - size * 0.05),
            p2: CGPoint(x: cx + size * 0.42, y: cy - size * 0.28),
            p3: CGPoint(x: cx + size * 0.12, y: cy - size * 0.12),
            color: wingColor)

        // Body
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy + size * 0.05, width: size * 0.52, height: size * 0.48, color: bodyColor)

        // Belly patch
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy + size * 0.1, width: size * 0.3, height: size * 0.28, color: bellyColor)

        // Head
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy - size * 0.16, width: size * 0.44, height: size * 0.38, color: bodyColor)

        // Horns
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx - size * 0.12, y: cy - size * 0.32),
            p2: CGPoint(x: cx - size * 0.16, y: cy - size * 0.45),
            p3: CGPoint(x: cx - size * 0.06, y: cy - size * 0.32),
            color: hornColor)
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx + size * 0.12, y: cy - size * 0.32),
            p2: CGPoint(x: cx + size * 0.16, y: cy - size * 0.45),
            p3: CGPoint(x: cx + size * 0.06, y: cy - size * 0.32),
            color: hornColor)

        // Nostrils
        DrawKit.circle(&ctx, x: cx - size * 0.04, y: cy - size * 0.1, r: size * 0.02, color: darkGreen)
        DrawKit.circle(&ctx, x: cx + size * 0.04, y: cy - size * 0.1, r: size * 0.02, color: darkGreen)

        // Small smoke puffs from nostrils when excited
        if mood == .excited || mood == .celebrating {
            let smokeColor = Color.gray.opacity(0.3)
            DrawKit.circle(&ctx, x: cx - size * 0.07, y: cy - size * 0.14, r: size * 0.02, color: smokeColor)
            DrawKit.circle(&ctx, x: cx + size * 0.07, y: cy - size * 0.14, r: size * 0.02, color: smokeColor)
            DrawKit.circle(&ctx, x: cx - size * 0.09, y: cy - size * 0.17, r: size * 0.015, color: smokeColor)
            DrawKit.circle(&ctx, x: cx + size * 0.09, y: cy - size * 0.17, r: size * 0.015, color: smokeColor)
        }

        // Eyes
        let eyeY = cy - size * 0.18
        let eyeSpacing = size * 0.1
        DrawKit.cuteEyes(
            &ctx, leftX: cx - eyeSpacing, rightX: cx + eyeSpacing, yPos: eyeY, eyeWidth: size * 0.08, eyeHeight: size * 0.09, mood: mood)

        // Mouth
        DrawKit.moodMouth(&ctx, xPos: cx, yPos: cy - size * 0.06, size: size * 0.14, mood: mood)

        // Blush
        DrawKit.blush(&ctx, leftX: cx - size * 0.16, rightX: cx + size * 0.16, yPos: cy - size * 0.12, radius: size * 0.04)

        // Feet
        DrawKit.ellipse(&ctx, xPos: cx - size * 0.12, yPos: cy + size * 0.3, width: size * 0.13, height: size * 0.07, color: darkGreen)
        DrawKit.ellipse(&ctx, xPos: cx + size * 0.12, yPos: cy + size * 0.3, width: size * 0.13, height: size * 0.07, color: darkGreen)
    }
}

// MARK: - Cat Renderer (Neko)

/// A cute chibi cat — round face, pointy ears, whiskers, curled tail.
enum CatRenderer {
    // swiftlint:disable:next function_body_length
    static func draw(in ctx: GraphicsContext, rect: CGRect, mood: MascotMood) {
        var ctx = ctx
        let size = min(rect.width, rect.height)
        let cx = rect.midX
        let cy = rect.midY

        let bodyColor = Color(red: 1.0, green: 0.72, blue: 0.35)
        let bellyColor = Color(red: 1.0, green: 0.92, blue: 0.78)
        let darkOrange = Color(red: 0.8, green: 0.5, blue: 0.2)
        let stripeColor = Color(red: 0.85, green: 0.55, blue: 0.2)

        // Tail (behind body) — curled upward
        var tailPath = Path()
        tailPath.move(to: CGPoint(x: cx + size * 0.18, y: cy + size * 0.12))
        tailPath.addCurve(
            to: CGPoint(x: cx + size * 0.38, y: cy - size * 0.15),
            control1: CGPoint(x: cx + size * 0.35, y: cy + size * 0.2),
            control2: CGPoint(x: cx + size * 0.42, y: cy - size * 0.05)
        )
        ctx.stroke(tailPath, with: .color(bodyColor), lineWidth: size * 0.06)
        // Tail tip stripe
        var tipPath = Path()
        tipPath.move(to: CGPoint(x: cx + size * 0.36, y: cy - size * 0.08))
        tipPath.addCurve(
            to: CGPoint(x: cx + size * 0.38, y: cy - size * 0.15),
            control1: CGPoint(x: cx + size * 0.40, y: cy - size * 0.08),
            control2: CGPoint(x: cx + size * 0.42, y: cy - size * 0.12)
        )
        ctx.stroke(tipPath, with: .color(stripeColor), lineWidth: size * 0.065)

        // Body
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy + size * 0.08, width: size * 0.46, height: size * 0.42, color: bodyColor)

        // Belly
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy + size * 0.12, width: size * 0.26, height: size * 0.25, color: bellyColor)

        // Head
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy - size * 0.14, width: size * 0.46, height: size * 0.38, color: bodyColor)

        // Ears — triangles with inner pink
        let earPink = Color(red: 1.0, green: 0.7, blue: 0.72)
        // Left ear
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx - size * 0.2, y: cy - size * 0.22),
            p2: CGPoint(x: cx - size * 0.2, y: cy - size * 0.44),
            p3: CGPoint(x: cx - size * 0.06, y: cy - size * 0.26),
            color: bodyColor)
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx - size * 0.17, y: cy - size * 0.24),
            p2: CGPoint(x: cx - size * 0.18, y: cy - size * 0.39),
            p3: CGPoint(x: cx - size * 0.09, y: cy - size * 0.27),
            color: earPink)
        // Right ear
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx + size * 0.2, y: cy - size * 0.22),
            p2: CGPoint(x: cx + size * 0.2, y: cy - size * 0.44),
            p3: CGPoint(x: cx + size * 0.06, y: cy - size * 0.26),
            color: bodyColor)
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx + size * 0.17, y: cy - size * 0.24),
            p2: CGPoint(x: cx + size * 0.18, y: cy - size * 0.39),
            p3: CGPoint(x: cx + size * 0.09, y: cy - size * 0.27),
            color: earPink)

        // Forehead stripes
        DrawKit.line(
            &ctx, from: CGPoint(x: cx - size * 0.04, y: cy - size * 0.28), to: CGPoint(x: cx - size * 0.06, y: cy - size * 0.22),
            color: stripeColor, lineWidth: 2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx, y: cy - size * 0.3), to: CGPoint(x: cx, y: cy - size * 0.22), color: stripeColor,
            lineWidth: 2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx + size * 0.04, y: cy - size * 0.28), to: CGPoint(x: cx + size * 0.06, y: cy - size * 0.22),
            color: stripeColor, lineWidth: 2)

        // Eyes
        let eyeY = cy - size * 0.15
        DrawKit.cuteEyes(
            &ctx, leftX: cx - size * 0.1, rightX: cx + size * 0.1, yPos: eyeY, eyeWidth: size * 0.08, eyeHeight: size * 0.09, mood: mood)

        // Nose — tiny pink triangle
        let noseY = cy - size * 0.06
        DrawKit.triangle(
            &ctx,
            p1: CGPoint(x: cx, y: noseY - size * 0.02),
            p2: CGPoint(x: cx - size * 0.02, y: noseY + size * 0.01),
            p3: CGPoint(x: cx + size * 0.02, y: noseY + size * 0.01),
            color: earPink)

        // Mouth
        DrawKit.moodMouth(&ctx, xPos: cx, yPos: cy - size * 0.01, size: size * 0.12, mood: mood)

        // Whiskers
        let whiskerColor = Color(red: 0.4, green: 0.35, blue: 0.3)
        let whiskerY = cy - size * 0.04
        // Left whiskers
        DrawKit.line(
            &ctx, from: CGPoint(x: cx - size * 0.08, y: whiskerY - size * 0.02),
            to: CGPoint(x: cx - size * 0.28, y: whiskerY - size * 0.06), color: whiskerColor, lineWidth: 1.2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx - size * 0.08, y: whiskerY), to: CGPoint(x: cx - size * 0.28, y: whiskerY),
            color: whiskerColor, lineWidth: 1.2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx - size * 0.08, y: whiskerY + size * 0.02),
            to: CGPoint(x: cx - size * 0.28, y: whiskerY + size * 0.06), color: whiskerColor, lineWidth: 1.2)
        // Right whiskers
        DrawKit.line(
            &ctx, from: CGPoint(x: cx + size * 0.08, y: whiskerY - size * 0.02),
            to: CGPoint(x: cx + size * 0.28, y: whiskerY - size * 0.06), color: whiskerColor, lineWidth: 1.2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx + size * 0.08, y: whiskerY), to: CGPoint(x: cx + size * 0.28, y: whiskerY),
            color: whiskerColor, lineWidth: 1.2)
        DrawKit.line(
            &ctx, from: CGPoint(x: cx + size * 0.08, y: whiskerY + size * 0.02),
            to: CGPoint(x: cx + size * 0.28, y: whiskerY + size * 0.06), color: whiskerColor, lineWidth: 1.2)

        // Blush
        DrawKit.blush(&ctx, leftX: cx - size * 0.16, rightX: cx + size * 0.16, yPos: cy - size * 0.06, radius: size * 0.04)

        // Paws
        DrawKit.ellipse(&ctx, xPos: cx - size * 0.1, yPos: cy + size * 0.28, width: size * 0.12, height: size * 0.08, color: darkOrange)
        DrawKit.ellipse(&ctx, xPos: cx + size * 0.1, yPos: cy + size * 0.28, width: size * 0.12, height: size * 0.08, color: darkOrange)
        // Paw pads
        DrawKit.circle(&ctx, x: cx - size * 0.1, y: cy + size * 0.29, r: size * 0.02, color: earPink)
        DrawKit.circle(&ctx, x: cx + size * 0.1, y: cy + size * 0.29, r: size * 0.02, color: earPink)
    }
}

// MARK: - Capybara Renderer (Kapiiko)

/// A cute chibi capybara — very round, small ears, buck teeth, zen expression.
enum CapybaraRenderer {
    static func draw(in ctx: GraphicsContext, rect: CGRect, mood: MascotMood) {
        var ctx = ctx
        let size = min(rect.width, rect.height)
        let cx = rect.midX
        let cy = rect.midY

        let bodyColor = Color(red: 0.65, green: 0.48, blue: 0.32)
        let bellyColor = Color(red: 0.82, green: 0.7, blue: 0.55)
        let darkBrown = Color(red: 0.45, green: 0.32, blue: 0.2)
        let noseColor = Color(red: 0.3, green: 0.22, blue: 0.15)

        // Body — extra round, capybara style
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy + size * 0.08, width: size * 0.54, height: size * 0.44, color: bodyColor)

        // Belly
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy + size * 0.14, width: size * 0.32, height: size * 0.26, color: bellyColor)

        // Head — large and round
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy - size * 0.13, width: size * 0.48, height: size * 0.4, color: bodyColor)

        // Snout area — slightly lighter, round bump
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy - size * 0.04, width: size * 0.22, height: size * 0.14, color: bellyColor)

        // Small round ears
        DrawKit.ellipse(&ctx, xPos: cx - size * 0.18, yPos: cy - size * 0.3, width: size * 0.1, height: size * 0.08, color: bodyColor)
        DrawKit.ellipse(&ctx, xPos: cx + size * 0.18, yPos: cy - size * 0.3, width: size * 0.1, height: size * 0.08, color: bodyColor)
        // Inner ear
        DrawKit.ellipse(&ctx, xPos: cx - size * 0.18, yPos: cy - size * 0.3, width: size * 0.06, height: size * 0.05, color: darkBrown)
        DrawKit.ellipse(&ctx, xPos: cx + size * 0.18, yPos: cy - size * 0.3, width: size * 0.06, height: size * 0.05, color: darkBrown)

        // Eyes — capybara has small eyes set wide apart
        let eyeY = cy - size * 0.18
        DrawKit.cuteEyes(
            &ctx, leftX: cx - size * 0.1, rightX: cx + size * 0.1, yPos: eyeY, eyeWidth: size * 0.065, eyeHeight: size * 0.07, mood: mood)

        // Nose — big oval
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy - size * 0.06, width: size * 0.1, height: size * 0.06, color: noseColor)

        // Mouth — with buck teeth for encouraging/excited
        if mood == .excited || mood == .celebrating {
            DrawKit.openMouth(&ctx, xPos: cx, yPos: cy + size * 0.02, width: size * 0.1, height: size * 0.08)
            // Buck teeth
            DrawKit.roundedRect(&ctx, xPos: cx - size * 0.02, yPos: cy, width: size * 0.03, height: size * 0.04, radius: 1, color: .white)
            DrawKit.roundedRect(&ctx, xPos: cx + size * 0.02, yPos: cy, width: size * 0.03, height: size * 0.04, radius: 1, color: .white)
        } else if mood == .happy || mood == .encouraging {
            DrawKit.smile(
                &ctx, centerX: cx, y: cy + size * 0.0, width: size * 0.1, height: size * 0.04, color: darkBrown, lineWidth: 2)
        } else {
            // Relaxed — very gentle smile
            DrawKit.smile(
                &ctx, centerX: cx, y: cy - size * 0.01, width: size * 0.07, height: size * 0.02, color: darkBrown, lineWidth: 1.5
            )
        }

        // Blush
        DrawKit.blush(&ctx, leftX: cx - size * 0.15, rightX: cx + size * 0.15, yPos: cy - size * 0.08, radius: size * 0.04)

        // Tiny stubby legs
        DrawKit.ellipse(&ctx, xPos: cx - size * 0.14, yPos: cy + size * 0.3, width: size * 0.11, height: size * 0.07, color: darkBrown)
        DrawKit.ellipse(&ctx, xPos: cx + size * 0.14, yPos: cy + size * 0.3, width: size * 0.11, height: size * 0.07, color: darkBrown)

        // Optional: little leaf/grass on head for zen vibes
        if mood == .relaxed {
            var leafPath = Path()
            leafPath.move(to: CGPoint(x: cx + size * 0.02, y: cy - size * 0.32))
            leafPath.addQuadCurve(
                to: CGPoint(x: cx + size * 0.12, y: cy - size * 0.42), control: CGPoint(x: cx + size * 0.12, y: cy - size * 0.32))
            leafPath.addQuadCurve(
                to: CGPoint(x: cx + size * 0.02, y: cy - size * 0.32), control: CGPoint(x: cx + size * 0.02, y: cy - size * 0.42))
            ctx.fill(leafPath, with: .color(Color(red: 0.4, green: 0.75, blue: 0.35)))
            // Stem
            DrawKit.line(
                &ctx, from: CGPoint(x: cx + size * 0.02, y: cy - size * 0.32), to: CGPoint(x: cx + size * 0.0, y: cy - size * 0.28),
                color: Color(red: 0.35, green: 0.6, blue: 0.3), lineWidth: 1.5)
        }
    }
}

// MARK: - Dog Renderer (Wanko)

/// A cute chibi dog — floppy ears, big eyes, tongue out when happy, wagging tail.
enum DogRenderer {
    static func draw(in ctx: GraphicsContext, rect: CGRect, mood: MascotMood) {
        var ctx = ctx
        let size = min(rect.width, rect.height)
        let cx = rect.midX
        let cy = rect.midY

        let bodyColor = Color(red: 0.85, green: 0.68, blue: 0.42)
        let bellyColor = Color(red: 1.0, green: 0.92, blue: 0.78)
        let darkBrown = Color(red: 0.55, green: 0.38, blue: 0.2)
        let noseColor = Color(red: 0.2, green: 0.15, blue: 0.1)
        let tongueColor = Color(red: 0.95, green: 0.5, blue: 0.5)

        // Tail (behind body) — upward wag
        var tailPath = Path()
        tailPath.move(to: CGPoint(x: cx + size * 0.18, y: cy + size * 0.05))
        tailPath.addQuadCurve(
            to: CGPoint(x: cx + size * 0.35, y: cy - size * 0.2),
            control: CGPoint(x: cx + size * 0.38, y: cy + size * 0.05)
        )
        ctx.stroke(tailPath, with: .color(bodyColor), lineWidth: size * 0.06)

        // Body
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy + size * 0.08, width: size * 0.48, height: size * 0.42, color: bodyColor)

        // Belly
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy + size * 0.12, width: size * 0.28, height: size * 0.25, color: bellyColor)

        // Head
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy - size * 0.14, width: size * 0.46, height: size * 0.38, color: bodyColor)

        // Floppy ears
        // Left ear — oval hanging down at angle
        let leftEarPath = earPath(cx: cx - size * 0.17, cy: cy - size * 0.22, width: size * 0.12, height: size * 0.2, angle: -15, size: size)
        ctx.fill(leftEarPath, with: .color(darkBrown))
        // Right ear
        let rightEarPath = earPath(cx: cx + size * 0.17, cy: cy - size * 0.22, width: size * 0.12, height: size * 0.2, angle: 15, size: size)
        ctx.fill(rightEarPath, with: .color(darkBrown))

        // Face patch — lighter muzzle area
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy - size * 0.06, width: size * 0.22, height: size * 0.16, color: bellyColor)

        // Eyes
        let eyeY = cy - size * 0.17
        DrawKit.cuteEyes(
            &ctx, leftX: cx - size * 0.1, rightX: cx + size * 0.1, yPos: eyeY, eyeWidth: size * 0.08, eyeHeight: size * 0.09, mood: mood)

        // Eyebrows (expressive!)
        let browColor = darkBrown
        if mood == .encouraging {
            // Worried/determined brows — angled inward
            DrawKit.line(
                &ctx, from: CGPoint(x: cx - size * 0.15, y: cy - size * 0.25),
                to: CGPoint(x: cx - size * 0.06, y: cy - size * 0.23), color: browColor, lineWidth: 2.5)
            DrawKit.line(
                &ctx, from: CGPoint(x: cx + size * 0.15, y: cy - size * 0.25),
                to: CGPoint(x: cx + size * 0.06, y: cy - size * 0.23), color: browColor, lineWidth: 2.5)
        }

        // Nose
        DrawKit.ellipse(&ctx, xPos: cx, yPos: cy - size * 0.07, width: size * 0.08, height: size * 0.05, color: noseColor)

        // Mouth + tongue
        if mood == .excited || mood == .celebrating || mood == .happy {
            DrawKit.openMouth(&ctx, xPos: cx, yPos: cy + size * 0.01, width: size * 0.1, height: size * 0.08)
            // Tongue hanging out
            DrawKit.ellipse(&ctx, xPos: cx, yPos: cy + size * 0.06, width: size * 0.06, height: size * 0.07, color: tongueColor)
        } else if mood == .encouraging {
            DrawKit.ellipse(&ctx, xPos: cx, yPos: cy + size * 0.01, width: size * 0.04, height: size * 0.05, color: noseColor)
        } else {
            DrawKit.smile(
                &ctx, centerX: cx, y: cy - size * 0.0, width: size * 0.08, height: size * 0.03, color: noseColor, lineWidth: 2)
        }

        // Blush
        DrawKit.blush(&ctx, leftX: cx - size * 0.15, rightX: cx + size * 0.15, yPos: cy - size * 0.07, radius: size * 0.04)

        // Paws
        DrawKit.ellipse(&ctx, xPos: cx - size * 0.11, yPos: cy + size * 0.29, width: size * 0.13, height: size * 0.08, color: darkBrown)
        DrawKit.ellipse(&ctx, xPos: cx + size * 0.11, yPos: cy + size * 0.29, width: size * 0.13, height: size * 0.08, color: darkBrown)
        // Lighter paw pads
        DrawKit.circle(&ctx, x: cx - size * 0.11, y: cy + size * 0.3, r: size * 0.025, color: bellyColor)
        DrawKit.circle(&ctx, x: cx + size * 0.11, y: cy + size * 0.3, r: size * 0.025, color: bellyColor)

        // Collar
        let collarY = cy - size * 0.0
        DrawKit.ellipse(
            &ctx, xPos: cx, yPos: collarY, width: size * 0.32, height: size * 0.04, color: Color(red: 0.85, green: 0.25, blue: 0.25))
        // Tag
        DrawKit.circle(&ctx, x: cx, y: collarY + size * 0.03, r: size * 0.025, color: Color(red: 0.95, green: 0.8, blue: 0.2))
    }

    private static func earPath(cx: CGFloat, cy: CGFloat, width: CGFloat, height: CGFloat, angle: Double, size: CGFloat) -> Path {
        var path = Path()
        let rect = CGRect(x: cx - width / 2, y: cy - height * 0.2, width: width, height: height)
        path.addEllipse(in: rect)
        return path
    }
}
