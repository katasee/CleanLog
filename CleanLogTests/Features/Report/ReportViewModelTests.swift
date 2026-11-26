import Foundation
import Testing

@testable import CleanLog

struct ReportViewModelTests {
    private let today = DayKey(year: 2026, month: 11, day: 25)
    private let november = MonthKey(year: 2026, month: 11)
    private let december2025 = MonthKey(year: 2025, month: 12)
    private let nov3 = DayKey(year: 2026, month: 11, day: 3)
    private let nov4 = DayKey(year: 2026, month: 11, day: 4)
    private let nov5 = DayKey(year: 2026, month: 11, day: 5)
    private let a100 = Apartment.fixture("100")
    private let a101 = Apartment.fixture("101")
    private let a102 = Apartment.fixture("102")
    private let a155 = Apartment.fixture("155", separate: true)

    private var novemberDays: [WorkDay] {
        [.fixture(nov3, ticked: [a100, a101, a155]), .fixture(nov4, ticked: [a100])]
    }

    private func makeViewModel(
        month: MonthKey? = nil,
        workDays: any WorkDayRepository = FakeWorkDayRepository(),
        urlAvailability: any URLAvailability = FakeURLAvailability(),
        pasteboard: any Pasteboard = FakePasteboard(),
        confirmationDuration: Duration = .seconds(2),
        locale: Locale = Locale(identifier: "uk_UA")
    ) -> ReportViewModel {
        ReportViewModel(
            month: month ?? november,
            today: today,
            workDays: workDays,
            urlAvailability: urlAvailability,
            pasteboard: pasteboard,
            confirmationDuration: confirmationDuration,
            calendar: .warsaw,
            locale: locale
        )
    }

    private func observing(
        _ viewModel: ReportViewModel,
        _ body: () async throws -> Void
    ) async rethrows {
        let observation = Task { await viewModel.observe() }
        defer { observation.cancel() }
        try await body()
    }

    @Test func buildsTheTitleAndSubtitle() async {
        let viewModel = makeViewModel(workDays: FakeWorkDayRepository(novemberDays))

        await observing(viewModel) {
            await eventually { viewModel.hasReport }
            #expect(viewModel.title == "Звіт за листопад")
            #expect(viewModel.subtitle == "2 дні · 4 квартири")
            #expect(viewModel.text == ReportBuilder.report(for: november, days: novemberDays))
        }
    }

    @Test func titleCarriesTheYearOfAnotherYear() {
        let viewModel = makeViewModel(month: december2025)
        #expect(viewModel.title == "Звіт за грудень 2025\u{202F}р.")
    }

    @Test func buildsTheEnglishTitle() async {
        let viewModel = makeViewModel(
            workDays: FakeWorkDayRepository(novemberDays),
            locale: Locale(identifier: "en_US")
        )

        await observing(viewModel) {
            await eventually { viewModel.hasReport }
            #expect(viewModel.title == "November report")
            #expect(viewModel.subtitle == "2 days · 4 apartments")
        }
    }

    @Test func emptyMonthDisablesBothActions() {
        let viewModel = makeViewModel()
        #expect(viewModel.hasReport == false)
        #expect(viewModel.text.isEmpty)
        #expect(viewModel.subtitle == "0 днів · 0 квартир")
    }

    @Test func followsTheStore() async throws {
        let workDays = FakeWorkDayRepository(novemberDays)
        let viewModel = makeViewModel(workDays: workDays)

        try await observing(viewModel) {
            await eventually { viewModel.hasReport }
            try await workDays.update(nov5) { day in
                let planned = day.planning([a102])
                return try planned.settingCleaned(
                    planned.entries[0].id,
                    to: true,
                    now: .warsaw(2026, 11, 25, 10),
                    today: today
                )
            }
            await eventually { viewModel.text.contains("5.11-(102)") }
            #expect(viewModel.subtitle == "3 дні · 5 квартир")
        }
    }

    @Test func sendsToWhatsAppWhenItIsInstalled() async {
        let viewModel = makeViewModel(workDays: FakeWorkDayRepository(novemberDays))

        await observing(viewModel) {
            await eventually { viewModel.hasReport }
            #expect(viewModel.sendAction == .whatsApp(WhatsAppLink.url(for: viewModel.text)))
        }
    }

    @Test func sharesTheTextWithoutWhatsApp() async {
        let viewModel = makeViewModel(
            workDays: FakeWorkDayRepository(novemberDays),
            urlAvailability: FakeURLAvailability(isAvailable: false)
        )

        await observing(viewModel) {
            await eventually { viewModel.hasReport }
            #expect(viewModel.sendAction == .share(viewModel.text))
        }
    }

    @Test func copyPutsTheExactTextOnThePasteboard() async {
        let pasteboard = FakePasteboard()
        let viewModel = makeViewModel(workDays: FakeWorkDayRepository(novemberDays), pasteboard: pasteboard)

        await observing(viewModel) {
            await eventually { viewModel.hasReport }
            viewModel.copy()
            #expect(pasteboard.copied == [viewModel.text])
            #expect(viewModel.isCopied)
            #expect(viewModel.copyCount == 1)
        }
    }

    @Test func confirmationEndsAfterItsDuration() async {
        let viewModel = makeViewModel(confirmationDuration: .zero)
        viewModel.copy()
        await viewModel.holdConfirmation()
        #expect(viewModel.isCopied == false)
    }

    @Test func copyingAgainRestartsTheConfirmation() async {
        let viewModel = makeViewModel(confirmationDuration: .seconds(3600))
        viewModel.copy()
        let firstHold = Task { await viewModel.holdConfirmation() }
        firstHold.cancel()
        await firstHold.value
        #expect(viewModel.isCopied)
        viewModel.copy()
        #expect(viewModel.isCopied)
        #expect(viewModel.copyCount == 2)
    }
}
