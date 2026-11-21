#if DEBUG
    import Foundation

    final class FakeApartmentRepository: ApartmentRepository {
        private var stored: [UUID: Apartment]
        private let now: () -> Date
        private let observers = StoreObservers()

        init(_ apartments: [Apartment] = [], now: @escaping () -> Date = Date.init) {
            stored = Dictionary(uniqueKeysWithValues: apartments.map { ($0.id, $0) })
            self.now = now
        }

        func apartments(includingArchived: Bool) -> AsyncStream<[Apartment]> {
            observers.stream { [unowned self] in
                stored.values
                    .filter { includingArchived || !$0.isArchived }
                    .sorted { $0.sortOrder < $1.sortOrder }
            }
        }

        func add(_ draft: ApartmentDraft) async throws -> Apartment {
            let valid = try draft.validated(against: Array(stored.values))
            let apartment = Apartment(valid, sortOrder: nextSortOrder, createdAt: now())
            stored[apartment.id] = apartment
            observers.notify()
            return apartment
        }

        func update(_ apartment: Apartment) async throws {
            let current = try storedApartment(apartment.id)
            let valid = try ApartmentDraft(apartment).validated(against: Array(stored.values), excluding: apartment.id)
            stored[apartment.id] = current.applying(valid)
            observers.notify()
        }

        func archive(_ id: UUID) async throws {
            var apartment = try storedApartment(id)
            apartment.isArchived = true
            stored[id] = apartment
            observers.notify()
        }

        func reorder(_ ids: [UUID]) async throws {
            let apartments = try ids.map(storedApartment)
            for (sortOrder, var apartment) in apartments.enumerated() {
                apartment.sortOrder = sortOrder
                stored[apartment.id] = apartment
            }
            observers.notify()
        }

        private var nextSortOrder: Int {
            (stored.values.map(\.sortOrder).max() ?? -1) + 1
        }

        private func storedApartment(_ id: UUID) throws(ApartmentError) -> Apartment {
            guard let apartment = stored[id] else { throw .notFound }
            return apartment
        }
    }
#endif
