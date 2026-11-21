import Foundation

nonisolated struct Money: Sendable, Hashable, Comparable, Codable {
    static let zero = Money(minorUnits: 0)

    let minorUnits: Int

    static func + (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs.minorUnits + rhs.minorUnits)
    }

    static func - (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs.minorUnits - rhs.minorUnits)
    }

    static func += (lhs: inout Money, rhs: Money) {
        lhs = lhs + rhs
    }

    static func * (lhs: Money, rhs: Int) -> Money {
        Money(minorUnits: lhs.minorUnits * rhs)
    }

    static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.minorUnits < rhs.minorUnits
    }
}

extension Sequence where Element == Money {
    nonisolated func sum() -> Money {
        reduce(.zero, +)
    }
}
