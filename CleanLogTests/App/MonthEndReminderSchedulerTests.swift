import Foundation
import Testing

@testable import CleanLog

struct MonthEndReminderSchedulerTests {
    private let november = MonthKey(year: 2026, month: 11)
    private let nov3 = DayKey(year: 2026, month: 11, day: 3)
    private let nov26 = DayKey(year: 2026, month: 11, day: 26)
    private let a100 = Apartment.fixture("100")
    private let on = MonthEndReminderSettings(isOn: true, time: ReminderTime(hour: 18, minute: 0))

    private let lastDayAtSix = DateComponents(
        year: 2026,
        month: 11,
        day: 30,
        hour: 18,
        minute: 0
    )

    private func makeScheduler(
        _ center: any ReminderCenter,
        settings: FakeSettingsRepository? = nil,
        workDays: FakeWorkDayRepository? = nil,
        now: Date = .warsaw(2026, 11, 26, 9)
    ) -> MonthEndReminderScheduler {
        MonthEndReminderScheduler(
            settings: settings ?? FakeSettingsRepository(on),
            workDays: workDays ?? FakeWorkDayRepository([.fixture(nov3, ticked: [a100])]),
            center: center,
            now: { now },
            calendar: .warsaw,
            locale: Locale(identifier: "uk_UA")
        )
    }

    private func observing(
        _ scheduler: MonthEndReminderScheduler,
        _ body: () async throws -> Void
    ) async rethrows {
        let settings = Task { await scheduler.observeSettings() }
        let days = Task { await scheduler.observeDays(in: november) }
        defer {
            settings.cancel()
            days.cancel()
        }
        try await body()
    }

    @Test func schedulesTheLastDayAtTheChosenTime() async {
        let center = FakeReminderCenter()
        let scheduler = makeScheduler(center)

        await observing(scheduler) {
            await eventually { center.pending != nil }
            #expect(center.pending?.fireDate == lastDayAtSix)
            #expect(center.pending?.month == november)
        }
    }

    @Test func cancelsWhenTurnedOff() async throws {
        let settings = FakeSettingsRepository(on)
        let center = FakeReminderCenter()
        let scheduler = makeScheduler(center, settings: settings)

        try await observing(scheduler) {
            await eventually { center.pending != nil }
            try await settings.saveMonthEndReminder(.initial)
            await eventually { center.pending == nil }
        }
    }

    @Test func cancelsWhenTheMonthHasNothingCleaned() async {
        let center = FakeReminderCenter()
        let scheduler = makeScheduler(center, workDays: FakeWorkDayRepository())

        await observing(scheduler) {
            await eventually { center.cancelCount > 0 }
            #expect(center.scheduleCount == 0)
        }
    }

    @Test func reschedulesWhenTheTimeChanges() async throws {
        let settings = FakeSettingsRepository(on)
        let center = FakeReminderCenter()
        let scheduler = makeScheduler(center, settings: settings)

        try await observing(scheduler) {
            await eventually { center.pending != nil }
            try await settings.saveMonthEndReminder(.init(isOn: true, time: .init(hour: 20, minute: 15)))
            await eventually { center.pending?.fireDate.hour == 20 }
            #expect(center.pending?.fireDate.minute == 15)
        }
    }

    @Test func schedulesOnceTheFirstApartmentIsTicked() async throws {
        let workDays = FakeWorkDayRepository()
        let center = FakeReminderCenter()
        let scheduler = makeScheduler(center, workDays: workDays)

        try await observing(scheduler) {
            await eventually { center.cancelCount > 0 }
            try await workDays.update(nov26) { _ in .fixture(nov26, ticked: [a100]) }
            await eventually { center.pending != nil }
        }
    }

    @Test func cancelsOnceTheMomentHasPassed() async {
        let center = FakeReminderCenter()
        let scheduler = makeScheduler(center, now: .warsaw(2026, 11, 30, 18, 30))

        await observing(scheduler) {
            await eventually { center.cancelCount > 0 }
            #expect(center.scheduleCount == 0)
        }
    }

    @Test func latestStateWinsOverARequestBeingAdded() async throws {
        let settings = FakeSettingsRepository(on)
        let center = GatedReminderCenter()
        let scheduler = makeScheduler(center, settings: settings)

        try await observing(scheduler) {
            await eventually { center.hasWaitingSchedule }
            try await settings.saveMonthEndReminder(.initial)
            center.open()
            await eventually { center.events == [.scheduled, .cancelled] }
            #expect(center.pending == nil)
        }
    }
}
