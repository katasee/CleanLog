import Foundation
import Observation

@Observable @MainActor
final class CalendarViewModel {
    private let today: DayKey
    private let workDays: any WorkDayRepository
    private let calendar: Calendar
    private let locale: Locale
    private var earnings: [DayKey: Money] = [:]

    let weekdaySymbols: [String]
    private(set) var shownMonth: MonthKey
    private(set) var selected: DayKey
    private(set) var monthTitle = ""
    private(set) var weeks: [[CalendarCell?]] = []

    init(
        selected: DayKey,
        today: DayKey,
        workDays: any WorkDayRepository,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.selected = selected
        self.today = today
        self.workDays = workDays
        self.calendar = calendar
        self.locale = locale
        shownMonth = selected.monthKey
        weekdaySymbols = DayFormat.weekdaySymbols(calendar: calendar, locale: locale)
        refresh()
    }

    func select(_ day: DayKey) {
        selected = day
        shownMonth = day.monthKey
        refresh()
    }

    func showPreviousMonth() {
        shownMonth = shownMonth.previous
        refresh()
    }

    func showNextMonth() {
        shownMonth = shownMonth.next
        refresh()
    }

    func observeMonth() async {
        let month = shownMonth
        for await monthDays in workDays.days(in: month) where month == shownMonth {
            earnings = Dictionary(
                uniqueKeysWithValues: monthDays.filter(\.hasCleanedEntries).map { ($0.day, $0.earned) }
            )
            refresh()
        }
    }

    private func refresh() {
        monthTitle = DayFormat.monthAndYear(shownMonth, calendar: calendar, locale: locale)
        weeks = MonthGrid.weeks(of: shownMonth, calendar: calendar).map { week in
            week.map { $0.map(cell) }
        }
    }

    private func cell(_ day: DayKey) -> CalendarCell {
        CalendarCell(
            day: day,
            earned: earnings[day],
            isToday: day == today,
            isSelected: day == selected,
            calendar: calendar,
            locale: locale
        )
    }
}
