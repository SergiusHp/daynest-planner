import SwiftUI

/// Третя сторінка: фокус-таймер із циферблатом-котиком, швидкими пресетами й музикою.
struct FocusPage: View {
    @Environment(AppStore.self) private var store
    @Environment(FocusModel.self) private var focus
    @Environment(\.rootInsets) private var insets

    var body: some View {
        @Bindable var focus = focus
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("Фокус")
                        .font(.nunito(26, .extraBold, relativeTo: .largeTitle))
                        .foregroundStyle(Theme.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(focus.hint)
                        .font(.nunito(13, .semibold, relativeTo: .footnote))
                        .foregroundStyle(Theme.inkMuted)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .animation(.easeOut(duration: 0.25), value: focus.hint)
                }
                .padding(.horizontal, 56)       // місце для кнопки-ноти праворуч

                DialView()
                    .padding(.horizontal, -10)

                Presets()

                VStack(spacing: 16) {
                    TaskPicker()
                    GeometryReader { g in
                        HStack(spacing: 12) {
                            Button("Скинути") { focus.reset() }
                                .buttonStyle(LedgeButtonStyle(fill: Theme.cream, text: Theme.ink, ledge: Theme.chip, border: Theme.chip))
                                .frame(width: (g.size.width - 12) / 3)
                                .accessibilityIdentifier("resetButton")
                            Button(focus.statusTitle) { focus.playPause() }
                                .buttonStyle(LedgeButtonStyle(fill: Theme.accent, text: Theme.onAccent, ledge: Theme.brown, border: Theme.brown))
                                .frame(width: (g.size.width - 12) * 2 / 3)
                                .accessibilityIdentifier("playButton")
                        }
                    }
                    .frame(height: 58)
                    SessionsLine(count: focus.sessions)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, insets.top + 12)
            .padding(.bottom, insets.bottom + 48)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.calTop)
        .overlay(alignment: .topTrailing) {
            MusicButton()
                .padding(.trailing, 16)
                .padding(.top, insets.top + 6)
        }
    }
}

/// Пресети: 5 / 15 / 25 / 45 / 60 хв.
private struct Presets: View {
    @Environment(FocusModel.self) private var focus

    var body: some View {
        HStack(spacing: 6) {
            ForEach([5, 15, 25, 45, 60], id: \.self) { m in
                let on = focus.minutes == m
                Button {
                    focus.setMinutes(m)
                } label: {
                    Text("\(m) хв")
                        .font(.nunitoFixed(14, .extraBold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(on ? Theme.onAccent : Theme.ink)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(
                            Capsule().fill(on ? Theme.accent : Theme.tog)
                                .overlay(Capsule().strokeBorder(on ? Theme.brown : .clear, lineWidth: 2))
                                .background(Capsule().fill(on ? Theme.brown : .clear).offset(y: 2))
                        )
                }
                .buttonStyle(InvisibleButtonStyle())
                .disabled(focus.running)
                .opacity(focus.running ? 0.45 : 1)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .animation(.easeOut(duration: 0.15), value: focus.minutes)
    }
}

/// «Над чим працюєш?» — сьогоднішні невиконані справи.
private struct TaskPicker: View {
    @Environment(AppStore.self) private var store
    @Environment(FocusModel.self) private var focus

    var body: some View {
        @Bindable var focus = focus
        let list = store.plans.filter { $0.date == store.today && !$0.done }
        let current = list.first { $0.id == focus.taskID }
        VStack(alignment: .leading, spacing: 8) {
            Text("Над чим працюєш?")
                .font(.nunito(13, .extraBold, relativeTo: .footnote))
                .foregroundStyle(Theme.inkSoft)
            Menu {
                Picker("Над чим працюєш?", selection: $focus.taskID) {
                    Text("Просто фокус, без справи").tag("")
                    ForEach(list) { p in
                        Text(p.time.isEmpty ? p.text : "\(p.text) · \(p.time)").tag(p.id)
                    }
                }
            } label: {
                HStack {
                    Text(current.map { $0.time.isEmpty ? $0.text : "\($0.text) · \($0.time)" } ?? "Просто фокус, без справи")
                        .font(.nunito(16, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.brown)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14).fill(Theme.cream)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.chip, lineWidth: 2))
                )
            }
            .disabled(focus.running)
        }
    }
}

private struct SessionsLine: View {
    let count: Int
    var body: some View {
        HStack(spacing: 6) {
            if count > 0 {
                Text("Сьогодні: \(count) \(DayKey.sessionsWord(count)) фокусу")
                ForEach(0..<min(count, 8), id: \.self) { _ in
                    Image("Paw").resizable().frame(width: 18, height: 18)
                }
            } else {
                Text("Сьогодні ще не було сесій фокусу")
            }
        }
        .font(.nunito(13, .extraBold, relativeTo: .footnote))
        .foregroundStyle(Theme.inkMuted)
        .frame(minHeight: 22)
        .accessibilityElement(children: .combine)
    }
}

/// Кнопка-нота: вмикає/вимикає музику, таймер не чіпає. Грає — помаранчева, нота підстрибує, пливуть хвилі.
struct MusicButton: View {
    @Environment(FocusModel.self) private var focus
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var start = Date()

    var body: some View {
        let on = focus.music.isPlaying
        Button {
            Haptics.tap()
            focus.music.toggleByUser()
        } label: {
            TimelineView(.animation(paused: !on || reduceMotion)) { ctx in
                let t = (on && !reduceMotion) ? loopPhase(ctx.date, start: start, duration: 1.0) : 0
                let w = (on && !reduceMotion) ? loopPhase(ctx.date, start: start, duration: 1.6) : 0
                let w2 = (on && !reduceMotion) ? loopPhase(ctx.date.addingTimeInterval(-0.5), start: start, duration: 1.6) : 0
                let box = CGRect(x: 0, y: 0, width: 24, height: 24)
                ZStack {
                    ZStack {
                        ScaledPath(path: VectorPaths.noteStem, box: box)
                            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        Circle().frame(width: 5.2 * 26 / 24, height: 5.2 * 26 / 24).offset(x: (6.5 - 12) * 26 / 24, y: (18 - 12) * 26 / 24)
                        Circle().frame(width: 5.2 * 26 / 24, height: 5.2 * 26 / 24).offset(x: (16.5 - 12) * 26 / 24, y: (16 - 12) * 26 / 24)
                    }
                    .offset(y: track([Key(0, 0, .inOut), Key(0.25, -2.5, .inOut), Key(0.6, 0, .inOut), Key(0.8, -1, .inOut), Key(1, 0)], t))
                    .rotationEffect(.degrees(track([Key(0, 0, .inOut), Key(0.25, -8, .inOut), Key(0.6, 7, .inOut), Key(0.8, -3, .inOut), Key(1, 0)], t)),
                                    anchor: UnitPoint(x: 0.5, y: 0.8))
                    ScaledPath(path: VectorPaths.noteWave1, box: box)
                        .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                        .opacity(on ? track([Key(0, 0), Key(0.25, 0.9), Key(1, 0)], w) : 0)
                        .offset(x: on ? -2 + 7 * w : 0)
                    ScaledPath(path: VectorPaths.noteWave2, box: box)
                        .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                        .opacity(on ? track([Key(0, 0), Key(0.25, 0.9), Key(1, 0)], w2) : 0)
                        .offset(x: on ? -2 + 7 * w2 : 0)
                    ScaledPath(path: VectorPaths.noteSlash, box: box)
                        .stroke(style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                        .opacity(on ? 0 : 1)
                }
                .frame(width: 26, height: 26)
            }
            .foregroundStyle(on ? Theme.onAccent : Theme.inkMuted)
            .frame(width: 48, height: 48)
            .background(
                Circle().fill(on ? Theme.accent : Theme.cream)
                    .overlay(Circle().strokeBorder(on ? Theme.brown : Theme.chip, lineWidth: 2.5))
                    .background(Circle().fill(on ? Theme.brown : Theme.chip).offset(y: 3))
            )
            .animation(.easeOut(duration: 0.25), value: on)
        }
        .buttonStyle(InvisibleButtonStyle())
        .accessibilityLabel(on ? "Музика грає. Вимкнути" : "Музика вимкнена. Увімкнути")
        .accessibilityIdentifier("musicButton")
    }
}
