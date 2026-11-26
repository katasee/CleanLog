import Foundation

nonisolated struct MonthEndReminderSettings: Sendable, Equatable, Codable {
    var isOn: Bool
    var time: ReminderTime

    static let initial = MonthEndReminderSettings(isOn: false, time: ReminderTime(hour: 18, minute: 0))
}
