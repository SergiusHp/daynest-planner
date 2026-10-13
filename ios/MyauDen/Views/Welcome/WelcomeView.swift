import SwiftUI

/// Привітальний екран: логотип, ілюстрація «Ідеї → План → Виконання», кнопка «Розпочати». Показується один раз.
struct WelcomeView: View {
    var onStart: () -> Void
    @Environment(\.rootInsets) private var insets

    var body: some View {
        VStack(spacing: 0) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 360)
                .frame(maxHeight: 150)
                .shadow(color: Color(hex: 0x783c0a, alpha: 0.12), radius: 0, x: 0, y: 3)
                .padding(.horizontal, 24)
                .padding(.top, insets.top + 10)
                .accessibilityLabel("Мій МЯУдень")
                .accessibilityAddTraits(.isHeader)

            GeometryReader { g in
                Image("Welcome")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height, alignment: .bottom)
                    .clipped()
            }
            .accessibilityElement()
            .accessibilityLabel("Людина з великим олівцем піднімається сходинками: ідеї, план, виконання")
            .accessibilityAddTraits(.isImage)

            Button("Розпочати", action: onStart)
                .buttonStyle(.creamLedge)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, insets.bottom + 28)
                .background(Theme.field)
                .accessibilityIdentifier("startButton")
        }
        .background(Theme.sky)
    }
}
