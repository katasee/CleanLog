import Foundation
import Testing

@testable import CleanLog

struct DayViewModelTests {
    private let today = DayKey(year: 2026, month: 11, day: 13)
    private let yesterday = DayKey(year: 2026, month: 11, day: 12)
    private let tomorrow = DayKey(year: 2026, month: 11, day: 14)

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
            calendar: .warsaw,
            locale: locale
        )
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
        #expect(todayHeader == DayHeader(title: "Сьогодні", subtitle: "Пʼятниця, 13 листопада", isToday: true))

        let pastHeader = makeViewModel(day: yesterday).header
        #expect(pastHeader == DayHeader(title: "12 листопада", subtitle: "Четвер · минулий день", isToday: false))

        let futureHeader = makeViewModel(day: tomorrow).header
        #expect(futureHeader == DayHeader(title: "14 листопада", subtitle: "Субота · майбутній день", isToday: false))
    }

    @Test func titlesInTheGivenLanguage() {
        let viewModel = makeViewModel(day: yesterday, locale: Locale(identifier: "en_US"))
        #expect(viewModel.header == DayHeader(title: "November 12", subtitle: "Thursday · past day", isToday: false))
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

    @Test func cannotTickAFutureDay() {
        #expect(makeViewModel(day: yesterday).canTick)
        #expect(makeViewModel(day: today).canTick)
        #expect(!makeViewModel(day: tomorrow).canTick)
    }
}
