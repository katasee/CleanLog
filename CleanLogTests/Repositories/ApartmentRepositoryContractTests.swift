import Foundation
import Testing

@testable import CleanLog

struct ApartmentRepositoryContractTests {
    private let now = Date.warsaw(2026, 11, 13, 9)

    private func draft(_ name: String, code: String? = nil) -> ApartmentDraft {
        ApartmentDraft(
            name: name,
            price: Money(minorUnits: 2800),
            accessCode: code,
            isReportedSeparately: false
        )
    }

    @Test(arguments: RepositoryKind.allCases)
    func startsEmpty(kind: RepositoryKind) async {
        var stream = kind.makeStore(now: now).apartments.apartments().makeAsyncIterator()
        #expect(await stream.next() == [])
    }

    @Test(arguments: RepositoryKind.allCases)
    func listsApartmentsInNameOrder(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        var stream = repository.apartments().makeAsyncIterator()
        _ = await stream.next()

        let added = try await repository.add(draft(" 100 ", code: "  "))
        _ = try await repository.add(draft("6piw", code: "4821"))
        _ = try await repository.add(draft("54"))

        #expect(added.name == "100")
        #expect(added.accessCode == nil)
        #expect(added.createdAt == now)
        let listed = try #require(await stream.next())
        #expect(listed.map(\.name) == ["54", "100", "6piw"])
        #expect(listed[2].accessCode == "4821")
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
        apartment.price = Money(minorUnits: 3000)
        apartment.accessCode = "1234#"
        try await repository.update(apartment)

        var stream = repository.apartments().makeAsyncIterator()
        let stored = try #require(await stream.next()?.first { $0.id == apartment.id })
        #expect(stored.name == "100A")
        #expect(stored.price == Money(minorUnits: 3000))
        #expect(stored.accessCode == "1234#")
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
    func deletesAnApartment(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        let apartment = try await repository.add(draft("100"))
        _ = try await repository.add(draft("101"))

        try await repository.delete(apartment.id)

        var stream = repository.apartments().makeAsyncIterator()
        #expect(await stream.next()?.map(\.name) == ["101"])
        await #expect(throws: ApartmentError.notFound) { try await repository.delete(apartment.id) }
    }

    @Test(arguments: RepositoryKind.allCases)
    func freesTheNameOfADeletedApartment(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        let apartment = try await repository.add(draft("100"))
        try await repository.delete(apartment.id)
        #expect(try await repository.add(draft("100")).name == "100")
    }

    @Test(arguments: RepositoryKind.allCases)
    func notifiesEveryObserver(kind: RepositoryKind) async throws {
        let repository = kind.makeStore(now: now).apartments
        var first = repository.apartments().makeAsyncIterator()
        var second = repository.apartments().makeAsyncIterator()
        _ = await first.next()
        _ = await second.next()

        _ = try await repository.add(draft("100"))

        #expect(await first.next()?.map(\.name) == ["100"])
        #expect(await second.next()?.map(\.name) == ["100"])
    }
}
