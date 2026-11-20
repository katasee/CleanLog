import Foundation

/// An amount of złoty, kept as whole grosze so sums are exact.
nonisolated struct Money: Sendable, Hashable, Comparable, Codable {
    static let zero = Money(grosze: 0)

    let grosze: Int

    static func + (lhs: Money, rhs: Money) -> Money {
        Money(grosze: lhs.grosze + rhs.grosze)
    }

    static func - (lhs: Money, rhs: Money) -> Money {
        Money(grosze: lhs.grosze - rhs.grosze)
    }

    static func += (lhs: inout Money, rhs: Money) {
        lhs = lhs + rhs
    }

    static func * (lhs: Money, rhs: Int) -> Money {
        Money(grosze: lhs.grosze * rhs)
    }

    static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.grosze < rhs.grosze
    }
}

extension Sequence where Element == Money {
    nonisolated func sum() -> Money {
        reduce(.zero, +)
    }
}
