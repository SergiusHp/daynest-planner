import Foundation

/// Аргументи запуску для автоматичних UI-тестів (у звичайному використанні нічого не роблять).
enum TestHooks {
    static let args = ProcessInfo.processInfo.arguments
    static var isUITest: Bool { args.contains("-uitest") }
    static var forceReduceMotion: Bool { args.contains("-uitest-reduce-motion") }

    static func applyBeforeLoad() {
        guard isUITest else { return }
        if args.contains("-uitest-reset") {
            if let domain = Bundle.main.bundleIdentifier { UserDefaults.standard.removePersistentDomain(forName: domain) }
            let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            try? FileManager.default.removeItem(at: dir.appendingPathComponent("plans.json"))
        }
        if args.contains("-uitest-skip-intro") {
            UserDefaults.standard.set(true, forKey: Keys.welcomeSeen)
            UserDefaults.standard.set(true, forKey: Keys.onboardSeen)
        }
    }

    static func applyAfterLoad(_ store: AppStore) {
        guard isUITest else { return }
        let today = DayKey.today
        if args.contains("-uitest-seed-many") {
            let names = ["Прочитати 10 сторінок книги", "Ранкова прогулянка", "Купити продукти", "Подзвонити бабусі",
                         "Полити квіти", "Написати лист", "Прибрати на столі", "Приготувати вечерю", "Почитати казку",
                         "Зарядка", "Оплатити рахунки", "Перевірити пошту", "Помити посуд", "Спланувати вихідні",
                         "Погуляти з котиком", "Лягти вчасно"]
            store.plans = names.enumerated().map { i, n in
                Plan(id: "t\(i)", date: today, text: n, time: i % 4 == 1 ? String(format: "%02d:00", 8 + i) : "")
            }
            store.save()
        } else if args.contains("-uitest-seed-sample") {
            store.plans = [
                Plan(id: "a", date: today, text: "Прочитати 10 сторінок книги", time: "08:30"),
                Plan(id: "b", date: today, text: "Зустріч із командою щодо запуску нового проєкту", time: "11:00", remind: 15),
                Plan(id: "c", date: today, text: "Купити продукти"),
                Plan(id: "d", date: today, text: "Подзвонити мамі", time: "19:00", done: true, doneAt: 1, scratch: 1),
                Plan(id: "e", date: DayKey.key(DayKey.addDays(Date(), 1)), text: "Похід у магазин"),
            ]
            store.save()
        }
        if let i = args.firstIndex(of: "-uitest-page"), i + 1 < args.count, let p = Int(args[i + 1]) { store.page = p }
    }
}

enum Keys {
    static let welcomeSeen = "welcomeSeen"
    static let onboardSeen = "onboardSeen"
    static let musicMuted = "musicMuted"
    static let focusSessions = "focusSessions"
}
