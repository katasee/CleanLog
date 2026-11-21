import Foundation

@testable import CleanLog

final class YieldingApartmentRepository: ApartmentRepository {
    private let wrapped: FakeApartmentRepository

    init(_ apartments: [Apartment]) {
        wrapped = FakeApartmentRepository(apartments)
    }

    func apartments() -> AsyncStream<[Apartment]> {
        wrapped.apartments()
    }

    func add(_ draft: ApartmentDraft) async throws -> Apartment {
        await Task.yield()
        return try await wrapped.add(draft)
    }

    func update(_ apartment: Apartment) async throws {
        await Task.yield()
        try await wrapped.update(apartment)
    }

    func delete(_ id: UUID) async throws {
        await Task.yield()
        try await wrapped.delete(id)
    }
}
