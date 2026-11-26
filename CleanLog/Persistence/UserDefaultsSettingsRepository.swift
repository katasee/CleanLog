import Foundation
import os

final class UserDefaultsSettingsRepository: SettingsRepository {
    private static let monthEndReminderKey = "settings.monthEndReminder"

    private let defaults: UserDefaults
    private let observers = StoreObservers()
    private let logger = Logger(subsystem: "CleanLog", category: "UserDefaultsSettingsRepository")

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func monthEndReminder() -> AsyncStream<MonthEndReminderSettings> {
        observers.stream { [unowned self] in storedMonthEndReminder() }
    }

    func saveMonthEndReminder(_ settings: MonthEndReminderSettings) async throws {
        let data = try JSONEncoder().encode(settings)
        defaults.set(data, forKey: Self.monthEndReminderKey)
        observers.notify()
    }

    private func storedMonthEndReminder() -> MonthEndReminderSettings {
        guard let data = defaults.data(forKey: Self.monthEndReminderKey) else { return .initial }
        do {
            return try JSONDecoder().decode(MonthEndReminderSettings.self, from: data)
        } catch {
            logger.error("Could not read the month-end reminder settings: \(error)")
            return .initial
        }
    }
}
