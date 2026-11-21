import Foundation

protocol ApartmentRepository: AnyObject {
    func apartments(includingArchived: Bool) -> AsyncStream<[Apartment]>
    func add(_ draft: ApartmentDraft) async throws -> Apartment
    func update(_ apartment: Apartment) async throws
    func archive(_ id: UUID) async throws
    func reorder(_ ids: [UUID]) async throws
}
