import Foundation

@testable import CleanLog

final class FailingSettingsRepository: SettingsRepository {
    struct WriteRefused: Error {}

    private let wrapped = FakeSettingsRepository()

    func monthEndReminder() -> AsyncStream<MonthEndReminderSettings> {
        wrapped.monthEndReminder()
    }

    func saveMonthEndReminder(_ settings: MonthEndReminderSettings) async throws {
        throw WriteRefused()
    }
}
