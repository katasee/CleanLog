import Foundation
import Testing

@testable import CleanLog

struct DayPlanViewModelTests {
    private let today = DayKey(year: 2026, month: 11, day: 13)
    private let tomorrow = DayKey(year: 2026, month: 11, day: 14)
    private let a100 = Apartment.fixture("100")
    private let a101 = Apartment.fixture("101")
    private let a106 = Apartment.fixture("106", minorUnits: 5600)

    private var template: [Apartment] {
        [a100, a101, a106]
    }

    private func makeViewModel(
        day: DayKey? = nil,
        template: [Apartment]? = nil,
        planned: [Apartment]? = nil,
        apartments: FakeApartmentRepository? = nil,
        workDays: (any WorkDayRepository)? = nil
    ) -> DayPlanViewModel {
        let day = day ?? today
        let days = [WorkDay.fixture(day, ticked: [], unticked: planned ?? [a100])]
        return DayPlanViewModel(
            day: day,
            today: today,
            apartments: apartments ?? FakeApartmentRepository(template ?? self.template),
            workDays: workDays ?? FakeWorkDayRepository(days),
            calendar: .warsaw,
            locale: Locale(identifier: "uk_UA")
        )
    }

    private func observing(
        _ viewModel: DayPlanViewModel,
        _ body: () async throws -> Void
    ) async rethrows {
        let task = Task { await viewModel.observe() }
        defer { task.cancel() }
        await eventually { !viewModel.tiles.isEmpty || viewModel.emptyMessage != nil }
        try await body()
    }

    private func tile(_ name: String, in viewModel: DayPlanViewModel) -> DayPlanTile? {
        viewModel.tiles.first { $0.name == name }
    }

    @Test func hidesApartmentsAlreadyOnTheDay() async {
        let viewModel = makeViewModel()

        await observing(viewModel) {
            #expect(viewModel.tiles.map(\.name) == ["101", "106"])
            #expect(viewModel.tiles.map(\.priceText) == ["28\u{00A0}zł", "56\u{00A0}zł"])
            #expect(viewModel.emptyMessage == nil)
        }
    }

    @Test func titleNamesTodayOrTheDate() {
        #expect(makeViewModel().title == "Додати на сьогодні")
        #expect(makeViewModel(day: DayKey(year: 2026, month: 11, day: 12)).title == "Додати на 12 листопада")
    }

    @Test func togglingSumsTheSelection() async {
        let viewModel = makeViewModel()

        await observing(viewModel) {
            viewModel.toggleSelection(of: a101.id)
            viewModel.toggleSelection(of: a106.id)

            #expect(viewModel.confirmTitle == "Додати 2 квартири · 84\u{00A0}zł")
            #expect(viewModel.selectedCountText == "обрано 2")
            #expect(tile("101", in: viewModel)?.isSelected == true)
            #expect(viewModel.canConfirm)

            viewModel.toggleSelection(of: a101.id)

            #expect(viewModel.confirmTitle == "Додати 1 квартиру · 56\u{00A0}zł")
            #expect(tile("101", in: viewModel)?.isSelected == false)
        }
    }

    @Test func nothingSelectedCannotConfirm() async {
        let viewModel = makeViewModel()

        await observing(viewModel) {
            #expect(viewModel.confirmTitle == "Обери квартири")
            #expect(!viewModel.canConfirm)
            #expect(viewModel.selectedCountText == nil)
        }
    }

    @Test(arguments: [("10", ["101", "106"]), ("6", ["106"]), (" 101 ", ["101"]), ("", ["101", "106"])])
    func searchFiltersByName(search: String, names: [String]) async {
        let viewModel = makeViewModel()

        await observing(viewModel) {
            viewModel.searchText = search
            #expect(viewModel.tiles.map(\.name) == names)
        }
    }

    @Test func searchKeepsHiddenSelection() async {
        let viewModel = makeViewModel()

        await observing(viewModel) {
            viewModel.toggleSelection(of: a101.id)
            viewModel.searchText = "106"

            #expect(viewModel.tiles.map(\.name) == ["106"])
            #expect(viewModel.confirmTitle == "Додати 1 квартиру · 28\u{00A0}zł")
        }
    }

    @Test func emptyTemplateOffersTheFirstApartment() async {
        let viewModel = makeViewModel(template: [], planned: [])

        await observing(viewModel) {
            #expect(viewModel.emptyMessage == "Створи першу квартиру")
        }
    }

    @Test func everythingPlannedSaysSo() async {
        let viewModel = makeViewModel(planned: template)

        await observing(viewModel) {
            #expect(viewModel.tiles.isEmpty)
            #expect(viewModel.emptyMessage == "Усі квартири вже додані")
        }
    }

    @Test func searchWithoutMatchSaysSo() async {
        let viewModel = makeViewModel()

        await observing(viewModel) {
            viewModel.searchText = "999"
            #expect(viewModel.emptyMessage == "Нічого не знайдено")
        }
    }

    @Test func newApartmentPrefillsAnUnmatchedSearch() async {
        let viewModel = makeViewModel()

        await observing(viewModel) {
            viewModel.searchText = "107"
            viewModel.startNewApartment()
            #expect(viewModel.newApartmentForm?.name == "107")

            viewModel.searchText = "10"
            viewModel.startNewApartment()
            #expect(viewModel.newApartmentForm?.name == "")
        }
    }

    @Test func newApartmentIsSelectedOnceItArrives() async throws {
        let viewModel = makeViewModel()

        try await observing(viewModel) {
            viewModel.startNewApartment()
            let form = try #require(viewModel.newApartmentForm)
            form.name = "107"
            form.priceText = "30"

            #expect(await form.save())

            await eventually { tile("107", in: viewModel)?.isSelected == true }
            #expect(viewModel.confirmTitle == "Додати 1 квартиру · 30\u{00A0}zł")
        }
    }

    @Test func deletedApartmentLeavesTheSum() async throws {
        let apartments = FakeApartmentRepository(template)
        let viewModel = makeViewModel(apartments: apartments)

        try await observing(viewModel) {
            viewModel.toggleSelection(of: a106.id)
            try await apartments.delete(a106.id)

            await eventually { viewModel.confirmTitle == "Обери квартири" }
            #expect(!viewModel.canConfirm)
        }
    }

    @Test func apartmentPlannedElsewhereLeaves() async throws {
        let workDays = FakeWorkDayRepository([.fixture(today, ticked: [], unticked: [a100])])
        let viewModel = makeViewModel(workDays: workDays)

        try await observing(viewModel) {
            viewModel.toggleSelection(of: a101.id)
            try await workDays.update(today) { $0.planning([a101]) }

            await eventually { tile("101", in: viewModel) == nil }
            #expect(viewModel.confirmTitle == "Обери квартири")
        }
    }

    @Test func confirmPlansTheSelectionInTemplateOrder() async throws {
        let workDays = FakeWorkDayRepository([.fixture(today, ticked: [], unticked: [a100])])
        let viewModel = makeViewModel(workDays: workDays)

        try await observing(viewModel) {
            viewModel.toggleSelection(of: a106.id)
            viewModel.toggleSelection(of: a101.id)

            #expect(await viewModel.confirm())

            let day = try #require(await workDays.stored(today))
            #expect(day.entries.map(\.name) == ["100", "101", "106"])
            #expect(day.entries.allSatisfy { !$0.isCleaned })
        }
    }

    @Test func confirmOnAFutureDay() async throws {
        let workDays = FakeWorkDayRepository()
        let viewModel = makeViewModel(day: tomorrow, workDays: workDays)

        try await observing(viewModel) {
            viewModel.toggleSelection(of: a101.id)

            #expect(await viewModel.confirm())

            let day = try #require(await workDays.stored(tomorrow))
            #expect(day.entries.map(\.name) == ["101"])
        }
    }

    @Test func confirmLeavesAFinishedTimerFinished() async throws {
        let finished = try WorkDay.fixture(today, ticked: [a100])
            .startingTimer(at: .warsaw(2026, 11, 13, 8), today: today)
            .finishingTimer(at: .warsaw(2026, 11, 13, 10), today: today)
        let workDays = FakeWorkDayRepository([finished])
        let viewModel = makeViewModel(workDays: workDays)

        try await observing(viewModel) {
            viewModel.toggleSelection(of: a101.id)

            #expect(await viewModel.confirm())

            let day = try #require(await workDays.stored(today))
            #expect(day.isTimerFinished)
            #expect(day.sessions == finished.sessions)
        }
    }

    @Test func failedSaveKeepsTheSelection() async {
        let failing = FailingWorkDayRepository([.fixture(today, ticked: [], unticked: [a100])])
        let viewModel = makeViewModel(workDays: failing)

        await observing(viewModel) {
            viewModel.toggleSelection(of: a101.id)

            #expect(await !viewModel.confirm())
            #expect(viewModel.errorMessage == "Не вдалося додати квартири")
            #expect(viewModel.isShowingError)
            #expect(viewModel.confirmTitle == "Додати 1 квартиру · 28\u{00A0}zł")
            #expect(viewModel.canConfirm)

            viewModel.isShowingError = false
            #expect(viewModel.errorMessage == nil)
        }
    }

    @Test func secondConfirmWhileSavingDoesNothing() async {
        let gated = GatedWorkDayRepository([.fixture(today, ticked: [], unticked: [a100])])
        let viewModel = makeViewModel(workDays: gated)

        await observing(viewModel) {
            viewModel.toggleSelection(of: a101.id)

            let first = Task { await viewModel.confirm() }
            await eventually { gated.updateCount == 1 }
            #expect(!viewModel.canConfirm)
            #expect(await !viewModel.confirm())

            gated.release()
            #expect(await first.value)
            #expect(gated.updateCount == 1)
        }
    }
}
