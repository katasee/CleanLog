nonisolated struct EarningsChange: Sendable, Equatable {
    enum Direction: Sendable, Equatable {
        case up
        case down
        case same
    }

    private static let percentScale = 100

    let direction: Direction
    let percent: Int

    static func between(current: Money, previous: Money) -> EarningsChange? {
        guard current > .zero, previous > .zero else { return nil }
        let difference = (current - previous).minorUnits
        let percent = HalfUpDivision.divide(abs(difference) * percentScale, by: previous.minorUnits)
        return EarningsChange(
            direction: direction(of: difference, percent: percent),
            percent: percent
        )
    }

    private static func direction(of difference: Int, percent: Int) -> Direction {
        guard percent > 0 else { return .same }
        return difference > 0 ? .up : .down
    }
}
