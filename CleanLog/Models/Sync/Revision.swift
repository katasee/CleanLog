import Foundation

nonisolated struct Revision<Value: Sendable & Equatable>: Sendable, Equatable {
    var value: Value
    var changedAt: Date
}
