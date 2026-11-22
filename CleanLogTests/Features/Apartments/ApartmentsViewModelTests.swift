import Foundation
import Testing

@testable import CleanLog

struct ApartmentsViewModelTests {
    private let a100 = Apartment.fixture("100")
    private let a101 = Apartment.fixture("101")
    private let repository: FakeApartmentRepository
    private let viewModel: ApartmentsViewModel

    init() {
        repository = FakeApartmentRepository([a100, a101])
        viewModel = ApartmentsViewModel(repository: repository, locale: Locale(identifier: "uk_UA"))
    }

    private func observing(
        _ viewModel: ApartmentsViewModel,
        _ body: () async throws -> Void
    ) async rethrows {
        let task = Task { await viewModel.observe() }
        defer { task.cancel() }
        await eventually { viewModel.showsEmptyState || !viewModel.rows.isEmpty }
        try await body()
    }

    @Test func listsRowsInNameOrder() async {
        let repository = FakeApartmentRepository([
            .fixture("6piw"),
            .fixture("106", minorUnits: 5600, separate: true),
            .fixture("54"),
        ])
        let viewModel = ApartmentsViewModel(repository: repository, locale: Locale(identifier: "uk_UA"))

        await observing(viewModel) {
            #expect(viewModel.rows.map(\.name) == ["54", "106", "6piw"])
            #expect(viewModel.rows[1].priceText == "56\u{00A0}zł")
            #expect(viewModel.rows[1].isReportedSeparately)
            #expect(!viewModel.rows[0].isReportedSeparately)
            #expect(viewModel.count == 3)
            #expect(!viewModel.showsEmptyState)
        }
    }

    @Test func showsTheEmptyStateOnlyOnceLoaded() async {
        let viewModel = ApartmentsViewModel(repository: FakeApartmentRepository())
        #expect(!viewModel.showsEmptyState)

        await observing(viewModel) {
            #expect(viewModel.showsEmptyState)
            #expect(viewModel.count == 0)
        }
    }

    @Test func opensTheSheets() async {
        await observing(viewModel) {
            viewModel.add()
            #expect(viewModel.sheet == .new)

            viewModel.edit(a100.id)
            #expect(viewModel.sheet == .edit(a100))

            viewModel.sheet = nil
            viewModel.edit(UUID())
            #expect(viewModel.sheet == nil)
        }
    }

    @Test func makesAFormForTheSheet() {
        let newForm = viewModel.makeFormViewModel(for: .new)
        #expect(newForm.isAdding)
        #expect(newForm.name.isEmpty)

        let editForm = viewModel.makeFormViewModel(for: .edit(a100))
        #expect(!editForm.isAdding)
        #expect(editForm.priceText == "28")
    }

    @Test func deletesOnlyAfterConfirmation() async throws {
        try await observing(viewModel) {
            viewModel.requestDeletion(a100.id)
            #expect(viewModel.pendingDeletion?.name == "100")
            #expect(viewModel.isConfirmingDeletion)

            viewModel.cancelDeletion()
            #expect(viewModel.pendingDeletion == nil)
            #expect(viewModel.rows.count == 2)

            viewModel.requestDeletion(a100.id)
            await viewModel.confirmDeletion(of: try #require(viewModel.pendingDeletion))

            await eventually { viewModel.rows.map(\.name) == ["101"] }
            #expect(viewModel.pendingDeletion == nil)
            #expect(viewModel.errorMessage == nil)
        }
    }

    @Test func deletesTheConfirmedRowAfterTheAlertDismisses() async throws {
        try await observing(viewModel) {
            viewModel.requestDeletion(a100.id)
            let confirmed = try #require(viewModel.pendingDeletion)
            viewModel.isConfirmingDeletion = false

            await viewModel.confirmDeletion(of: confirmed)

            await eventually { viewModel.rows.map(\.name) == ["101"] }
            #expect(viewModel.errorMessage == nil)
        }
    }

    @Test func dismissingTheConfirmationCancelsTheDeletion() async {
        await observing(viewModel) {
            viewModel.requestDeletion(a100.id)
            viewModel.isConfirmingDeletion = false
            #expect(viewModel.pendingDeletion == nil)
        }
    }

    @Test func ignoresADeletionOfAnUnknownApartment() async {
        await observing(viewModel) {
            viewModel.requestDeletion(UUID())
            #expect(viewModel.pendingDeletion == nil)
        }
    }

    @Test func reportsAFailedDeletion() async throws {
        try await observing(viewModel) {
            viewModel.requestDeletion(a100.id)
            let confirmed = try #require(viewModel.pendingDeletion)
            try await repository.delete(a100.id)

            await viewModel.confirmDeletion(of: confirmed)

            #expect(viewModel.errorMessage != nil)
            #expect(viewModel.isShowingError)
            #expect(viewModel.pendingDeletion == nil)
            viewModel.isShowingError = false
            #expect(viewModel.errorMessage == nil)
        }
    }

    @Test func confirmsADeletionOnce() async throws {
        let viewModel = ApartmentsViewModel(repository: YieldingApartmentRepository([a100, a101]))

        try await observing(viewModel) {
            viewModel.requestDeletion(a100.id)
            let confirmed = try #require(viewModel.pendingDeletion)
            async let first: Void = viewModel.confirmDeletion(of: confirmed)
            async let second: Void = viewModel.confirmDeletion(of: confirmed)
            _ = await (first, second)

            #expect(viewModel.errorMessage == nil)
            await eventually { viewModel.rows.map(\.name) == ["101"] }
        }
    }
}
