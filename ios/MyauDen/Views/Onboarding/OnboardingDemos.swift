import SwiftUI

// Хореографія кожного демо: жест → відповідь інтерфейсу → пауза → м'яке повернення до початку.
// Ключові кадри перенесено з CSS веб-версії; `t` — фаза циклу 0…1, nil — статичний кадр (зменшений рух).

private let tapIn = Ease.cubic(0.2, 0.7, 0.3, 1)

// MARK: - 1. Сонечко повертає на сьогодні
struct SunDemo: View {
    static let duration = 4.8
    let t: Double?
    private let dates = DemoDates()

    var body: some View {
        let p = t ?? 0.3
        let still = t == nil
        let from = Double(dates.otherIndex), to = Double(dates.todayIndex), dir = (to - from).sign == .minus ? -1.0 : 1.0
        // виділення ковзає з «іншого» дня на сьогодні, з легким перельотом
        let pill = still ? to : track([Key(0, from, .cubic(0.3, 0, 0.15, 1)), Key(0.25, from, .cubic(0.3, 0, 0.15, 1)),
                                        Key(0.38, to + dir * 0.08, .easeOut), Key(0.42, to), Key(0.9, to, .step), Key(0.91, from)], p)
        let pillOp = still ? 1 : track([Key(0, 1), Key(0.85, 1), Key(0.9, 0), Key(0.91, 0), Key(0.97, 1)], p)
        let fromW = still ? 0 : track([Key(0, 1), Key(0.27, 1), Key(0.33, 0), Key(0.94, 0), Key(0.98, 1)], p)
        let toW = still ? 1 : track([Key(0, 0), Key(0.33, 0), Key(0.38, 1), Key(0.86, 1), Key(0.9, 0)], p)
        let ringOp = still ? 1 : track([Key(0, 0), Key(0.4, 0), Key(0.45, 1), Key(0.64, 0)], p)
        let ringS = still ? 1 : track([Key(0, 0.92), Key(0.4, 0.92), Key(0.45, 1), Key(0.64, 1.28)], p)
        let mixB = still ? 1 : track([Key(0, 0), Key(0.29, 0), Key(0.36, 1), Key(0.85, 1), Key(0.91, 0)], p)
        let rippleOp = still ? 0.6 : track([Key(0, 0), Key(0.21, 0), Key(0.23, 0.75), Key(0.46, 0)], p)
        let rippleS = still ? 1 : track([Key(0, 0.3), Key(0.21, 0.3), Key(0.23, 0.42), Key(0.46, 1.6)], p)
        let sunS = still ? 1 : track([Key(0, 1), Key(0.21, 1), Key(0.24, 0.92), Key(0.31, 1.05), Key(0.38, 1)], p)

        ZStack(alignment: .topLeading) {
            MiniCard {
                MiniHeader(titleA: dates.titleA, titleB: "Сьогоднішні справи", dateA: dates.dateA, dateB: dates.dateB, mixB: mixB)
                MiniSun(scale: sunS)
                Circle().stroke(Theme.accent, lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .scaleEffect(rippleS).opacity(rippleOp)
                    .offset(x: 229, y: 9)
                MiniStrip(dates: dates, pill: pill, pillOpacity: pillOp,
                          whiteMix: { i in i == dates.otherIndex ? fromW : (i == dates.todayIndex ? toW : 0) },
                          ring: (ringOp, ringS), ringIndex: dates.todayIndex)
                MiniRows(items: ["Купити продукти", "Подзвонити бабусі"]).opacity(1 - mixB)
                MiniRows(items: ["Прочитати 10 сторінок", "Прогулянка з котиком", "Полити квіти"]).opacity(mixB)
                MiniScene().offset(y: 244)
            }
            hand(p, still)
        }
        .frame(width: 300, height: 400, alignment: .topLeading)
    }

    private func hand(_ p: Double, _ still: Bool) -> some View {
        if still { return HandView(x: 259, y: 40) }
        return HandView(
            x: 259, y: 40,
            dx: track([Key(0, 44, tapIn), Key(0.13, 5, .inOut), Key(0.18, 0), Key(0.22, 0, .easeOut), Key(0.29, 0), Key(0.5, 8, .easeIn), Key(0.62, 40)], p),
            dy: track([Key(0, 70, tapIn), Key(0.13, 9, .inOut), Key(0.18, -5), Key(0.22, 1, .easeOut), Key(0.29, 0), Key(0.5, 16, .easeIn), Key(0.62, 64)], p),
            rot: track([Key(0, 10, tapIn), Key(0.13, 2, .inOut), Key(0.18, 0), Key(0.22, 0, .easeOut), Key(0.29, 0), Key(0.5, 3, .easeIn), Key(0.62, 10)], p),
            scale: track([Key(0, 1, tapIn), Key(0.13, 1, .inOut), Key(0.18, 1.04), Key(0.22, 0.9, .easeOut), Key(0.29, 1), Key(0.5, 1, .easeIn), Key(0.62, 1)], p),
            opacity: track([Key(0, 0, tapIn), Key(0.13, 1), Key(0.5, 1, .easeIn), Key(0.62, 0)], p))
    }
}

// MARK: - 2. Свайп уліво — наступна сторінка
struct SwipeDemo: View {
    static let duration = 4.6
    let t: Double?
    private let dates = DemoDates()

    var body: some View {
        let p = t ?? 0
        let still = t == nil
        let trackX = still ? -112 : track([Key(0, 0), Key(0.21, 0, .cubic(0.45, 0, 0.35, 1)), Key(0.52, -170, .cubic(0.2, 0.75, 0.25, 1)),
                                            Key(0.61, -306, .inOut), Key(0.67, -300), Key(0.89, -300, .step), Key(0.9, 0)], p)
        let screenOp = still ? 1 : track([Key(0, 1), Key(0.84, 1), Key(0.89, 0), Key(0.91, 0), Key(0.98, 1)], p)
        let dotX = still ? 0 : track([Key(0, 0), Key(0.52, 0, .cubic(0.3, 0, 0.2, 1)), Key(0.6, 11), Key(0.89, 11, .step), Key(0.9, 0)], p)
        let dotOp = still ? 1 : track([Key(0, 1), Key(0.89, 1), Key(0.9, 0), Key(0.96, 1)], p)
        let trailS = still ? 0.66 : track([Key(0, 0), Key(0.21, 0, .cubic(0.45, 0, 0.35, 1)), Key(0.52, 1), Key(1, 1)], p)
        let trailOp = still ? 1 : track([Key(0, 0), Key(0.21, 0), Key(0.24, 1), Key(0.52, 1), Key(0.68, 0)], p)

        ZStack(alignment: .topLeading) {
            MiniCard {
                HStack(spacing: 0) {
                    dayPage.frame(width: 300, height: 400)
                    calPage.frame(width: 300, height: 400)
                }
                .frame(width: 600, height: 400, alignment: .topLeading)
                .offset(x: trackX)
                .opacity(screenOp)
                .frame(width: 300, height: 400, alignment: .topLeading)
                .clipped()
                // крапки сторінок
                ZStack(alignment: .leading) {
                    HStack(spacing: 5) { ForEach(0..<3, id: \.self) { _ in Circle().fill(Theme.inkFaint).frame(width: 6, height: 6) } }
                    Circle().fill(Theme.brown).frame(width: 6, height: 6).offset(x: dotX).opacity(dotOp)
                }
                .frame(width: 28, height: 6)
                .offset(x: 136, y: 382)
            }
            // пунктирний слід зі стрілкою вліво
            ZStack(alignment: .leading) {
                Path { p in p.move(to: .zero); p.addLine(to: CGPoint(x: 174, y: 0)) }
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 5]))
                Path { p in p.move(to: CGPoint(x: 8, y: -7)); p.addLine(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 8, y: 7)) }
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 174, height: 14)
            .scaleEffect(x: trailS, y: 1, anchor: .trailing)
            .opacity(trailOp)
            .offset(x: 62, y: 193)
            hand(p, still)
        }
        .frame(width: 300, height: 400, alignment: .topLeading)
    }

    private var dayPage: some View {
        ZStack(alignment: .topLeading) {
            MiniHeader(titleB: "Сьогоднішні справи", dateB: dates.dateB)
            MiniSun()
            MiniStrip(dates: dates, pill: Double(dates.todayIndex), whiteMix: { $0 == dates.todayIndex ? 1 : 0 }, ringIndex: dates.todayIndex)
            MiniRows(items: ["Прочитати 10 сторінок", "Прогулянка з котиком", "Полити квіти"])
            MiniScene().offset(y: 244)
        }
        .frame(width: 300, height: 400, alignment: .topLeading)
        .background(Theme.day)
    }

    private var calPage: some View {
        let now = DayKey.startOfToday
        let first = DayKey.firstOfMonth(now), start = DayKey.monday(of: first)
        let last = DayKey.addDays(DayKey.addMonths(first, 1), -1), end = DayKey.addDays(DayKey.monday(of: last), 6)
        let count = (DayKey.calendar.dateComponents([.day], from: start, to: end).day ?? 34) + 1
        return ZStack(alignment: .topLeading) {
            HStack(spacing: 3) {
                Text("Тиждень").foregroundStyle(Theme.inkSoft).padding(.horizontal, 11).padding(.vertical, 4)
                Text("Місяць").foregroundStyle(Theme.onAccent).padding(.horizontal, 11).padding(.vertical, 4).background(Capsule().fill(Theme.accent))
            }
            .font(.nunitoFixed(10.5, .extraBold))
            .padding(3)
            .background(Capsule().fill(Theme.tog))
            .frame(width: 300)
            .offset(y: 22)
            Text(verbatim: "\(DayKey.monthNom[DayKey.month(now)]) \(DayKey.year(now))")
                .font(.nunitoFixed(16, .extraBold)).foregroundStyle(Theme.ink)
                .offset(x: 20, y: 56)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(260 / 7), spacing: 0), count: 7), spacing: 2) {
                ForEach(0..<count, id: \.self) { i in
                    let d = DayKey.addDays(start, i)
                    let isToday = DayKey.key(d) == DayKey.key(now), out = DayKey.month(d) != DayKey.month(now)
                    Text("\(DayKey.dayNumber(d))")
                        .font(.nunitoFixed(10, isToday ? .extraBold : .bold))
                        .foregroundStyle(isToday ? Theme.onAccent : (out ? Theme.inkFaint : Theme.ink))
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(isToday ? Theme.accent : .clear))
                        .frame(height: 20)
                }
            }
            .frame(width: 260)
            .offset(x: 20, y: 88)
            Text("Плани на \(DayKey.dayNumber(now)) \(DayKey.monthGen[DayKey.month(now)])")
                .font(.nunitoFixed(12, .extraBold)).foregroundStyle(Theme.ink)
                .offset(x: 20, y: 232)
            MiniRows(items: ["Прочитати 10 сторінок", "Полити квіти"], top: 254)
        }
        .frame(width: 300, height: 400, alignment: .topLeading)
        .background(Theme.calTop)
    }

    private func hand(_ p: Double, _ still: Bool) -> some View {
        if still { return HandView(x: 236, y: 200, dx: -112, dy: 1, rot: -6, scale: 0.92, touch: 0.28) }
        let curve = Ease.cubic(0.45, 0, 0.35, 1)
        return HandView(
            x: 236, y: 200,
            dx: track([Key(0, 26, tapIn), Key(0.11, 0, .inOut), Key(0.16, 3), Key(0.21, 0, curve), Key(0.52, -170, .easeOut), Key(0.59, -178, .easeIn), Key(0.7, -196)], p),
            dy: track([Key(0, 44, tapIn), Key(0.11, 0, .inOut), Key(0.16, -4), Key(0.21, 1, curve), Key(0.52, 1, .easeOut), Key(0.59, -6, .easeIn), Key(0.7, -34)], p),
            rot: track([Key(0, 8, tapIn), Key(0.11, 0, .inOut), Key(0.16, 0), Key(0.21, 0, curve), Key(0.52, -6, .easeOut), Key(0.59, -6, .easeIn), Key(0.7, -10)], p),
            scale: track([Key(0, 1, tapIn), Key(0.11, 1, .inOut), Key(0.16, 1.04), Key(0.21, 0.92, curve), Key(0.52, 0.92, .easeOut), Key(0.59, 1, .easeIn), Key(0.7, 1)], p),
            opacity: track([Key(0, 0, tapIn), Key(0.11, 1), Key(0.59, 1, .easeIn), Key(0.7, 0)], p),
            touch: track([Key(0, 0), Key(0.2, 0), Key(0.23, 0.28), Key(0.5, 0.28), Key(0.57, 0)], p),
            touchScale: track([Key(0, 0.4), Key(0.2, 0.4), Key(0.23, 1), Key(0.5, 1), Key(0.57, 1.5)], p))
    }
}

// MARK: - 3. Котик відкриває «Новий план»
struct CatDemo: View {
    static let duration = 5.6
    let t: Double?
    private let dates = DemoDates()

    var body: some View {
        let p = t ?? 0
        let still = t == nil
        let catSX = still ? 1 : track([Key(0, 1), Key(0.19, 1), Key(0.22, 1.015), Key(0.28, 0.995), Key(0.33, 1)], p)
        let catSY = still ? 1 : track([Key(0, 1), Key(0.19, 1), Key(0.22, 0.975), Key(0.28, 1.02), Key(0.33, 1)], p)
        let catY = still ? 0 : track([Key(0, 0), Key(0.22, 0), Key(0.28, -2), Key(0.33, 0)], p)
        let pawOp = still ? 1 : track([Key(0, 0), Key(0.21, 0), Key(0.27, 1), Key(0.4, 0)], p)
        let pawY = still ? -6 : track([Key(0, 6), Key(0.21, 6), Key(0.27, -6), Key(0.4, -26)], p)
        let pawS = still ? 1 : track([Key(0, 0.6), Key(0.21, 0.6), Key(0.27, 1)], p)
        let scrim = still ? 0.55 : track([Key(0, 0), Key(0.29, 0), Key(0.38, 1), Key(0.87, 1), Key(0.95, 0)], p)
        let sheetY = still ? 0.52 : track([Key(0, 1.04), Key(0.3, 1.04, .cubic(0.2, 0.8, 0.25, 1)), Key(0.41, -0.02, .inOut),
                                           Key(0.45, 0), Key(0.87, 0, .cubic(0.5, 0, 0.75, 0)), Key(0.95, 1.04)], p)
        let typed = still ? 1 : track([Key(0, 0), Key(0.48, 0, .steps(21)), Key(0.7, 1), Key(0.96, 1, .step), Key(0.97, 0)], p)
        let caretOn = still ? true : (p * Self.duration).truncatingRemainder(dividingBy: 1) < 0.55

        ZStack(alignment: .topLeading) {
            MiniCard {
                MiniHeader(titleB: "Сьогоднішні справи", dateB: dates.dateB)
                MiniSun()
                MiniStrip(dates: dates, pill: Double(dates.todayIndex), whiteMix: { $0 == dates.todayIndex ? 1 : 0 }, ringIndex: dates.todayIndex)
                MiniRows(items: ["Прогулянка з котиком"])
                MiniScene()
                    .scaleEffect(x: catSX, y: catSY, anchor: UnitPoint(x: 0.6, y: 1))
                    .offset(y: 244 + catY)
                Image("Paw").resizable()
                    .frame(width: 24, height: 24)
                    .scaleEffect(pawS)
                    .opacity(pawOp)
                    .offset(x: 176, y: 250 + pawY)
                Theme.scrim.opacity(scrim).frame(width: 300, height: 400)
                miniSheet(typed: typed, caretOn: caretOn)
                    .offset(y: 400 - 198 + 198 * sheetY)
            }
            hand(p, still)
        }
        .frame(width: 300, height: 400, alignment: .topLeading)
    }

    private func miniSheet(typed: Double, caretOn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Theme.inkFaint).frame(width: 30, height: 4).frame(maxWidth: .infinity).padding(.bottom, 4)
            HStack(spacing: 8) {
                Image("CatWink").resizable().frame(width: 58, height: 41).padding(.leading, -4)
                Text("Новий план").font(.nunitoFixed(16, .extraBold)).foregroundStyle(Theme.ink)
            }
            Text("Що плануєш зробити?").font(.nunitoFixed(10.5, .extraBold)).foregroundStyle(Theme.inkSoft).padding(.top, 6)
            HStack(spacing: 0) {
                Text("Прочитати 10 сторінок")
                    .font(.nunitoFixed(13, .bold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize()
                    .mask(alignment: .leading) { GeometryReader { g in Rectangle().frame(width: g.size.width * typed) } }
                    .overlay(alignment: .leading) {
                        GeometryReader { g in
                            RoundedRectangle(cornerRadius: 1).fill(Theme.accent)
                                .frame(width: 2, height: 16)
                                .offset(x: g.size.width * typed + 1, y: (g.size.height - 16) / 2)
                                .opacity(caretOn ? 1 : 0)
                        }
                    }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .frame(height: 42)
            .background(RoundedRectangle(cornerRadius: 11).fill(Theme.cream)
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(Theme.accent, lineWidth: 2)))
            .padding(.top, 5)
            HStack(spacing: 8) {
                Text("Скасувати").foregroundStyle(Theme.inkSoft).frame(width: 85, height: 34)
                Text("Додати").foregroundStyle(Theme.onAccent).frame(width: 171, height: 34)
                    .background(Capsule().fill(Theme.accent).background(Capsule().fill(Theme.accentDark).offset(y: 2)))
            }
            .font(.nunitoFixed(12, .extraBold))
            .padding(.top, 12)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .frame(width: 300, height: 198, alignment: .topLeading)
        .background(UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22).fill(Theme.day)
            .shadow(color: Color(hex: 0x5f2507, alpha: 0.14), radius: 9, x: 0, y: -6))
    }

    private func hand(_ p: Double, _ still: Bool) -> some View {
        if still { return HandView(x: 184, y: 268, clipBottom: 36) }
        return HandView(
            x: 184, y: 326,
            dx: track([Key(0, 46, tapIn), Key(0.11, 5, .inOut), Key(0.15, 0), Key(0.19, 0, .easeOut), Key(0.25, 0, .easeIn), Key(0.34, 42)], p),
            dy: track([Key(0, 60, tapIn), Key(0.11, 8, .inOut), Key(0.15, -5), Key(0.19, 1, .easeOut), Key(0.25, 0, .easeIn), Key(0.34, 58)], p),
            rot: track([Key(0, 10, tapIn), Key(0.11, 2, .inOut), Key(0.15, 0), Key(0.19, 0, .easeOut), Key(0.25, 0, .easeIn), Key(0.34, 10)], p),
            scale: track([Key(0, 1, tapIn), Key(0.11, 1, .inOut), Key(0.15, 1.04), Key(0.19, 0.9, .easeOut), Key(0.25, 1, .easeIn), Key(0.34, 1)], p),
            opacity: track([Key(0, 0, tapIn), Key(0.11, 1), Key(0.25, 1, .easeIn), Key(0.34, 0)], p))
    }
}
