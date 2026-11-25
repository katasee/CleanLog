import Foundation
import Observation

@Observable @MainActor
final class StatsViewModel {
    private let workDays: any WorkDayRepository
    private let calendar: Calendar
    private let locale: Locale
    private var today: DayKey
    private var shownDays: [WorkDay] = []
    private var previousEarned: Money?

    private(set) var shownMonth: MonthKey
    private(set) var monthTitle = ""
    private(set) var summary: StatsSummary

    init(
        today: DayKey,
        workDays: any WorkDayRepository,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.today = today
        self.workDays = workDays
        self.calendar = calendar
        self.locale = locale
        shownMonth = today.monthKey
        summary = StatsSummary(
            stats: .calculate(days: [], today: today),
            previousEarned: nil,
            month: today.monthKey,
            isFinished: false,
            calendar: calendar,
            locale: locale
        )
        refresh()
    }

    var canShowNextMonth: Bool {
        shownMonth < today.monthKey
    }

    func showPreviousMonth() {
        show(shownMonth.previous)
    }

    func showNextMonth() {
        guard canShowNextMonth else { return }
        show(shownMonth.next)
    }

    func advance(to today: DayKey) {
        self.today = today
        refresh()
    }

    func observeMonth() async {
        let month = shownMonth
        for await monthDays in workDays.days(in: month) where month == shownMonth {
            shownDays = monthDays
            refresh()
        }
    }

    func observePreviousMonth() async {
        let month = shownMonth
        for await previousDays in workDays.days(in: month.previous) where month == shownMonth {
            previousEarned = previousDays.map(\.earned).sum()
            refresh()
        }
    }

    private func show(_ month: MonthKey) {
        shownMonth = month
        shownDays = []
        previousEarned = nil
        refresh()
    }

    private func refresh() {
        monthTitle = DayFormat.monthAndYear(shownMonth, calendar: calendar, locale: locale)
        summary = StatsSummary(
            stats: .calculate(days: shownDays, today: today),
            previousEarned: previousEarned,
            month: shownMonth,
            isFinished: canShowNextMonth,
            calendar: calendar,
            locale: locale
        )
    }
}
