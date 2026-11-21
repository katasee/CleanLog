import Foundation

protocol ApartmentRepository: AnyObject {
    func apartments() -> AsyncStream<[Apartment]>
    func add(_ draft: ApartmentDraft) async throws -> Apartment
    func update(_ apartment: Apartment) async throws
    func delete(_ id: UUID) async throws
}
