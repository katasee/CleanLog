import Foundation

struct CalendarDayCard: Equatable {
    let weekdayText: String
    let dateText: String
    let summaryText: String
}

extension CalendarDayCard {
    init(workDay: WorkDay, isToday: Bool, calendar: Calendar, locale: Locale) {
        let weekday = DayFormat.weekday(workDay.day, calendar: calendar, locale: locale)
        self.init(
            weekdayText: isToday ? String(localized: .calendarCardToday(weekday), locale: locale) : weekday,
            dateText: DayFormat.dayAndMonth(workDay.day, calendar: calendar, locale: locale),
            summaryText: Self.summary(of: workDay, locale: locale)
        )
    }

    private static func summary(of workDay: WorkDay, locale: Locale) -> String {
        if workDay.hasCleanedEntries {
            let earned = MoneyFormat.string(workDay.earned, locale: locale)
            return String(localized: .calendarCardEarned(apartments: workDay.cleanedCount, earned), locale: locale)
        }
        if !workDay.entries.isEmpty {
            return String(localized: .calendarCardPlanned(apartments: workDay.entries.count), locale: locale)
        }
        return String(localized: .calendarCardDayOff, locale: locale)
    }
}
