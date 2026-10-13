import SwiftUI

/// Мультяшний циферблат-котик. Лапку крутять пальцем по шкалі (1–60 хв); дотик до мордочки — старт/пауза.
/// У режимі фокусу шкала ховається, мордочка збільшується, а кільце показує, скільки часу лишилось.
struct DialView: View {
    @Environment(FocusModel.self) private var focus
    @Environment(AppStore.self) private var store
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var gestureMode: GestureMode?
    @State private var hop = false

    private enum GestureMode { case tap, knob, ignore }

    // система координат веб-версії: viewBox -26 2 352 304, центр (150, 150)
    private static let box = CGSize(width: 352, height: 304)
    private static let ox: CGFloat = 26, oy: CGFloat = -2
    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x + ox, y: y + oy) }
    private static let shift = CGAffineTransform(translationX: ox, y: oy)

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width / Self.box.width, 1.3)
            ZStack(alignment: .topLeading) {
                artwork
                    .frame(width: Self.box.width, height: Self.box.height)
                    .scaleEffect(s, anchor: .topLeading)
            }
            .frame(width: Self.box.width * s, height: Self.box.height * s, alignment: .topLeading)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture(scale: s, offsetX: (geo.size.width - Self.box.width * s) / 2))
        }
        .aspectRatio(Self.box.width / Self.box.height, contentMode: .fit)
        .frame(maxWidth: 380)
        .keyframeAnimator(initialValue: CGFloat(0), trigger: focus.finishCount) { v, y in
            v.offset(y: y)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-10, duration: 0.2); CubicKeyframe(0, duration: 0.3)
                CubicKeyframe(-10, duration: 0.2); CubicKeyframe(0, duration: 0.3)
                CubicKeyframe(-10, duration: 0.2); CubicKeyframe(0, duration: 0.3)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Тривалість фокусу")
        .accessibilityValue(focus.inFocus ? "\(focus.timeText), \(focus.subText)" : "\(focus.minutes) хв")
        .accessibilityHint(focus.inFocus ? "Двічі торкніться, щоб поставити на паузу чи продовжити" : "Проведіть угору чи вниз, щоб змінити час")
        .accessibilityAdjustableAction { dir in
            guard !focus.running else { return }
            switch dir {
            case .increment: focus.setMinutes(focus.minutes + 1)
            case .decrement: focus.setMinutes(focus.minutes - 1)
            @unknown default: break
            }
        }
        .accessibilityAction { focus.playPause() }
        .accessibilityIdentifier("dial")
    }

    // MARK: малюнок
    private var artwork: some View {
        let mode = focus.inFocus
        let frac = mode ? min(1, focus.remaining / focus.total) : min(1, focus.remaining / 3600)
        let knobA = min(1, (mode ? focus.total : focus.remaining) / 3600) * 2 * .pi
        let center = Self.pt(150, 150)
        let spring = reduceMotion ? Animation?.none : .spring(response: 0.6, dampingFraction: 0.62)

        return ZStack(alignment: .topLeading) {
            // вуса
            Group {
                VectorPaths.whiskerL.applying(Self.shift).stroke(Theme.brown, style: .init(lineWidth: 3, lineCap: .round))
                VectorPaths.whiskerR.applying(Self.shift).stroke(Theme.brown, style: .init(lineWidth: 3, lineCap: .round))
            }
            // вушка (ворушаться під час фокусу)
            EarsView(running: focus.running && !reduceMotion)
            // тарілка з тінню
            Circle().fill(Color(hex: 0xe9a35e)).frame(width: 284, height: 284).position(Self.pt(150, 157))
            Circle().fill(Theme.card).overlay(Circle().stroke(Theme.brown, lineWidth: 3.5))
                .frame(width: 284, height: 284).position(center)
            // доріжка й дуга
            Circle().stroke(Theme.tog, lineWidth: 22).frame(width: 244, height: 244).position(center)
            Circle()
                .trim(from: 0, to: frac)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 244, height: 244)
                .position(center)
                .opacity(frac < 0.004 ? 0 : 1)
                .animation(focus.running ? .linear(duration: 0.3) : .easeOut(duration: 0.15), value: frac)
            // напрямні, поділки й цифри — ховаються в режимі фокусу
            Group {
                Circle().stroke(Theme.brown.opacity(0.35), lineWidth: 2).frame(width: 267, height: 267).position(center)
                Circle().stroke(Theme.brown.opacity(0.35), lineWidth: 2).frame(width: 221, height: 221).position(center)
                ScaleTicks().frame(width: Self.box.width, height: Self.box.height)
                ForEach(0..<6, id: \.self) { i in
                    let a = Double(i) * 60 * .pi / 180
                    Text(i == 0 ? "60" : "\(i * 10)")
                        .font(.nunitoFixed(13, .extraBold))
                        .foregroundStyle(Theme.inkMuted)
                        .position(Self.pt(150 + 85 * sin(a), 150 - 85 * cos(a)))
                }
            }
            .opacity(mode ? 0 : 1)
            .animation(.easeInOut(duration: 0.35), value: mode)

            // мордочка
            FaceView(time: focus.timeText, sub: focus.subText, eyesClosed: focus.running, scale: mode ? 1.66 : 1)
                .frame(width: Self.box.width, height: Self.box.height)
                .animation(spring, value: mode)

            // лапка-повзунок
            PawKnob()
                .scaleEffect(mode ? 0.001 : 1)
                .rotationEffect(.degrees(mode ? -90 : 0))
                .opacity(mode ? 0 : 1)
                .animation(reduceMotion ? nil : .timingCurve(0.5, -0.4, 0.6, 1, duration: 0.35), value: mode)
                .position(Self.pt(150 + 122 * sin(knobA), 150 - 122 * cos(knobA)))
                .animation(gestureMode == .knob ? .linear(duration: 0.08) : .easeOut(duration: 0.2), value: knobA)
                .accessibilityHidden(true)
        }
    }

    // MARK: жести
    private func dragGesture(scale s: CGFloat, offsetX: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { g in
                func toBox(_ p: CGPoint) -> CGPoint { CGPoint(x: (p.x - offsetX) / s - Self.ox, y: p.y / s - Self.oy) }
                if gestureMode == nil {
                    let p = toBox(g.startLocation)
                    let r = hypot(p.x - 150, p.y - 150)
                    if r < (focus.inFocus ? 110 : 66) { gestureMode = .tap }
                    else if focus.running || r > 152 { gestureMode = .ignore }
                    else { gestureMode = .knob; store.pagerLocked = true }
                }
                if gestureMode == .knob { focus.setMinutes(minutes(at: toBox(g.location))) }
            }
            .onEnded { g in
                if gestureMode == .tap && hypot(g.translation.width, g.translation.height) < 12 { focus.playPause() }
                gestureMode = nil
                store.pagerLocked = false
            }
    }

    private func minutes(at p: CGPoint) -> Int {
        var deg = atan2(p.x - 150, -(p.y - 150)) * 180 / .pi
        if deg < 0 { deg += 360 }
        var m = Int((deg / 6).rounded())
        let prev = focus.minutes
        if prev - m > 30 { m = 60 }          // перетнули верх за годинниковою стрілкою
        else if m - prev > 30 { m = 1 }      // перетнули верх у зворотний бік
        return max(1, min(60, m))
    }
}

/// 60 поділок шкали.
private struct ScaleTicks: View {
    var body: some View {
        Canvas { ctx, _ in
            ctx.translateBy(x: 26, y: -2)
            for i in 0..<60 {
                let a = Double(i) * 6 * .pi / 180, major = i % 5 == 0
                let r1: Double = major ? 98 : 102, r2: Double = 107
                var p = Path()
                p.move(to: CGPoint(x: 150 + r1 * sin(a), y: 150 - r1 * cos(a)))
                p.addLine(to: CGPoint(x: 150 + r2 * sin(a), y: 150 - r2 * cos(a)))
                ctx.stroke(p, with: .color(Theme.brown.opacity(major ? 1 : 0.45)),
                           style: StrokeStyle(lineWidth: major ? 3 : 1.6, lineCap: .round))
            }
        }
    }
}

private struct EarsView: View {
    let running: Bool
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation(paused: !running)) { ctx in
            let t = running ? loopPhase(ctx.date, start: start, duration: 3.2) : 0
            let tR = running ? loopPhase(ctx.date.addingTimeInterval(-0.15), start: start, duration: 3.2) : 0
            let l = track([Key(0, 0), Key(0.86, 0, .inOut), Key(0.9, -9, .inOut), Key(0.95, 4, .inOut), Key(1, 0)], t)
            let r = track([Key(0, 0), Key(0.86, 0, .inOut), Key(0.9, 9, .inOut), Key(0.95, -4, .inOut), Key(1, 0)], tR)
            ZStack(alignment: .topLeading) {
                ear(VectorPaths.earLOuter, VectorPaths.earLInner)
                    .rotationEffect(.degrees(l), anchor: UnitPoint(x: (85.2 + 26) / 352, y: (72 - 2) / 304))
                ear(VectorPaths.earROuter, VectorPaths.earRInner)
                    .rotationEffect(.degrees(r), anchor: UnitPoint(x: (214.8 + 26) / 352, y: (72 - 2) / 304))
            }
        }
        .frame(width: 352, height: 304)
    }

    private func ear(_ outer: Path, _ inner: Path) -> some View {
        let t = CGAffineTransform(translationX: 26, y: -2)
        return ZStack {
            outer.applying(t).fill(Color(hex: 0xf6a35c))
            outer.applying(t).stroke(Theme.brown, style: .init(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
            inner.applying(t).fill(Color(hex: 0xfbcfa3))
        }
        .frame(width: 352, height: 304)
    }
}

/// Мордочка: очі (відкриті / заплющені під час фокусу), рум'янець, час, носик і ротик.
private struct FaceView: View {
    let time: String, sub: String, eyesClosed: Bool, scale: CGFloat

    var body: some View {
        let t = CGAffineTransform(translationX: 26, y: -2)
        ZStack(alignment: .topLeading) {
            Circle().fill(Theme.cream)
                .overlay(Circle().stroke(Theme.brown, lineWidth: 3.5 / scale))   // товщина контуру не росте зі збільшенням
                .frame(width: 132, height: 132).position(x: 176, y: 148)
            if eyesClosed {
                VectorPaths.eyeClosedL.applying(t).stroke(Theme.ink, style: .init(lineWidth: 3, lineCap: .round))
                VectorPaths.eyeClosedR.applying(t).stroke(Theme.ink, style: .init(lineWidth: 3, lineCap: .round))
            } else {
                Ellipse().fill(Theme.ink).frame(width: 9, height: 11).position(x: 154, y: 111)
                Ellipse().fill(Theme.ink).frame(width: 9, height: 11).position(x: 198, y: 111)
            }
            Ellipse().fill(Color(hex: 0xf9a77a).opacity(0.6)).frame(width: 16, height: 9).position(x: 140, y: 122)
            Ellipse().fill(Color(hex: 0xf9a77a).opacity(0.6)).frame(width: 16, height: 9).position(x: 212, y: 122)
            Text(time)
                .font(.nunitoFixed(38, .extraBold))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText(countsDown: true))
                .position(x: 176, y: 145)
                .accessibilityIdentifier("timeText")
            VectorPaths.nose.applying(t).fill(Color(hex: 0xe0703a))
            VectorPaths.nose.applying(t).stroke(Theme.brown, style: .init(lineWidth: 1.5, lineJoin: .round))
            VectorPaths.mouth.applying(t).stroke(Theme.brown, style: .init(lineWidth: 2.2, lineCap: .round))
            Text(sub)
                .font(.nunitoFixed(11.5, .extraBold))
                .foregroundStyle(Theme.inkMuted)
                .position(x: 176, y: 193)
        }
        .scaleEffect(scale, anchor: UnitPoint(x: 176.0 / 352, y: 148.0 / 304))
    }
}

/// Лапка-повзунок (білий кружечок із подушечками).
private struct PawKnob: View {
    var body: some View {
        ZStack {
            Circle().fill(Theme.accentDark).frame(width: 42, height: 42).offset(y: 3)
            Circle().fill(Theme.cream).overlay(Circle().stroke(Theme.brown, lineWidth: 3.5)).frame(width: 42, height: 42)
            Ellipse().fill(Theme.brown).frame(width: 14, height: 11.2).offset(y: 4)
            ForEach([(-8.0, -5.0), (-3.0, -9.5), (3.0, -9.5), (8.0, -5.0)], id: \.0) { p in
                Ellipse().fill(Theme.brown).frame(width: 5.6, height: 6.8).offset(x: p.0, y: p.1)
            }
        }
        .frame(width: 48, height: 52)
    }
}
