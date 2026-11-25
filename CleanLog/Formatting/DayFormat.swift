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

    static func dayNumber(_ day: DayKey, calendar: Calendar, locale: Locale) -> String {
        day.startDate(in: calendar).formatted(style(calendar: calendar, locale: locale).day())
    }

    static func weekday(_ day: DayKey, calendar: Calendar, locale: Locale) -> String {
        day.startDate(in: calendar).formatted(style(calendar: calendar, locale: locale).weekday(.wide))
    }

    static func month(_ month: MonthKey, calendar: Calendar, locale: Locale) -> String {
        firstDate(of: month, calendar: calendar).formatted(style(calendar: calendar, locale: locale).month(.wide))
    }

    static func monthAndYear(_ month: MonthKey, calendar: Calendar, locale: Locale) -> String {
        firstDate(of: month, calendar: calendar).formatted(
            style(calendar: calendar, locale: locale).month(.wide).year()
        )
    }

    static func monthInPhrase(_ month: MonthKey, calendar: Calendar, locale: Locale) -> String {
        firstDate(of: month, calendar: calendar).formatted(
            Date.VerbatimFormatStyle(
                format: "\(month: .wide)",
                locale: locale,
                timeZone: calendar.timeZone,
                calendar: calendar
            )
        )
    }

    static func weekdaySymbols(calendar: Calendar, locale: Locale) -> [String] {
        var localized = calendar
        localized.locale = locale
        let symbols = localized.shortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    static func time(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        date.formatted(style(calendar: calendar, locale: locale).hour().minute())
    }

    private static func firstDate(of month: MonthKey, calendar: Calendar) -> Date {
        DayKey(year: month.year, month: month.month, day: 1).startDate(in: calendar)
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
