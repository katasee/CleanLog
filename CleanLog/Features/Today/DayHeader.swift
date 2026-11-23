import Foundation

struct DayHeader: Equatable {
    let title: String
    let subtitle: String
    let isToday: Bool
}

extension DayHeader {
    init(day: DayKey, kind: DayKind, calendar: Calendar, locale: Locale) {
        let weekday = DayFormat.weekday(day, calendar: calendar, locale: locale)
        let dayAndMonth = DayFormat.dayAndMonth(day, calendar: calendar, locale: locale)
        switch kind {
        case .today:
            self.init(
                title: String(localized: .todayHeaderTitle, locale: locale),
                subtitle: DayFormat.weekdayAndDate(day, calendar: calendar, locale: locale),
                isToday: true
            )
        case .past:
            self.init(
                title: dayAndMonth,
                subtitle: String(localized: .todayHeaderPast(weekday), locale: locale),
                isToday: false
            )
        case .future:
            self.init(
                title: dayAndMonth,
                subtitle: String(localized: .todayHeaderFuture(weekday), locale: locale),
                isToday: false
            )
        }
    }
}
