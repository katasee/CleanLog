import Foundation

struct ReminderRequest: Equatable {
    static let identifier = "month-end-report"

    nonisolated private static let yearKey = "year"
    nonisolated private static let monthKey = "month"
    nonisolated private static let months = 1...12

    let month: MonthKey
    let fireDate: DateComponents
    let title: String
    let body: String

    var userInfo: [String: Int] {
        [Self.yearKey: month.year, Self.monthKey: month.month]
    }

    init(_ reminder: MonthEndReminder, calendar: Calendar, locale: Locale) {
        let monthName = DayFormat.monthInTitle(
            reminder.month,
            includesYear: false,
            calendar: calendar,
            locale: locale
        )
        month = reminder.month
        fireDate = DateComponents(
            year: reminder.day.year,
            month: reminder.day.month,
            day: reminder.day.day,
            hour: reminder.time.hour,
            minute: reminder.time.minute
        )
        title = String(localized: .reminderMonthEndTitle, locale: locale)
        body = String(localized: .reminderMonthEndBody(monthName), locale: locale)
    }

    nonisolated static func month(from userInfo: [AnyHashable: Any]) -> MonthKey? {
        guard
            let year = userInfo[yearKey] as? Int,
            let month = userInfo[monthKey] as? Int,
            months.contains(month)
        else { return nil }
        return MonthKey(year: year, month: month)
    }
}
