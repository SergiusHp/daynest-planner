import Foundation
import Observation

/// Фокус-таймер: 1–60 хв, пауза/продовження, сесії за день, музика й сповіщення про завершення.
@Observable
final class FocusModel {
    var minutes = 25
    var remaining: Double = 25 * 60
    var running = false
    var finished = false           // показ «готово!» кілька секунд після завершення
    var finishCount = 0            // лічильник завершень — запускає «стрибок» котика
    var sessions = 0
    var taskID = ""                // над чим працюємо (необов'язково)

    let music = MusicPlayer()

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var endAt: Date?
    @ObservationIgnored private var backWork: DispatchWorkItem?

    init() { sessions = FocusModel.loadSessions()[DayKey.today] ?? 0 }

    var total: Double { Double(minutes * 60) }
    /// Режим фокусу: шкала ховається, циферблат збільшується, кільце показує залишок.
    var inFocus: Bool { running || finished || (remaining > 0 && remaining < total) }
    var started: Bool { remaining > 0 && remaining < total }

    var statusTitle: String { running ? "Пауза" : (started ? "Продовжити" : "Почати") }
    var subText: String {
        running ? "залишилось" : (started ? "пауза" : (remaining <= 0 ? "готово!" : "хвилин фокусу"))
    }
    var hint: String {
        running ? "Тримай фокус. Котик стежить за часом."
            : (remaining <= 0 ? "Чудова робота. Час на перерву." : "Покрути лапку по шкалі, щоб задати час")
    }
    var timeText: String {
        let s = Int(remaining.rounded(.up))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    func setMinutes(_ m: Int) {
        let m = max(1, min(60, m))
        if m == minutes && remaining == total { return }
        minutes = m
        remaining = total
        finished = false
        if m % 5 == 0 { Haptics.strong() } else { Haptics.tick() }   // кожні 5 хв — відчутніше
    }

    func playPause() {
        if running {
            running = false
            timer?.invalidate()
            if let endAt { remaining = max(0, endAt.timeIntervalSinceNow) }
            endAt = nil
            Notifier.shared.cancelFocusEnd()
            music.pause()                            // зупинка таймера — зупинка музики
        } else {
            if remaining <= 0 { remaining = total }
            finished = false
            backWork?.cancel()
            running = true
            let end = Date().addingTimeInterval(remaining)
            endAt = end
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in self?.tick() }
            music.mutedByUser = false
            music.play()                             // старт таймера завжди вмикає музику
            // сповіщення про кінець — спрацює й тоді, коли застосунок згорнутий чи закритий
            Notifier.shared.requestIfNeeded { ok in
                if ok, self.running { Notifier.shared.scheduleFocusEnd(at: end, minutes: self.minutes) }
            }
        }
        Haptics.strong()
    }

    func reset() {
        running = false
        finished = false
        timer?.invalidate()
        backWork?.cancel()
        endAt = nil
        remaining = total
        Notifier.shared.cancelFocusEnd()
        music.pause()                                // скидання — музика зупиняється
    }

    /// Після повернення з фону — перерахувати залишок.
    func resync() {
        refreshSessionsForToday()
        guard running else { return }
        tick()
    }

    private func tick() {
        guard running, let endAt else { return }
        remaining = max(0, endAt.timeIntervalSinceNow)
        if remaining <= 0 { finish() }
    }

    private func finish() {
        running = false
        timer?.invalidate()
        endAt = nil
        remaining = 0
        finished = true
        finishCount += 1
        sessions += 1
        var all = FocusModel.loadSessions(); all[DayKey.today] = sessions
        UserDefaults.standard.set(all, forKey: Keys.focusSessions)
        Chime.play()
        Haptics.success()
        music.fadeOut()                              // сесію завершено — музика затихає
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.running else { return }
            self.finished = false
            self.remaining = self.total
        }
        backWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: work)
    }

    private func refreshSessionsForToday() { sessions = FocusModel.loadSessions()[DayKey.today] ?? 0 }
    private static func loadSessions() -> [String: Int] {
        (UserDefaults.standard.dictionary(forKey: Keys.focusSessions) as? [String: Int]) ?? [:]
    }
}
