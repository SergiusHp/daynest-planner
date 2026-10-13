import SwiftUI

/// Знайомство з жестами: три кроки з анімованими демонстраціями. Показується один раз, після привітання.
struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.rootInsets) private var insets
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var forward = true
    @State private var startedAt = Date()

    static let texts = [
        "Натисни на сонечко, щоб повернутися до сьогоднішнього дня.",
        "Свайпни вліво, щоб перейти на наступну сторінку.",
        "Натисни на котика, щоб запланувати день.",
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(step + 1)/3")
                    .font(.nunitoFixed(13, .extraBold))
                    .tracking(0.8)
                    .monospacedDigit()
                    .foregroundStyle(Theme.inkMuted)
                    .accessibilityLabel("Крок \(step + 1) з 3")
                    .accessibilityIdentifier("obProgress")
                Spacer()
                Button("Пропустити") { onFinish() }
                    .font(.nunito(15, .extraBold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(minWidth: 44, minHeight: 44)
                    .opacity(step == 2 ? 0 : 1)
                    .disabled(step == 2)
                    .accessibilityHidden(step == 2)
                    .accessibilityIdentifier("obSkip")
            }
            .frame(height: 48)

            GeometryReader { geo in
                let k = min(geo.size.width / 300, geo.size.height / 400, 1.3)
                ZStack {
                    RadialGradient(colors: [Color(hex: 0xfdd195, alpha: 0.55), Color(hex: 0xfdd195, alpha: 0)],
                                   center: .center, startRadius: 0, endRadius: min(geo.size.width, 360) * 0.46)
                    ZStack {
                        demo(for: step)
                            .id(step)
                            .transition(.asymmetric(
                                insertion: .offset(x: forward ? 40 : -40).combined(with: .opacity),
                                removal: .offset(x: forward ? -40 : 40).combined(with: .opacity)))
                    }
                    .frame(width: 300, height: 400)
                    .scaleEffect(k)
                    .frame(width: 300 * k, height: 400 * k)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 20).onEnded { g in
                    let dx = g.translation.width, dy = g.translation.height
                    guard abs(dx) > 50, abs(dx) > abs(dy) * 1.3 else { return }
                    if dx < 0 && step < 2 { go(step + 1) } else if dx > 0 && step > 0 { go(step - 1) }
                })
            }
            .padding(.top, 8)
            .accessibilityHidden(true)

            Text(Self.texts[step])
                .font(.nunito(21, .extraBold, relativeTo: .title2))
                .minimumScaleFactor(0.85)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
                .frame(minHeight: 84, alignment: .top)
                .padding(.top, 20)
                .id("t\(step)")
                .transition(.opacity.combined(with: .offset(y: 6)))
                .accessibilityIdentifier("obText")

            Button(step == 2 ? "Почати" : "Далі") {
                if step < 2 { go(step + 1) } else { onFinish() }
            }
            .buttonStyle(.primaryLedge)
            .padding(.top, 12)
            .accessibilityIdentifier("obNext")
        }
        .padding(.horizontal, 24)
        .padding(.top, insets.top + 4)
        .padding(.bottom, insets.bottom + 20)
        .background(LinearGradient(colors: [Theme.calTop, Theme.day, Theme.day], startPoint: .top, endPoint: .bottom))
    }

    private func go(_ i: Int) {
        Haptics.tap()
        forward = i > step
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            step = i
            startedAt = Date()
        }
    }

    @ViewBuilder
    private func demo(for i: Int) -> some View {
        TimelineView(.animation(paused: reduceMotion)) { ctx in
            let elapsed = ctx.date.timeIntervalSince(startedAt)
            switch i {
            case 0: SunDemo(t: reduceMotion ? nil : (elapsed / SunDemo.duration).truncatingRemainder(dividingBy: 1))
            case 1: SwipeDemo(t: reduceMotion ? nil : (elapsed / SwipeDemo.duration).truncatingRemainder(dividingBy: 1))
            default: CatDemo(t: reduceMotion ? nil : (elapsed / CatDemo.duration).truncatingRemainder(dividingBy: 1))
            }
        }
    }
}

// MARK: - спільні деталі мініатюр

/// Картка-мініатюра екрана застосунку 300×400.
struct MiniCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack(alignment: .topLeading) { content }
            .frame(width: 300, height: 400, alignment: .topLeading)
            .background(Theme.day)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(Color(hex: 0xf4d6aa), lineWidth: 2))
            .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color(hex: 0xefc994)).offset(y: 7))
            .shadow(color: Color(hex: 0x5f2507, alpha: 0.3), radius: 22, x: 0, y: 20)
    }
}

/// Мультяшна рука з витягнутим пальцем; (x, y) — куди вказує кінчик пальця.
struct HandView: View {
    var x: CGFloat, y: CGFloat
    var dx: Double = 0, dy: Double = 0, rot: Double = 0, scale: Double = 1, opacity: Double = 1
    var touch: Double = 0, touchScale: Double = 1
    var clipBottom: CGFloat = 0

    private static let tip = CGPoint(x: 23.5, y: 3)
    var body: some View {
        let box = CGRect(x: 0, y: 0, width: 64, height: 84)
        ZStack(alignment: .topLeading) {
            Circle().fill(Theme.accent)
                .frame(width: 26, height: 26)
                .scaleEffect(touchScale)
                .opacity(touch)
                .offset(x: Self.tip.x - 13, y: Self.tip.y - 13)
            ZStack {
                ScaledPath(path: VectorPaths.handCuff, box: box).fill(Theme.accent)
                ScaledPath(path: VectorPaths.handCuff, box: box).stroke(Theme.brown, style: .init(lineWidth: 2.9, lineJoin: .round))
                ScaledPath(path: VectorPaths.handPalm, box: box).fill(Theme.cream)
                ScaledPath(path: VectorPaths.handPalm, box: box).stroke(Theme.brown, style: .init(lineWidth: 2.9, lineCap: .round, lineJoin: .round))
                ScaledPath(path: VectorPaths.handLines, box: box).stroke(Theme.brown, style: .init(lineWidth: 2.4, lineCap: .round))
                ScaledPath(path: VectorPaths.handBlush, box: box).stroke(Color(hex: 0xf9a77a), style: .init(lineWidth: 2, lineCap: .round))
            }
            .frame(width: 58, height: 76)
            .mask(alignment: .top) { Rectangle().frame(height: 76 - clipBottom) }
            .shadow(color: Color(hex: 0x5f2507, alpha: 0.18), radius: 3, x: 0, y: 4)
        }
        .frame(width: 58, height: 76, alignment: .topLeading)
        .scaleEffect(scale, anchor: UnitPoint(x: Self.tip.x / 58, y: Self.tip.y / 76))
        .rotationEffect(.degrees(rot), anchor: UnitPoint(x: Self.tip.x / 58, y: Self.tip.y / 76))
        .offset(x: x - Self.tip.x + dx, y: y - Self.tip.y + dy)
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}

struct MiniHeader: View {
    var titleA: String? = nil
    var titleB: String
    var dateA: String? = nil
    var dateB: String
    var mixB: Double = 1          // 0 — показано A, 1 — показано B
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                if let titleA { Text(titleA).opacity(1 - mixB) }
                Text(titleB).opacity(mixB)
            }
            .font(.nunitoFixed(18, .extraBold))
            .foregroundStyle(Theme.ink)
            ZStack(alignment: .leading) {
                if let dateA { Text(dateA).opacity(1 - mixB) }
                Text(dateB).opacity(mixB)
            }
            .font(.nunitoFixed(11, .bold))
            .foregroundStyle(Theme.inkMuted)
        }
        .lineLimit(1)
        .frame(width: 210, alignment: .leading)
        .offset(x: 20, y: 24)
    }
}

struct MiniSun: View {
    var scale: Double = 1
    var body: some View {
        TimelineView(.animation) { ctx in
            Image("Sun").resizable()
                .rotationEffect(.degrees((ctx.date.timeIntervalSinceReferenceDate / 40).truncatingRemainder(dividingBy: 1) * 360))
        }
        .frame(width: 46, height: 46)
        .scaleEffect(scale)
        .offset(x: 236, y: 16)
    }
}

struct MiniRows: View {
    let items: [String]
    var top: CGFloat = 148
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, s in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.checkBg)
                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.brown, lineWidth: 2))
                        .frame(width: 15, height: 15)
                    Text(s).font(.nunitoFixed(13, .bold)).foregroundStyle(Theme.ink).lineLimit(1)
                }
                .frame(width: 260, height: 30, alignment: .leading)
                .overlay(alignment: .top) { if i > 0 { Rectangle().fill(Theme.divider).frame(height: 1) } }
            }
        }
        .offset(x: 20, y: top)
    }
}

struct MiniScene: View {
    var body: some View {
        Image("CatScene").resizable()
            .frame(width: 300, height: 156)
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.16)],
                                 startPoint: .top, endPoint: .bottom))
    }
}

/// Дати поточного тижня для мініатюр.
struct DemoDates {
    let monday: Date, todayIndex: Int, otherIndex: Int
    init() {
        let now = DayKey.startOfToday
        monday = DayKey.monday(of: now)
        todayIndex = DayKey.weekdayIndex(now)
        otherIndex = todayIndex < 6 ? todayIndex + 1 : todayIndex - 1
    }
    func day(_ i: Int) -> Date { DayKey.addDays(monday, i) }
    var titleA: String { otherIndex == todayIndex + 1 ? "Справи на завтра" : "Справи на день" }
    var dateA: String { DayKey.weekdayLongDate(day(otherIndex)) }
    var dateB: String { DayKey.longDate(day(todayIndex)) }
}

/// Рядок днів тижня. `pill` — позиція виділення (індекс, може бути дробовим під час руху).
struct MiniStrip: View {
    let dates: DemoDates
    var pill: Double
    var pillOpacity: Double = 1
    var whiteMix: (Int) -> Double            // наскільки білий текст у кожного дня (0…1)
    var ring: (opacity: Double, scale: Double) = (0, 1)
    var ringIndex: Int

    private let chipW: CGFloat = (260 - 30) / 7
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 5) { ForEach(0..<7, id: \.self) { _ in RoundedRectangle(cornerRadius: 9).fill(Theme.chip) } }
            RoundedRectangle(cornerRadius: 9).fill(Theme.accent)
                .frame(width: chipW)
                .offset(x: CGFloat(pill) * (chipW + 5))
                .opacity(pillOpacity)
            RoundedRectangle(cornerRadius: 11).stroke(Theme.accent, lineWidth: 3)
                .frame(width: chipW + 2, height: 46)
                .scaleEffect(ring.scale)
                .opacity(ring.opacity)
                .offset(x: CGFloat(ringIndex) * (chipW + 5) - 1, y: -1)
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { i in
                    let w = whiteMix(i)
                    ZStack {
                        chipText(i).foregroundStyle(Theme.ink).opacity(1 - w)
                        chipText(i).foregroundStyle(Theme.onAccent).opacity(w)
                    }
                    .frame(width: chipW, height: 44)
                    .overlay(alignment: .bottom) {
                        if i == dates.todayIndex && w < 0.5 && pillOpacity > 0.5 && Int(pill.rounded()) != i {
                            Circle().fill(Theme.accent).frame(width: 4, height: 4).padding(.bottom, 4)
                        }
                    }
                }
            }
        }
        .frame(width: 260, height: 44)
        .offset(x: 20, y: 88)
    }

    private func chipText(_ i: Int) -> some View {
        VStack(spacing: 1) {
            Text(DayKey.wdShort[i]).font(.nunitoFixed(9, .bold))
            Text("\(DayKey.dayNumber(dates.day(i)))").font(.nunitoFixed(13, .extraBold))
        }
    }
}
