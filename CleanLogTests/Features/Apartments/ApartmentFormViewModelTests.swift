import Foundation
import Testing

@testable import CleanLog

struct ApartmentFormViewModelTests {
    private let a100 = Apartment.fixture("100")
    private let a6piw = Apartment.fixture("6piw")
    private let repository: FakeApartmentRepository

    init() {
        repository = FakeApartmentRepository([a100, a6piw])
    }

    private func makeForm(editing apartment: Apartment?) -> ApartmentFormViewModel {
        ApartmentFormViewModel(
            repository: repository,
            editing: apartment,
            locale: Locale(identifier: "uk_UA")
        )
    }

    private func stored(_ name: String) async -> Apartment? {
        var stream = repository.apartments().makeAsyncIterator()
        return await stream.next()?.first { $0.name == name }
    }

    @Test func startsBlankForANewApartment() {
        let form = makeForm(editing: nil)

        #expect(form.title == String(localized: .apartmentsFormTitleNew))
        #expect(form.name.isEmpty)
        #expect(form.priceText.isEmpty)
        #expect(form.accessCode.isEmpty)
        #expect(!form.isReportedSeparately)
        #expect(!form.canSave)
    }

    @Test func prefillsAnEditedApartment() {
        var apartment = Apartment.fixture("100", minorUnits: 2850, separate: true)
        apartment.accessCode = "4821"

        let form = makeForm(editing: apartment)

        #expect(form.title == "100")
        #expect(form.name == "100")
        #expect(form.priceText == "28,50")
        #expect(form.accessCode == "4821")
        #expect(form.isReportedSeparately)
        #expect(form.canSave)
    }

    @Test(arguments: [
        ("   ", "28", false), ("106", "", false), ("106", "28,505", false), ("106", "56", true), ("106", "0", true),
    ])
    func enablesSaveForAValidForm(name: String, price: String, canSave: Bool) {
        let form = makeForm(editing: nil)
        form.name = name
        form.priceText = price
        #expect(form.canSave == canSave)
    }

    @Test func addsANewApartment() async throws {
        let form = makeForm(editing: nil)
        form.name = " 106 "
        form.priceText = "56"
        form.accessCode = "  "
        form.isReportedSeparately = true

        #expect(await form.save())

        let added = try #require(await stored("106"))
        #expect(added.price == Money(minorUnits: 5600))
        #expect(added.isReportedSeparately)
        #expect(added.accessCode == nil)
    }

    @Test func updatesAnEditedApartment() async throws {
        let form = makeForm(editing: a100)
        form.priceText = "30"
        form.accessCode = "4821"

        #expect(await form.save())

        let updated = try #require(await stored("100"))
        #expect(updated.id == a100.id)
        #expect(updated.price == Money(minorUnits: 3000))
        #expect(updated.accessCode == "4821")
    }

    @Test func refusesToSaveAnInvalidForm() async {
        let form = makeForm(editing: nil)
        form.name = "106"

        #expect(await !form.save())
        #expect(await stored("106") == nil)
    }

    @Test func keepsTheSheetOpenOnADuplicateName() async {
        let form = makeForm(editing: nil)
        form.name = "6PIW"
        form.priceText = "28"

        #expect(await !form.save())
        #expect(form.nameError != nil)
        #expect(form.errorMessage == nil)

        form.name = "7piw"
        #expect(form.nameError == nil)
    }

    @Test func reportsAFailedUpdate() async throws {
        let form = makeForm(editing: a100)
        try await repository.delete(a100.id)

        #expect(await !form.save())
        #expect(form.errorMessage != nil)
        #expect(form.isShowingError)
        #expect(form.nameError == nil)

        form.isShowingError = false
        #expect(form.errorMessage == nil)
    }

    @Test func savesOnce() async {
        let form = ApartmentFormViewModel(repository: YieldingApartmentRepository([]), editing: nil)
        form.name = "106"
        form.priceText = "56"

        async let first = form.save()
        async let second = form.save()
        let results = await [first, second]

        #expect(results.filter { $0 }.count == 1)
        #expect(form.errorMessage == nil)
        #expect(form.nameError == nil)
    }
}
