import SwiftUI

/// Нижня частина сторінки дня: котик на пагорбах. Торкання котика відкриває «Новий план».
struct CatZone: View {
    @Environment(AppStore.self) private var store
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var tapAt: Date?

    var body: some View {
        Image("CatScene")
            .resizable()
            .aspectRatio(426.0 / 222.0, contentMode: .fit)
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.16)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay { GeometryReader { g in overlays(in: g.size) } }
            .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func overlays(in size: CGSize) -> some View {
        let w = size.width, h = size.height
        // прозора кнопка точно над котиком (без рамок, фону й підсвітки)
        Button {
            Haptics.tap()
            tapAt = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { store.sheet = .new(date: store.selected) }
        } label: {
            Color.clear
        }
        .buttonStyle(InvisibleButtonStyle())
        .frame(width: w * 0.54, height: h * 0.92)
        .position(x: w * (0.33 + 0.27), y: h * (0.02 + 0.46))
        .accessibilityLabel("Додати план")
        .accessibilityHint("Котик відкриє вікно нового плану")
        .accessibilityIdentifier("catButton")

        // лапка злітає над котиком у відповідь на дотик
        if let tapAt, !reduceMotion {
            TimelineView(.animation) { ctx in
                let t = min(1, ctx.date.timeIntervalSince(tapAt) / 0.5)
                Image("Paw")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .scaleEffect(0.6 + 0.4 * t)
                    .opacity(t < 0.4 ? t / 0.4 : 1 - (t - 0.4) / 0.6)
                    .offset(y: 8 - 34 * t)
                    .position(x: w * 0.58 + 15, y: h * 0.04 + 15)
            }
            .allowsHitTesting(false)
            .task(id: tapAt) { try? await Task.sleep(for: .milliseconds(600)); self.tapAt = nil }
        }

        // напівпрозора стрілка «далі», що м'яко «хвилюється»
        JellyArrow { withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) { store.page = 1 } }
            .position(x: w - 12 - 22, y: h - 4 - 22)
    }
}

/// Стрілка-іконка з «желейною» анімацією (як @keyframes jelly у веб-версії).
struct JellyArrow: View {
    var action: () -> Void
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var start = Date()

    var body: some View {
        Button(action: action) {
            TimelineView(.animation(paused: reduceMotion)) { ctx in
                let t = reduceMotion ? 0 : loopPhase(ctx.date, start: start, duration: 2.8)
                // (зсув x, зсув y, масштаб x, масштаб y, поворот)
                let ks: (Double, Double, Double, Double, Double) = (
                    track([Key(0, 0, .inOut), Key(0.2, 3, .inOut), Key(0.45, 6, .inOut), Key(0.7, 2, .inOut), Key(1, 0)], t),
                    track([Key(0, 0, .inOut), Key(0.2, -2, .inOut), Key(0.45, 0, .inOut), Key(0.7, 2, .inOut), Key(1, 0)], t),
                    track([Key(0, 1, .inOut), Key(0.2, 1.1, .inOut), Key(0.45, 0.93, .inOut), Key(0.7, 1.05, .inOut), Key(1, 1)], t),
                    track([Key(0, 1, .inOut), Key(0.2, 0.9, .inOut), Key(0.45, 1.08, .inOut), Key(0.7, 0.95, .inOut), Key(1, 1)], t),
                    track([Key(0, 0, .inOut), Key(0.2, -5, .inOut), Key(0.45, 3, .inOut), Key(0.7, -2, .inOut), Key(1, 0)], t))
                Image(systemName: "chevron.right")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Theme.brown)
                    .scaleEffect(x: ks.2, y: ks.3, anchor: UnitPoint(x: 0.35, y: 0.5))
                    .rotationEffect(.degrees(ks.4), anchor: UnitPoint(x: 0.35, y: 0.5))
                    .offset(x: ks.0, y: ks.1)
            }
            .frame(width: 44, height: 44)
            .opacity(0.6)
        }
        .buttonStyle(InvisibleButtonStyle())
        .accessibilityLabel("Відкрити тиждень і місяць")
    }
}
