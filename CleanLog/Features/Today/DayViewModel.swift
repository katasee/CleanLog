import Foundation
import Observation

@Observable @MainActor
final class DayViewModel {
    private let day: DayKey
    private let workDays: any WorkDayRepository
    private let apartments: any ApartmentRepository
    private let locale: Locale
    private var workDay: WorkDay?
    private var template: [Apartment] = []

    let header: DayHeader
    let kind: DayKind
    private(set) var rows: [DayRow] = []
    private(set) var cleanedCountText = ""

    init(
        day: DayKey,
        today: DayKey,
        workDays: any WorkDayRepository,
        apartments: any ApartmentRepository,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.day = day
        self.workDays = workDays
        self.apartments = apartments
        self.locale = locale
        kind = day.kind(relativeTo: today)
        header = DayHeader(
            day: day,
            kind: kind,
            calendar: calendar,
            locale: locale
        )
    }

    var canTick: Bool {
        kind != .future
    }

    var showsEmptyState: Bool {
        workDay != nil && rows.isEmpty
    }

    var emptyTitle: String {
        String(localized: kind == .today ? .todayEmptyTitleToday : .todayEmptyTitleOther, locale: locale)
    }

    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask { await self.observeDay() }
            group.addTask { await self.observeTemplate() }
        }
    }

    private func observeDay() async {
        for await workDay in workDays.day(day) {
            self.workDay = workDay
            refresh()
        }
    }

    private func observeTemplate() async {
        for await template in apartments.apartments() {
            self.template = template
            refresh()
        }
    }

    private func refresh() {
        guard let workDay else { return }
        rows = workDay.entries.map { DayRow($0, template: template) }
        cleanedCountText = String(
            localized: .todayListProgress(workDay.cleanedCount, workDay.entries.count),
            locale: locale
        )
    }
}
