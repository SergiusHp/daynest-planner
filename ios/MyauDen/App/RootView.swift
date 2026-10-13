import SwiftUI

/// Потік запуску: привітання (один раз) → знайомство з жестами (один раз) → планер.
struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Keys.welcomeSeen) private var welcomeSeen = false
    @AppStorage(Keys.onboardSeen) private var onboardSeen = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MainPager()
                    .accessibilityHidden(!welcomeSeen || !onboardSeen)
                    .allowsHitTesting(welcomeSeen && onboardSeen)

                if welcomeSeen && !onboardSeen {
                    // з'являється під привітанням одразу, тож планер між екранами не «блимає»
                    OnboardingView { withAnimation(.easeInOut(duration: 0.45)) { onboardSeen = true } }
                        .transition(.asymmetric(insertion: .identity, removal: .opacity))
                        .zIndex(1)
                }
                if !welcomeSeen {
                    WelcomeView { withAnimation(.easeInOut(duration: 0.45)) { welcomeSeen = true } }
                        .transition(.asymmetric(insertion: .identity, removal: .opacity.combined(with: .offset(y: -16))))
                        .zIndex(2)
                }
            }
            .environment(\.rootInsets, geo.safeAreaInsets)
            .environment(\.reduceMotion, systemReduceMotion || TestHooks.forceReduceMotion)
            .ignoresSafeArea()
        }
        .onAppear {
            Notifier.shared.onOpenPlanDay = { date in
                store.select(date)
                store.page = 0
            }
        }
    }
}

/// Три сторінки, що гортаються свайпом: день → тиждень/місяць → фокус.
/// Гортання блокується, поки палець веде справу вправо чи крутить лапку таймера — жести не конфліктують.
struct MainPager: View {
    @Environment(AppStore.self) private var store
    @Environment(\.rootInsets) private var insets
    @State private var scrolled: Int? = 0

    var body: some View {
        @Bindable var store = store
        GeometryReader { geo in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    DayPage().frame(width: geo.size.width, height: geo.size.height).id(0)
                    CalendarPage().frame(width: geo.size.width, height: geo.size.height).id(1)
                    FocusPage().frame(width: geo.size.width, height: geo.size.height).id(2)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrolled)
            .scrollIndicators(.hidden)
            .scrollDisabled(store.pagerLocked)
            .onChange(of: scrolled) { _, v in if let v, v != store.page { store.page = v } }
            .onChange(of: store.page) { _, v in
                if scrolled != v { withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) { scrolled = v } }
            }
            .onAppear { scrolled = store.page }
        }
        .background(Theme.day)
        .overlay(alignment: .bottom) {
            PageDots(page: $store.page)
                .padding(.bottom, max(insets.bottom - 6, 10))
        }
        .sheet(item: $store.sheet) { target in
            PlanSheet(target: target)
        }
    }
}

/// Крапки-індикатор сторінок; торкання — перехід.
struct PageDots: View {
    @Binding var page: Int
    private let names = ["План дня", "Тиждень і місяць", "Фокус"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.brown : Theme.inkFaint)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) { page = i } }
                    .accessibilityElement()
                    .accessibilityLabel(names[i])
                    .accessibilityAddTraits(i == page ? [.isButton, .isSelected] : .isButton)
            }
        }
        .animation(.easeOut(duration: 0.25), value: page)
    }
}
