import Foundation

protocol SettingsRepository: AnyObject {
    func monthEndReminder() -> AsyncStream<MonthEndReminderSettings>
    func saveMonthEndReminder(_ settings: MonthEndReminderSettings) async throws
}
