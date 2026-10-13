import SwiftUI

/// Криві згладжування (як у CSS): лінійна, cubic-bezier, «сходинка».
enum Ease {
    case linear
    case cubic(Double, Double, Double, Double)
    case step                      // steps(1, end): тримає значення до наступного ключа
    case steps(Int)                // steps(n, end)

    static let ease = Ease.cubic(0.25, 0.1, 0.25, 1)
    static let inOut = Ease.cubic(0.42, 0, 0.58, 1)
    static let easeOut = Ease.cubic(0, 0, 0.58, 1)
    static let easeIn = Ease.cubic(0.42, 0, 1, 1)

    func y(_ x: Double) -> Double {
        let x = max(0, min(1, x))
        switch self {
        case .linear: return x
        case .step: return x >= 1 ? 1 : 0
        case .steps(let n): return floor(x * Double(n)) / Double(n)
        case let .cubic(x1, y1, x2, y2):
            // розв'язуємо x(t) = x методом Ньютона з підстраховкою бісекцією
            func bx(_ t: Double) -> Double { let u = 1 - t; return 3*u*u*t*x1 + 3*u*t*t*x2 + t*t*t }
            func by(_ t: Double) -> Double { let u = 1 - t; return 3*u*u*t*y1 + 3*u*t*t*y2 + t*t*t }
            func dx(_ t: Double) -> Double { let u = 1 - t; return 3*u*u*x1 + 6*u*t*(x2 - x1) + 3*t*t*(1 - x2) }
            var t = x
            for _ in 0..<8 {
                let err = bx(t) - x
                if abs(err) < 1e-5 { return by(t) }
                let d = dx(t)
                if abs(d) < 1e-6 { break }
                t -= err / d
            }
            var lo = 0.0, hi = 1.0; t = x
            for _ in 0..<30 {
                let v = bx(t)
                if abs(v - x) < 1e-5 { break }
                if v < x { lo = t } else { hi = t }
                t = (lo + hi) / 2
            }
            return by(t)
        }
    }
}

/// Ключовий кадр: момент (0…1), значення і крива до НАСТУПНОГО кадру (як animation-timing-function у CSS).
struct Key {
    let t: Double
    let v: Double
    let ease: Ease
    init(_ t: Double, _ v: Double, _ ease: Ease = .ease) { self.t = t; self.v = v; self.ease = ease }
}

/// Значення доріжки ключових кадрів у момент `t` (0…1).
func track(_ keys: [Key], _ t: Double) -> Double {
    guard let first = keys.first else { return 0 }
    if t <= first.t { return first.v }
    for i in 0..<(keys.count - 1) {
        let a = keys[i], b = keys[i + 1]
        if t <= b.t {
            let span = b.t - a.t
            if span <= 0 { return b.v }
            return a.v + (b.v - a.v) * a.ease.y((t - a.t) / span)
        }
    }
    return keys.last!.v
}

/// Фаза циклічної анімації (0…1) для TimelineView.
func loopPhase(_ date: Date, start: Date, duration: Double) -> Double {
    let e = date.timeIntervalSince(start)
    return (e.truncatingRemainder(dividingBy: duration)) / duration
}
