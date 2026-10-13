import SwiftUI

/// Детермінований генератор: та сама справа — ті самі подряпини (порт функції seeded() з веб-версії).
struct SeededRandom {
    private var h: UInt32
    init(_ str: String) {
        let units = Array(str.utf16)
        var h = UInt32(1779033703) ^ UInt32(truncatingIfNeeded: units.count)
        for u in units {
            h = (h ^ UInt32(u)) &* 3432918353
            h = (h << 13) | (h >> 19)
        }
        self.h = h
    }
    mutating func next() -> Double {
        h = (h ^ (h >> 16)) &* 2246822507
        h = (h ^ (h >> 13)) &* 3266489909
        h ^= h >> 16
        return Double(h) / 4294967296
    }
}

/// Котячі подряпини замість закреслення. Справжні виглядають так: групи з 3–4 паралельних борозен,
/// кожна глибша на початку й сходить нанівець, середні кігті довші за крайні,
/// навколо темної борозни — світліша «зчесана» смуга з подертим краєм і волокнами.
enum Scratch {
    static let styles = 4   // 0 «Удари лапою», 1 «Один мах», 2 «Навхрест», 3 «Шкряб-шкряб»
    static let pad: CGFloat = 9

    struct Claw {
        var s: CGPoint, c: CGPoint, e: CGPoint
        var scuff: Path, groove: Path, shine: Path, fibers: Path
        var delay: Double, duration: Double
        var length: CGFloat
    }

    private struct Group {
        var cx: CGFloat, cy: CGFloat, a: CGFloat, l: CGFloat, claws: Int, gap: CGFloat
        var delay: Double, step: Double, t: Double, w: CGFloat
    }

    // точка й нормаль на квадратичній кривій S–C–E
    private static func onCurve(_ s: CGPoint, _ c: CGPoint, _ e: CGPoint, _ t: CGFloat) -> (CGPoint, CGVector) {
        let u = 1 - t
        let x = u*u*s.x + 2*u*t*c.x + t*t*e.x, y = u*u*s.y + 2*u*t*c.y + t*t*e.y
        let dx = 2*u*(c.x-s.x) + 2*t*(e.x-c.x), dy = 2*u*(c.y-s.y) + 2*t*(e.y-c.y)
        let l = max(hypot(dx, dy), 0.0001)
        return (CGPoint(x: x, y: y), CGVector(dx: -dy/l, dy: dx/l))
    }
    // профіль товщини: кіготь входить, найглибше на першій чверті, далі звужується до вістря
    private static func profile(_ t: CGFloat) -> CGFloat {
        t < 0.12 ? 0.55 + 0.45 * (t / 0.12) : pow(1 - (t - 0.12) / 0.88, 0.8)
    }
    // звужена форма вздовж кривої; jag — наскільки подертий край, shift — зсув уздовж нормалі
    private static func taper(_ s: CGPoint, _ c: CGPoint, _ e: CGPoint, _ w: CGFloat, _ rnd: inout SeededRandom,
                              jag: CGFloat, shift: CGFloat) -> Path {
        var left: [CGPoint] = [], right: [CGPoint] = []
        let n = 16
        for i in 0...n {
            let t = CGFloat(i) / CGFloat(n)
            let (p, nv) = onCurve(s, c, e, t)
            let half = w * profile(t) / 2
            let jl = CGFloat(rnd.next() - 0.5) * jag * w, jr = CGFloat(rnd.next() - 0.5) * jag * w
            left.append(CGPoint(x: p.x + nv.dx*(half + shift + jl), y: p.y + nv.dy*(half + shift + jl)))
            right.append(CGPoint(x: p.x - nv.dx*(half - shift + jr), y: p.y - nv.dy*(half - shift + jr)))
        }
        var path = Path()
        path.move(to: left[0])
        left.dropFirst().forEach { path.addLine(to: $0) }
        right.reversed().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }

    private static func plan(style: Int, w: CGFloat, H: CGFloat, rnd: inout SeededRandom) -> [Group] {
        func deg(_ d: CGFloat) -> CGFloat { d * .pi / 180 }
        func r() -> CGFloat { CGFloat(rnd.next()) }
        var g: [Group] = []
        let h = H - 18                                   // висота самого тексту
        switch style {
        case 1:   // один довгий низький мах через увесь текст
            let L = w * 0.98 + 8
            let a = (r() < 0.5 ? 1 : -1) * atan2(h * (0.35 + r() * 0.2), L)
            g.append(Group(cx: w/2, cy: H/2, a: a, l: L, claws: 4, gap: 4.6, delay: 0, step: 0.055, t: 0.26, w: 2.9 + r()))
        case 2:   // хрести: спершу «\», за мить «/»
            let n = max(1, Int((w / 74).rounded())), L = min(58, w / CGFloat(n) * 0.95), a = atan2(h * 1.15, L)
            for i in 0..<n {
                let cx = (CGFloat(i) + 0.5) * w / CGFloat(n) + (r() - 0.5) * 6
                g.append(Group(cx: cx, cy: H/2, a: a, l: L, claws: 3, gap: 4.6, delay: Double(i) * 0.26, step: 0.04, t: 0.15, w: 2.6 + r() * 0.8))
                g.append(Group(cx: cx, cy: H/2, a: -a, l: L, claws: 3, gap: 4.6, delay: Double(i) * 0.26 + 0.14, step: 0.04, t: 0.15, w: 2.6 + r() * 0.8))
            }
        case 3:   // багато коротких майже вертикальних подряпин
            let n = max(3, Int((w / 32).rounded()))
            var order = Array(0..<n)
            for i in stride(from: n - 1, to: 0, by: -1) { order.swapAt(i, Int(r() * CGFloat(i + 1)) % (i + 1)) }
            for i in 0..<n {
                g.append(Group(cx: (CGFloat(i) + 0.5) * w / CGFloat(n) + (r() - 0.5) * 8, cy: H/2 + (r() - 0.5) * 6,
                               a: deg(72 + r() * 26), l: H * (0.6 + r() * 0.35), claws: r() < 0.5 ? 2 : 3, gap: 4.2,
                               delay: Double(order[i]) * 0.055, step: 0.022, t: 0.11, w: 1.8 + r() * 0.9))
            }
        default:  // удари лапою: кілька груп крутих паралельних борозен
            let n = max(1, Int((w / 88).rounded()))
            for k in 0..<n {
                let a = deg(56 + r() * 12)
                g.append(Group(cx: (CGFloat(k) + 0.5) * w / CGFloat(n) + (r() - 0.5) * 10, cy: H/2, a: a, l: H / sin(a),
                               claws: r() < 0.3 ? 3 : 4, gap: 5.2 + r() * 1.6, delay: Double(k) * 0.17, step: 0.042, t: 0.16, w: 2.3 + r() * 1.3))
            }
        }
        return g
    }

    /// Подряпини для тексту розміром `size` (координати від лівого верхнього кута тексту, з запасом `pad` згори й знизу).
    static func claws(style: Int, key: String, size: CGSize) -> [Claw] {
        let w = max(36, size.width), H = size.height + pad * 2
        var rnd = SeededRandom(key + ":" + String(style))
        var out: [Claw] = []
        for g in plan(style: style, w: w, H: H, rnd: &rnd) {
            let dir = CGVector(dx: cos(g.a), dy: sin(g.a)), nor = CGVector(dx: -dir.dy, dy: dir.dx)
            for k in 0..<g.claws {
                let edge = k == 0 || k == g.claws - 1
                let off = (CGFloat(k) - CGFloat(g.claws - 1) / 2) * g.gap
                let L = g.l * (0.85 + CGFloat(rnd.next()) * 0.2) * (edge ? 0.84 : 1)     // середні кігті довші
                let slide = (CGFloat(rnd.next()) - 0.5) * 6 + (edge ? 3 : 0)
                let mx = g.cx + nor.dx*off + dir.dx*slide, my = g.cy + nor.dy*off + dir.dy*slide
                let s = CGPoint(x: mx - dir.dx*L/2, y: my - dir.dy*L/2), e = CGPoint(x: mx + dir.dx*L/2, y: my + dir.dy*L/2)
                let bend = (CGFloat(rnd.next()) - 0.5) * min(8, L * 0.06)
                let c = CGPoint(x: (s.x+e.x)/2 + nor.dx*bend, y: (s.y+e.y)/2 + nor.dy*bend)
                let W = g.w * (0.85 + CGFloat(rnd.next()) * 0.3)
                let delay = g.delay + Double(k) * g.step
                // волокна, що стирчать із подертого краю
                var fib = Path()
                for _ in 0..<2 {
                    let t = 0.12 + CGFloat(rnd.next()) * 0.45
                    let (p, nv) = onCurve(s, c, e, t)
                    let side: CGFloat = rnd.next() < 0.5 ? 1 : -1
                    let half = W * profile(t) * 1.05, fl = 2.5 + CGFloat(rnd.next()) * 3.5
                    let p0 = CGPoint(x: p.x + nv.dx*half*side, y: p.y + nv.dy*half*side)
                    fib.move(to: p0)
                    fib.addLine(to: CGPoint(x: p0.x + (-dir.dx*0.7 + nv.dx*side*0.7)*fl, y: p0.y + (-dir.dy*0.7 + nv.dy*side*0.7)*fl))
                }
                let scuff = taper(s, c, e, W*2.3 + 1.4, &rnd, jag: 0.45, shift: 0)
                let groove = taper(s, c, e, W, &rnd, jag: 0.12, shift: 0.4)
                let shine = taper(s, c, e, W*0.28, &rnd, jag: 0, shift: -W*0.32)
                out.append(Claw(s: s, c: c, e: e, scuff: scuff, groove: groove, shine: shine, fibers: fib,
                                delay: delay, duration: g.t, length: L))
            }
        }
        return out
    }

    /// Скільки триває анімація (оцінка за довжиною тексту — для черговості переміщення справи вниз).
    static func duration(style: Int, key: String, text: String) -> Double {
        let w = min(CGFloat(text.count) * 8.6, 290)
        let lines = max(1, ceil(CGFloat(text.count) * 8.6 / 290))
        let cl = claws(style: style, key: key, size: CGSize(width: w, height: 24 * lines))
        return cl.map { $0.delay + $0.duration }.max() ?? 0.4
    }
}

/// Малює подряпини; `elapsed` — секунди від початку (nil — показати повністю, без анімації).
struct ScratchCanvas: View {
    let claws: [Scratch.Claw]
    let elapsed: Double?
    var inset: CGFloat = 0          // запас навколо тексту: кігті можуть трохи виходити за його межі

    var body: some View {
        Canvas { ctx, _ in
            ctx.translateBy(x: inset, y: inset)
            for claw in claws {
                var p: CGFloat = 1
                if let elapsed {
                    let t = (elapsed - claw.delay) / claw.duration
                    // cubic-bezier(.55,0,.35,1) — кіготь розганяється й гальмує
                    p = CGFloat(Ease.cubic(0.55, 0, 0.35, 1).y(max(0, min(1, t))))
                }
                guard p > 0 else { continue }
                var reveal = Path()
                reveal.move(to: claw.s)
                reveal.addQuadCurve(to: claw.e, control: claw.c)
                let mask = reveal.trimmedPath(from: 0, to: p)
                    .strokedPath(StrokeStyle(lineWidth: 16, lineCap: .round))
                ctx.drawLayer { layer in
                    layer.clip(to: mask)
                    layer.fill(claw.scuff, with: .color(Color(hex: 0xe3ad78, alpha: 0.55)))
                    layer.fill(claw.groove, with: .color(Theme.brown))
                    layer.fill(claw.shine, with: .color(Color(hex: 0xfff6e4, alpha: 0.8)))
                    layer.stroke(claw.fibers, with: .color(Theme.brown.opacity(0.7)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
