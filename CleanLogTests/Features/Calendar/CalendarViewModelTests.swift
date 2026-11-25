import Foundation
import Testing

@testable import CleanLog

struct CalendarViewModelTests {
    private let today = DayKey(year: 2026, month: 11, day: 13)
    private let nov6 = DayKey(year: 2026, month: 11, day: 6)
    private let nov12 = DayKey(year: 2026, month: 11, day: 12)
    private let nov14 = DayKey(year: 2026, month: 11, day: 14)
    private let a100 = Apartment.fixture("100")
    private let a101 = Apartment.fixture("101")
    private let a106 = Apartment.fixture("106", minorUnits: 5600)

    private var days: [WorkDay] {
        [
            .fixture(nov6, ticked: [a106]),
            .fixture(nov12, ticked: [], unticked: [a100]),
            .fixture(nov14, ticked: [], unticked: [a100]),
        ]
    }

    private func makeViewModel(
        selected: DayKey? = nil,
        today: DayKey? = nil,
        workDays: (any WorkDayRepository)? = nil
    ) -> CalendarViewModel {
        CalendarViewModel(
            selected: selected ?? nov6,
            today: today ?? self.today,
            workDays: workDays ?? FakeWorkDayRepository(days),
            calendar: .mondayFirst,
            locale: Locale(identifier: "uk_UA")
        )
    }

    private func observingMonth(
        _ viewModel: CalendarViewModel,
        _ body: () async throws -> Void
    ) async rethrows {
        let task = Task { await viewModel.observeMonth() }
        defer { task.cancel() }
        await eventually { viewModel.cell(nov6)?.amountText != nil }
        try await body()
    }

    private func observingSelectedDay(
        _ viewModel: CalendarViewModel,
        _ body: () async throws -> Void
    ) async rethrows {
        let task = Task { await viewModel.observeSelectedDay() }
        defer { task.cancel() }
        await eventually { viewModel.card != nil }
        try await body()
    }

    private func observedCard(
        selected: DayKey,
        days: [WorkDay] = []
    ) async -> CalendarDayCard? {
        let viewModel = makeViewModel(selected: selected, workDays: FakeWorkDayRepository(days))
        var card: CalendarDayCard?
        await observingSelectedDay(viewModel) { card = viewModel.card }
        return card
    }

    @Test func opensOnTheSelectedDaysMonth() {
        let viewModel = makeViewModel(selected: DayKey(year: 2026, month: 10, day: 2))
        #expect(viewModel.shownMonth == MonthKey(year: 2026, month: 10))
        #expect(viewModel.monthTitle == "Жовтень 2026\u{202F}р.")
        #expect(viewModel.weekdaySymbols.first == "пн")
    }

    @Test func laysTheMonthOutInWeeks() {
        let weeks = makeViewModel().weeks
        #expect(weeks.count == 6)
        #expect(weeks[0].prefix(6).allSatisfy { $0 == nil })
        #expect(weeks[0][6]?.numberText == "1")
    }

    @Test func showsEarningsOnlyOnDaysThatEarned() async {
        let viewModel = makeViewModel()

        await observingMonth(viewModel) {
            #expect(viewModel.cell(nov6)?.amountText == "56")
            #expect(viewModel.cell(nov12)?.amountText == nil)
            #expect(viewModel.cell(nov14)?.amountText == nil)
        }
    }

    @Test func marksTodayAndTheSelectedDay() {
        let cells = makeViewModel().weeks.flatMap { $0 }.compactMap { $0 }
        #expect(cells.filter(\.isToday).map(\.day) == [today])
        #expect(cells.filter(\.isSelected).map(\.day) == [nov6])
    }

    @Test func pagingKeepsTheSelection() {
        let viewModel = makeViewModel()
        viewModel.showNextMonth()
        #expect(viewModel.shownMonth == MonthKey(year: 2026, month: 12))
        #expect(viewModel.selected == nov6)
        #expect(viewModel.weeks.flatMap { $0 }.allSatisfy { $0?.isSelected != true })

        viewModel.showPreviousMonth()
        viewModel.showPreviousMonth()
        #expect(viewModel.shownMonth == MonthKey(year: 2026, month: 10))
    }

    @Test func selectingADayInAnotherMonthPagesToIt() {
        let viewModel = makeViewModel()
        let october30 = DayKey(year: 2026, month: 10, day: 30)
        viewModel.select(october30)
        #expect(viewModel.selected == october30)
        #expect(viewModel.shownMonth == MonthKey(year: 2026, month: 10))
        #expect(viewModel.cell(october30)?.isSelected == true)
    }

    @Test func followsATickWhileOpen() async throws {
        let workDays = FakeWorkDayRepository(days)
        let viewModel = makeViewModel(workDays: workDays)

        try await observingMonth(viewModel) {
            try await workDays.update(nov12) { day in
                try day.settingCleaned(day.entries[0].id, to: true, now: .warsaw(2026, 11, 12, 10), today: today)
            }
            await eventually { viewModel.cell(nov12)?.amountText == "28" }
        }
    }

    @Test func readsTheAmountInTheAccessibilityLabel() async {
        let viewModel = makeViewModel()

        await observingMonth(viewModel) {
            #expect(viewModel.cell(nov6)?.accessibilityLabel == "6 листопада, 56\u{00A0}zł")
            #expect(viewModel.cell(nov12)?.accessibilityLabel == "12 листопада")
            #expect(viewModel.cell(today)?.accessibilityLabel == "13 листопада, сьогодні")
        }
    }

    @Test func cardSumsWhatWasCleaned() async {
        let card = await observedCard(selected: nov6, days: [.fixture(nov6, ticked: [a100], unticked: [a101])])
        #expect(card?.summaryText == "1 квартира · 28\u{00A0}zł")
        #expect(card?.dateText == "6 листопада")
    }

    @Test func cardCountsAPlanOnly() async {
        let planned = (0..<5).map { Apartment.fixture("\(110 + $0)") }
        let card = await observedCard(selected: nov14, days: [.fixture(nov14, ticked: [], unticked: planned)])
        #expect(card?.summaryText == "5 квартир")
    }

    @Test func cardCallsAnEmptyDayADayOff() async {
        let card = await observedCard(selected: DayKey(year: 2026, month: 11, day: 20))
        #expect(card?.summaryText == "вихідний")
    }

    @Test func cardNamesToday() async {
        #expect(await observedCard(selected: today)?.weekdayText == "Сьогодні · Пʼятниця")
        #expect(await observedCard(selected: nov12)?.weekdayText == "Четвер")
    }

    @Test func quickPicksAreTodayYesterdayAndAWeekAgo() {
        let picks = makeViewModel(selected: today).quickPicks
        #expect(picks.map(\.day) == [today, nov12, nov6])
        #expect(picks.map(\.title) == ["Сьогодні", "Учора", "Тиждень тому"])
        #expect(picks.map(\.isSelected) == [true, false, false])
    }

    @Test func quickPickPagesToItsMonth() {
        let nov3 = DayKey(year: 2026, month: 11, day: 3)
        let viewModel = makeViewModel(selected: nov3, today: nov3)
        viewModel.select(viewModel.quickPicks[2].day)
        #expect(viewModel.selected == DayKey(year: 2026, month: 10, day: 27))
        #expect(viewModel.shownMonth == MonthKey(year: 2026, month: 10))
        #expect(viewModel.quickPicks[2].isSelected)
    }

    @Test func cardFollowsTheSelectionAcrossMonths() async {
        let viewModel = makeViewModel()

        await observingSelectedDay(viewModel) {
            viewModel.showPreviousMonth()
            #expect(viewModel.card?.dateText == "6 листопада")
        }
    }

    @Test func cardWaitsForTheNewlySelectedDay() async {
        let viewModel = makeViewModel()

        await observingSelectedDay(viewModel) {
            viewModel.select(nov12)
            #expect(viewModel.card == nil)
        }
    }
}

extension CalendarViewModel {
    fileprivate func cell(_ day: DayKey) -> CalendarCell? {
        weeks.flatMap { $0 }.compactMap { $0 }.first { $0.day == day }
    }
}
