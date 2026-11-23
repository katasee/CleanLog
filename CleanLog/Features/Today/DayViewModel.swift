import Foundation
import Observation
import os

@Observable @MainActor
final class DayViewModel {
    private let day: DayKey
    private let workDays: any WorkDayRepository
    private let apartments: any ApartmentRepository
    private let now: () -> Date
    private let calendar: Calendar
    private let locale: Locale
    private let logger = Logger(subsystem: "CleanLog", category: "DayViewModel")
    private var workDay: WorkDay?
    private var template: [Apartment] = []
    private var monthDays: [WorkDay] = []
    private var copySource: WorkDay?
    private var hasRequestedCopySource = false

    let header: DayHeader
    let kind: DayKind
    private(set) var rows: [DayRow] = []
    private(set) var cleanedCountText = ""
    private(set) var summary: DaySummary?
    private(set) var copyOffer: CopyOffer?

    init(
        day: DayKey,
        today: DayKey,
        workDays: any WorkDayRepository,
        apartments: any ApartmentRepository,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.day = day
        self.workDays = workDays
        self.apartments = apartments
        self.now = now
        self.calendar = calendar
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
            if kind == .today {
                group.addTask { await self.observeMonth() }
            }
        }
    }

    private func observeDay() async {
        for await workDay in workDays.day(day) {
            self.workDay = workDay
            refresh()
            if workDay.entries.isEmpty && !hasRequestedCopySource {
                hasRequestedCopySource = true
                await loadCopySource()
            }
        }
    }

    private func observeTemplate() async {
        for await template in apartments.apartments() {
            self.template = template
            refresh()
        }
    }

    private func observeMonth() async {
        for await monthDays in workDays.days(in: day.monthKey) {
            self.monthDays = monthDays
            refresh()
        }
    }

    private func loadCopySource() async {
        do {
            copySource = try await workDays.latestDayWithEntries(before: day)
        } catch {
            logger.error("Could not read the day to copy: \(error)")
        }
        refresh()
    }

    private func refresh() {
        guard let workDay else { return }
        rows = workDay.entries.map { DayRow($0, template: template) }
        cleanedCountText = String(
            localized: .todayListProgress(workDay.cleanedCount, workDay.entries.count),
            locale: locale
        )
        summary = DaySummary(
            workDay,
            kind: kind,
            month: monthDays,
            now: now(),
            calendar: calendar,
            locale: locale
        )
        copyOffer = copySource.flatMap { source in
            CopyOffer(
                copying: source,
                into: workDay,
                template: template,
                locale: locale
            )
        }
    }
}
