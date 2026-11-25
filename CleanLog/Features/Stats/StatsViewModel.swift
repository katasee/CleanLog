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
    private(set) var monthTitle: String
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
        summary = Self.summary(
            of: [],
            previousEarned: nil,
            month: today.monthKey,
            today: today,
            calendar: calendar,
            locale: locale
        )
        monthTitle = DayFormat.monthAndYear(today.monthKey, calendar: calendar, locale: locale)
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
        summary = Self.summary(
            of: shownDays,
            previousEarned: previousEarned,
            month: shownMonth,
            today: today,
            calendar: calendar,
            locale: locale
        )
    }

    private static func summary(
        of days: [WorkDay],
        previousEarned: Money?,
        month: MonthKey,
        today: DayKey,
        calendar: Calendar,
        locale: Locale
    ) -> StatsSummary {
        StatsSummary(
            stats: .calculate(days: days, today: today),
            previousEarned: previousEarned,
            month: month,
            isFinished: month < today.monthKey,
            calendar: calendar,
            locale: locale
        )
    }
}
