import Foundation
import SwiftData
import os

final class SwiftDataApartmentRepository: ApartmentRepository {
    private let container: ModelContainer
    private let now: () -> Date
    private let observers = StoreObservers()
    private let logger = Logger(subsystem: "CleanLog", category: "SwiftDataApartmentRepository")

    init(container: ModelContainer, now: @escaping () -> Date = Date.init) {
        self.container = container
        self.now = now
    }

    func apartments(includingArchived: Bool) -> AsyncStream<[Apartment]> {
        observers.stream { [unowned self] in
            do {
                return try storedRecords()
                    .filter { includingArchived || !$0.isArchived }
                    .map(\.domain)
            } catch {
                logger.error("Could not read apartments: \(error)")
                return []
            }
        }
    }

    func add(_ draft: ApartmentDraft) async throws -> Apartment {
        let existing = try storedRecords().map(\.domain)
        let valid = try draft.validated(against: existing)
        let nextSortOrder = (existing.map(\.sortOrder).max() ?? -1) + 1
        let apartment = Apartment(valid, sortOrder: nextSortOrder, createdAt: now())
        let record = ApartmentRecord()
        context.insert(record)
        record.apply(apartment)
        try save()
        return apartment
    }

    func update(_ apartment: Apartment) async throws {
        let records = try storedRecords()
        guard let record = records.first(where: { $0.id == apartment.id }) else {
            throw ApartmentError.notFound
        }
        let valid = try ApartmentDraft(apartment).validated(against: records.map(\.domain), excluding: apartment.id)
        record.apply(record.domain.applying(valid))
        try save()
    }

    func archive(_ id: UUID) async throws {
        try storedRecord(id).isArchived = true
        try save()
    }

    func reorder(_ ids: [UUID]) async throws {
        let records = try ids.map(storedRecord)
        for (sortOrder, record) in records.enumerated() {
            record.sortOrder = sortOrder
        }
        try save()
    }

    private var context: ModelContext {
        container.mainContext
    }

    private func storedRecords() throws -> [ApartmentRecord] {
        try context.fetch(FetchDescriptor<ApartmentRecord>(sortBy: [SortDescriptor(\.sortOrder)]))
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
