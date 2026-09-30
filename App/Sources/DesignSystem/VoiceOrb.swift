import SwiftUI

/// Prototype Voice Orb: blobs orbiting a centre, radius driven by `level` (0...1).
struct VoiceOrb: View {
    var level: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            Canvas { gc, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let base = min(size.width, size.height) * 0.22
                gc.addFilter(.alphaThreshold(min: 0.5, color: .white))
                gc.addFilter(.blur(radius: 14))
                for i in 0..<6 {
                    let a = t * 0.8 + Double(i) * .pi / 3
                    let r = base * (0.5 + 0.9 * level)
                    let p = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a * 1.3) * r)
                    let rect = CGRect(x: p.x - base, y: p.y - base, width: base * 2, height: base * 2)
                    gc.fill(Path(ellipseIn: rect), with: .color(.white))
                }
            }
            .background(Tokens.spectrum)
            .mask(Circle())
        }
        .accessibilityHidden(true)
    }
}
