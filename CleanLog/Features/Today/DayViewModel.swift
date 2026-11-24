import Foundation
import Observation
import os

@Observable @MainActor
final class DayViewModel {
    private let day: DayKey
    private let today: DayKey
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
    private(set) var timer: DayTimer?
    private(set) var droppedNote: String?
    private(set) var errorMessage: String?

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
        self.today = today
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

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    var manualDurationParts: DurationParts {
        DurationParts(roundingDown: workDay?.workedDuration(now: now()) ?? .zero)
    }

    func timerText(at date: Date) -> String {
        DurationFormat.clock(workDay?.workedDuration(now: date) ?? .zero)
    }

    func startTimer() async {
        let now = now()
        await perform { try $0.startingTimer(at: now, today: today) }
    }

    func pauseTimer() async {
        let now = now()
        await perform { try $0.pausingTimer(at: now, today: today) }
    }

    func finishTimer() async {
        let now = now()
        await perform { try $0.finishingTimer(at: now, today: today) }
    }

    func setManualDuration(_ parts: DurationParts) async {
        await perform { $0.settingManualDuration(parts.duration) }
    }

    func resetManualDuration() async {
        await perform { $0.settingManualDuration(nil) }
    }

    func setCleaned(_ id: DayEntry.ID, to isCleaned: Bool) async {
        let now = now()
        await perform { workDay in
            try workDay.settingCleaned(
                id,
                to: isCleaned,
                now: now,
                today: today
            )
        }
    }

    func remove(_ id: DayEntry.ID) async {
        await perform { $0.removingEntry(id) }
    }

    func copyPlan() async {
        guard let copySource else { return }
        await perform { $0.copyingPlan(from: copySource, template: template) }
    }

    func observe() async {
        if kind == .today {
            await dropOverrunTimers()
        }
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

    private func dropOverrunTimers() async {
        do {
            for overrun in try await workDays.daysWithOpenSession(before: today) {
                try await workDays.update(overrun.day) { $0.droppingOverrunTimer(today: today) }
            }
        } catch {
            showSaveError("Could not drop the overrun timers", error)
        }
    }

    private func perform(_ change: (WorkDay) throws -> WorkDay) async {
        do {
            try await workDays.update(day, change)
        } catch {
            showSaveError("Could not save the day", error)
        }
    }

    private func showSaveError(_ action: String, _ error: any Error) {
        logger.error("\(action): \(error)")
        errorMessage = String(localized: .todayErrorSave, locale: locale)
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
        timer = DayTimer(
            workDay,
            kind: kind,
            now: now(),
            calendar: calendar,
            locale: locale
        )
        droppedNote = workDay.isTimeDropped ? String(localized: .todayTimerDropped, locale: locale) : nil
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
