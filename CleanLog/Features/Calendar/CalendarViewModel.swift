import Foundation
import Observation

@Observable @MainActor
final class CalendarViewModel {
    private let today: DayKey
    private let workDays: any WorkDayRepository
    private let calendar: Calendar
    private let locale: Locale
    private var earnings: [DayKey: Money] = [:]
    private var selectedWorkDay: WorkDay?

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

    var quickPicks: [CalendarQuickPick] {
        [
            quickPick(today, title: .calendarQuickToday),
            quickPick(today.adding(days: -1, calendar: calendar), title: .calendarQuickYesterday),
            quickPick(today.adding(days: -7, calendar: calendar), title: .calendarQuickWeekAgo),
        ]
    }

    var card: CalendarDayCard? {
        guard let selectedWorkDay, selectedWorkDay.day == selected else { return nil }
        return CalendarDayCard(
            workDay: selectedWorkDay,
            isToday: selected == today,
            calendar: calendar,
            locale: locale
        )
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
            earnings = Self.earnings(in: monthDays)
            refresh()
        }
    }

    func observeSelectedDay() async {
        let day = selected
        for await workDay in workDays.day(day) where day == selected {
            selectedWorkDay = workDay
        }
    }

    private static func earnings(in monthDays: [WorkDay]) -> [DayKey: Money] {
        let earned = monthDays.filter(\.hasCleanedEntries).map { ($0.day, $0.earned) }
        return Dictionary(earned) { first, _ in first }
    }

    private func refresh() {
        monthTitle = DayFormat.monthAndYear(shownMonth, calendar: calendar, locale: locale)
        weeks = MonthGrid.weeks(of: shownMonth, calendar: calendar).map { week in
            week.map { $0.map(cell) }
        }
    }

    private func quickPick(_ day: DayKey, title: LocalizedStringResource) -> CalendarQuickPick {
        CalendarQuickPick(
            day: day,
            title: String(localized: title, locale: locale),
            isSelected: day == selected
        )
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
