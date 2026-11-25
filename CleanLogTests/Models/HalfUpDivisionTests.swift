import Testing

@testable import CleanLog

struct HalfUpDivisionTests {
    @Test(arguments: [(10, 4, 3), (9, 4, 2), (1, 2, 1), (1, 3, 0), (0, 5, 0)])
    func roundsHalfUp(numerator: Int, denominator: Int, expected: Int) {
        #expect(HalfUpDivision.divide(numerator, by: denominator) == expected)
    }
}
