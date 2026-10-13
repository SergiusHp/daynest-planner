import SwiftUI
import Observation

enum CalendarMode: String { case week, month }

/// Що відкрито в шторці плану.
enum SheetTarget: Identifiable, Equatable {
    case new(date: String)
    case edit(Plan)
    var id: String {
        switch self {
        case .new(let d): return "new-\(d)"
        case .edit(let p): return "edit-\(p.id)"
        }
    }
}

/// Стан застосунку: плани, вибраний день, сторінка, календар. Зберігається у JSON-файлі на пристрої.
@Observable
final class AppStore {
    static let welcomeTask = "Ознайомитись з програмою"

    var plans: [Plan] = []
    var selected: String = DayKey.today
    var today: String = DayKey.today
    var page: Int = 0
    var calMode: CalendarMode = .month
    var cursor: Date = DayKey.firstOfMonth(Date())        // місяць, показаний у календарі
    var sheet: SheetTarget?
    var justAdded: String?
    /// Тимчасово заборонити гортання сторінок (поки палець веде справу чи лапку таймера).
    var pagerLocked = false

    /// Справи, що саме зараз «зацарапуються»: до кінця анімації лишаються на своєму місці у списку.
    var settling: Set<String> = []
    /// Коли почалися подряпини для щойно виконаних справ (для анімації).
    var scratchStarted: [String: Date] = [:]
    private var lastScratch = -1

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("plans.json")
    }()

    init() {
        TestHooks.applyBeforeLoad()
        load()
        TestHooks.applyAfterLoad(self)
    }

    // MARK: збереження
    private func load() {
        if let data = try? Data(contentsOf: fileURL), let list = try? JSONDecoder().decode([Plan].self, from: data) {
            plans = list
        } else {
            plans = [Plan(date: DayKey.today, text: AppStore.welcomeTask)]   // перша справа нового користувача
            save()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(plans) { try? data.write(to: fileURL, options: .atomic) }
        Notifier.shared.syncPlanReminders(plans)
    }

    // MARK: вибірки
    func plans(on key: String) -> [Plan] {
        plans.filter { $0.date == key }.sorted { a, b in
            let ad = a.done && !settling.contains(a.id), bd = b.done && !settling.contains(b.id)
            if ad != bd { return !ad }
            if ad { return a.doneAt < b.doneAt }
            let at = a.time.isEmpty ? "99:99" : a.time, bt = b.time.isEmpty ? "99:99" : b.time
            return at < bt
        }
    }
    func count(on key: String) -> Int { plans.reduce(0) { $0 + ($1.date == key ? 1 : 0) } }

    // MARK: дні
    /// Перечитати системну дату (застосунок міг бути відкритий через північ).
    @discardableResult
    func refreshToday() -> Bool {
        let k = DayKey.today
        guard k != today else { return false }
        if selected == today { selected = k }
        today = k
        return true
    }

    func select(_ key: String) {
        selected = key
        let d = DayKey.dateOrToday(key)
        if calMode == .month && DayKey.firstOfMonth(d) != cursor { cursor = DayKey.firstOfMonth(d) }
    }

    func goToday() {
        refreshToday()
        cursor = DayKey.firstOfMonth(Date())
        select(today)
    }

    func shiftCalendar(_ dir: Int) {
        if calMode == .month {
            cursor = DayKey.addMonths(cursor, dir)
        } else {
            select(DayKey.key(DayKey.addDays(DayKey.dateOrToday(selected), dir * 7)))
        }
    }

    // MARK: зміни
    func add(text: String, date: String, time: String, remind: Int) {
        let p = Plan(date: date, text: text, time: time, remind: time.isEmpty ? 0 : remind)
        plans.append(p)
        justAdded = p.id
        save()
        select(date)
    }

    func update(_ id: String, text: String, date: String, time: String, remind: Int) {
        guard let i = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[i].text = text
        plans[i].date = date
        plans[i].time = time
        plans[i].remind = time.isEmpty ? 0 : remind
        save()
        select(date)
    }

    func delete(_ id: String) {
        plans.removeAll { $0.id == id }
        save()
    }

    /// Закреслити / повернути справу. Повертає тривалість анімації подряпин (сек).
    @discardableResult
    func toggle(_ id: String, style chosen: Int? = nil, animate: Bool = true) -> Double {
        guard let i = plans.firstIndex(where: { $0.id == id }) else { return 0 }
        let becomesDone = !plans[i].done
        plans[i].done = becomesDone
        plans[i].doneAt = becomesDone ? Date().timeIntervalSince1970 * 1000 : 0
        var wait = 0.38
        if becomesDone {
            let style = chosen ?? pickScratch()
            lastScratch = style
            plans[i].scratch = style
            if animate {
                scratchStarted[id] = Date()
                wait = Scratch.duration(style: style, key: id, text: plans[i].text) + 0.32
            }   // після свайпу подряпини вже «проведені» пальцем — анімацію не повторюємо
            Haptics.success()
        } else {
            scratchStarted[id] = nil
            Haptics.tap()
        }
        settling.insert(id)
        save()
        // кіт «дозацарапує», і лише тоді справа переїжджає вниз (або назад угору)
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { _ = self?.settling.remove(id) }
            self?.scratchStarted[id] = nil          // анімацію завершено — далі подряпини статичні
        }
        return wait
    }

    func pickScratch() -> Int {
        var s: Int
        repeat { s = Int.random(in: 0..<Scratch.styles) } while s == lastScratch
        lastScratch = s
        return s
    }

    func scratchStyle(of p: Plan) -> Int {
        if let s = p.scratch { return s }
        var r = SeededRandom("s" + p.id)
        return Int(r.next() * Double(Scratch.styles))
    }
}
