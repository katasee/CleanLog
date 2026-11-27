import Foundation
import SwiftData
import os

final class SwiftDataApartmentRepository: ApartmentRepository, StoreRepublishing {
    private let container: ModelContainer
    private let now: () -> Date
    private let observers = StoreObservers()
    private let logger = Logger(subsystem: "CleanLog", category: "SwiftDataApartmentRepository")

    init(container: ModelContainer, now: @escaping () -> Date = Date.init) {
        self.container = container
        self.now = now
    }

    func apartments() -> AsyncStream<[Apartment]> {
        observers.stream { [unowned self] in
            do {
                return ApartmentNameOrder.sorted(try storedRecords().map(\.domain), by: \.name)
            } catch {
                logger.error("Could not read apartments: \(error)")
                return []
            }
        }
    }

    func add(_ draft: ApartmentDraft) async throws -> Apartment {
        let existing = try storedRecords().map(\.domain)
        let valid = try draft.validated(against: existing)
        let apartment = Apartment(valid, createdAt: now())
        context.inserted(ApartmentRecord()).apply(Revision(value: apartment, changedAt: apartment.createdAt))
        try save()
        return apartment
    }

    func update(_ apartment: Apartment) async throws {
        let records = try storedRecords()
        guard let record = records.first(where: { $0.id == apartment.id }) else {
            throw ApartmentError.notFound
        }
        let valid = try ApartmentDraft(apartment).validated(against: records.map(\.domain), excluding: apartment.id)
        record.apply(Revision(value: record.domain.applying(valid), changedAt: now()))
        try save()
    }

    func delete(_ id: UUID) async throws {
        context.delete(try storedRecord(id))
        try save()
    }

    func republish() {
        observers.notify()
    }

    private var context: ModelContext {
        container.mainContext
    }

    private func storedRecords() throws -> [ApartmentRecord] {
        try context.fetch(FetchDescriptor<ApartmentRecord>())
    }

    private func storedRecord(_ id: UUID) throws -> ApartmentRecord {
        let descriptor = FetchDescriptor<ApartmentRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else { throw ApartmentError.notFound }
        return record
    }

    private func save() throws {
        try context.saveOrRollBack()
        observers.notify()
    }
}
