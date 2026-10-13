import SwiftUI

/// Сторінка «Сьогоднішні справи»: шапка й котик нерухомі, прокручується лише список справ.
struct DayPage: View {
    @Environment(AppStore.self) private var store
    @Environment(\.rootInsets) private var insets

    private var title: String {
        if store.selected == store.today { return "Сьогоднішні справи" }
        if store.selected == DayKey.key(DayKey.addDays(DayKey.dateOrToday(store.today), 1)) { return "Справи на завтра" }
        return "Справи на день"
    }
    private var subtitle: String {
        let d = DayKey.dateOrToday(store.selected)
        return store.selected == store.today ? DayKey.longDate(d) : DayKey.weekdayLongDate(d)
    }

    var body: some View {
        let list = store.plans(on: store.selected)
        let done = list.filter(\.done).count
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.nunito(26, .extraBold, relativeTo: .largeTitle))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("dayTitle")
                        Text(subtitle)
                            .font(.nunito(14, .semibold, relativeTo: .subheadline))
                            .foregroundStyle(Theme.inkMuted)
                    }
                    Spacer(minLength: 0)
                    SunButton { withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) { store.goToday() } }
                        .padding(.top, -8)
                        .padding(.trailing, -6)
                }
                WeekStrip()
                    .padding(.top, 24)
                HStack(alignment: .center, spacing: 12) {
                    Text("Список справ")
                        .font(.nunito(18, .extraBold, relativeTo: .title3))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                    if !list.isEmpty {
                        Text("\(done) з \(list.count) виконано")
                            .font(.nunito(13, .bold, relativeTo: .footnote))
                            .foregroundStyle(Theme.inkMuted)
                            .lineLimit(1)
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 12)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.chip).frame(height: 1.5) }
            }
            .padding(.horizontal, 24)
            .padding(.top, insets.top + 14)

            if list.isEmpty {
                Text("На цей день ще немає планів. Натисни на котика, щоб додати перший.")
                    .font(.nunito(14, .semibold, relativeTo: .callout))
                    .foregroundStyle(Theme.inkMuted)
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .accessibilityIdentifier("emptyDay")
            } else {
                TaskList(plans: list)
            }

            CatZone()
        }
        .background(Theme.day)
    }
}

/// Список справ із нативним свайпом зліва направо: закреслити / повернути.
struct TaskList: View {
    @Environment(AppStore.self) private var store
    let plans: [Plan]

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(plans) { plan in
                    TaskRow(plan: plan)
                        .id(plan.id)
                        .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Theme.divider)
                        .listRowSeparator(plan.id == plans.first?.id ? .hidden : .visible, edges: .top)
                        .listRowSeparator(plan.id == plans.last?.id ? .hidden : .visible, edges: .bottom)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                store.toggle(plan.id)
                            } label: {
                                Label(plan.done ? "Повернути" : "Виконано",
                                      systemImage: plan.done ? "arrow.uturn.backward" : "checkmark")
                            }
                            .tint(plan.done ? Theme.inkMuted : Theme.accent)
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 44)
            .contentMargins(.bottom, 20, for: .scrollContent)
            // м'яке згасання біля котика
            .mask(VStack(spacing: 0) {
                Color.black
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: 20)
            })
            .accessibilityIdentifier("taskList")
            .onChange(of: store.justAdded) { _, id in
                guard let id else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeOut(duration: 0.4)) { proxy.scrollTo(id, anchor: .bottom) }
                    store.justAdded = nil
                }
            }
        }
    }
}

/// Сонечко: невидима кнопка «повернутися на сьогодні»; вигляд і обертання — як у веб-версії.
struct SunButton: View {
    var action: () -> Void
    @Environment(\.reduceMotion) private var reduceMotion

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            TimelineView(.animation(paused: reduceMotion)) { ctx in
                let angle = reduceMotion ? 0 : (ctx.date.timeIntervalSinceReferenceDate / 40).truncatingRemainder(dividingBy: 1) * 360
                Image("Sun")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(angle))
            }
            .padding(8)                     // ширша зона дотику (66×66), картинка лишається 50×50
        }
        .buttonStyle(InvisibleButtonStyle())
        .padding(-8)
        .accessibilityLabel("Повернутися на сьогодні")
        .accessibilityIdentifier("sunButton")
    }
}

/// Тиждень із 7 «чипів»; торкання — вибір дня.
struct WeekStrip: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let mon = DayKey.monday(of: DayKey.dateOrToday(store.selected))
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let d = DayKey.addDays(mon, i), k = DayKey.key(d)
                let sel = k == store.selected, isToday = k == store.today
                Button {
                    Haptics.tick()
                    withAnimation(.easeOut(duration: 0.2)) { store.select(k) }
                } label: {
                    VStack(spacing: 3) {
                        Text(DayKey.wdShort[i]).font(.nunitoFixed(13, .bold))
                        Text("\(DayKey.dayNumber(d))").font(.nunitoFixed(17, .extraBold))
                    }
                    .foregroundStyle(sel ? Theme.onAccent : Theme.ink)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(RoundedRectangle(cornerRadius: 10).fill(sel ? Theme.accent : Theme.chip))
                    .overlay(alignment: .bottom) {
                        if isToday && !sel { Circle().fill(Theme.accent).frame(width: 5, height: 5).padding(.bottom, 5) }
                    }
                }
                .buttonStyle(InvisibleButtonStyle())
                .accessibilityLabel("\(DayKey.wdFull[i]), \(DayKey.dayNumber(d)) \(DayKey.monthGen[DayKey.month(d)])")
                .accessibilityAddTraits(sel ? .isSelected : [])
            }
        }
    }
}
