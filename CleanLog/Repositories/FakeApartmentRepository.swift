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

        func apartments() -> AsyncStream<[Apartment]> {
            observers.stream { [unowned self] in
                ApartmentNameOrder.sorted(stored.values, by: \.name)
            }
        }

        func add(_ draft: ApartmentDraft) async throws -> Apartment {
            let valid = try draft.validated(against: Array(stored.values))
            let apartment = Apartment(valid, createdAt: now())
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

        func delete(_ id: UUID) async throws {
            guard stored.removeValue(forKey: id) != nil else { throw ApartmentError.notFound }
            observers.notify()
        }

        private func storedApartment(_ id: UUID) throws(ApartmentError) -> Apartment {
            guard let apartment = stored[id] else { throw .notFound }
            return apartment
        }
    }
#endif
