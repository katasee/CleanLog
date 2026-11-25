nonisolated enum HalfUpDivision {
    static func divide(_ numerator: Int, by denominator: Int) -> Int {
        (numerator * 2 + denominator) / (denominator * 2)
    }
}
