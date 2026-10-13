import Foundation
import UserNotifications

/// Локальні сповіщення iOS: нагадування про плани й кінець фокус-сесії.
/// На відміну від веб-версії, вони приходять і тоді, коли застосунок закритий.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()
    private let center = UNUserNotificationCenter.current()
    private static let planPrefix = "plan-"
    static let focusID = "focus-end"

    /// Що робити, коли користувач торкнувся сповіщення про план (відкрити потрібний день).
    var onOpenPlanDay: ((String) -> Void)?

    func activate() { center.delegate = self }

    func authorizationStatus(_ done: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { s in DispatchQueue.main.async { done(s.authorizationStatus) } }
    }

    /// Просимо дозвіл лише тоді, коли користувач сам обрав нагадування або запустив таймер.
    func requestIfNeeded(_ done: ((Bool) -> Void)? = nil) {
        // в автоматичних UI-тестах системне вікно дозволу лише заважало б
        if TestHooks.isUITest { DispatchQueue.main.async { done?(false) }; return }
        center.getNotificationSettings { s in
            if s.authorizationStatus == .notDetermined {
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
                    DispatchQueue.main.async { done?(ok) }
                }
            } else {
                let ok = s.authorizationStatus == .authorized || s.authorizationStatus == .provisional
                DispatchQueue.main.async { done?(ok) }
            }
        }
    }

    /// Перепланувати всі нагадування: найближчі 60 (обмеження iOS — 64 очікуваних сповіщення на застосунок).
    func syncPlanReminders(_ plans: [Plan]) {
        let now = Date()
        let upcoming = plans.compactMap { p -> (Plan, Date)? in
            guard let at = p.reminderDate, at > now else { return nil }
            return (p, at)
        }.sorted { $0.1 < $1.1 }.prefix(60)

        center.getPendingNotificationRequests { pending in
            let old = pending.map(\.identifier).filter { $0.hasPrefix(Notifier.planPrefix) }
            self.center.removePendingNotificationRequests(withIdentifiers: old)
            for (p, at) in upcoming {
                let c = UNMutableNotificationContent()
                c.title = "Мій МЯУдень"
                c.body = "Через \(ReminderOption.label(p.remind)): \(p.text) (\(p.time))"
                c.sound = .default
                c.userInfo = ["date": p.date]
                c.threadIdentifier = "plans"
                let comps = DayKey.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: at)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                self.center.add(UNNotificationRequest(identifier: Notifier.planPrefix + p.id, content: c, trigger: trigger))
            }
        }
    }

    func scheduleFocusEnd(at date: Date, minutes: Int) {
        cancelFocusEnd()
        let interval = date.timeIntervalSinceNow
        guard interval > 1 else { return }
        let c = UNMutableNotificationContent()
        c.title = "Фокус завершено"
        c.body = "\(minutes) хв зосередженої роботи позаду. Котик пишається тобою — час на перерву."
        c.sound = UNNotificationSound(named: UNNotificationSoundName("chime.wav"))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: Notifier.focusID, content: c, trigger: trigger))
    }

    func cancelFocusEnd() {
        center.removePendingNotificationRequests(withIdentifiers: [Notifier.focusID])
        center.removeDeliveredNotifications(withIdentifiers: [Notifier.focusID])
    }

    // показувати банер і коли застосунок відкритий
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // кінець фокусу на відкритому екрані вже показує сам таймер (звук + анімація)
        if notification.request.identifier == Notifier.focusID { completionHandler([]); return }
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let date = response.notification.request.content.userInfo["date"] as? String {
            DispatchQueue.main.async { self.onOpenPlanDay?(date) }
        }
        completionHandler()
    }
}
