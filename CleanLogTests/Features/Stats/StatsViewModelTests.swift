import Foundation
import Testing

@testable import CleanLog

struct StatsViewModelTests {
    private let today = DayKey(year: 2026, month: 11, day: 25)
    private let november = MonthKey(year: 2026, month: 11)
    private let october = MonthKey(year: 2026, month: 10)
    private let nov3 = DayKey(year: 2026, month: 11, day: 3)
    private let oct5 = DayKey(year: 2026, month: 10, day: 5)
    private let sep10 = DayKey(year: 2026, month: 9, day: 10)
    private let a100 = Apartment.fixture("100")
    private let a101 = Apartment.fixture("101")

    private func makeViewModel(_ days: [WorkDay] = []) -> StatsViewModel {
        makeViewModel(workDays: FakeWorkDayRepository(days))
    }

    private func makeViewModel(workDays: any WorkDayRepository) -> StatsViewModel {
        StatsViewModel(
            today: today,
            workDays: workDays,
            calendar: .warsaw,
            locale: Locale(identifier: "uk_UA")
        )
    }

    private func observing(
        _ viewModel: StatsViewModel,
        _ body: () async throws -> Void
    ) async rethrows {
        let month = Task { await viewModel.observeMonth() }
        let previousMonth = Task { await viewModel.observePreviousMonth() }
        defer {
            month.cancel()
            previousMonth.cancel()
        }
        try await body()
    }

    @Test func opensOnTheCurrentMonth() {
        let viewModel = makeViewModel()
        #expect(viewModel.shownMonth == november)
        #expect(viewModel.monthTitle == "Листопад 2026\u{202F}р.")
        #expect(viewModel.canShowNextMonth == false)
    }

    @Test func goesNoFurtherThanTheCurrentMonth() {
        let viewModel = makeViewModel()
        viewModel.showNextMonth()
        #expect(viewModel.shownMonth == november)

        viewModel.showPreviousMonth()
        #expect(viewModel.shownMonth == october)
        #expect(viewModel.monthTitle == "Жовтень 2026\u{202F}р.")
        #expect(viewModel.canShowNextMonth)

        viewModel.showNextMonth()
        #expect(viewModel.shownMonth == november)
    }

    @Test func summarizesTheShownMonth() async {
        let viewModel = makeViewModel([.fixture(nov3, ticked: [a100, a101])])

        await observing(viewModel) {
            await eventually { viewModel.summary.cleanedText == "2" }
            #expect(viewModel.summary.earnedText == "56\u{00A0}zł")
        }
    }

    @Test func showsTheChangeOnAFinishedMonth() async {
        let viewModel = makeViewModel([.fixture(oct5, ticked: [a100, a101]), .fixture(sep10, ticked: [a100])])
        viewModel.showPreviousMonth()

        await observing(viewModel) {
            await eventually { viewModel.summary.changeText == "↑ 100% до вересня" }
        }
    }

    @Test func hidesTheChangeOnTheCurrentMonth() async {
        let viewModel = makeViewModel([.fixture(nov3, ticked: [a100, a101]), .fixture(oct5, ticked: [a100])])

        await observing(viewModel) {
            await eventually { viewModel.summary.cleanedText == "2" }
            #expect(viewModel.summary.changeText == nil)
        }
    }

    @Test func pagingClearsTheOldMonth() async {
        let viewModel = makeViewModel([.fixture(nov3, ticked: [a100, a101]), .fixture(oct5, ticked: [a100])])

        await observing(viewModel) {
            await eventually { viewModel.summary.cleanedText == "2" }
            viewModel.showPreviousMonth()
            #expect(viewModel.summary.cleanedText == "0")
            #expect(viewModel.summary.changeText == nil)
        }
    }

    @Test func followsATick() async throws {
        let workDays = FakeWorkDayRepository([.fixture(nov3, ticked: [a100], unticked: [a101])])
        let viewModel = makeViewModel(workDays: workDays)

        try await observing(viewModel) {
            await eventually { viewModel.summary.cleanedText == "1" }
            try await workDays.update(nov3) { day in
                try day.settingCleaned(day.entries[1].id, to: true, now: .warsaw(2026, 11, 25, 10), today: today)
            }
            await eventually { viewModel.summary.cleanedText == "2" }
        }
    }

    @Test func leavesTodaysUnfinishedTimeOut() async {
        var running = WorkDay.fixture(today, ticked: [a100])
        running.sessions = [WorkSession(id: UUID(), start: .warsaw(2026, 11, 25, 8), end: nil)]
        let viewModel = makeViewModel([running])

        await observing(viewModel) {
            await eventually { viewModel.summary.cleanedText == "1" }
            #expect(viewModel.summary.workedText == "0 год")
            #expect(viewModel.summary.perHourText == "—")
        }
    }

    @Test func advancingIntoANewMonthKeepsTheShownMonth() async {
        let viewModel = makeViewModel([.fixture(nov3, ticked: [a100, a101]), .fixture(oct5, ticked: [a100])])

        await observing(viewModel) {
            await eventually { viewModel.summary.cleanedText == "2" }
            viewModel.advance(to: DayKey(year: 2026, month: 12, day: 1))
            #expect(viewModel.shownMonth == november)
            #expect(viewModel.canShowNextMonth)
            await eventually { viewModel.summary.changeText == "↑ 100% до жовтня" }
        }
    }
}
