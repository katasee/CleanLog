import Foundation

nonisolated enum ApartmentNameOrder {
    static func sorted<Values: Sequence>(_ values: Values, by name: (Values.Element) -> String) -> [Values.Element] {
        values.sorted { areInIncreasingOrder(name($0), name($1)) }
    }

    static func areInIncreasingOrder(_ lhs: String, _ rhs: String) -> Bool {
        let lhsRank = rank(of: lhs)
        let rhsRank = rank(of: rhs)
        guard lhsRank == rhsRank else {
            return lhsRank < rhsRank
        }
        switch lhs.compare(rhs, options: [.numeric, .caseInsensitive], range: nil, locale: nil) {
        case .orderedAscending:
            return true
        case .orderedDescending:
            return false
        case .orderedSame:
            return lhs < rhs
        }
    }

    private static func rank(of name: String) -> Int {
        isDigitsOnly(name) ? 0 : 1
    }

    private static func isDigitsOnly(_ name: String) -> Bool {
        !name.isEmpty && name.allSatisfy { ("0"..."9").contains($0) }
    }
}
