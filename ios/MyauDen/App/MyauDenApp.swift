import SwiftUI

@main
struct MyauDenApp: App {
    @State private var store = AppStore()
    @State private var focus = FocusModel()
    @Environment(\.scenePhase) private var phase

    init() {
        Notifier.shared.activate()
        Haptics.prepare()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(focus)
                .environment(\.locale, Locale(identifier: "uk_UA"))
                .tint(Theme.accent)
                .preferredColorScheme(.light)          // застосунок має одну теплу світлу тему
                .dynamicTypeSize(.xSmall ... .xxLarge)  // збільшений текст підтримуємо, але без розвалу верстки
                .onChange(of: phase) { _, p in
                    if p == .active {
                        if store.refreshToday() { store.cursor = DayKey.firstOfMonth(Date()) }
                        focus.resync()
                        Notifier.shared.syncPlanReminders(store.plans)
                    }
                }
        }
    }
}

/// Відступи безпечної зони екрана (виріз, «острів», нижня смужка) — сторінки малюють фон під ними самі.
private struct RootInsetsKey: EnvironmentKey { static let defaultValue = EdgeInsets() }
extension EnvironmentValues {
    var rootInsets: EdgeInsets {
        get { self[RootInsetsKey.self] }
        set { self[RootInsetsKey.self] = newValue }
    }
}

/// Чи вимкнено рух (системне налаштування «Зменшити рух» або тестовий режим).
struct ReduceMotionKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var reduceMotion: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}
