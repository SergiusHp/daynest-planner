import UIKit

/// Тактильний відгук (Taptic Engine).
enum Haptics {
    private static let selection = UISelectionFeedbackGenerator()
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let notify = UINotificationFeedbackGenerator()

    /// Легкий «тік» — крок шкали таймера.
    static func tick() { selection.selectionChanged() }
    /// Натискання.
    static func tap() { light.impactOccurred() }
    /// Відчутніший поштовх — кожні 5 хвилин на шкалі, старт таймера.
    static func strong() { medium.impactOccurred() }
    /// Успіх — справу закреслено, фокус завершено.
    static func success() { notify.notificationOccurred(.success) }

    static func prepare() { selection.prepare(); light.prepare() }
}
