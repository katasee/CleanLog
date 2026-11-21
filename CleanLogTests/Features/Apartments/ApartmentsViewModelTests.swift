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

    private func observing(_ body: () async throws -> Void) async rethrows {
        let task = Task { await viewModel.observe() }
        defer { task.cancel() }
        await eventually { !viewModel.rows.isEmpty }
        try await body()
    }

    @Test func listsRowsInNameOrder() async {
        let repository = FakeApartmentRepository([
            .fixture("6piw"),
            .fixture("106", minorUnits: 5600, separate: true),
            .fixture("54"),
        ])
        let viewModel = ApartmentsViewModel(repository: repository, locale: Locale(identifier: "uk_UA"))
        let task = Task { await viewModel.observe() }
        defer { task.cancel() }

        await eventually { viewModel.rows.count == 3 }

        #expect(viewModel.rows.map(\.name) == ["54", "106", "6piw"])
        #expect(viewModel.rows[1].priceText == "56\u{00A0}zł")
        #expect(viewModel.rows[1].isReportedSeparately)
        #expect(!viewModel.rows[0].isReportedSeparately)
        #expect(viewModel.count == 3)
        #expect(!viewModel.showsEmptyState)
    }

    @Test func showsTheEmptyStateOnlyOnceLoaded() async {
        let viewModel = ApartmentsViewModel(repository: FakeApartmentRepository())
        #expect(!viewModel.showsEmptyState)

        let task = Task { await viewModel.observe() }
        defer { task.cancel() }

        await eventually { viewModel.showsEmptyState }
        #expect(viewModel.count == 0)
    }

    @Test func opensTheSheets() async {
        await observing {
            viewModel.add()
            #expect(viewModel.sheet == .new)

            viewModel.edit(a100.id)
            #expect(viewModel.sheet == .edit(a100))

            viewModel.sheet = nil
            viewModel.edit(UUID())
            #expect(viewModel.sheet == nil)
        }
    }

    @Test func deletesOnlyAfterConfirmation() async {
        await observing {
            viewModel.requestDeletion(a100.id)
            #expect(viewModel.pendingDeletion?.name == "100")
            #expect(viewModel.isConfirmingDeletion)

            viewModel.cancelDeletion()
            #expect(viewModel.pendingDeletion == nil)
            #expect(viewModel.rows.count == 2)

            viewModel.requestDeletion(a100.id)
            await viewModel.confirmDeletion()

            await eventually { viewModel.rows.map(\.name) == ["101"] }
            #expect(viewModel.pendingDeletion == nil)
            #expect(viewModel.errorMessage == nil)
        }
    }

    @Test func dismissingTheConfirmationCancelsTheDeletion() async {
        await observing {
            viewModel.requestDeletion(a100.id)
            viewModel.isConfirmingDeletion = false
            #expect(viewModel.pendingDeletion == nil)
        }
    }

    @Test func ignoresADeletionOfAnUnknownApartment() async {
        await observing {
            viewModel.requestDeletion(UUID())
            #expect(viewModel.pendingDeletion == nil)
        }
    }

    @Test func reportsAFailedDeletion() async throws {
        try await observing {
            viewModel.requestDeletion(a100.id)
            try await repository.delete(a100.id)

            await viewModel.confirmDeletion()

            #expect(viewModel.errorMessage != nil)
            #expect(viewModel.isShowingError)
            #expect(viewModel.pendingDeletion == nil)
            viewModel.isShowingError = false
            #expect(viewModel.errorMessage == nil)
        }
    }

    @Test func confirmsADeletionOnce() async {
        await observing {
            viewModel.requestDeletion(a100.id)
            async let first: Void = viewModel.confirmDeletion()
            async let second: Void = viewModel.confirmDeletion()
            _ = await (first, second)

            #expect(viewModel.errorMessage == nil)
        }
    }
}
