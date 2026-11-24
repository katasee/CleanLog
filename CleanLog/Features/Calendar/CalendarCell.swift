import Foundation

struct CalendarCell: Identifiable, Equatable {
    let day: DayKey
    let numberText: String
    let amountText: String?
    let isToday: Bool
    let isSelected: Bool
    let accessibilityLabel: String

    var id: DayKey {
        day
    }
}

extension CalendarCell {
    init(
        day: DayKey,
        earned: Money?,
        isToday: Bool,
        isSelected: Bool,
        calendar: Calendar,
        locale: Locale
    ) {
        self.init(
            day: day,
            numberText: DayFormat.dayNumber(day, calendar: calendar, locale: locale),
            amountText: earned.map { MoneyFormat.amount($0, locale: locale) },
            isToday: isToday,
            isSelected: isSelected,
            accessibilityLabel: Self.spokenLabel(
                day: day,
                earned: earned,
                isToday: isToday,
                calendar: calendar,
                locale: locale
            )
        )
    }

    private static func spokenLabel(
        day: DayKey,
        earned: Money?,
        isToday: Bool,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        var label = DayFormat.dayAndMonth(day, calendar: calendar, locale: locale)
        if let earned {
            let amount = MoneyFormat.string(earned, locale: locale)
            label = String(localized: .calendarCellEarned(label, amount), locale: locale)
        }
        if isToday {
            label = String(localized: .calendarCellToday(label), locale: locale)
        }
        return label
    }
}
