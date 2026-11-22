import Foundation

nonisolated enum DayFormat {
    static func weekdayAndDate(_ day: DayKey, calendar: Calendar, locale: Locale) -> String {
        day.startDate(in: calendar).formatted(
            style(calendar: calendar, locale: locale).weekday(.wide).day().month(.wide)
        )
    }

    static func dayAndMonth(_ day: DayKey, calendar: Calendar, locale: Locale) -> String {
        day.startDate(in: calendar).formatted(style(calendar: calendar, locale: locale).day().month(.wide))
    }

    static func weekday(_ day: DayKey, calendar: Calendar, locale: Locale) -> String {
        day.startDate(in: calendar).formatted(style(calendar: calendar, locale: locale).weekday(.wide))
    }

    static func month(_ month: MonthKey, calendar: Calendar, locale: Locale) -> String {
        let firstDay = DayKey(year: month.year, month: month.month, day: 1)
        return firstDay.startDate(in: calendar).formatted(style(calendar: calendar, locale: locale).month(.wide))
    }

    static func time(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        date.formatted(style(calendar: calendar, locale: locale).hour().minute())
    }

    private static func style(calendar: Calendar, locale: Locale) -> Date.FormatStyle {
        Date.FormatStyle(
            locale: locale,
            calendar: calendar,
            timeZone: calendar.timeZone,
            capitalizationContext: .beginningOfSentence
        )
    }
}
