import Foundation

/// Робота з датами: ключі днів «рррр-мм-дд», тиждень із понеділка, українські назви.
enum DayKey {
    static var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "uk_UA")
        c.firstWeekday = 2          // тиждень починається з понеділка
        c.timeZone = .current
        return c
    }()

    static let monthGen = ["січня", "лютого", "березня", "квітня", "травня", "червня", "липня", "серпня", "вересня", "жовтня", "листопада", "грудня"]
    static let monthNom = ["Січень", "Лютий", "Березень", "Квітень", "Травень", "Червень", "Липень", "Серпень", "Вересень", "Жовтень", "Листопад", "Грудень"]
    static let monthShort = ["січ", "лют", "бер", "квіт", "трав", "черв", "лип", "серп", "вер", "жовт", "лист", "груд"]
    static let wdFull = ["понеділок", "вівторок", "середа", "четвер", "пʼятниця", "субота", "неділя"]
    static let wdShort = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Нд"]

    static func key(_ d: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 1, c.day ?? 1)
    }
    static func date(from key: String) -> Date? {
        let p = key.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))
    }
    static func dateOrToday(_ key: String) -> Date { date(from: key) ?? startOfToday }
    static var startOfToday: Date { calendar.startOfDay(for: Date()) }
    static var today: String { key(Date()) }

    static func addDays(_ d: Date, _ n: Int) -> Date { calendar.date(byAdding: .day, value: n, to: d) ?? d }
    static func addMonths(_ d: Date, _ n: Int) -> Date { calendar.date(byAdding: .month, value: n, to: d) ?? d }
    /// 0 — понеділок … 6 — неділя
    static func weekdayIndex(_ d: Date) -> Int { (calendar.component(.weekday, from: d) + 5) % 7 }
    static func monday(of d: Date) -> Date { addDays(calendar.startOfDay(for: d), -weekdayIndex(d)) }
    static func firstOfMonth(_ d: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: d)) ?? d
    }
    static func dayNumber(_ d: Date) -> Int { calendar.component(.day, from: d) }
    static func month(_ d: Date) -> Int { calendar.component(.month, from: d) - 1 }
    static func year(_ d: Date) -> Int { calendar.component(.year, from: d) }

    /// «9 жовтня 2026»
    static func longDate(_ d: Date) -> String { "\(dayNumber(d)) \(monthGen[month(d)]) \(year(d))" }
    /// «Пʼятниця, 9 жовтня 2026»
    static func weekdayLongDate(_ d: Date) -> String {
        let w = wdFull[weekdayIndex(d)]
        return w.prefix(1).uppercased() + w.dropFirst() + ", " + longDate(d)
    }

    /// «1 план / 2 плани / 5 планів»
    static func plansWord(_ n: Int) -> String {
        if n % 10 == 1 && n % 100 != 11 { return "план" }
        if (2...4).contains(n % 10) && !(12...14).contains(n % 100) { return "плани" }
        return "планів"
    }
    static func sessionsWord(_ n: Int) -> String {
        if n % 10 == 1 && n % 100 != 11 { return "сесія" }
        if (2...4).contains(n % 10) && !(12...14).contains(n % 100) { return "сесії" }
        return "сесій"
    }
}
