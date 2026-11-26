import Foundation

nonisolated struct ApartmentMerge: Sendable, Equatable {
    let survivor: Revision<Apartment>
    let removedIDs: Set<UUID>
}

nonisolated enum ApartmentDuplicates {
    static func merges(in apartments: [Revision<Apartment>]) -> [ApartmentMerge] {
        Dictionary(grouping: apartments) { ApartmentName.matchKey($0.value.name) }
            .sorted { $0.key < $1.key }
            .compactMap { merge(of: $0.value) }
    }

    private static func merge(of copies: [Revision<Apartment>]) -> ApartmentMerge? {
        guard copies.count > 1, let newest = copies.max(by: isOlder), let survivorID = smallestID(in: copies) else {
            return nil
        }
        let survivor = Apartment(
            id: survivorID,
            name: newest.value.name,
            price: newest.value.price,
            accessCode: newest.value.accessCode,
            isReportedSeparately: newest.value.isReportedSeparately,
            createdAt: copies.map(\.value.createdAt).min() ?? newest.value.createdAt
        )
        return ApartmentMerge(
            survivor: Revision(value: survivor, changedAt: newest.changedAt),
            removedIDs: Set(copies.map(\.value.id)).subtracting([survivorID])
        )
    }

    private static func isOlder(_ lhs: Revision<Apartment>, _ rhs: Revision<Apartment>) -> Bool {
        if lhs.changedAt != rhs.changedAt {
            return lhs.changedAt < rhs.changedAt
        }
        return lhs.value.id.uuidString > rhs.value.id.uuidString
    }

    private static func smallestID(in copies: [Revision<Apartment>]) -> UUID? {
        copies.map(\.value.id).min { $0.uuidString < $1.uuidString }
    }
}
