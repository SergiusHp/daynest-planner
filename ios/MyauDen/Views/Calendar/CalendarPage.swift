import SwiftUI

/// Друга сторінка: тиждень / місяць і невиконані плани під календарем.
struct CalendarPage: View {
    @Environment(AppStore.self) private var store
    @Environment(\.rootInsets) private var insets

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ModeToggle()
                header.padding(.top, 16)
                HStack(spacing: 0) {
                    ForEach(DayKey.wdShort, id: \.self) { d in
                        Text(d).font(.nunitoFixed(14, .bold)).foregroundStyle(Theme.ink).frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
                .accessibilityHidden(true)
                CalendarGrid().padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, insets.top + 12)
            .padding(.bottom, 16)

            ScaledPath(path: VectorPaths.calWave, box: CGRect(x: 0, y: 0, width: 390, height: 26), uniform: false)
                .fill(Theme.card)
                .frame(height: 26)
                .padding(.bottom, -1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Image("CalendarSpot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 210)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                    EventsList()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, insets.bottom + 48)
            }
            .scrollIndicators(.hidden)
            .background(Theme.card)
        }
        .background(Theme.calTop)
        .overlay(alignment: .bottomTrailing) {
            JellyArrow { withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) { store.page = 2 } }
                .padding(.trailing, 12)
                .padding(.bottom, max(insets.bottom - 12, 6))
                .accessibilityLabel("Відкрити фокус")
        }
    }

    private var title: String {
        if store.calMode == .month {
            return "\(DayKey.monthNom[DayKey.month(store.cursor)]) \(DayKey.year(store.cursor))"
        }
        let start = DayKey.monday(of: DayKey.dateOrToday(store.selected)), end = DayKey.addDays(start, 6)
        if DayKey.month(start) == DayKey.month(end) {
            return "\(DayKey.dayNumber(start))–\(DayKey.dayNumber(end)) \(DayKey.monthGen[DayKey.month(end)])"
        }
        return "\(DayKey.dayNumber(start)) \(DayKey.monthShort[DayKey.month(start)]) – \(DayKey.dayNumber(end)) \(DayKey.monthShort[DayKey.month(end)])"
    }

    private var header: some View {
        HStack {
            navButton("chevron.left", store.calMode == .month ? "Попередній місяць" : "Попередній тиждень") { store.shiftCalendar(-1) }
            Spacer()
            Text(title)
                .font(.nunito(18, .extraBold, relativeTo: .title3))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("calTitle")
            Spacer()
            navButton("chevron.right", store.calMode == .month ? "Наступний місяць" : "Наступний тиждень") { store.shiftCalendar(1) }
        }
    }

    private func navButton(_ icon: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tick()
            withAnimation(.easeOut(duration: 0.2)) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(InvisibleButtonStyle())
        .accessibilityLabel(label)
    }
}

/// Перемикач «Тиждень / Місяць».
struct ModeToggle: View {
    @Environment(AppStore.self) private var store
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            item(.week, "Тиждень")
            item(.month, "Місяць")
        }
        .padding(5)
        .background(Capsule().fill(Theme.tog))
    }

    private func item(_ mode: CalendarMode, _ title: String) -> some View {
        let on = store.calMode == mode
        return Button {
            Haptics.tick()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                store.calMode = mode
                store.cursor = DayKey.firstOfMonth(DayKey.dateOrToday(store.selected))
            }
        } label: {
            Text(title)
                .font(.nunitoFixed(16, .extraBold))
                .foregroundStyle(on ? Theme.onAccent : Theme.ink)
                .padding(.horizontal, 22)
                .frame(minHeight: 38)
                .background {
                    if on { Capsule().fill(Theme.accent).matchedGeometryEffect(id: "seg", in: ns) }
                }
        }
        .buttonStyle(InvisibleButtonStyle())
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// Сітка днів: місяць (до 6 рядків) або тиждень (7 днів із кількістю планів).
struct CalendarGrid: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let week = store.calMode == .week
        let sel = DayKey.dateOrToday(store.selected)
        let start: Date, count: Int
        if week {
            start = DayKey.monday(of: sel); count = 7
        } else {
            start = DayKey.monday(of: store.cursor)
            let last = DayKey.addDays(DayKey.addMonths(store.cursor, 1), -1)
            let end = DayKey.addDays(DayKey.monday(of: last), 6)
            count = (DayKey.calendar.dateComponents([.day], from: start, to: end).day ?? 34) + 1
        }
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return LazyVGrid(columns: cols, spacing: 0) {
            ForEach(0..<count, id: \.self) { i in
                let d = DayKey.addDays(start, i), k = DayKey.key(d)
                let n = store.count(on: k)
                let out = !week && DayKey.month(d) != DayKey.month(store.cursor)
                DayCell(day: DayKey.dayNumber(d), selected: k == store.selected, today: k == store.today,
                        outside: out, count: n, week: week)
                    .onTapGesture {
                        Haptics.tick()
                        withAnimation(.easeOut(duration: 0.2)) {
                            if out { store.cursor = DayKey.firstOfMonth(d) }
                            store.select(k)
                        }
                    }
                    .accessibilityElement()
                    .accessibilityLabel("\(DayKey.dayNumber(d)) \(DayKey.monthGen[DayKey.month(d)])" + (n > 0 ? ", планів: \(n)" : ""))
                    .accessibilityAddTraits(k == store.selected ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

struct DayCell: View {
    let day: Int, selected: Bool, today: Bool, outside: Bool, count: Int, week: Bool

    var body: some View {
        let size: CGFloat = week ? 42 : 34
        ZStack(alignment: week ? .top : .center) {
            Text("\(day)")
                .font(.nunitoFixed(week ? 17 : 16, (selected || today) ? .extraBold : .semibold))
                .monospacedDigit()
                .foregroundStyle(today ? Theme.onAccent : (outside ? Theme.inkFaint : Theme.ink))
                .frame(width: size, height: size)
                .background(Circle().fill(today ? Theme.accent : .clear))
                .overlay(Circle().strokeBorder(selected && !today ? Theme.accent : .clear, lineWidth: 2))
                .padding(.top, week ? 4 : 0)
            if week && count > 0 {
                Text("\(count) \(DayKey.plansWord(count))")
                    .font(.nunitoFixed(11, .bold))
                    .foregroundStyle(Theme.inkMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            if !week && count > 0 {
                Circle().fill(Theme.dotRing).frame(width: 5, height: 5).frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: week ? 70 : 42)
        .contentShape(Rectangle())
    }
}

/// Список під календарем — лише невиконані плани (виконані зберігаються, але тут приховані).
struct EventsList: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let sel = DayKey.dateOrToday(store.selected)
        VStack(alignment: .leading, spacing: 0) {
            if store.calMode == .month {
                Text("Плани на \(DayKey.dayNumber(sel)) \(DayKey.monthGen[DayKey.month(sel)])")
                    .font(.nunito(19, .extraBold, relativeTo: .title3))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 12)
                let all = store.plans(on: store.selected), list = all.filter { !$0.done }
                if list.isEmpty {
                    empty(all.isEmpty ? "На цей день планів немає. Поверніться до дня й натисніть на котика." : "Усі плани на цей день виконано.")
                } else {
                    rows(list).padding(.top, 12)
                }
            } else {
                Text("Плани на тиждень")
                    .font(.nunito(19, .extraBold, relativeTo: .title3))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 12)
                let mon = DayKey.monday(of: sel)
                let days = (0..<7).map { DayKey.addDays(mon, $0) }
                let groups = days.enumerated().compactMap { i, d -> (Int, Date, [Plan])? in
                    let l = store.plans(on: DayKey.key(d)).filter { !$0.done }
                    return l.isEmpty ? nil : (i, d, l)
                }
                if groups.isEmpty {
                    let anyThisWeek = days.contains { store.count(on: DayKey.key($0)) > 0 }
                    empty(anyThisWeek ? "Усі плани цього тижня виконано." : "Цього тижня планів ще немає. Поверніться до дня й натисніть на котика.")
                } else {
                    ForEach(groups, id: \.0) { i, d, l in
                        Text("\(DayKey.wdFull[i]), \(DayKey.dayNumber(d)) \(DayKey.monthGen[DayKey.month(d)])")
                            .font(.nunito(12, .extraBold, relativeTo: .caption))
                            .foregroundStyle(Theme.inkMuted)
                            .padding(.top, 16)
                        rows(l).padding(.top, 8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.25), value: store.plans)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("eventsList")
    }

    private func rows(_ list: [Plan]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(list) { p in
                HStack(spacing: 12) {
                    Circle().fill(Theme.accent)
                        .overlay(Circle().strokeBorder(Theme.dotRing, lineWidth: 2))
                        .frame(width: 18, height: 18)
                    Text(p.text)
                        .font(.nunito(16, .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !p.time.isEmpty {
                        Text(p.time).font(.nunito(14, .semibold)).monospacedDigit().foregroundStyle(Theme.inkMuted)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { store.sheet = .edit(p) }
                .accessibilityElement(children: .combine)
                .accessibilityHint("Відкрити для змін")
            }
        }
    }

    private func empty(_ text: String) -> some View {
        Text(text)
            .font(.nunito(14, .semibold, relativeTo: .callout))
            .foregroundStyle(Theme.inkMuted)
            .padding(.top, 12)
            .accessibilityIdentifier("calEmpty")
    }
}
