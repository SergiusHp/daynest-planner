import SwiftUI

/// Рядок справи: квадратик-позначка, текст, час. Виконана справа — котячі подряпини й прозорість 50%.
struct TaskRow: View {
    @Environment(AppStore.self) private var store
    @Environment(\.reduceMotion) private var reduceMotion
    let plan: Plan

    var body: some View {
        let started = store.scratchStarted[plan.id]
        let style = store.scratchStyle(of: plan)
        // поки йде анімація — оновлюємо рядок щокадру; потім він статичний
        TimelineView(.animation(paused: started == nil || reduceMotion)) { ctx in
            let elapsed: Double? = (plan.done && !reduceMotion) ? started.map { ctx.date.timeIntervalSince($0) } : nil
            let live = elapsed.map { $0 < 1.6 } ?? false
            content(style: style, elapsed: live ? elapsed : nil)
                .modifier(RowShake(style: style, elapsed: live ? elapsed : nil))
        }
    }

    @ViewBuilder
    private func content(style: Int, elapsed: Double?) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Button {
                store.toggle(plan.id)
            } label: {
                CheckBox(done: plan.done)
                    .padding(.top, 1)
                    .frame(width: 44, height: 44, alignment: .topLeading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, -18)
            .accessibilityLabel("Виконано: \(plan.text)")
            .accessibilityValue(plan.done ? "виконано" : "не виконано")
            .accessibilityAddTraits(.isToggle)
            .accessibilityIdentifier("check-\(plan.id)")

            Button {
                store.sheet = .edit(plan)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.text)
                        .font(.nunito(17, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .overlay(alignment: .topLeading) {
                            if plan.done {
                                GeometryReader { g in
                                    ScratchOverlay(key: plan.id, style: style, size: g.size, elapsed: elapsed)
                                }
                            }
                        }
                    if !plan.time.isEmpty {
                        Text(plan.time)
                            .font(.nunito(13, .bold, relativeTo: .footnote))
                            .monospacedDigit()
                            .foregroundStyle(Theme.inkMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(plan.text + (plan.time.isEmpty ? "" : ", о \(plan.time)") + (plan.done ? ", виконано" : ""))
            .accessibilityHint("Відкрити для змін")
            .accessibilityIdentifier("task-\(plan.id)")
        }
        .padding(.vertical, 14)
        .opacity(plan.done ? 0.5 : 1)
        .animation(.easeOut(duration: 0.35), value: plan.done)
    }
}

struct CheckBox: View {
    let done: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(done ? Theme.brown : Theme.checkBg)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.brown, lineWidth: 2))
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Theme.checkBg)
                    .opacity(done ? 1 : 0)
            }
            .frame(width: 26, height: 26)
            .animation(.easeOut(duration: 0.15), value: done)
    }
}

/// Подряпини поверх тексту + «крихти паперу», що відлітають.
struct ScratchOverlay: View {
    let key: String
    let style: Int
    let size: CGSize
    let elapsed: Double?
    private let margin: CGFloat = 24

    var body: some View {
        let claws = Scratch.claws(style: style, key: key, size: size)
        let w = max(36, size.width), h = size.height + Scratch.pad * 2
        ZStack(alignment: .topLeading) {
            ScratchCanvas(claws: claws, elapsed: elapsed, inset: margin)
                .frame(width: w + margin * 2, height: h + margin * 2)
                .offset(x: -margin, y: -Scratch.pad - margin)
            if let elapsed {
                Crumbs(key: key, style: style, size: size, elapsed: elapsed)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

/// Крихти паперу: скільки й куди зносить — залежить від стилю.
struct Crumbs: View {
    let key: String, style: Int, size: CGSize, elapsed: Double

    var body: some View {
        Canvas { ctx, _ in
            var r = SeededRandom("crumb:" + key)
            let count = [7, 8, 9, 14][style % 4]
            let drift: CGFloat = style == 1 ? 18 : 0
            for _ in 0..<count {
                let x0 = CGFloat(r.next()) * size.width
                let y0 = size.height * (0.4 + CGFloat(r.next()) * 0.5)
                let dark = r.next() < 0.5
                let dur = 0.52 + r.next() * 0.26, delay = r.next() * 0.42
                let dx = drift + (CGFloat(r.next()) - 0.5) * 22, dy = 14 + CGFloat(r.next()) * 16
                let rot = r.next() * 240
                let t = (elapsed - delay) / dur
                guard t > 0, t < 1 else { continue }
                let e = CGFloat(Ease.cubic(0.3, 0.6, 0.6, 1).y(t))
                var c = ctx
                c.opacity = 1 - e
                c.translateBy(x: x0 + dx * e, y: y0 + dy * e)
                c.rotate(by: .degrees(rot * Double(e)))
                c.fill(Path(CGRect(x: -1.5, y: -1.5, width: 3, height: 3)),
                       with: .color(dark ? Theme.brown : Color(hex: 0xe7b98a)))
            }
        }
        .frame(width: size.width, height: size.height + 40, alignment: .topLeading)
    }
}

/// «Фізика» рядка для кожного стилю: здригання, ривок, подвійний удар, дрібне тремтіння.
struct RowShake: ViewModifier {
    let style: Int
    let elapsed: Double?

    func body(content: Content) -> some View {
        var x = 0.0, y = 0.0, rot = 0.0
        if let e = elapsed {
            switch style {
            case 1:
                if e < 0.42 { let t = e / 0.42
                    x = track([Key(0, 0), Key(0.35, 5), Key(0.7, -1), Key(1, 0)], t) }
            case 2:
                if e < 0.56 { let t = (e.truncatingRemainder(dividingBy: 0.28)) / 0.28
                    x = track([Key(0, 0, .inOut), Key(0.33, 2, .inOut), Key(0.66, -2, .inOut), Key(1, 0)], t)
                    y = track([Key(0, 0), Key(0.33, 1), Key(0.66, 1), Key(1, 0)], t)
                    rot = track([Key(0, 0), Key(0.33, 0.5), Key(0.66, -0.5), Key(1, 0)], t) }
            case 3:
                if e < 0.63 { let t = (e.truncatingRemainder(dividingBy: 0.09)) / 0.09
                    x = track([Key(0, 0, .linear), Key(0.33, -1.5, .linear), Key(0.66, 1.5, .linear), Key(1, 0)], t) }
            default:
                if e < 0.48 { let t = (e.truncatingRemainder(dividingBy: 0.24)) / 0.24
                    x = track([Key(0, 0, .inOut), Key(0.33, -2, .inOut), Key(0.66, 2, .inOut), Key(1, 0)], t)
                    rot = track([Key(0, 0), Key(0.33, -0.4), Key(0.66, 0.3), Key(1, 0)], t) }
            }
        }
        return content
            .offset(x: x, y: y)
            .rotationEffect(.degrees(rot))
    }
}
