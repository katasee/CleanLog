import Foundation
import Testing

@testable import CleanLog

struct ApartmentRepositoryContractTests {
    private let now = Date.warsaw(2026, 11, 13, 9)

    private func draft(_ name: String, code: String? = nil) -> ApartmentDraft {
        ApartmentDraft(name: name, price: Money(grosze: 2800), accessCode: code, isReportedSeparately: false)
    }

    @Test(arguments: RepositoryKind.allCases)
    func startsEmpty(kind: RepositoryKind) async {
        var stream = kind.makeStore(now: now).apartments.apartments(includingArchived: false).makeAsyncIterator()
        #expect(await stream.next() == [])
    }

    @Test(arguments: RepositoryKind.allCases)
    func addsApartmentsInOrder(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        var stream = repository.apartments(includingArchived: false).makeAsyncIterator()
        _ = await stream.next()

        let added = try await repository.add(draft(" 100 ", code: "  "))
        _ = try await repository.add(draft("101", code: "4821"))
        _ = try await repository.add(draft("102"))

        #expect(added.name == "100")
        #expect(added.accessCode == nil)
        #expect(added.createdAt == now)
        let listed = try #require(await stream.next())
        #expect(listed.map(\.name) == ["100", "101", "102"])
        #expect(listed.map(\.sortOrder) == [0, 1, 2])
        #expect(listed[1].accessCode == "4821")
    }

    @Test(arguments: RepositoryKind.allCases)
    func rejectsADuplicateName(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        _ = try await repository.add(draft("100"))
        await #expect(throws: ApartmentError.duplicateName) {
            try await repository.add(draft(" 100"))
        }
    }

    @Test(arguments: RepositoryKind.allCases)
    func updatesTheEditableFields(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        var apartment = try await repository.add(draft("100"))
        _ = try await repository.add(draft("101"))

        apartment.name = "100A "
        apartment.price = Money(grosze: 3000)
        apartment.accessCode = "1234#"
        try await repository.update(apartment)

        var stream = repository.apartments(includingArchived: false).makeAsyncIterator()
        let stored = try #require(await stream.next()?.first)
        #expect(stored.name == "100A")
        #expect(stored.price == Money(grosze: 3000))
        #expect(stored.accessCode == "1234#")
        #expect(stored.sortOrder == 0)
    }

    @Test(arguments: RepositoryKind.allCases)
    func validatesAnUpdate(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        var apartment = try await repository.add(draft("100"))
        _ = try await repository.add(draft("101"))

        try await repository.update(apartment)
        apartment.name = "101"
        await #expect(throws: ApartmentError.duplicateName) { try await repository.update(apartment) }
        await #expect(throws: ApartmentError.notFound) { try await repository.update(.fixture("999")) }
    }

    @Test(arguments: RepositoryKind.allCases)
    func archivingHidesButKeeps(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        let apartment = try await repository.add(draft("100"))
        try await repository.archive(apartment.id)

        var active = repository.apartments(includingArchived: false).makeAsyncIterator()
        var all = repository.apartments(includingArchived: true).makeAsyncIterator()
        #expect(await active.next() == [])
        #expect(await all.next()?.map(\.isArchived) == [true])
        await #expect(throws: ApartmentError.notFound) { try await repository.archive(UUID()) }
    }

    @Test(arguments: RepositoryKind.allCases)
    func reordersByTheGivenIds(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        let first = try await repository.add(draft("a"))
        let second = try await repository.add(draft("b"))
        let third = try await repository.add(draft("c"))

        try await repository.reorder([third.id, first.id, second.id])

        var stream = repository.apartments(includingArchived: false).makeAsyncIterator()
        #expect(await stream.next()?.map(\.name) == ["c", "a", "b"])
        await #expect(throws: ApartmentError.notFound) { try await repository.reorder([UUID()]) }
    }

    @Test(arguments: RepositoryKind.allCases)
    func notifiesEveryObserver(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        var first = repository.apartments(includingArchived: false).makeAsyncIterator()
        var second = repository.apartments(includingArchived: false).makeAsyncIterator()
        _ = await first.next()
        _ = await second.next()

        _ = try await repository.add(draft("100"))

        #expect(await first.next()?.map(\.name) == ["100"])
        #expect(await second.next()?.map(\.name) == ["100"])
    }
}
