import Foundation

nonisolated struct MonthEndReminder: Sendable, Equatable {
    let month: MonthKey
    let day: DayKey
    let time: ReminderTime

    static func next(
        settings: MonthEndReminderSettings,
        month: MonthKey,
        hasCleanedApartment: Bool,
        now: Date,
        calendar: Calendar
    ) -> MonthEndReminder? {
        guard settings.isOn, hasCleanedApartment else { return nil }
        guard let lastDay = month.days(in: calendar).last else {
            preconditionFailure("Month \(month) has no days")
        }
        guard settings.time.date(on: lastDay, calendar: calendar) > now else { return nil }
        return MonthEndReminder(month: month, day: lastDay, time: settings.time)
    }
}
