import Foundation

nonisolated struct Revision<Value: Sendable & Equatable>: Sendable, Equatable {
    var value: Value
    var changedAt: Date
}

extension Revision where Value: Identifiable, Value.ID == UUID {
    nonisolated static func newestFirst(_ copies: [Revision]) -> [Revision] {
        copies.sorted { lhs, rhs in
            guard lhs.changedAt == rhs.changedAt else { return lhs.changedAt > rhs.changedAt }
            return lhs.value.id.uuidString < rhs.value.id.uuidString
        }
    }

    nonisolated static func survivorID(among copies: [Revision]) -> UUID? {
        copies.map(\.value.id).min { $0.uuidString < $1.uuidString }
    }
}
