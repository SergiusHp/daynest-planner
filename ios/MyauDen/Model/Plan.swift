import Foundation

/// Один план (справа). Формат полів збігається з веб-версією, тож дані легко перенести.
struct Plan: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var date: String          // «рррр-мм-дд» у місцевому часовому поясі
    var text: String
    var time: String          // «гг:хх» або порожньо
    var done: Bool
    var doneAt: Double        // мс від 1970 — порядок виконаних унизу списку
    var remind: Int           // хвилин до початку; 0 — без нагадування
    var scratch: Int?         // стиль котячих подряпин (0…3), запам'ятовується при виконанні

    init(id: String = Plan.newID(), date: String, text: String, time: String = "",
         done: Bool = false, doneAt: Double = 0, remind: Int = 0, scratch: Int? = nil) {
        self.id = id; self.date = date; self.text = text; self.time = time
        self.done = done; self.doneAt = doneAt; self.remind = remind; self.scratch = scratch
    }

    // стійкий до старих/неповних записів декодер
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        date = try c.decode(String.self, forKey: .date)
        text = try c.decode(String.self, forKey: .text)
        time = (try? c.decode(String.self, forKey: .time)) ?? ""
        done = (try? c.decode(Bool.self, forKey: .done)) ?? false
        doneAt = (try? c.decode(Double.self, forKey: .doneAt)) ?? 0
        remind = (try? c.decode(Int.self, forKey: .remind)) ?? 0
        scratch = try? c.decode(Int.self, forKey: .scratch)
    }

    static func newID() -> String {
        String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(10)).lowercased()
    }

    /// Момент початку плану (день + час) або nil, якщо часу немає.
    var startDate: Date? {
        guard !time.isEmpty else { return nil }
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, let day = DayKey.date(from: date) else { return nil }
        return DayKey.calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: day)
    }

    /// Коли спрацює нагадування (якщо обране).
    var reminderDate: Date? {
        guard remind > 0, !done, let start = startDate else { return nil }
        return start.addingTimeInterval(TimeInterval(-remind * 60))
    }
}

/// Варіанти нагадування — ті самі, що й у веб-версії.
enum ReminderOption: Int, CaseIterable, Identifiable {
    case none = 0, m5 = 5, m15 = 15, m30 = 30, m45 = 45, h1 = 60
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .none: return "Без нагадування"
        case .m5: return "За 5 хвилин"
        case .m15: return "За 15 хвилин"
        case .m30: return "За 30 хвилин"
        case .m45: return "За 45 хвилин"
        case .h1: return "За 1 годину"
        }
    }
    static func label(_ minutes: Int) -> String { minutes == 60 ? "1 годину" : "\(minutes) хв" }
}
