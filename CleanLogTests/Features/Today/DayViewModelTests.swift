import Foundation
import Testing

@testable import CleanLog

struct DayViewModelTests {
    private let today = DayKey(year: 2026, month: 11, day: 13)
    private let yesterday = DayKey(year: 2026, month: 11, day: 12)
    private let tomorrow = DayKey(year: 2026, month: 11, day: 14)
    private let a28 = Apartment.fixture("100")
    private let a56 = Apartment.fixture("106", minorUnits: 5600, separate: true)

    private func makeViewModel(
        day: DayKey,
        days: [WorkDay] = [],
        apartments: FakeApartmentRepository = FakeApartmentRepository(),
        locale: Locale = Locale(identifier: "uk_UA")
    ) -> DayViewModel {
        DayViewModel(
            day: day,
            today: today,
            workDays: FakeWorkDayRepository(days),
            apartments: apartments,
            now: { .warsaw(2026, 11, 13, 9) },
            calendar: .warsaw,
            locale: locale
        )
    }

    private func at(_ hour: Int, _ minute: Int = 0) -> Date {
        .warsaw(2026, 11, 13, hour, minute)
    }

    private func observing(
        _ viewModel: DayViewModel,
        _ body: () async throws -> Void
    ) async rethrows {
        let task = Task { await viewModel.observe() }
        defer { task.cancel() }
        await eventually { viewModel.showsEmptyState || !viewModel.rows.isEmpty }
        try await body()
    }

    @Test func titlesTodayAndOtherDays() {
        let todayHeader = makeViewModel(day: today).header
        #expect(
            todayHeader
                == DayHeader(
                    title: "Сьогодні",
                    subtitle: "Пʼятниця, 13 листопада",
                    isToday: true
                )
        )

        let pastHeader = makeViewModel(day: yesterday).header
        #expect(
            pastHeader
                == DayHeader(
                    title: "12 листопада",
                    subtitle: "Четвер · минулий день",
                    isToday: false
                )
        )

        let futureHeader = makeViewModel(day: tomorrow).header
        #expect(
            futureHeader
                == DayHeader(
                    title: "14 листопада",
                    subtitle: "Субота · майбутній день",
                    isToday: false
                )
        )
    }

    @Test func titlesInTheGivenLanguage() {
        let viewModel = makeViewModel(day: yesterday, locale: Locale(identifier: "en_US"))
        #expect(
            viewModel.header
                == DayHeader(
                    title: "November 12",
                    subtitle: "Thursday · past day",
                    isToday: false
                )
        )
    }

    @Test func listsRowsWithTheTemplateAccessCode() async {
        var withCode = Apartment.fixture("100")
        withCode.accessCode = "4821"
        let deleted = Apartment.fixture("101")
        let day = WorkDay.fixture(today, ticked: [deleted], unticked: [withCode])
        let viewModel = makeViewModel(
            day: today,
            days: [day],
            apartments: FakeApartmentRepository([withCode])
        )

        await observing(viewModel) {
            await eventually { viewModel.rows.last?.accessCode == "4821" }
            #expect(
                viewModel.rows == [
                    DayRow(
                        id: day.entries[0].id,
                        name: "101",
                        accessCode: nil,
                        isReportedSeparately: false,
                        isCleaned: true
                    ),
                    DayRow(
                        id: day.entries[1].id,
                        name: "100",
                        accessCode: "4821",
                        isReportedSeparately: false,
                        isCleaned: false
                    ),
                ]
            )
            #expect(viewModel.cleanedCountText == "1 з 2 прибрано")
            #expect(!viewModel.showsEmptyState)
        }
    }

    @Test func summarizesToday() async {
        let otherA28 = Apartment.fixture("101")
        let viewModel = makeViewModel(
            day: today,
            days: [
                .fixture(DayKey(year: 2026, month: 11, day: 5), ticked: [a28, otherA28]),
                .fixture(today, ticked: [a28], unticked: [a56]),
            ],
            apartments: FakeApartmentRepository([a28, a56, otherA28])
        )
        let expected = DaySummary.today(
            TodaySummary(
                earned: "28\u{00A0}zł",
                planned: "з 84\u{00A0}zł",
                progress: 1.0 / 3,
                month: "Листопад",
                monthEarned: "84\u{00A0}zł",
                monthCount: "3 квартири"
            )
        )

        await observing(viewModel) {
            await eventually { viewModel.summary == expected }
        }
    }

    @Test func summarizesPastAndFutureDays() async {
        let past = makeViewModel(
            day: yesterday,
            days: [.fixture(yesterday, ticked: [a28], unticked: [a56])]
        )
        await observing(past) {
            #expect(past.summary == .past(earned: "28\u{00A0}zł"))
        }

        let future = makeViewModel(
            day: tomorrow,
            days: [.fixture(tomorrow, ticked: [], unticked: [a28, a56])]
        )
        await observing(future) {
            #expect(future.summary == .future(planned: "84\u{00A0}zł"))
        }
    }

    @Test func offersTheCopyWithTheFilteredCount() async {
        let a100 = Apartment.fixture("100")
        let a101 = Apartment.fixture("101")
        let a102 = Apartment.fixture("102")
        let viewModel = makeViewModel(
            day: today,
            days: [.fixture(yesterday, ticked: [a100, a101, a102])],
            apartments: FakeApartmentRepository([a100, a102])
        )

        await observing(viewModel) {
            #expect(viewModel.showsEmptyState)
            #expect(viewModel.emptyTitle == "Які квартири сьогодні?")
            await eventually { viewModel.copyOffer == CopyOffer(count: 2, text: "Як учора · 2 квартири") }
        }
    }

    @Test func offersNoCopyWhenNothingRemains() async throws {
        let a101 = Apartment.fixture("101")
        let apartments = FakeApartmentRepository([a28, a101])
        let viewModel = makeViewModel(
            day: today,
            days: [.fixture(yesterday, ticked: [a101])],
            apartments: apartments
        )

        try await observing(viewModel) {
            await eventually { viewModel.copyOffer?.count == 1 }
            try await apartments.delete(a101.id)
            await eventually { viewModel.copyOffer == nil }
        }
    }

    @Test func showsTheEmptyStateOnlyOnceLoaded() async {
        let viewModel = makeViewModel(day: today)
        #expect(!viewModel.showsEmptyState)

        await observing(viewModel) {
            #expect(viewModel.showsEmptyState)
            #expect(viewModel.emptyTitle == "Які квартири сьогодні?")
        }
    }

    @Test func titlesTheEmptyStateOfAnotherDay() async {
        let viewModel = makeViewModel(day: yesterday)

        await observing(viewModel) {
            #expect(viewModel.showsEmptyState)
            #expect(viewModel.emptyTitle == "Квартир на цей день немає")
        }
    }

    @Test func showsEveryTodayTimerState() async throws {
        let planned = WorkDay.fixture(today, ticked: [], unticked: [a28])
        let running = try planned.startingTimer(at: at(7, 30), today: today)
        let paused = try running.pausingTimer(at: at(8, 45), today: today)
        let finished = try paused.startingTimer(at: at(9, 10), today: today)
            .finishingTimer(at: at(13, 5), today: today)
        let expectations: [(WorkDay, DayTimer)] = [
            (planned, .idle),
            (running, .running(status: "Працюю · з 07:30")),
            (paused, .paused),
            (finished, .finished(total: "5:10", span: "07:30 – 13:05 · пауза 25 хв")),
        ]

        for (workDay, expected) in expectations {
            let viewModel = makeViewModel(day: today, days: [workDay])
            await observing(viewModel) {
                #expect(viewModel.timer == expected)
            }
        }
    }

    @Test func showsAPastDayTotal() async throws {
        let workDay = try WorkDay.fixture(yesterday, ticked: [a28])
            .startingTimer(at: .warsaw(2026, 11, 12, 8), today: yesterday)
            .finishingTimer(at: .warsaw(2026, 11, 12, 10, 15), today: yesterday)
        let viewModel = makeViewModel(day: yesterday, days: [workDay])

        await observing(viewModel) {
            #expect(viewModel.timer == .past(total: "2:15", span: "08:00 – 10:15"))
            #expect(viewModel.droppedNote == nil)
        }
    }

    @Test func showsTheDroppedNote() async throws {
        let workDay = try WorkDay.fixture(yesterday, ticked: [a28])
            .startingTimer(at: .warsaw(2026, 11, 12, 8), today: yesterday)
            .droppingOverrunTimer(today: today)
        let viewModel = makeViewModel(day: yesterday, days: [workDay])

        await observing(viewModel) {
            #expect(viewModel.timer == .past(total: "0:00", span: nil))
            #expect(viewModel.droppedNote == "Час не записано — таймер не зупинили")
        }
    }

    @Test func hasNoTimerOnAFutureDay() async {
        let viewModel = makeViewModel(
            day: tomorrow,
            days: [.fixture(tomorrow, ticked: [], unticked: [a28])]
        )

        await observing(viewModel) {
            #expect(viewModel.timer == nil)
        }
    }

    @Test func formatsTheTickingClock() async throws {
        let workDay = try WorkDay.fixture(today, ticked: [], unticked: [a28])
            .startingTimer(at: at(7, 30), today: today)
            .pausingTimer(at: at(10), today: today)
            .startingTimer(at: at(10, 25), today: today)
        let viewModel = makeViewModel(day: today, days: [workDay])

        await observing(viewModel) {
            #expect(viewModel.timerText(at: at(11, 25)) == "3:30:00")
        }
    }

    @Test func cannotTickAFutureDay() {
        #expect(makeViewModel(day: yesterday).canTick)
        #expect(makeViewModel(day: today).canTick)
        #expect(!makeViewModel(day: tomorrow).canTick)
    }
}
