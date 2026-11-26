#if DEBUG
    import Foundation

    final class FakeSettingsRepository: SettingsRepository {
        private var reminder: MonthEndReminderSettings
        private let observers = StoreObservers()

        init(_ reminder: MonthEndReminderSettings = .initial) {
            self.reminder = reminder
        }

        func monthEndReminder() -> AsyncStream<MonthEndReminderSettings> {
            observers.stream { [unowned self] in reminder }
        }

        func saveMonthEndReminder(_ settings: MonthEndReminderSettings) async throws {
            reminder = settings
            observers.notify()
        }
    }
#endif
